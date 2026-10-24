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
    cases.extend([
        dict(id='lock-day-ambient', scenario='lock-screen-blur-enabled', view='lock-screen', lock_state='ambient'),
        dict(id='lock-night-ambient', scenario='lock-screen-blur-enabled', view='lock-screen', lock_state='ambient', dark=True),
        dict(id='lock-auth', scenario='lock-screen-blur-enabled', view='lock-screen', lock_state='auth'),
        dict(id='lock-error', scenario='lock-screen-blur-enabled', view='lock-screen', lock_state='error'),
        dict(id='lock-reduced', scenario='lock-screen-blur-enabled', view='lock-screen', lock_state='reduced'),
        dict(id='lock-depth', scenario='wallpaper-depth-enabled', view='lock-screen', lock_state='depth'),
        dict(id='lock-fallback', scenario='segmentation-failed', view='lock-screen', lock_state='fallback'),
        dict(id='lock-debug', scenario='lock-screen-blur-enabled', view='lock-screen', lock_state='auth', debug_geometry=True),
        dict(id='ribbon-debug', view='desktop', debug_geometry=True),
        dict(id='lock-compact-auth', scenario='lock-screen-blur-enabled', view='lock-screen', lock_state='auth', size='1366x768'),
    ])
    for page in range(11):
        cases.append(dict(id=f'welcome-page-{page}', view='welcome', welcome_page=page))
        cases.append(dict(id=f'welcome-en-page-{page}', view='welcome', welcome_page=page, locale='en'))
    for locale in ('zh_CN', 'en'):
        for page in (0, 1, 2):
            cases.append(dict(id=f'welcome-{locale}-page-{page}-1366', view='welcome', welcome_page=page,
                              locale=locale, size='1366x768'))
    cases.append(dict(id='welcome-offline-preparation', view='welcome', welcome_page=8, scenario='offline'))
    for island in ('notification', 'progress', 'privacy', 'authorization', 'media', 'device', 'critical'):
        cases.append(dict(id='system-island-'+island, view='desktop', island_state=island))
    cases.append(dict(id='system-ui-gallery', view='gallery'))
    cases.append(dict(id='temporal-study', view='temporal-study', size='1440x1000'))
    cases.extend([dict(id='material-study-light', view='material-study'),
                  dict(id='material-study-dark', view='material-study', dark=True),
                  dict(id='material-study-en-1440', view='material-study', locale='en', size='1440x900'),
                  dict(id='material-study-kemono', view='material-study', wallpaper='kemono')])
    for name, size in [('hdplus','1600x900'), ('fhd','1920x1080'), ('qhd','2560x1440'), ('narrow','1366x768')]:
        cases.append(dict(id='axis-'+name, size=size))
    cases.extend([dict(id='night-desktop', scenario='moonlit-night', dark=True),
                  dict(id='focus-desktop', focus=True, ambient=True),
                  dict(id='ribbon-detail', region='ribbon'),
                  dict(id='ribbon-narrow-detail', size='1366x768', region='ribbon')])
    records=[]
    for case in cases:
        options=dict(locale='zh_CN', voice='standard', scenario='laptop-balanced', density='balanced', size='1920x1080', scale=1, dark=False, wallpaper='snow', view='desktop', ambient=False, focus=False, region='full', lock_state='ambient', debug_geometry=False, island_state='idle', welcome_page=0)
        options.update(case)
        stem=output / options['id']
        command=[str(binary), '--smoke-test', '--audit-idle', '--capture', str(stem)+'.png']
        for key in ('locale','voice','scenario','density','size','wallpaper','view','lock_state','island_state','welcome_page'):
            command.extend(['--'+key.replace('_', '-'), str(options[key])])
        command.extend(['--capture-region',options['region']])
        for key in ('dark','ambient','focus'):
            if options[key]: command.append('--'+key)
        if options['debug_geometry']:
            command.append('--debug-geometry')
        env=dict(os.environ,QT_SCALE_FACTOR=str(options['scale']))
        with Path(str(stem)+'.log').open('w') as log:
            result=subprocess.run(command,env=env,stdout=log,stderr=subprocess.STDOUT,timeout=25,check=False)
        record=dict(options,revision=revision,exitCode=result.returncode,physicalSize=None)
        capture=Path(str(stem)+'.png')
        if capture.exists():
            record['physicalSize']=list(struct.unpack('>II',capture.read_bytes()[16:24]))
            logical=[int(n) for n in options['size'].split('x')]
            if options['region'] == 'ribbon':
                record['logicalCropHeight']=record['physicalSize'][1]/options['scale']
            if record['physicalSize'][0] != logical[0]*options['scale'] or (options['region'] == 'full' and record['physicalSize'][1] != logical[1]*options['scale']):
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
