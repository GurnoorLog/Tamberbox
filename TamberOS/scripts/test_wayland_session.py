#!/usr/bin/env python3
"""Run only an isolated headless Sway instance. No physical DRM/input access."""
import json,os,pathlib,subprocess,tempfile,time,shutil
ROOT=pathlib.Path(__file__).resolve().parents[1]
OUT=ROOT/'build/m3-evidence';OUT.mkdir(parents=True,exist_ok=True)
def wait(test,seconds=15):
 end=time.monotonic()+seconds
 while time.monotonic()<end:
  value=test()
  if value:return value
  time.sleep(.15)
 raise RuntimeError('Timed out waiting for isolated session')
with tempfile.TemporaryDirectory(prefix='tamber-wayland-') as temp:
 base=pathlib.Path(temp);runtime=base/'runtime';runtime.mkdir(mode=0o700)
 data=base/'data';(data/'applications').mkdir(parents=True)
 (data/'applications/tamber-test.desktop').write_text('[Desktop Entry]\nType=Application\nName=Tamber Test Terminal\nExec=foot --app-id=tamber-test --title=Tamber-terminal\nTerminal=false\n')
 env=os.environ.copy();env.update(XDG_RUNTIME_DIR=str(runtime),XDG_CONFIG_HOME=str(base/'config'),XDG_DATA_HOME=str(data),XDG_DATA_DIRS=str(data),WLR_BACKENDS='headless',WLR_RENDERER='pixman',WLR_HEADLESS_OUTPUTS='1',WLR_LIBINPUT_NO_DEVICES='1',QT_QPA_PLATFORM='wayland',QT_QUICK_BACKEND='software',QT_QUICK_CONTROLS_STYLE='Basic',PATH=str(ROOT/'build/shell')+':'+env['PATH'],LD_LIBRARY_PATH=str(ROOT/'build/session-deps/lib'),QT_PLUGIN_PATH=str(ROOT/'build/session-deps/lib/plugins'))
 env.pop('SWAYSOCK',None);env.pop('WAYLAND_DISPLAY',None);env.pop('DISPLAY',None)
 config=base/'sway.conf';config.write_text((ROOT/'session/sway.conf').read_text()+'\noutput HEADLESS-1 mode 1280x720\n')
 log=(OUT/'sway-session.log').open('w')
 proc=subprocess.Popen(['sway','-d','-c',str(config)],env=env,stdout=log,stderr=subprocess.STDOUT)
 def run(*args,check=True):return subprocess.run(args,env=env,text=True,capture_output=True,check=check,timeout=15)
 try:
  sock=wait(lambda:next(iter(runtime.glob('sway-ipc.*.sock')),None));env['SWAYSOCK']=str(sock)
  display=wait(lambda:next((p for p in runtime.glob('wayland-*') if not p.name.endswith('.lock')),None));env['WAYLAND_DISPLAY']=display.name
  wait(lambda:(runtime/('tamber-'+display.name)).exists());wait(lambda:'TAMBER_FRAME bar' in (OUT/'sway-session.log').read_text(),30);time.sleep(.5)
  run('grim',str(OUT/'desktop.png'))
  run('tamber-desktop','--command','launcher');wait(lambda:'TAMBER_FRAME launcher' in (OUT/'sway-session.log').read_text(),15);time.sleep(.5)
  keyboard=subprocess.Popen(['wtype','-s','400','-d','50','Tamber Test','-s','1500','-k','Return','-s','500'],env=env)
  time.sleep(1.5);run('grim',str(OUT/'launcher.png'));assert keyboard.wait(timeout=10)==0
  def windows():
   tree=json.loads(run('swaymsg','-r','-t','get_tree').stdout)
   def walk(n):
    return ([n] if n.get('app_id')=='tamber-test' else [])+sum((walk(c) for k in ['nodes','floating_nodes'] for c in n.get(k,[])),[])
   return walk(tree)
  found=wait(windows);time.sleep(.5)
  (OUT/'launched-windows.json').write_text(json.dumps(found,indent=2)+'\n')
  assert found[0]['rect']['y']>=40, 'Application overlaps reserved menu bar'
  assert found[0]['rect']['y']+found[0]['rect']['height']<=636, 'Application overlaps reserved dock'
  run('grim',str(OUT/'application.png'))
  run('tamber-desktop','--command','controls');time.sleep(.5);run('grim',str(OUT/'settings.png'))
  run('wtype','-s','400','-k','Escape');time.sleep(.3)
  env['TAMBER_TEST_SWAY']='1'
  result=run(str(ROOT/'build/shell/session-test'));(OUT/'window-actions.txt').write_text(result.stdout+result.stderr)
  del env['TAMBER_TEST_SWAY']
  # Existing launcher and keyboard integration tests now run on real Wayland.
  result=run('ctest','--test-dir',str(ROOT/'build/shell'),'--output-on-failure');(OUT/'ctest.txt').write_text(result.stdout+result.stderr)
  (OUT/'outputs.json').write_text(run('swaymsg','-r','-t','get_outputs').stdout)
  (OUT/'versions.txt').write_text(run('sway','--version').stdout+run('qmake6','-query','QT_VERSION').stdout+run('uname','-m').stdout)
  runtime_log=(OUT/'sway-session.log').read_text()
  for problem in ['Failed to get image from provider','ReferenceError:','TypeError:']:
   assert problem not in runtime_log, problem
  (OUT/'result.json').write_text(json.dumps({'passed':True,'backend':'headless Sway / pixman','physical_devices_used':False,'launcher_keyboard_real_process':True,'window_minimize_restore_close':True,'hardware_validation':'pending'},indent=2)+'\n')
 finally:
  if proc.poll() is None:
   run('swaymsg','exit',check=False);proc.wait(timeout=10)
  log.close()
