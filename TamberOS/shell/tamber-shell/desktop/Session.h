#pragma once
#include <QObject>
#include <QVariantList>
#include <QWindow>
#include <QJsonObject>
#include <functional>
class Session : public QObject {
 Q_OBJECT
 Q_PROPERTY(QVariantList windows READ windows NOTIFY changed)
 Q_PROPERTY(QString status READ status NOTIFY changed)
 Q_PROPERTY(QString audio READ audio NOTIFY changed)
 Q_PROPERTY(QString network READ network NOTIFY changed)
 Q_PROPERTY(bool connected READ connected NOTIFY changed)
public:
 explicit Session(QObject *parent=nullptr);
 QVariantList windows() const { return items; }
 QString status() const { return message; }
 QString audio() const { return audioState; }
 QString network() const { return networkState; }
 bool connected() const { return online; }
 static QVariantList windowList(const QJsonObject &tree);
 Q_INVOKABLE void consoleState(const QString &state);
 Q_INVOKABLE QVariantMap systemInfo() const;
 Q_INVOKABLE void configure(QWindow *window, const QString &role);
 Q_INVOKABLE void windowAction(const QString &id,const QString &action);
 Q_INVOKABLE void workspace(int number);
 Q_INVOKABLE void scale(double value);
 Q_INVOKABLE void volume(int direction);
 Q_INVOKABLE void mute();
 Q_INVOKABLE void wifi(bool enabled);
 Q_INVOKABLE void refresh();
 void dispatch(const QString &command);
signals:
 void changed();
 void openLauncher();
 void openControls();
 void openGames();
 void openLibrary();
private:
 void run(const QString &program,const QStringList &args,std::function<void(bool,QString)> callback);
 void command(const QString &text);
 QVariantList items;
 QString message,audioState="Audio service unavailable",networkState="Network service unavailable";
 bool online=false,busy=false;
};
