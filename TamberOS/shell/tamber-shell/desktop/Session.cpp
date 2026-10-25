#include "Session.h"
#include <LayerShellQt/Window>
#include <QProcess>
#include <QTimer>
#include <QJsonDocument>
#include <QJsonArray>
#include <QStandardPaths>
#include <QRegularExpression>
Session::Session(QObject *parent):QObject(parent){
 auto *timer=new QTimer(this);connect(timer,&QTimer::timeout,this,&Session::refresh);timer->start(1000);refresh();
}
void Session::run(const QString &program,const QStringList &args,std::function<void(bool,QString)> callback){
 if(QStandardPaths::findExecutable(program).isEmpty()){callback(false,program+" unavailable");return;}
 auto *p=new QProcess(this);auto *timeout=new QTimer(p);timeout->setSingleShot(true);
 connect(timeout,&QTimer::timeout,p,&QProcess::kill);
 connect(p,&QProcess::errorOccurred,p,[p,callback](QProcess::ProcessError e){if(e==QProcess::FailedToStart){callback(false,p->errorString());p->deleteLater();}});
 connect(p,qOverload<int,QProcess::ExitStatus>(&QProcess::finished),this,[p,callback](int code,QProcess::ExitStatus state){
  QString out=QString::fromUtf8(p->readAllStandardOutput());if(code!=0)out+=QString::fromUtf8(p->readAllStandardError());
  callback(code==0&&state==QProcess::NormalExit,out.trimmed().left(65536));p->deleteLater();
 });p->start(program,args);timeout->start(2500);
}
QVariantList Session::windowList(const QJsonObject &tree){
 QVariantList result;
 std::function<void(QJsonObject,bool)> visit=[&](QJsonObject node,bool hidden){
  hidden=hidden || node.value("name").toString()=="__i3_scratch";
  const auto app=node.value("app_id").toString();
  if(!app.isEmpty() || node.value("window").isDouble()){
   QString name=node.value("name").toString();if(name.isEmpty())name=app;
   result.append(QVariantMap{{"id",QString::number(node.value("id").toInteger())},{"title",name},{"appId",app},{"focused",node.value("focused").toBool()},{"minimized",hidden}});
  }
  for(const auto key:{"nodes","floating_nodes"})for(const auto &child:node.value(key).toArray())visit(child.toObject(),hidden);
 };visit(tree,false);return result;
}
void Session::refresh(){
 if(busy)return;busy=true;
 run("swaymsg",{"-r","-t","get_tree"},[this](bool ok,QString out){
  QJsonParseError error;auto doc=QJsonDocument::fromJson(out.toUtf8(),&error);
  online=ok && error.error==QJsonParseError::NoError && doc.isObject();
  items=online?windowList(doc.object()):QVariantList{};busy=false;emit changed();
 });
 run("wpctl",{"get-volume","@DEFAULT_AUDIO_SINK@"},[this](bool ok,QString out){audioState=ok?out:"Audio service unavailable";emit changed();});
 run("nmcli",{"-t","-f","STATE","general"},[this](bool ok,QString out){networkState=ok?out:"Network service unavailable";emit changed();});
}
void Session::command(const QString &text){
 run("swaymsg",{"-r",text},[this](bool ok,QString out){
  const auto replies=QJsonDocument::fromJson(out.toUtf8()).array();bool accepted=ok&&!replies.isEmpty();
  for(const auto &r:replies)accepted=accepted&&r.toObject().value("success").toBool();
  message=accepted?"":"Compositor request failed: "+out.left(160);emit changed();refresh();
 });
}
void Session::windowAction(const QString &id,const QString &action){
 bool known=false,hidden=false;for(const auto &v:items){auto m=v.toMap();if(m["id"].toString()==id){known=true;hidden=m["minimized"].toBool();}}
 if(!known || !QRegularExpression("^[0-9]+$").match(id).hasMatch())return;
 QString suffix;
 if(action=="focus")suffix=hidden?"scratchpad show":"focus";
 else if(action=="minimize")suffix="move scratchpad";
 else if(action=="fullscreen")suffix="fullscreen toggle";
 else if(action=="float")suffix="floating toggle";
 else if(action=="close")suffix="kill";
 else return;
 command("[con_id="+id+"] "+suffix);
}
void Session::workspace(int n){if(n>=1&&n<=4)command("workspace number "+QString::number(n));}
void Session::scale(double n){if(n==1||n==1.25||n==1.5||n==2)command("output * scale "+QString::number(n));}
void Session::volume(int direction){if(direction!=-1&&direction!=1)return;run("wpctl",{"set-volume","-l","1.0","@DEFAULT_AUDIO_SINK@",direction>0?"5%+":"5%-"},[this](bool ok,QString out){message=ok?"":out.left(160);emit changed();refresh();});}
void Session::mute(){run("wpctl",{"set-mute","@DEFAULT_AUDIO_SINK@","toggle"},[this](bool ok,QString out){message=ok?"":out.left(160);emit changed();refresh();});}
void Session::wifi(bool on){run("nmcli",{"radio","wifi",on?"on":"off"},[this](bool ok,QString out){message=ok?"":out.left(160);emit changed();refresh();});}
void Session::dispatch(const QString &c){if(c=="launcher")emit openLauncher();else if(c=="controls")emit openControls();}
void Session::configure(QWindow *w,const QString &role){
 if(!w)return;using L=LayerShellQt::Window;auto *layer=L::get(w);layer->setScope("tamber-"+role);
 layer->setKeyboardInteractivity(L::KeyboardInteractivityNone);
 if(role=="wallpaper"){layer->setLayer(L::LayerBackground);layer->setAnchors(L::Anchors(L::AnchorTop)|L::AnchorBottom|L::AnchorLeft|L::AnchorRight);layer->setExclusiveZone(-1);}
 else if(role=="bar"){layer->setLayer(L::LayerTop);layer->setAnchors(L::Anchors(L::AnchorTop)|L::AnchorLeft|L::AnchorRight);layer->setExclusiveZone(40);}
 else if(role=="dock"){layer->setLayer(L::LayerTop);layer->setAnchors(L::AnchorBottom);layer->setMargins(QMargins(0,0,0,12));layer->setExclusiveZone(84);}
 else {layer->setLayer(L::LayerOverlay);layer->setAnchors({});layer->setExclusiveZone(-1);layer->setKeyboardInteractivity(L::KeyboardInteractivityExclusive);}
}
