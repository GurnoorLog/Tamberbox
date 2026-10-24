#!/usr/bin/env python3
"""Safe, read-only telemetry probe for TamberOS development.

Null indicates a sensor that could not be detected/read.  No synthetic metrics.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
from typing import Any


def read_int(path: Path) -> int | None:
    try:
        return int(path.read_text().strip())
    except (OSError, ValueError):
        return None


def bytes_mem_available(meminfo: str) -> tuple[int | None, int | None]:
    info = {}
    for line in meminfo.splitlines():
        if ':' not in line:
            continue
        key, value = line.split(':', 1)
        vals = value.strip().split()
        if vals and vals[0].isdigit():
            info[key] = int(vals[0]) * 1024  # /proc/meminfo values are kB
    return info.get('MemTotal'), info.get('MemAvailable')


def probe(sysroot: Path = Path('/')) -> dict[str, Any]:
    """Read only standard Linux sysfs and procfs. Useful with fixture sysroot."""
    temp_values: list[float] = []
    for file in sorted((sysroot / 'sys/class/thermal').glob('thermal_zone*/temp')):
        raw = read_int(file)
        if raw is not None and -40000 <= raw <= 150000:
            temp_values.append(round(raw / 1000.0, 1))
    frequency = read_int(sysroot / 'sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq')
    try:
        memory = (sysroot / 'proc/meminfo').read_text()
        total, available = bytes_mem_available(memory)
    except OSError:
        total, available = None, None
    model_path = sysroot / 'proc/device-tree/model'
    try:
        model = model_path.read_bytes().decode('utf-8', errors='replace').strip('\x00\n')
    except OSError:
        model = None
    return {
        'source': 'linux sysfs/procfs (read only)',
        'board_model': model,
        'cpu0_frequency_mhz': round(frequency / 1000.0, 1) if frequency is not None else None,
        'thermal_zone_celsius': temp_values,
        'memory_total_bytes': total,
        'memory_available_bytes': available,
        'npu_runtime_status': 'not checked',
        'gpu_acceleration_status': 'not checked',
    }


def main() -> None:
    parser = argparse.ArgumentParser(description='Tamber hardware: safe read-only snapshot')
    parser.add_argument('--json', action='store_true', help='format result as JSON')
    args = parser.parse_args()
    result = probe()
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        for key, value in result.items():
            print(f'{key}: {value}')


if __name__ == '__main__':
    main()
