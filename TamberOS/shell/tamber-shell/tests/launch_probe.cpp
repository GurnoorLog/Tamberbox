#include <QGuiApplication>
#include <QWindow>
#include <QFile>
#include <QTimer>
int main(int argc,char **argv){
 QGuiApplication app(argc,argv);if(app.arguments().size()!=2)return 2;
 QWindow window;window.setTitle("Tamber launch integration test");window.resize(320,200);window.show();
 QTimer::singleShot(300,&app,[&]{QFile f(app.arguments()[1]);app.exit(window.isVisible() && f.open(QIODevice::WriteOnly)?0:1);});
 return app.exec();
}
