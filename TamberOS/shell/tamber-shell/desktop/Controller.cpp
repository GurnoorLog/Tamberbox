#include "Controller.h"
#include <QDir>
#include <fcntl.h>
#include <unistd.h>
#include <linux/joystick.h>
#include <cerrno>
Controller::Controller(QObject*p):QObject(p){connect(&timer,&QTimer::timeout,this,&Controller::poll);timer.start(30);}
Controller::~Controller(){if(descriptor>=0)::close(descriptor);}
void Controller::attach(int fd){if(descriptor>=0)::close(descriptor);descriptor=fd;axes.clear();emit changed();}
void Controller::poll(){
 if(descriptor<0){if(qEnvironmentVariable("WLR_BACKENDS")=="headless")return;if(scanCountdown-- > 0)return;scanCountdown=33;for(const auto &name:QDir("/dev/input").entryList({"js*"},QDir::System|QDir::Files)){int fd=::open(("/dev/input/"+name).toUtf8().constData(),O_RDONLY|O_NONBLOCK|O_CLOEXEC);if(fd>=0){attach(fd);break;}}return;}
 js_event e;for(int count=0;count<128;++count){auto n=::read(descriptor,&e,sizeof(e));if(n<0&&(errno==EAGAIN||errno==EWOULDBLOCK))break;if(n!=sizeof(e)){attach(-1);break;}
 if(e.type&JS_EVENT_INIT)continue;QString command;
 if(e.type==JS_EVENT_BUTTON&&e.value){if(e.number==0)command="accept";if(e.number==1)command="back";if(e.number==2)command="favorite";}
 if(e.type==JS_EVENT_AXIS&&(e.number==0||e.number==1||e.number==6||e.number==7)){int value=e.value>16000?1:e.value<-16000?-1:0;int old=axes.value(e.number);axes[e.number]=value;if(value&&value!=old)command=(e.number%2==0)?(value>0?"right":"left"):(value>0?"down":"up");}
 if(active&&!command.isEmpty())emit action(command);
 }
}
