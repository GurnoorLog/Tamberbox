"""Static integration checks; does not imply Wayland runtime validation."""
import json
import pathlib
import unittest

ROOT=pathlib.Path(__file__).resolve().parents[1]

class WaybarGameIntegrationTest(unittest.TestCase):
 def test_sway_modules_and_no_external_commands(self):
  config=json.loads((ROOT/'session/waybar/config.jsonc').read_text())
  joined=json.dumps(config)
  self.assertIn('sway/workspaces',joined)
  self.assertIn('sway/window',joined)
  for forbidden in ['hyprland/','omarchy-', 'pacman', 'wttrbar', '/home/']:
   self.assertNotIn(forbidden,joined)
  self.assertEqual(config['custom/tamber']['on-click'], 'tamber-desktop --command launcher')
  self.assertEqual(config['custom/tamber']['on-click-right'], 'tamber-desktop --command games')
 def test_own_session_and_fallback(self):
  sway=(ROOT/'session/sway.conf').read_text()
  start=(ROOT/'session/start-tamber-session').read_text()
  qml=(ROOT/'shell/tamber-shell/desktop/Desktop.qml').read_text()
  self.assertIn('exec waybar --config',sway)
  self.assertIn('TAMBER_EXTERNAL_BAR',start)
  self.assertIn('if(!externalBar)',qml)
  self.assertIn('Mod4+g exec tamber-desktop --command games',sway)
  self.assertNotIn('~/.config/waybar',start)
 def test_launcher_uses_gio_and_game_categories(self):
  source=(ROOT/'shell/tamber-shell/Launcher.cpp').read_text()
  qml=(ROOT/'shell/tamber-shell/desktop/Desktop.qml').read_text()
  self.assertIn('g_desktop_app_info_get_categories',source)
  self.assertIn('"isGame"',source)
  self.assertIn('gameLibrary.games.filter',qml)
  self.assertIn('appLauncher.launch(modelData.appId)',qml)
  self.assertIn('function showLibrary()',qml)

if __name__=='__main__':unittest.main()
