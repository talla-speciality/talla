#!/usr/bin/env python3
"""Run iOS 27 QA across screen classes, without requiring a simulator per hardware SKU."""
import argparse
import json
from pathlib import Path
import subprocess

MATRIX = {
    'small-phone': 'com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation',
    'mini-phone': 'com.apple.CoreSimulator.SimDeviceType.iPhone-13-mini',
    'phone': 'com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro',
    'large-phone': 'com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro-Max',
    'mini-ipad': 'com.apple.CoreSimulator.SimDeviceType.iPad-mini-A17-Pro',
    'ipad': 'com.apple.CoreSimulator.SimDeviceType.iPad-A16',
    'pro-ipad': 'com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M5-12GB',
    'large-ipad': 'com.apple.CoreSimulator.SimDeviceType.iPad-Pro-13-inch-M5-12GB',
}

def sim_json(*args):
    return json.loads(subprocess.check_output(['xcrun', 'simctl', 'list', *args, '-j'], text=True))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--devices', nargs='+', choices=MATRIX, default=list(MATRIX))
    parser.add_argument('--derived-data', default='build/apple-device-tests')
    parser.add_argument('--results', default='build/results/devices')
    parser.add_argument('--skip-build', action='store_true')
    parser.add_argument('--layout-only', action='store_true')
    args = parser.parse_args()
    runtimes = [r for r in sim_json('runtimes')['runtimes'] if r['isAvailable'] and r['version'].split('.')[0] == '27' and '.iOS-' in r['identifier']]
    if not runtimes:
        parser.error('Install an iOS 27 simulator runtime; older runtimes cannot validate this matrix.')
    runtime = max(runtimes, key=lambda r: tuple(map(int, r['version'].split('.'))))['identifier']
    available_types = {d['identifier'] for d in sim_json('devicetypes')['devicetypes']}
    missing = [MATRIX[key] for key in args.devices if MATRIX[key] not in available_types]
    if missing:
        parser.error('Missing simulator device types: ' + ', '.join(missing))
    result_dir = Path(args.results).resolve()
    result_dir.mkdir(parents=True, exist_ok=True)
    base = ['xcodebuild', '-project', 'Talla Speciality.xcodeproj', '-scheme', 'Talla Speciality', '-derivedDataPath', str(Path(args.derived_data).resolve())]
    if not args.skip_build:
        subprocess.run(base + ['-destination', 'generic/platform=iOS Simulator', 'build-for-testing'], check=True)
    outcomes = []
    for key in args.devices:
        name = 'Talla QA ' + key
        devices = sim_json('devices', 'available')['devices'].get(runtime, [])
        device = next((d for d in devices if d['name'] == name and d.get('deviceTypeIdentifier') == MATRIX[key]), None)
        if device is None:
            device_id = subprocess.check_output(['xcrun', 'simctl', 'create', name, MATRIX[key], runtime], text=True).strip()
            was_booted = False
        else:
            device_id, was_booted = device['udid'], device['state'] == 'Booted'
        bundle = result_dir / (key + '.xcresult')
        if bundle.exists():
            parser.error(f'{bundle} already exists; choose a new results directory.')
        command = base + ['-destination', 'platform=iOS Simulator,id=' + device_id, '-parallel-testing-enabled', 'NO', '-collect-test-diagnostics', 'never', '-resultBundlePath', str(bundle), '-only-testing:Talla SpecialityUITests/TallaDeviceLayoutTests']
        if not args.layout_only:
            command += ['-only-testing:Talla SpecialityUITests/Talla_SpecialityUITests']
        print(f'Running {key}: {device_id}', flush=True)
        try:
            with (result_dir / (key + '.log')).open('w') as log:
                result = subprocess.run(command + ['test-without-building'], stdout=log, stderr=subprocess.STDOUT)
            expected_count = 3 if args.layout_only else 9
            try:
                summary = json.loads(subprocess.check_output([
                    'xcrun', 'xcresulttool', 'get', 'test-results', 'summary',
                    '--path', str(bundle), '--format', 'json'
                ], text=True))
            except (subprocess.CalledProcessError, json.JSONDecodeError):
                summary = {}
            passed = result.returncode == 0 and summary.get('passedTests') == expected_count and summary.get('failedTests') == 0 and summary.get('skippedTests') == 0
            outcomes.append({'device': key, 'udid': device_id, 'passed': passed, 'executed': summary.get('totalTestCount', 0), 'result': str(bundle)})
            print(f'{key}: {"PASS" if passed else "FAIL"}', flush=True)
            (result_dir / 'summary.json').write_text(json.dumps(outcomes, indent=2) + '\n')
        finally:
            if not was_booted:
                subprocess.run(['xcrun', 'simctl', 'shutdown', device_id], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    raise SystemExit(0 if all(row['passed'] for row in outcomes) else 1)

if __name__ == '__main__':
    main()
