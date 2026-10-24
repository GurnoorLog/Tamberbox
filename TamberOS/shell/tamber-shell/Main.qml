import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

ApplicationWindow {
    id: window
    visible: true
    width: 1280; height: 720
    minimumWidth: 960; minimumHeight: 640
    title: "Tamber Shell — development session"
    color: "#111214"
    property color cream: "#f1ece2"
    property color muted: "#aaa8a4"
    property color orange: "#ed8956"
    property string launchPulse: ""
    property string clockText: Qt.formatTime(new Date(), "HH:mm")
    Settings { id: preferences; property bool reducedMotion: false; property bool opaquePanels: false }
    function openApps() { launcher.open(); search.forceActiveFocus() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: window.clockText = Qt.formatTime(new Date(), "HH:mm") }
    Timer { id: pulseTimer; interval: 1800; onTriggered: window.launchPulse = "" }
    Connections {
        target: appLauncher
        function onLaunchAccepted(id) { window.launchPulse = id; pulseTimer.restart(); launcher.close() }
    }
    component ActionButton: Button {
        id: action
        focusPolicy: Qt.StrongFocus; hoverEnabled: true
        Accessible.name: text
        contentItem: Text { text: action.text; color: window.cream; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        background: Rectangle { radius: 9; color: action.down ? "#443229" : action.hovered ? "#333438" : "transparent"; border.width: action.activeFocus ? 2 : 0; border.color: window.orange }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient { GradientStop { position: 0; color: "#242528" } GradientStop { position: 0.64; color: "#171819" } GradientStop { position: 1; color: "#25201d" } }
    }
    Rectangle {
        anchors.top: parent.top; width: parent.width; height: 44
        color: preferences.opaquePanels ? "#252629" : "#d9252629"
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 16; spacing: 20
            Label { text: "TamberOS"; color: window.cream; font.pixelSize: 15; font.weight: Font.DemiBold }
            ActionButton { text: "Applications"; onClicked: window.openApps() }
            Item { Layout.fillWidth: true }
            Label { text: "Development session"; color: window.muted; font.pixelSize: 12 }
            ActionButton { text: "Controls"; onClicked: controls.open() }
            Label { text: window.clockText; color: window.cream; font.pixelSize: 14; font.weight: Font.Medium }
        }
    }
    Column {
        anchors.left: parent.left; anchors.leftMargin: 68; anchors.verticalCenter: parent.verticalCenter; spacing: 14
        Label { text: "A space to make your own."; font.pixelSize: 36; font.weight: Font.Medium; color: window.cream }
        Label { text: "Your applications. One quiet workspace."; font.pixelSize: 17; color: window.muted }
        ActionButton { text: "Open applications"; width: 180; height: 42; onClicked: window.openApps() }
    }
    Image { source: "qrc:/brand/tamber-llama.svg"; width: 150; height: 190; fillMode: Image.PreserveAspectFit; anchors.right: parent.right; anchors.rightMargin: 90; anchors.verticalCenter: parent.verticalCenter; opacity: 0.8 }
    Label { anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 20; text: appLauncher.status; color: window.muted; font.pixelSize: 12 }
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 18
        width: dockRow.implicitWidth + 20; height: 74; radius: 22
        color: preferences.opaquePanels ? "#303033" : "#dc303033"; border.color: "#555052"
        RowLayout {
            id: dockRow; anchors.centerIn: parent; spacing: 6
            ActionButton { text: "Apps"; Layout.preferredWidth: 66; Layout.preferredHeight: 56; onClicked: window.openApps() }
            Repeater {
                model: appLauncher.applications.slice(0, 4)
                delegate: Item {
                    required property var modelData
                    Layout.preferredWidth: 88; Layout.preferredHeight: 56
                    ActionButton { anchors.fill: parent; text: modelData.name; onClicked: appLauncher.launch(modelData.appId); ToolTip.visible: hovered; ToolTip.text: modelData.name }
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                        width: 5; height: 5; radius: 3; color: window.orange
                        opacity: window.launchPulse === modelData.appId ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: preferences.reducedMotion ? 0 : 200 } }
                    }
                }
            }
            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 28; color: "#5a5553" }
            ActionButton { text: "Controls"; Layout.preferredWidth: 80; Layout.preferredHeight: 56; onClicked: controls.open() }
        }
    }
    Popup {
        id: launcher
        width: Math.min(600, window.width - 80); height: Math.min(480, window.height - 140)
        anchors.centerIn: parent; modal: true; focus: true; padding: 24
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { color: "#28292c"; radius: 20; border.color: "#555052" }
        ColumnLayout {
            anchors.fill: parent; spacing: 18
            RowLayout {
                Label { text: "Applications"; color: window.cream; font.pixelSize: 24; font.weight: Font.Medium; Layout.fillWidth: true }
                ActionButton { text: "Refresh"; onClicked: appLauncher.refresh() }
                ActionButton { text: "Close"; onClicked: launcher.close() }
            }
            TextField {
                id: search; Layout.fillWidth: true; placeholderText: "Search installed applications"; color: window.cream
                selectByMouse: true; font.pixelSize: 16
                background: Rectangle { radius: 10; color: "#1c1d20"; border.color: search.activeFocus ? window.orange : "#555052" }
                onTextChanged: apps.currentIndex = 0
                Keys.onDownPressed: { apps.forceActiveFocus(); apps.currentIndex = 0 }
                onAccepted: { if (apps.count > 0) appLauncher.launch(apps.model[apps.currentIndex].appId) }
            }
            ListView {
                id: apps; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 5
                model: appLauncher.applications.filter(a => a.name.toLowerCase().includes(search.text.toLowerCase()))
                keyNavigationEnabled: true
                highlightMoveDuration: preferences.reducedMotion ? 0 : 100
                Keys.onReturnPressed: { if (count > 0) appLauncher.launch(model[currentIndex].appId) }
                delegate: ActionButton {
                    required property var modelData
                    required property int index
                    width: apps.width; height: 46; text: modelData.name
                    background: Rectangle { radius: 9; color: apps.currentIndex === index ? "#43342d" : "transparent"; border.color: parent.activeFocus ? window.orange : "transparent" }
                    onClicked: appLauncher.launch(modelData.appId)
                }
                Label { anchors.centerIn: parent; visible: apps.count === 0; text: "No matching applications"; color: window.muted }
                ScrollBar.vertical: ScrollBar { }
            }
            Label { text: "↑ ↓ to select · Enter to launch · Esc to close"; color: window.muted; font.pixelSize: 12 }
        }
    }
    Popup {
        id: controls; x: window.width - width - 20; y: 54; width: 330; height: 330; padding: 24; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle { radius: 18; color: preferences.opaquePanels ? "#28292c" : "#ed28292c"; border.color: "#555052" }
        ColumnLayout {
            anchors.fill: parent; spacing: 14
            Label { text: "Control center"; font.pixelSize: 22; color: window.cream }
            CheckBox { text: "Reduce motion"; checked: preferences.reducedMotion; onToggled: preferences.reducedMotion = checked }
            CheckBox { text: "Opaque panels"; checked: preferences.opaquePanels; onToggled: preferences.opaquePanels = checked }
            Label { text: "Network, audio and display controls remain in your desktop's system settings."; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: window.muted; font.pixelSize: 14 }
            Item { Layout.fillHeight: true }
            ActionButton { text: "Close"; Layout.alignment: Qt.AlignRight; onClicked: controls.close() }
        }
    }
    Shortcut { sequence: "Ctrl+Space"; onActivated: window.openApps() }
    Shortcut { sequence: "Ctrl+,"; onActivated: controls.open() }
}
