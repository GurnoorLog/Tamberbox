#include <QtTest>
#include <QTemporaryDir>
#include <QDir>
#include <QFile>
#include <QImage>
#include <linux/joystick.h>
#include <unistd.h>
#include <fcntl.h>
#include "Launcher.h"
#include "desktop/GameLibrary.h"
#include "desktop/Controller.h"
class PlayTest:public QObject {
 Q_OBJECT
private slots:
 void library(){
  QTemporaryDir temp;QVERIFY(temp.isValid());qputenv("XDG_CONFIG_HOME",temp.path().toUtf8());qputenv("XDG_DATA_HOME",temp.path().toUtf8());qputenv("XDG_DATA_DIRS",temp.path().toUtf8());QDir().mkpath(temp.path()+"/applications");
  QFile desktop(temp.path()+"/applications/game.desktop");QVERIFY(desktop.open(QIODevice::WriteOnly));desktop.write("[Desktop Entry]\nType=Application\nName=Test Game\nExec=/bin/true\nCategories=Game;\n");desktop.close();
  QFile other(temp.path()+"/applications/not-game.desktop");QVERIFY(other.open(QIODevice::WriteOnly));other.write("[Desktop Entry]\nType=Application\nName=Not Game\nExec=/bin/true\nCategories=NotGame;\n");other.close();
  Launcher apps;GameLibrary library(&apps);QCOMPARE(library.games().size(),1);QString id="game.desktop";
  library.favorite(id);QVERIFY(library.games()[0].toMap()["favorite"].toBool());library.hide(id);QVERIFY(library.games().isEmpty());library.restoreHidden();QCOMPARE(library.games().size(),1);
  QImage image(64,64,QImage::Format_RGB32);image.fill(Qt::blue);QString path=temp.path()+"/cover.png";QVERIFY(image.save(path));QVERIFY(library.artwork(id,path));QVERIFY(library.games()[0].toMap()["art"].toString().endsWith(".png"));QVERIFY(!library.artwork(id,"https://example.com/art"));
  GameLibrary reload(&apps);QVERIFY(reload.games()[0].toMap()["favorite"].toBool());QVERIFY(!reload.games()[0].toMap()["art"].toString().isEmpty());
  QVERIFY(!library.launch("unknown"));QVERIFY(library.launch(id));
  QVERIFY(!library.games()[0].toMap()["lastPlayed"].toString().isEmpty());
  library.collection(id,"  Weekend  ");QCOMPARE(library.games()[0].toMap()["collection"].toString(),QString("Weekend"));
  GameLibrary persisted(&apps);QCOMPARE(persisted.games()[0].toMap()["collection"].toString(),QString("Weekend"));
  QVERIFY(!persisted.games()[0].toMap()["lastPlayed"].toString().isEmpty());
  library.collection("unknown","Do not save");QCOMPARE(library.games().size(),1);
  library.collection(id,QString(100,'x'));QCOMPARE(library.games()[0].toMap()["collection"].toString().size(),48);
  library.collection(id,"");QVERIFY(library.games()[0].toMap()["collection"].toString().isEmpty());
  QString runner=temp.path()+"/runner",rom=temp.path()+"/game with spaces.rom",core=temp.path()+"/core.so",output=temp.path()+"/args";
  for(auto file:{rom,core}){QFile f(file);QVERIFY(f.open(QIODevice::WriteOnly));f.write("test");}
  QFile script(runner);QVERIFY(script.open(QIODevice::WriteOnly));script.write(("#!/bin/sh\nprintf '%s\\n' \"$@\" > '"+output+"'\n").toUtf8());script.close();QVERIFY(script.setPermissions(QFile::ReadOwner|QFile::WriteOwner|QFile::ExeOwner));
  QVERIFY(!library.addEmulator("Bad",runner,"/missing",core));QVERIFY(library.addEmulator("Emulated",runner,rom,core));QVERIFY(!library.addEmulator("Duplicate",runner,rom,core));
  QString profile;for(auto v:library.games())if(v.toMap()["platform"]=="RetroArch")profile=v.toMap()["appId"].toString();QVERIFY(!profile.isEmpty());QVERIFY(library.launch(profile));QTRY_VERIFY(QFile::exists(output));QFile result(output);QVERIFY(result.open(QIODevice::ReadOnly));QCOMPARE(result.readAll(),("-L\n"+core+"\n"+rom+"\n").toUtf8());
 }
 void controller(){
  int pipes[2];QVERIFY(pipe2(pipes,O_NONBLOCK|O_CLOEXEC)==0);Controller pad;pad.attach(pipes[0]);QSignalSpy spy(&pad,&Controller::action);
  auto send=[&](unsigned char type,unsigned char number,short value){js_event e{};e.type=type;e.number=number;e.value=value;QCOMPARE(::write(pipes[1],&e,sizeof(e)),ssize_t(sizeof(e)));pad.poll();};
  send(JS_EVENT_BUTTON,0,1);QCOMPARE(spy.size(),0);pad.setProperty("active",true);send(JS_EVENT_BUTTON|JS_EVENT_INIT,0,1);QCOMPARE(spy.size(),0);
  send(JS_EVENT_BUTTON,0,1);QCOMPARE(spy.takeFirst()[0].toString(),QString("accept"));send(JS_EVENT_AXIS,6,32767);QCOMPARE(spy.takeFirst()[0].toString(),QString("right"));send(JS_EVENT_AXIS,6,32767);QVERIFY(spy.isEmpty());send(JS_EVENT_AXIS,6,0);send(JS_EVENT_AXIS,6,-32767);QCOMPARE(spy.takeFirst()[0].toString(),QString("left"));send(JS_EVENT_BUTTON,1,1);QCOMPARE(spy.takeFirst()[0].toString(),QString("back"));::close(pipes[1]);pad.poll();QCOMPARE(pad.status(),QString("No controller connected"));
 }
};
QTEST_MAIN(PlayTest)
#include "play_test.moc"
