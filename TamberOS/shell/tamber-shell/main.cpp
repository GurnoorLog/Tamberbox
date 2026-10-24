#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>
#include <QImage>
#include "Launcher.h"
int main(int argc,char *argv[]) {
 QGuiApplication app(argc,argv); app.setApplicationName("Tamber Shell");app.setOrganizationName("TamberOS");
 Launcher launcher;QQmlApplicationEngine engine;engine.rootContext()->setContextProperty("appLauncher",&launcher);
 engine.loadFromModule("TamberShell","Main");if(engine.rootObjects().isEmpty())return 1;
 auto args=app.arguments();int shot=args.indexOf("--screenshot");
 if(shot>=0 && shot+1<args.size())QTimer::singleShot(1500,&app,[&]{
  auto *w=qobject_cast<QQuickWindow*>(engine.rootObjects().first());app.exit(w && w->grabWindow().save(args.at(shot+1))?0:2);
 });
 return app.exec();
}
