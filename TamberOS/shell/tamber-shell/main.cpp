#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName("Tamber Shell Prototype");
    QQmlApplicationEngine engine;
    engine.loadFromModule("TamberShell", "Main");
    if (engine.rootObjects().isEmpty()) return 1;
    return app.exec();
}
