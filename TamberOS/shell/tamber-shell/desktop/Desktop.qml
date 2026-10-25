import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings

Item {
    id: root
    property color cream: "#f1ece2"
    property color muted: "#aaa6a4"
    property color accent: "#ee9466"
    property string clock: Qt.formatDateTime(new Date(), "ddd  d MMM   HH:mm")
    Settings { id: preferences; category: "Desktop"; property bool reducedMotion: false; property bool opaque: false; property real wallpaperOpacity: 1 }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.clock = Qt.formatDateTime(new Date(), "ddd  d MMM   HH:mm") }
    function showApps() { appsWindow.visible = !appsWindow.visible; if(appsWindow.visible) { search.text=""; search.forceActiveFocus() } }
    Connections { target: session; function onOpenLauncher() { root.showApps() } function onOpenControls() { settingsWindow.visible=!settingsWindow.visible } }
    Connections { target: appLauncher; function onLaunchAccepted(id) { appsWindow.visible=false } }
    component TextLabel: Label { color: root.cream; font.pixelSize: 14 }
    component Action: Button {
        id: button
        focusPolicy: Qt.StrongFocus
        Accessible.name: text
        contentItem: Text { text: button.text; color: root.cream; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        background: Rectangle { radius: 10; color: button.down ? "#594034" : button.hovered ? "#484247" : "transparent"; border.width: button.activeFocus ? 2 : 0; border.color: root.accent }
    }
    component Surface: Rectangle { color: preferences.opaque ? "#29292e" : "#ed29292e"; radius: 22; border.color: "#605855"; border.width: 1 }
    Window {
        id: wallpaper
        width: Screen.width; height: Screen.height; color: "#17181c"
        flags: Qt.FramelessWindowHint
        Component.onCompleted: { session.configure(wallpaper,"wallpaper"); visible=true }
        Image { anchors.fill: parent; source: "qrc:/brand/wallpapers/quiet-ridge.svg"; fillMode: Image.PreserveAspectCrop; opacity: preferences.wallpaperOpacity }
        Column {
            anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 120; spacing: 9
            Image { source: "qrc:/brand/tamber-llama.svg"; width: 66; height: 82; fillMode: Image.PreserveAspectFit; anchors.right: parent.right; opacity: 0.65 }
            TextLabel { text: "T A M B E R O S"; font.pixelSize: 12; opacity: 0.5 }
        }
    }
    Window {
        id: bar; width: Screen.width; height: 40; color: "transparent"; flags: Qt.FramelessWindowHint
        Component.onCompleted: { session.configure(bar,"bar"); visible=true }
        Rectangle { anchors.fill: parent; color: preferences.opaque ? "#252529" : "#c9252529" }
        RowLayout {
            anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18; spacing: 14
            Action { text: "TamberOS"; font.bold: true; onClicked: settingsWindow.visible=!settingsWindow.visible }
            Action { text: "Applications"; onClicked: root.showApps() }
            Repeater { model: 4; Action { required property int index; text: (index+1).toString(); Layout.preferredWidth: 28; onClicked: session.workspace(index+1); ToolTip.visible: hovered; ToolTip.text: "Workspace "+(index+1) } }
            Item { Layout.fillWidth: true }
            TextLabel { text: session.connected ? "" : "Compositor unavailable"; color: root.accent }
            Action { text: "Control center"; onClicked: settingsWindow.visible=!settingsWindow.visible }
            TextLabel { text: root.clock; font.pixelSize: 13 }
        }
    }
    Window {
        id: dock; width: Math.min(Screen.width-32,112+Math.min(appLauncher.applications.length,4)*60+Math.min(session.windows.length,6)*68); height: 76; color: "transparent"; flags: Qt.FramelessWindowHint
        Component.onCompleted: { session.configure(dock,"dock"); visible=true }
        Surface { anchors.fill: parent; anchors.margins: 4; radius: 20 }
        RowLayout {
            anchors.centerIn: parent; spacing: 5
            Action { text: "⌘"; Layout.preferredWidth: 48; Layout.preferredHeight: 54; onClicked: root.showApps(); ToolTip.visible: hovered; ToolTip.text: "Applications · Super+Space" }
            Repeater {
                model: appLauncher.applications.slice(0,4)
                delegate: Action {
                    required property var modelData
                    Layout.preferredWidth: 55; Layout.preferredHeight: 54
                    text: modelData.name.slice(0,2).toUpperCase()
                    onClicked: appLauncher.launch(modelData.appId)
                    ToolTip.visible: hovered; ToolTip.text: modelData.name
                    scale: hovered ? 1.12 : 1
                    Behavior on scale { NumberAnimation { duration: preferences.reducedMotion ? 0 : 150; easing.type: Easing.OutCubic } }
                    background: Rectangle { anchors.margins: 6; radius: 12; color: "#413d40"; border.color: parent.activeFocus ? root.accent : "#63554f" }
                }
            }
            Rectangle { Layout.preferredHeight: 34; Layout.preferredWidth: 1; color: "#675b55" }
            Repeater {
                model: session.windows.slice(0,6)
                delegate: Item {
                    required property var modelData
                    Layout.preferredWidth: 63; Layout.preferredHeight: 54
                    Action { anchors.fill: parent; text: modelData.title.slice(0,8); onClicked: session.windowAction(modelData.id,"focus"); ToolTip.visible: hovered; ToolTip.text: modelData.title+(modelData.minimized?" · Minimized":"") }
                    Rectangle { width: modelData.focused ? 16 : 5; height: 3; radius: 2; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; color: modelData.minimized ? root.muted : root.accent; Behavior on width { NumberAnimation { duration: preferences.reducedMotion ? 0 : 150 } } }
                }
            }
            Action { text: "☷"; Layout.preferredWidth: 40; Layout.preferredHeight: 54; onClicked: settingsWindow.visible=!settingsWindow.visible; ToolTip.visible: hovered; ToolTip.text: "Settings and windows" }
        }
    }
    Window {
        id: appsWindow; width: Math.min(650,Screen.width-40); height: Math.min(510,Screen.height-100); color: "transparent"; flags: Qt.FramelessWindowHint
        Component.onCompleted: session.configure(appsWindow,"launcher")
        Surface { anchors.fill: parent }
        Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: appsWindow.visible=false
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 28; spacing: 16
                RowLayout { TextLabel { text: "Applications"; font.pixelSize: 25; Layout.fillWidth: true } Action { text: "Refresh"; onClicked: appLauncher.refresh() } Action { text: "Close"; onClicked: appsWindow.visible=false } }
                TextField {
                    id: search; Layout.fillWidth: true; Layout.preferredHeight: 46; placeholderText: "Search your applications"; color: root.cream; font.pixelSize: 17; selectByMouse: true
                    background: Rectangle { radius: 12; color: "#1b1c20"; border.color: search.activeFocus ? root.accent : "#65544d" }
                    onTextChanged: results.currentIndex=0
                    Keys.onDownPressed: { results.forceActiveFocus(); results.currentIndex=0 }
                    Keys.onEscapePressed: appsWindow.visible=false
                    onAccepted: if(results.count)appLauncher.launch(results.model[Math.max(results.currentIndex,0)].appId)
                }
                ListView {
                    id: results; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6; keyNavigationEnabled: true
                    model: appLauncher.applications.filter(a=>a.name.toLowerCase().includes(search.text.toLowerCase()))
                    Keys.onReturnPressed: if(count)appLauncher.launch(model[currentIndex].appId)
                    Keys.onEscapePressed: appsWindow.visible=false
                    delegate: Action {
                        required property var modelData; required property int index
                        width: results.width; height: 50; text: modelData.name
                        background: Rectangle { radius: 12; color: results.currentIndex===index ? "#4d3930" : "transparent"; border.color: parent.activeFocus ? root.accent : "transparent" }
                        onClicked: appLauncher.launch(modelData.appId)
                    }
                    TextLabel { anchors.centerIn: parent; visible: results.count===0; text: "No applications found"; color: root.muted }
                    ScrollBar.vertical: ScrollBar {}
                }
                TextLabel { text: appLauncher.status || "↑ ↓ Navigate    Enter Open    Esc Close"; color: root.muted; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.Wrap }
            }
        }
    }
    Window {
        id: settingsWindow; width: Math.min(800,Screen.width-40); height: Math.min(560,Screen.height-90); color: "transparent"; flags: Qt.FramelessWindowHint
        Component.onCompleted: session.configure(settingsWindow,"controls")
        Surface { anchors.fill: parent }
        Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: settingsWindow.visible=false
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 26; spacing: 14
                RowLayout { TextLabel { text: "System settings"; font.pixelSize: 25; Layout.fillWidth: true } Action { text: "Close"; onClicked: settingsWindow.visible=false } }
                TabBar { id: tabs; Layout.fillWidth: true; TabButton { text: "Appearance" } TabButton { text: "Connections & sound" } TabButton { text: "Windows" } }
                StackLayout {
                    currentIndex: tabs.currentIndex; Layout.fillWidth: true; Layout.fillHeight: true
                    ColumnLayout {
                        spacing: 10
                        TextLabel { text: "Make room for focus."; font.pixelSize: 21 }
                        CheckBox { text: "Reduce animation"; checked: preferences.reducedMotion; onToggled: preferences.reducedMotion=checked; palette.windowText: root.cream }
                        CheckBox { text: "Opaque panels"; checked: preferences.opaque; onToggled: preferences.opaque=checked; palette.windowText: root.cream }
                        TextLabel { text: "Wallpaper intensity"; color: root.muted }
                        Slider { Layout.fillWidth: true; from: 0; to: 1; value: preferences.wallpaperOpacity; onMoved: preferences.wallpaperOpacity=value }
                        RowLayout { TextLabel { text: "Display scale (all outputs)"; Layout.fillWidth: true } Repeater { model: [1,1.25,1.5,2]; Action { required property var modelData; text: modelData+"×"; onClicked: session.scale(modelData) } } }
                        TextLabel { text: "Appearance persists. Output scale applies to this session only."; color: root.muted; font.pixelSize: 12 }
                        Item { Layout.fillHeight: true }
                    }
                    ColumnLayout {
                        spacing: 12
                        TextLabel { text: "Network"; font.pixelSize: 20 }
                        TextLabel { text: session.network; color: root.muted }
                        RowLayout { Action { text: "Wi-Fi on"; onClicked: session.wifi(true) } Action { text: "Wi-Fi off"; onClicked: session.wifi(false) } }
                        TextLabel { text: "Output audio"; font.pixelSize: 20 }
                        TextLabel { text: session.audio; color: root.muted }
                        RowLayout { Action { text: "− Volume"; onClicked: session.volume(-1) } Action { text: "Mute / unmute"; onClicked: session.mute() } Action { text: "+ Volume"; onClicked: session.volume(1) } }
                        TextLabel { text: "Uses NetworkManager and PipeWire when available. Unavailable services and permission errors are reported; no simulated device state."; wrapMode: Text.Wrap; Layout.fillWidth: true; color: root.muted }
                        Item { Layout.fillHeight: true }
                    }
                    ListView {
                        clip: true; spacing: 8; model: session.windows
                        delegate: Rectangle {
                            required property var modelData
                            width: ListView.view.width; height: 80; radius: 12; color: "#353337"
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 8; spacing: 2
                                TextLabel { text: modelData.title; elide: Text.ElideRight; Layout.fillWidth: true }
                                RowLayout { Repeater { model: ["focus","minimize","fullscreen","float","close"]; Action { required property var modelData; property string targetId: parent.parent.parent.modelData.id; text: modelData; onClicked: session.windowAction(targetId,modelData) } } }
                            }
                        }
                        TextLabel { anchors.centerIn: parent; visible: session.windows.length===0; text: "No open windows"; color: root.muted }
                    }
                }
                TextLabel { text: session.status; color: root.accent; Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 12 }
            }
        }
    }
}
