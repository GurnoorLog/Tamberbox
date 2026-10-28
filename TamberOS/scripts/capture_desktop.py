#!/usr/bin/env python3
"""Capture the actual isolated desktop; no test suite or physical devices."""
import os, pathlib, subprocess, tempfile, time
ROOT=pathlib.Path(__file__).resolve().parents[1]
out=ROOT/'build/ui-capture';out.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='tamber-capture-') as temp:
    base=pathlib.Path(temp);runtime=base/'runtime';runtime.mkdir(mode=0o700)
    env=os.environ.copy()
    env.update(XDG_RUNTIME_DIR=str(runtime),XDG_CONFIG_HOME=str(base/'config'),TAMBER_ROOT=str(ROOT),TAMBER_EXTERNAL_BAR='1',XDG_CURRENT_DESKTOP='sway',XDG_SESSION_TYPE='wayland',WLR_BACKENDS='headless',WLR_RENDERER='pixman',WLR_HEADLESS_OUTPUTS='1',WLR_LIBINPUT_NO_DEVICES='1',QT_QPA_PLATFORM='wayland',QT_QUICK_BACKEND='software',QT_QUICK_CONTROLS_STYLE='Basic',PATH=str(ROOT/'build/shell')+':'+env['PATH'],LD_LIBRARY_PATH=str(ROOT/'build/session-deps/lib'),QT_PLUGIN_PATH=str(ROOT/'build/session-deps/lib/plugins'))
    env.pop('DISPLAY',None);env.pop('SWAYSOCK',None);env.pop('WAYLAND_DISPLAY',None)
    config=base/'sway.conf';config.write_text((ROOT/'session/sway.conf').read_text()+'\noutput HEADLESS-1 mode 1280x720\n')
    with (out/'runtime.log').open('w') as log:
        proc=subprocess.Popen(['sway','-c',str(config)],env=env,stdout=log,stderr=log)
        try:
            for _ in range(150):
                displays=[p for p in runtime.glob('wayland-*') if not p.name.endswith('.lock')]
                if displays and 'TAMBER_FRAME wallpaper' in (out/'runtime.log').read_text():break
                if proc.poll() is not None:raise RuntimeError('Desktop exited; see runtime.log')
                time.sleep(.2)
            else:raise RuntimeError('Desktop did not render; see runtime.log')
            env['WAYLAND_DISPLAY']=displays[0].name
            time.sleep(3)
            subprocess.run(['grim',str(out/'desktop.png')],env=env,check=True)
        finally:
            proc.terminate();proc.wait(timeout=10)
