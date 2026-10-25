#!/usr/bin/env python3
"""Read actual Waybar GTK accessibility labels, without inspecting other apps."""
import json,sys,time
import pyatspi
nodes=[]
def walk(node,depth=0):
 if depth>12:return
 entry={'name':node.name or '', 'role':node.getRoleName()}
 try:entry['text']=node.queryText().getText(0,-1)
 except NotImplementedError:pass
 try:
  e=node.queryComponent().getExtents(pyatspi.DESKTOP_COORDS);entry['rect']=[e.x,e.y,e.width,e.height]
 except NotImplementedError:pass
 nodes.append(entry)
 for child in node:
  if child:walk(child,depth+1)
for attempt in range(20):
 desktop=pyatspi.Registry.getDesktop(0)
 for app in desktop:
  if app and 'waybar' in (app.name or '').lower():walk(app)
 if nodes:break
 time.sleep(.25)
print(json.dumps(nodes,indent=2))
if not nodes:sys.exit(2)
