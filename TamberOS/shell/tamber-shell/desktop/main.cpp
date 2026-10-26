#include "Session.h"
#include "Launcher.h"
#include "GameLibrary.h"
#include "Controller.h"
#include <LayerShellQt/Shell>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QLocalServer>
#include <QLocalSocket>
#include <QStandardPaths>
#include <QFileInfo>
#include <QQuickImageProvider>
#include <QIcon>
class AppIcons : public QQuickImageProvider {
 Launcher *launcher;
public:
 explicit AppIcons(Launcher *l):QQuickImageProvider(QQuickImageProvider::Pixmap),launcher(l){}
 QPixmap requestPixmap(const QString &id,QSize *size,const QSize &requested) override {
  QString name;for(const auto &v:launcher->applications()){auto m=v.toMap();if(m["appId"].toString()==id || m["appId"].toString()==id+".desktop"){name=m["iconName"].toString();break;}}
  QSize dimensions=requested.isValid()?requested:QSize(40,40);dimensions=dimensions.boundedTo(QSize(128,128));
  auto result=QIcon::fromTheme(name,QIcon(":/brand/application.svg")).pixmap(dimensions);if(size)*size=result.size();return result;
 }
};
int main(int argc,char **argv){
 if(qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE"))qputenv("QT_QUICK_CONTROLS_STYLE","Basic");
 QGuiApplication app(argc,argv);app.setApplicationName("Tamber Desktop");app.setOrganizationName("TamberOS");
 const QString socket=QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation)+"/tamber-"+QFileInfo(qEnvironmentVariable("WAYLAND_DISPLAY","wayland-0")).fileName();
 const auto args=app.arguments();const int request=args.indexOf("--command");
 QLocalSocket client;client.connectToServer(socket);
 if(client.waitForConnected(150)){
  if(request>=0&&request+1<args.size()){const auto value=args[request+1];if(value!="launcher"&&value!="controls"&&value!="games"&&value!="library")return 2;client.write(value.toUtf8());client.waitForBytesWritten(500);return 0;}return 3;
 }
 if(request>=0)return 4;
 if(app.platformName()!="wayland"){qCritical("Tamber desktop requires a Wayland session. Use tamber-shell for X11 preview.");return 2;}
 QLocalServer server;server.setSocketOptions(QLocalServer::UserAccessOption);QLocalServer::removeServer(socket);if(!server.listen(socket))return 5;
 LayerShellQt::Shell::useLayerShell();Session session;Launcher launcher;GameLibrary library(&launcher);Controller controller;
 QObject::connect(&server,&QLocalServer::newConnection,&app,[&]{while(auto *peer=server.nextPendingConnection()){
  QObject::connect(peer,&QLocalSocket::readyRead,&session,[peer,&session]{session.dispatch(QString::fromUtf8(peer->readAll()).left(32));peer->disconnectFromServer();});
  QObject::connect(peer,&QLocalSocket::disconnected,peer,&QObject::deleteLater);
 }});
 QQmlApplicationEngine engine;engine.rootContext()->setContextProperty("gameLibrary",&library);engine.rootContext()->setContextProperty("controller",&controller);engine.addImageProvider("apps",new AppIcons(&launcher));engine.rootContext()->setContextProperty("externalBar",qEnvironmentVariable("TAMBER_EXTERNAL_BAR")=="1");engine.rootContext()->setContextProperty("session",&session);engine.rootContext()->setContextProperty("appLauncher",&launcher);
 engine.load(QUrl("qrc:/desktop/Desktop.qml"));if(engine.rootObjects().isEmpty())return 1;return app.exec();
}
