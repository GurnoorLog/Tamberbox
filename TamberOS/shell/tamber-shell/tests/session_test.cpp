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
  auto window=s.windows().first().toMap();QString id=window["id"].toString();
  s.windowAction("1] kill; exit","close");s.windowAction(id,"unsupported");
  s.windowAction(id,"minimize");
  QTRY_VERIFY_WITH_TIMEOUT(s.windows().first().toMap()["minimized"].toBool(),5000);
  s.windowAction(id,"focus");QTRY_VERIFY_WITH_TIMEOUT(!s.windows().first().toMap()["minimized"].toBool(),5000);
  s.windowAction(id,"float");QTest::qWait(300);
  s.windowAction(id,"fullscreen");QTest::qWait(300);
  s.windowAction(id,"fullscreen");QTest::qWait(300);
  s.windowAction(id,"close");QTRY_VERIFY_WITH_TIMEOUT(s.windows().isEmpty(),5000);
 }
};
QTEST_GUILESS_MAIN(SessionTest)
#include "session_test.moc"
