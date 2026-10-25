#!/usr/bin/env python3
"""Synthetic SNI client for testing the real Waybar tray, not a user service."""
import os,sys,pathlib
import dbus,dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
DBusGMainLoop(set_as_default=True)
bus=dbus.SessionBus();name=f'org.kde.StatusNotifierItem-{os.getpid()}-1'
owner=dbus.service.BusName(name,bus=bus)
class Item(dbus.service.Object):
 def __init__(self):super().__init__(owner,'/StatusNotifierItem')
 @dbus.service.method('org.freedesktop.DBus.Properties',in_signature='ss',out_signature='v')
 def Get(self,interface,prop):return self.GetAll(interface).get(prop,'')
 @dbus.service.method('org.freedesktop.DBus.Properties',in_signature='s',out_signature='a{sv}')
 def GetAll(self,interface):return {'Category':'ApplicationStatus','Id':'tamber-tray-test','Title':'Tamber tray fixture','Status':'Active','IconName':'applications-games','ItemIsMenu':False,'Menu':dbus.ObjectPath('/')}
 @dbus.service.method('org.kde.StatusNotifierItem',in_signature='ii',out_signature='')
 def Activate(self,x,y):pathlib.Path(sys.argv[1]).write_text('activated\n')
 @dbus.service.method('org.kde.StatusNotifierItem',in_signature='ii',out_signature='')
 def ContextMenu(self,x,y):pass
item=Item();watcher=bus.get_object('org.kde.StatusNotifierWatcher','/StatusNotifierWatcher')
watcher.RegisterStatusNotifierItem(name,dbus_interface='org.kde.StatusNotifierWatcher')
GLib.MainLoop().run()
