import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 800
    minimumWidth: 850
    minimumHeight: 600
    title: "TamberOS — shell prototype (not a compositor)"
    color: "#0C0C0E"
    property int page: 0
    property bool reduceMotion: false
    property var pages: ["Home", "AI Studio", "Games", "Files", "System", "Settings"]

    Rectangle {
        anchors.fill: parent
        color: "#0C0C0E"
    }
    RowLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
            Layout.preferredWidth: 232
            Layout.fillHeight: true
            color: "#17181C"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14
                Label { text: "TAMBER"; color: "#F2EEE5"; font.pixelSize: 30; font.bold: true }
                Label { text: "OS     /     PRE-ALPHA"; color: "#FF9255"; font.pixelSize: 12; font.bold: true }
                Item { Layout.preferredHeight: 26 }
                Repeater {
                    model: window.pages
                    delegate: Button {
                        required property int index
                        required property string modelData
                        Layout.fillWidth: true
                        height: 48
                        text: "  " + modelData
                        onClicked: window.page = index
                        background: Rectangle { radius: 10; color: window.page === index ? "#33231E" : "#17181C"; border.color: window.page === index ? "#FF5A1F" : "transparent" }
                        contentItem: Text { text: parent.text; color: window.page === index ? "#FF9255" : "#F2EEE5"; font.pixelSize: 15; verticalAlignment: Text.AlignVCenter }
                    }
                }
                Item { Layout.fillHeight: true }
                Label { text: "DESIGN PROTOTYPE"; color: "#AAA7A4"; font.pixelSize: 11 }
                Label { text: "Mock data — no privileged actions"; color: "#AAA7A4"; wrapMode: Text.Wrap; Layout.fillWidth: true; font.pixelSize: 12 }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#0C0C0E"
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 38
                spacing: 24
                RowLayout {
                    Label { text: window.pages[window.page].toUpperCase(); color: "#F2EEE5"; font.pixelSize: 40; font.bold: true; Layout.fillWidth: true }
                    Rectangle { color: "#2B221F"; radius: 18; width: 164; height: 34; Label { anchors.centerIn: parent; text: "●  DESIGN MOCK"; color: "#FF9255"; font.pixelSize: 12 } }
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#343338" }
                Label {
                    text: ["YOUR BOX. YOUR RULES.", "INTELLIGENCE. ON DEVICE.", "PLAY WITHOUT LIMITS.", "YOUR SPACE.", "KNOW YOUR HARDWARE.", "MAKE IT YOURS."][window.page]
                    font.pixelSize: 30; font.bold: true; color: "#FF5A1F"; wrapMode: Text.Wrap
                }
                Label {
                    Layout.fillWidth: true; Layout.preferredHeight: 70; wrapMode: Text.Wrap
                    color: "#AAA7A4"; font.pixelSize: 17
                    text: [
                        "Welcome to TamberOS. Browse modes, apps and local tools through a focused and responsive interface.",
                        "The AI integration is a placeholder until a local Ollama installation is explicitly detected.",
                        "Discover locally configured games. This prototype does not include copyrighted titles or ROMs.",
                        "The production file browser will use your existing Linux user permissions.",
                        "A real release will show measured temperatures, CPU frequencies and compatible NPU runtime status.",
                        "Personalize the OS while preserving privacy and accessibility."
                    ][window.page]
                }
                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 16; rowSpacing: 16
                    Repeater {
                        model: window.page === 0 ? ["AI Studio", "Game Mode", "System Center", "Launch Apps"] :
                               window.page === 4 ? ["CPU", "Thermals", "Storage", "NPU"] :
                               window.page === 5 ? ["Appearance", "Accessibility", "Privacy", "Updates"] :
                               window.page === 1 ? ["Local models", "Chat history", "Privacy", "Settings"] :
                               window.page === 2 ? ["Library", "Controllers", "Recently played", "Emulators"] :
                                                   ["Home", "Documents", "Downloads", "Search"]
                        delegate: Rectangle {
                            required property string modelData
                            Layout.fillWidth: true; Layout.preferredHeight: 124
                            radius: 18; color: "#1A1B20"; border.color: "#313239"
                            Column { anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                Text { text: modelData; color: "#F2EEE5"; font.pixelSize: 22; font.bold: true }
                                Text { text: "Prototype · not yet connected"; color: "#AAA7A4"; font.pixelSize: 13 }
                            }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Label { text: "TAMBEROS  /  0.1 DESIGN BUILD     •     ALMALINUX ARM64 TARGET     •     BOARD BOOT UNVERIFIED"; color: "#85858A"; font.pixelSize: 11; wrapMode: Text.Wrap; Layout.fillWidth: true }
            }
        }
    }
    Shortcut { sequence: "Ctrl+1"; onActivated: window.page = 0 }
    Shortcut { sequence: "Ctrl+2"; onActivated: window.page = 1 }
    Shortcut { sequence: "Ctrl+3"; onActivated: window.page = 2 }
    Shortcut { sequence: "Escape"; onActivated: window.page = 0 }
}
