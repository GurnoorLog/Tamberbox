#pragma once
#include <QObject>
#include <QVariantList>
#include <QJsonObject>
class Launcher;
class GameLibrary : public QObject {
 Q_OBJECT
 Q_PROPERTY(QVariantList games READ games NOTIFY changed)
 Q_PROPERTY(QString status READ status NOTIFY changed)
public:
 explicit GameLibrary(Launcher *launcher, QObject *parent=nullptr);
 QVariantList games() const { return items; }
 QString status() const { return message; }
 Q_INVOKABLE void refresh();
 Q_INVOKABLE bool launch(const QString &id);
 Q_INVOKABLE void favorite(const QString &id);
 Q_INVOKABLE void hide(const QString &id);
 Q_INVOKABLE void restoreHidden();
 Q_INVOKABLE bool artwork(const QString &id, const QString &path);
 Q_INVOKABLE bool addEmulator(const QString &name,const QString &runner,const QString &rom,const QString &core);
signals:
 void changed();
 void launched();
private:
 Launcher *apps; QVariantList items; QJsonObject state; QString file,message;
 bool save(); bool known(const QString &id) const;
};
