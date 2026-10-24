from pathlib import Path
import importlib.util
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1] / 'services/tamber-hardware/tamber_hardware.py'
spec = importlib.util.spec_from_file_location('tamber_hardware', SOURCE)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class HardwareTests(unittest.TestCase):
    def test_memory_units(self):
        self.assertEqual(module.bytes_mem_available('MemTotal: 1000 kB\nMemAvailable: 250 kB\n'), (1024000, 256000))

    def test_safe_missing_sensors(self):
        with tempfile.TemporaryDirectory() as temp:
            data = module.probe(Path(temp))
            self.assertEqual(data['thermal_zone_celsius'], [])
            self.assertIsNone(data['cpu0_frequency_mhz'])
            self.assertEqual(data['npu_runtime_status'], 'not checked')

    def test_fake_fixture_and_invalid_thermal_value(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for path, content in {
                'sys/class/thermal/thermal_zone0/temp': '42200',
                'sys/class/thermal/thermal_zone1/temp': '9999999',
                'sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq': '1800000',
                'proc/meminfo': 'MemTotal: 4000 kB\nMemAvailable: 1234 kB',
                'proc/device-tree/model': 'Orange Pi 5 Ultra\x00',
            }.items():
                file = root / path
                file.parent.mkdir(parents=True, exist_ok=True)
                file.write_text(content)
            data = module.probe(root)
            self.assertEqual(data['thermal_zone_celsius'], [42.2])
            self.assertEqual(data['cpu0_frequency_mhz'], 1800)
            self.assertEqual(data['board_model'], 'Orange Pi 5 Ultra')
            self.assertEqual(data['memory_available_bytes'], 1263616)


if __name__ == '__main__':
    unittest.main()
