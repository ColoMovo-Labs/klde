#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""CircleCI-only software rendering evidence, not a hardware benchmark."""
import argparse
import json
import os
from pathlib import Path
import struct
import subprocess


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('binary', type=Path)
    args = parser.parse_args()
    binary = args.binary.resolve()
    output = Path('artifacts/smoke/matrix')
    output.mkdir(parents=True, exist_ok=True)
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()
    cases = []
    for dark in (False, True):
        for locale in ('zh_CN', 'en'):
            for voice in ('standard', 'cute'):
                cases.append(dict(id=f'{"dark" if dark else "light"}-{locale}-{voice}', dark=dark, locale=locale, voice=voice, view='quick-settings'))
    for scenario in ('critical-battery', 'high-temperature', 'offline', 'desktop-no-battery', 'hybrid-gpu-laptop', 'weather-provider-error', 'session-error', 'input-unavailable', 'no-microphone', 'no-sensors', 'bluetooth-unavailable', 'weak-wifi', 'bluetooth-connected', 'igpu-only-laptop', 'update-available', 'weather-snow', 'weather-rain', 'wifi-disconnected', 'no-internet', 'low-battery', 'weather-clear', 'weather-cloudy', 'weather-thunderstorm', 'weather-fog', 'weather-extreme-heat', 'weather-extreme-cold'):
        for voice in ('standard', 'cute'):
            cases.append(dict(id=f'{scenario}-{voice}', scenario=scenario, voice=voice, view='notifications' if scenario in ('critical-battery','high-temperature','session-error') else 'weather-preview' if scenario.startswith('weather-') else 'ribbon'))
    for name, size, scale in [('laptop','1366x768',1), ('full-hd','1920x1080',1), ('qhd','2560x1440',1), ('hidpi','1440x900',2), ('ultrawide','3440x1440',1), ('portrait','1080x1920',1)]:
        cases.append(dict(id='size-'+name, size=size, scale=scale, view='quick-settings', density='dense'))
    for wallpaper in ('snow','abstract','quiet','kemono'):
        cases.append(dict(id='ambient-'+wallpaper, wallpaper=wallpaper, ambient=True, density='dense'))
    cases.append(dict(id="reference-composition", ambient=True, wallpaper="abstract", view="notifications", density="dense"))
    cases.append(dict(id="expanded-controls", view="quick-settings-expanded", dark=True, voice="cute"))
    for scenario in ('clear-morning', 'cloudy-day', 'sunset', 'rainy-evening', 'starry-night', 'moonlit-night', 'wallpaper-depth-enabled', 'segmentation-failed', 'lock-screen-blur-enabled', 'waydroid-ready'):
        cases.append(dict(id='temporal-'+scenario, scenario=scenario, ambient=True,
                          view='lock-preview' if scenario == 'lock-screen-blur-enabled' else 'launcher' if scenario == 'waydroid-ready' else 'desktop'))
    cases.append(dict(id='working-desktop', scenario='laptop-balanced', view='desktop'))
    cases.append(dict(id='temporal-expanded', scenario='sunset', view='temporal'))
    cases.append(dict(id='ambient-laptop', size='1366x768', ambient=True, density='dense'))
    cases.append(dict(id='lock-screen-dark', scenario='lock-screen-blur-enabled', view='lock-preview', dark=True, ambient=True))
    cases.append(dict(id='temporal-study', view='temporal-study', size='1440x1000'))
    records=[]
    for case in cases:
        options=dict(locale='zh_CN', voice='standard', scenario='laptop-balanced', density='balanced', size='1920x1080', scale=1, dark=False, wallpaper='snow', view='desktop', ambient=False)
        options.update(case)
        stem=output / options['id']
        command=[str(binary), '--smoke-test', '--audit-idle', '--capture', str(stem)+'.png']
        for key in ('locale','voice','scenario','density','size','wallpaper','view'):
            command.extend(['--'+key,options[key]])
        for key in ('dark','ambient'):
            if options[key]: command.append('--'+key)
        env=dict(os.environ,QT_SCALE_FACTOR=str(options['scale']))
        with Path(str(stem)+'.log').open('w') as log:
            result=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=25,check=False)
        record=dict(options,revision=revision,exitCode=result.returncode,physicalSize=None)
        capture=Path(str(stem)+'.png')
        if capture.exists():
            record['physicalSize']=list(struct.unpack('>II',capture.read_bytes()[16:24]))
            logical=[int(n) for n in options['size'].split('x')]
            if record['physicalSize'] != [n*options['scale'] for n in logical]:
                record['exitCode']=1
        else:
            record['exitCode']=1
        records.append(record)
        print(options['id'],record['exitCode'],record['physicalSize'],flush=True)
    (output/'manifest.json').write_text(json.dumps(records,indent=2)+'\n')
    if any(r['exitCode'] != 0 for r in records):
        raise SystemExit('Visual matrix has failed cases; inspect per-case logs and PNGs.')


if __name__ == '__main__':
    main()
