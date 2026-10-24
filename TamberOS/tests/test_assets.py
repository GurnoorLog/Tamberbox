import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('assets',ROOT/'scripts/check_assets.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

class AssetTests(unittest.TestCase):
    def test_originals_unchanged(self):self.assertEqual(m.check(),[])
    def test_changed_original_rejected(self):
        with tempfile.TemporaryDirectory() as t:
            r=Path(t);(r/'references').mkdir();(r/'branding').mkdir()
            (r/'branding/logo.svg').write_text('changed')
            (r/'references/assets.lock.json').write_text(json.dumps({'original_assets':{'branding/logo.svg':'0'*64},'final_concepts':{}}))
            self.assertTrue(any('changed' in e for e in m.check(r)))
    def test_missing_concepts_cannot_pass_release_gate(self):
        with tempfile.TemporaryDirectory() as t:
            r=Path(t);(r/'references').mkdir()
            (r/'references/assets.lock.json').write_text(json.dumps({'original_assets':{},'final_concepts':{}}))
            self.assertTrue(any('BLOCKED' in e for e in m.check(r,True)))
