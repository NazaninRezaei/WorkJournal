#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include "journalmodel.h"
#include "shamsi.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName("Journal");
    QGuiApplication::setOrganizationName("JournalApp");

    QQuickStyle::setStyle("Basic");

    qmlRegisterType<JournalModel>("Journal", 1, 0, "JournalModel");
    qmlRegisterSingletonType<Shamsi>("Journal", 1, 0, "Shamsi",
        [](QQmlEngine*, QJSEngine*) -> QObject* { return new Shamsi; });

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;
    return app.exec();
}
