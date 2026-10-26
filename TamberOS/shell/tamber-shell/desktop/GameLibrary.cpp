#include "GameLibrary.h"
#include "Launcher.h"
#include <QStandardPaths>
#include <QDir>
#include <QFile>
#include <QSaveFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonArray>
#include <QCryptographicHash>
#include <QProcess>
#include <QProcessEnvironment>
#include <QImageReader>
#include <QUrl>
#include <QDateTime>
#include <algorithm>
GameLibrary::GameLibrary(Launcher *l,QObject *p):QObject(p),apps(l){
 file=QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation)+"/play.json";
 QFile input(file); if(input.open(QIODevice::ReadOnly)&&input.size()<1024*1024)state=QJsonDocument::fromJson(input.readAll()).object();
 connect(apps,&Launcher::applicationsChanged,this,&GameLibrary::refresh);refresh();
}
bool GameLibrary::save(){
 QDir().mkpath(QFileInfo(file).absolutePath());QSaveFile out(file);
 if(!out.open(QIODevice::WriteOnly)||out.write(QJsonDocument(state).toJson())<0||!out.commit()){message="Could not save library";emit changed();return false;}return true;
}
bool GameLibrary::known(const QString &id) const{for(const auto &v:items)if(v.toMap()["appId"]==id)return true;return false;}
void GameLibrary::refresh(){
 items.clear();auto prefs=state["preferences"].toObject();
 auto append=[&](QVariantMap m){auto id=m["appId"].toString();auto p=prefs[id].toObject();if(p["hidden"].toBool())return;
 m["favorite"]=p["favorite"].toBool();m["art"]=p["art"].toString();items.append(m);};
 for(const auto &v:apps->applications()){auto m=v.toMap();if(m["isGame"].toBool()){m["platform"]="Native";append(m);}}
 for(const auto &v:state["profiles"].toArray()){auto m=v.toObject().toVariantMap();m["platform"]="RetroArch";append(m);}
 std::stable_sort(items.begin(),items.end(),[](const QVariant&a,const QVariant&b){auto x=a.toMap(),y=b.toMap();if(x["favorite"]!=y["favorite"])return x["favorite"].toBool();return x["name"].toString().localeAwareCompare(y["name"].toString())<0;});emit changed();
}
void GameLibrary::favorite(const QString&id){if(!known(id))return;auto p=state["preferences"].toObject();auto m=p[id].toObject();m["favorite"]=!m["favorite"].toBool();p[id]=m;state["preferences"]=p;if(save())refresh();}
void GameLibrary::hide(const QString&id){if(!known(id))return;auto p=state["preferences"].toObject();auto m=p[id].toObject();m["hidden"]=true;p[id]=m;state["preferences"]=p;if(save())refresh();}
void GameLibrary::restoreHidden(){auto p=state["preferences"].toObject();for(auto it=p.begin();it!=p.end();++it){auto m=it.value().toObject();m["hidden"]=false;it.value()=m;}state["preferences"]=p;if(save())refresh();}
bool GameLibrary::artwork(const QString&id,const QString&path){
 if(!known(id))return false;QFileInfo f(path);QImageReader reader(path);auto size=reader.size();const auto format=reader.format();
 if(!f.isAbsolute()||!f.isFile()||f.size()>20*1024*1024||!size.isValid()||size.width()>8192||size.height()>8192||reader.read().isNull()){message="Choose a local image up to 20 MiB and 8192 pixels";emit changed();return false;}
 QString folder=QFileInfo(file).absolutePath()+"/art";QDir().mkpath(folder);QString dest=folder+"/"+QCryptographicHash::hash((id+QString::number(f.lastModified().toMSecsSinceEpoch())).toUtf8(),QCryptographicHash::Sha256).toHex()+"."+(format.isEmpty()?QByteArray("img"):format);
 if(!QFile::exists(dest)&&!QFile::copy(path,dest)){message="Artwork copy failed";emit changed();return false;}
 auto p=state["preferences"].toObject();auto m=p[id].toObject();m["art"]=QUrl::fromLocalFile(dest).toString();p[id]=m;state["preferences"]=p;if(!save())return false;refresh();return true;
}
bool GameLibrary::addEmulator(const QString&name,const QString&runner,const QString&rom,const QString&core){
 if(name.trimmed().isEmpty()||!QFileInfo(runner).isAbsolute()||!QFileInfo(runner).isExecutable()||!QFileInfo(runner).isFile()||!QFileInfo(rom).isAbsolute()||!QFileInfo(rom).isFile()||!QFileInfo(core).isAbsolute()||!QFileInfo(core).isFile()) {message="Choose a name, executable RetroArch binary, existing ROM and libretro core using absolute paths";emit changed();return false;}
 auto profiles=state["profiles"].toArray();QString id="retroarch:"+QString(QCryptographicHash::hash((runner+"\n"+rom+"\n"+core).toUtf8(),QCryptographicHash::Sha256).toHex());
 for(const auto &p:profiles)if(p.toObject()["appId"]==id){message="This emulator profile already exists";emit changed();return false;}
 profiles.append(QJsonObject{{"appId",id},{"name",name.trimmed()},{"runner",runner},{"rom",rom},{"core",core}});state["profiles"]=profiles;if(!save())return false;message="Profile added";refresh();return true;
}
bool GameLibrary::launch(const QString&id){
 if(!known(id))return false;bool ok=false;
 if(!id.startsWith("retroarch:")){ok=apps->launch(id);message=apps->status();}
 else for(const auto &v:state["profiles"].toArray()){auto p=v.toObject();if(p["appId"]!=id)continue;
 if(!QFileInfo(p["runner"].toString()).isExecutable()||!QFileInfo(p["rom"].toString()).isFile()||!QFileInfo(p["core"].toString()).isFile())break;
 QProcess process;process.setProgram(p["runner"].toString());process.setArguments({"-L",p["core"].toString(),p["rom"].toString()});auto env=QProcessEnvironment::systemEnvironment();env.insert("QT_WAYLAND_SHELL_INTEGRATION","xdg-shell");process.setProcessEnvironment(env);ok=process.startDetached();break;}
 if(id.startsWith("retroarch:"))message=ok?"Emulator launch requested":"Emulator, core or ROM unavailable";emit changed();if(ok)emit launched();return ok;
}
