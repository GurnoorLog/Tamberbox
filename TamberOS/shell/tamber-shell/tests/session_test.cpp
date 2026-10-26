#include "desktop/Session.h"
#include <QtTest>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonArray>
class SessionTest:public QObject {
 Q_OBJECT
private slots:
 void parseTree(){
  const auto tree=QJsonDocument::fromJson(R"({"nodes":[{"name":"__i3_scratch","floating_nodes":[{"id":42,"app_id":"sample","name":"Hidden","focused":false}]}],"floating_nodes":[{"id":9,"app_id":"terminal","name":"Active","focused":true}]})").object();
  const auto list=Session::windowList(tree);QCOMPARE(list.size(),2);QVERIFY(list[0].toMap()["minimized"].toBool());QVERIFY(list[1].toMap()["focused"].toBool());
 }
 void realCompositor(){
  if(qEnvironmentVariableIsEmpty("TAMBER_TEST_SWAY"))QSKIP("Explicit isolated compositor integration only");
  Session s;QTRY_VERIFY_WITH_TIMEOUT(s.connected(),5000);
  QTRY_VERIFY_WITH_TIMEOUT(!s.windows().isEmpty(),5000);
  QString id;
  for(const auto &v:s.windows())if(v.toMap()["appId"]=="tamber-test")id=v.toMap()["id"].toString();
  QVERIFY2(!id.isEmpty(),"The isolated terminal fixture must exist");
  const auto before=s.windows().size();
  auto target=[&](){for(const auto &v:s.windows())if(v.toMap()["id"].toString()==id)return v.toMap();return QVariantMap{};};
  s.windowAction("1] kill; exit","close");s.windowAction(id,"unsupported");
  s.windowAction(id,"minimize");
  QTRY_VERIFY_WITH_TIMEOUT(target()["minimized"].toBool(),5000);
  s.windowAction(id,"focus");QTRY_VERIFY_WITH_TIMEOUT(!target()["minimized"].toBool(),5000);
  s.windowAction(id,"float");QTest::qWait(300);
  s.windowAction(id,"fullscreen");QTRY_VERIFY_WITH_TIMEOUT(target()["fullscreen"].toBool(),5000);
  s.windowAction(id,"fullscreen");QTRY_VERIFY_WITH_TIMEOUT(!target()["fullscreen"].toBool(),5000);
  s.windowAction(id,"close");QTRY_VERIFY_WITH_TIMEOUT(target().isEmpty(),5000);
  QCOMPARE(s.windows().size(),before-1);
 }
};
QTEST_GUILESS_MAIN(SessionTest)
#include "session_test.moc"
