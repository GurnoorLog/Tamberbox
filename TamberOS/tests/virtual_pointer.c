/* Original bounded virtual-input test client. Never accesses /dev/input. */
#include <wayland-client.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "virtual-pointer.h"
static struct zwlr_virtual_pointer_manager_v1 *manager;
static void global(void *data,struct wl_registry *registry,uint32_t name,const char *interface,uint32_t version){
 (void)data;(void)version;
 if(!strcmp(interface,"zwlr_virtual_pointer_manager_v1"))manager=wl_registry_bind(registry,name,&zwlr_virtual_pointer_manager_v1_interface,1);
}
static void removed(void *data,struct wl_registry *registry,uint32_t name){(void)data;(void)registry;(void)name;}
int main(int argc,char **argv){
 if(argc!=4)return 2;
 struct wl_display *display=wl_display_connect(NULL);if(!display)return 3;
 struct wl_registry *registry=wl_display_get_registry(display);
 struct wl_registry_listener listener={global,removed};wl_registry_add_listener(registry,&listener,NULL);wl_display_roundtrip(display);if(!manager)return 4;
 struct zwlr_virtual_pointer_v1 *pointer=zwlr_virtual_pointer_manager_v1_create_virtual_pointer(manager,NULL);
 wl_display_roundtrip(display);usleep(200000);
 zwlr_virtual_pointer_v1_motion_absolute(pointer,1,atoi(argv[1]),atoi(argv[2]),1280,720);zwlr_virtual_pointer_v1_frame(pointer);wl_display_roundtrip(display);usleep(200000);
 if(!strcmp(argv[3],"scroll")){zwlr_virtual_pointer_v1_axis_source(pointer,WL_POINTER_AXIS_SOURCE_WHEEL);zwlr_virtual_pointer_v1_axis_discrete(pointer,2,WL_POINTER_AXIS_VERTICAL_SCROLL,wl_fixed_from_int(15),1);zwlr_virtual_pointer_v1_frame(pointer);}
 else {uint32_t button=!strcmp(argv[3],"right")?273:272;zwlr_virtual_pointer_v1_button(pointer,2,button,WL_POINTER_BUTTON_STATE_PRESSED);zwlr_virtual_pointer_v1_frame(pointer);wl_display_roundtrip(display);usleep(100000);zwlr_virtual_pointer_v1_button(pointer,3,button,WL_POINTER_BUTTON_STATE_RELEASED);zwlr_virtual_pointer_v1_frame(pointer);}
 wl_display_roundtrip(display);usleep(200000);zwlr_virtual_pointer_v1_destroy(pointer);wl_display_roundtrip(display);wl_display_disconnect(display);return 0;
}
