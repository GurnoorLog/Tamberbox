#include <QGuiApplication>
#include <QQuickView>
#include <QTimer>
#include <QImage>
int main(int argc,char **argv){
 QGuiApplication app(argc,argv);if(argc!=3)return 2;
 QQuickView view;view.setResizeMode(QQuickView::SizeRootObjectToView);view.setSource(QUrl::fromLocalFile(QString::fromLocal8Bit(argv[1])));
 if(view.status()==QQuickView::Error)return 3;view.resize(1280,720);view.show();
 QTimer::singleShot(1000,&app,[&]{app.exit(view.grabWindow().save(QString::fromLocal8Bit(argv[2]))?0:4);});return app.exec();
}
