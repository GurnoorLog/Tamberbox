#!/usr/bin/env python3
"""Run real VM + SSH checks together, supporting per-exec network isolation."""
import argparse
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import time
from urllib.parse import urlparse
import vm


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--name',required=True)
    p.add_argument('--code',required=True)
    p.add_argument('--vars',required=True)
    p.add_argument('--use-host-proxy',action='store_true')
    p.add_argument('--host-ca-bundle',type=Path,help='Explicit public development proxy CA bundle; copied only into this guest')
    p.add_argument('--build-shell',action='store_true')
    args=p.parse_args()
    proxy=None
    if args.use_host_proxy:
        u=urlparse(os.environ.get('https_proxy',os.environ.get('HTTPS_PROXY','')))
        if u.scheme!='http' or u.hostname not in ('127.0.0.1','localhost') or u.username or u.password or not u.port:
            raise ValueError('Expected credential-free loopback HTTP proxy in this execution environment')
        proxy=f'http://10.0.2.2:{u.port}'
    prep=argparse.Namespace(name=args.name,code=args.code,vars=args.vars,smoke=False,proxy=proxy)
    # Inject only explicitly supplied public certificates into the disposable seed.
    original_config=vm.cloud_config
    if args.host_ca_bundle:
        ca=args.host_ca_bundle.read_text()
        if 'PRIVATE KEY' in ca or 'BEGIN CERTIFICATE' not in ca:raise ValueError('Expected public PEM certificate bundle')
        def with_ca(*params):
            cfg=json.loads(original_config(*params).split('\n',1)[1])
            cfg['write_files'].append({'path':'/etc/pki/ca-trust/source/anchors/tamber-dev-proxy.pem','permissions':'0644','content':ca})
            cfg['runcmd'].insert(0,['update-ca-trust'])
            return '#cloud-config\n'+json.dumps(cfg,indent=2)+'\n'
        vm.cloud_config=with_ca
    vm.prepare(prep,vm.load_lock())
    dest=vm.output_path(args.name)
    report={'boot':False,'ssh':False,'cloud_init':False,'smoke':False,'dnf_transaction':False,'shell_build':False,'proxy':bool(proxy)}
    runner=None
    def ssh(command,filename,timeout=120):
        cmd=['ssh','-n','-o','ServerAliveInterval=15','-o','ServerAliveCountMax=3','-i',str(dest/'id_ed25519'),'-p','2222','-o','BatchMode=yes',
             '-o','ConnectTimeout=10','-o','StrictHostKeyChecking=yes',
             '-o',f'UserKnownHostsFile={dest / "known_hosts"}','tamber@127.0.0.1',command]
        print('Running guest check: '+filename,flush=True)
        with (dest/filename).open('w') as f:
            result=subprocess.run(cmd,stdout=f,stderr=subprocess.STDOUT,timeout=timeout)
        return result.returncode
    with (dest/'runner.txt').open('w') as runlog:
        try:
            runner=subprocess.Popen([sys.executable,str(Path(vm.__file__)),'run','--name',args.name,'--network','--ssh-port','2222','--timeout','7200'],stdout=runlog,stderr=subprocess.STDOUT,start_new_session=True)
            deadline=time.monotonic()+900
            key=None
            while time.monotonic()<deadline:
                if runner.poll() is not None:raise RuntimeError('VM exited before SSH readiness')
                if (dest/'serial.log').exists():
                    serial=(dest/'serial.log').read_text(errors='replace')
                    match=re.search(r'TAMBER_SSH_HOSTKEY (ssh-ed25519 [A-Za-z0-9+/=]+)',serial)
                    if match:key=match.group(1);break
                time.sleep(3)
            if not key:raise TimeoutError('No SSH host key from trusted local serial channel')
            report['boot']=True
            (dest/'known_hosts').write_text('[127.0.0.1]:2222 '+key+'\n')
            for _ in range(20):
                if ssh('id; uname -m; uname -r; cat /etc/os-release','ssh-login.txt')==0:
                    report['ssh']=True;break
                time.sleep(3)
            if not report['ssh']:raise RuntimeError('SSH login failed')
            report['cloud_init']=ssh('cloud-init status --wait --long','cloud-init.txt',180)==0
            proxy_option=f'--proxy {proxy}' if proxy else ''
            ssh(f'ip -brief addr; cat /etc/resolv.conf; curl {proxy_option} --verbose --fail --max-time 25 -I https://repo.almalinux.org/', 'network-diagnostic.txt',60)
            ssh('sudo /usr/local/bin/tamber-m1-check | sudo tee /dev/ttyAMA0','guest-smoke.txt',1800)
            smoke=(dest/'guest-smoke.txt').read_text()
            report['smoke_checks']=vm.check_transcript(smoke)
            report['smoke']=all(report['smoke_checks'].values())
            if args.build_shell:
                # SCP source files only; no host directory sharing, credentials or image cache.
                subprocess.run(['scp','-i',str(dest/'id_ed25519'),'-P','2222','-o','StrictHostKeyChecking=yes',
                    '-o',f'UserKnownHostsFile={dest / "known_hosts"}','-r',str(vm.ROOT/'shell/tamber-shell'),
                    'tamber@127.0.0.1:/home/tamber/'],check=True,timeout=60)
                install='sudo dnf --releasever=10.2 -y '
                if proxy:install+=f'--setopt=proxy={proxy} '
                install+='install gcc-c++ cmake ninja-build qt6-qtbase-devel qt6-qtdeclarative-devel rpm-build'
                report['dnf_transaction']=ssh(install,'dnf-install.txt',2400)==0
                if report['dnf_transaction']:
                    report['shell_build']=ssh('cmake -S tamber-shell -B build/shell -DCMAKE_BUILD_TYPE=Release && cmake --build build/shell --parallel 2 && file build/shell/tamber-shell','shell-build.txt',2400)==0
                ssh("rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\\n' | sort",'rpm-inventory.txt',120)
            ssh('sudo poweroff','poweroff.txt',30)
            runner.wait(timeout=120)
        except (Exception, KeyboardInterrupt) as e:
            report['error']=str(e) or type(e).__name__
        finally:
            if runner and runner.poll() is None:
                os.killpg(runner.pid, signal.SIGINT)
                try:runner.wait(timeout=20)
                except subprocess.TimeoutExpired:
                    os.killpg(runner.pid, signal.SIGKILL)
                    runner.wait()
            (dest/'live-result.json').write_text(json.dumps(report,indent=2)+'\n')
            print(json.dumps(report,indent=2),flush=True)
    return 0 if all(report[k] for k in ('boot','ssh','cloud_init','smoke')) and (not args.build_shell or report['shell_build']) else 1


if __name__=='__main__':sys.exit(main())
