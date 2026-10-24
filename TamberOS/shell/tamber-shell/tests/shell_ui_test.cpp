#include <QtTest>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTemporaryDir>
#include <QDir>
#include <QFile>
#include <QImage>
#include "Launcher.h"
class ShellUITest:public QObject {
 Q_OBJECT
private slots:
 void keyboardLaunchAndControls(){
  QTemporaryDir dir;QVERIFY(dir.isValid());QDir().mkpath(dir.path()+"/applications");
  qputenv("XDG_DATA_HOME",dir.path().toUtf8());qputenv("XDG_DATA_DIRS",dir.path().toUtf8());
  QFile entry(dir.path()+"/applications/tamber-probe.desktop");QVERIFY(entry.open(QIODevice::WriteOnly));
  entry.write(("[Desktop Entry]\nType=Application\nName=Tamber probe\nExec="+QCoreApplication::applicationDirPath()+"/launch-probe "+dir.path()+"/launched\nTerminal=false\n").toUtf8());entry.close();
  Launcher launcher;QQmlApplicationEngine engine;engine.rootContext()->setContextProperty("appLauncher",&launcher);
  engine.load(QUrl::fromLocalFile(TAMBER_QML_SOURCE));QVERIFY(!engine.rootObjects().isEmpty());
  auto *window=qobject_cast<QQuickWindow*>(engine.rootObjects().first());QVERIFY(window);
  window->requestActivate();QTest::qWait(300);
  auto *popup=window->findChild<QObject*>("launcher");auto *search=window->findChild<QObject*>("search");auto *controls=window->findChild<QObject*>("controls");QVERIFY(popup && search && controls);
  QTest::keyClick(window,Qt::Key_Space,Qt::ControlModifier);QTRY_VERIFY(popup->property("visible").toBool());
  QTest::keyClick(window,Qt::Key_T);QTRY_COMPARE(search->property("text").toString(),QString("t"));
  QTest::qWait(200);QVERIFY(window->grabWindow().save("launcher.png"));
  QTest::keyClick(window,Qt::Key_Down);QTest::keyClick(window,Qt::Key_Return);
  QTRY_VERIFY_WITH_TIMEOUT(QFile::exists(dir.path()+"/launched"),10000);QTRY_VERIFY(!popup->property("visible").toBool());
  QTest::keyClick(window,Qt::Key_Comma,Qt::ControlModifier);QTRY_VERIFY(controls->property("visible").toBool());
  QTest::qWait(200);QVERIFY(window->grabWindow().save("controls.png"));
  QTest::keyClick(window,Qt::Key_Escape);QTRY_VERIFY(!controls->property("visible").toBool());
 }
};
QTEST_MAIN(ShellUITest)
#include "shell_ui_test.moc"
