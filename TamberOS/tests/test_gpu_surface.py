import importlib.util
import os
from pathlib import Path
import socket
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('gpu_surface', Path(__file__).resolve().parents[1]/'scripts/run_gpu_surface.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

class SurfaceGuards(unittest.TestCase):
    def test_requires_wayland_and_gpu_renderer(self):
        for env in ({}, {'WAYLAND_DISPLAY':'wayland-1','QT_QUICK_BACKEND':'software'}):
            with self.assertRaises(ValueError):
                module.plan('/missing', 'quickshell', env)

    def test_socket_type_symlink_and_owned_export(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp)/'export.sock'
            path.write_text('not a socket')
            with self.assertRaises(ValueError):
                module.plan(str(path), 'quickshell', {'WAYLAND_DISPLAY':'test'})
            path.unlink()
            try:
                server_socket = socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET)
            except PermissionError:
                self.skipTest('This sandbox denies Unix socket creation; exercised on CI')
            with server_socket as server:
                server.bind(str(path))
                link = Path(tmp)/'link'
                link.symlink_to(path)
                with self.assertRaises(ValueError):
                    module.plan(str(link), 'quickshell', {'WAYLAND_DISPLAY':'test'})
                with patch.object(module.shutil, 'which', return_value='/test/quickshell'):
                    command = module.plan(str(path), 'quickshell', {'WAYLAND_DISPLAY':'test'})
                    self.assertEqual(command[:2], ['/test/quickshell', '-p'])
                with patch.object(module.os, 'getuid', return_value=os.getuid()+1):
                    with self.assertRaises(ValueError):
                        module.plan(str(path), 'quickshell', {'WAYLAND_DISPLAY':'test'})
