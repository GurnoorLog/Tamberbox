#pragma once
#include <QObject>
#include <QVariantList>
class Launcher : public QObject {
 Q_OBJECT
 Q_PROPERTY(QVariantList applications READ applications NOTIFY applicationsChanged)
 Q_PROPERTY(QString status READ status NOTIFY statusChanged)
public:
 explicit Launcher(QObject *parent=nullptr);
 QVariantList applications() const { return apps; }
 QString status() const { return message; }
 Q_INVOKABLE void refresh();
 Q_INVOKABLE bool launch(const QString &id);
signals:
 void applicationsChanged();
 void statusChanged();
 void launchAccepted(QString id);
private:
 QVariantList apps;
 QString message;
};
