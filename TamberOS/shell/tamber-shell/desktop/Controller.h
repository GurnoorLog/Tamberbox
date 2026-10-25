#pragma once
#include <QObject>
#include <QTimer>
#include <QMap>
class Controller: public QObject {
 Q_OBJECT
 Q_PROPERTY(bool active MEMBER active)
 Q_PROPERTY(QString status READ status NOTIFY changed)
public:
 explicit Controller(QObject *parent=nullptr);
 ~Controller();
 QString status()const{return descriptor<0?"No controller connected":"Controller connected";}
 // Takes ownership of an already opened nonblocking descriptor; also used by pipe tests.
 void attach(int fd);
 void poll();
signals:
 void action(QString name);
 void changed();
private:
 int scanCountdown=0; int descriptor=-1; bool active=false;QTimer timer;QMap<int,int> axes;
};
