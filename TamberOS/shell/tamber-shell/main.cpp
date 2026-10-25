#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>
#include <QImage>
#include "Launcher.h"
int main(int argc,char *argv[]) {
 if(qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))qputenv("QT_QUICK_CONTROLS_STYLE","Basic");
 QGuiApplication app(argc,argv); app.setApplicationName("Tamber Shell");app.setOrganizationName("TamberOS");
 Launcher launcher;QQmlApplicationEngine engine;engine.rootContext()->setContextProperty("appLauncher",&launcher);
 engine.load(QUrl("qrc:/TamberShell/Main.qml"));if(engine.rootObjects().isEmpty())return 1;
 auto args=app.arguments();int shot=args.indexOf("--screenshot");
 if(shot>=0 && shot+1<args.size())QTimer::singleShot(1500,&app,[&]{
  auto *w=qobject_cast<QQuickWindow*>(engine.rootObjects().first());app.exit(w && w->grabWindow().save(args.at(shot+1))?0:2);
 });
 return app.exec();
}
