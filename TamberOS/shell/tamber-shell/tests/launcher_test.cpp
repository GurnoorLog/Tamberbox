#include <QtTest>
#include <QTemporaryDir>
#include <QDir>
#include <QFile>
#include "Launcher.h"
class LauncherTest:public QObject {
 Q_OBJECT
private slots:
 void launchAndFiltering(){
  QTemporaryDir dir;QVERIFY(dir.isValid());QDir().mkpath(dir.path()+"/applications");
  qputenv("XDG_DATA_HOME",dir.path().toUtf8());qputenv("XDG_DATA_DIRS",dir.path().toUtf8());
  QFile script(dir.path()+"/probe.sh");QVERIFY(script.open(QIODevice::WriteOnly));
  script.write(("#!/bin/sh\nprintf '%s' \"$QT_WAYLAND_SHELL_INTEGRATION\" > "+dir.path()+"/launched\n").toUtf8());script.close();
  qputenv("QT_WAYLAND_SHELL_INTEGRATION","layer-shell");
  auto entry=[&](QString id,QString extra){QFile f(dir.path()+"/applications/"+id);QVERIFY(f.open(QIODevice::WriteOnly));f.write(("[Desktop Entry]\nType=Application\nName=Tamber test\nExec=/bin/sh "+dir.path()+"/probe.sh\nTerminal=false\n"+extra).toUtf8());};
  entry("tamber-test.desktop","");entry("hidden.desktop","Hidden=true\n");entry("nodisplay.desktop","NoDisplay=true\n");
  Launcher launcher;QCOMPARE(launcher.applications().size(),1);QVERIFY(!launcher.launch("/bin/sh"));QVERIFY(!launcher.launch("hidden.desktop"));
  QVERIFY(launcher.launch("tamber-test.desktop"));QTRY_VERIFY_WITH_TIMEOUT(QFile::exists(dir.path()+"/launched"),5000);
  QFile result(dir.path()+"/launched");QVERIFY(result.open(QIODevice::ReadOnly));QCOMPARE(result.readAll(),QByteArray("xdg-shell"));
  qunsetenv("QT_WAYLAND_SHELL_INTEGRATION");
 }
};
QTEST_GUILESS_MAIN(LauncherTest)
#include "launcher_test.moc"
