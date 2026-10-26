import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings

Item {
    id: root
    property color cream: "#f1ece2"
    property color muted: "#aaa6a4"
    property color accent: "#dfa77c"
    property string clock: Qt.formatDateTime(new Date(), "ddd  d MMM   HH:mm")
    Settings { id: preferences; category: "Desktop"; property bool reducedMotion: false; property bool opaque: false; property real wallpaperOpacity: 1 }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.clock = Qt.formatDateTime(new Date(), "ddd  d MMM   HH:mm") }
    function showConsole() { appsWindow.visible=false; settingsWindow.visible=false; gamesWindow.visible=false; playMode.toggle() }
    function showLibrary() { playMode.leave(); gamesWindow.visible = !gamesWindow.visible; if(gamesWindow.visible) { appLauncher.refresh(); gameSearch.text=""; gameGrid.forceActiveFocus() } }
    function showApps() { playMode.leave(); appsWindow.visible = !appsWindow.visible; if(appsWindow.visible) { search.text=""; search.forceActiveFocus() } }
    Connections { target: session; function onOpenLauncher() { root.showApps() } function onOpenControls() { playMode.leave(); settingsWindow.visible=!settingsWindow.visible } function onOpenGames() { root.showConsole() } function onOpenLibrary() { root.showLibrary() } }
    Connections { target: appLauncher; function onLaunchAccepted(id) { appsWindow.visible=false } }
    Console { id: playMode; reducedMotion: preferences.reducedMotion; onReducedMotionRequested: preferences.reducedMotion=!preferences.reducedMotion; onAdvancedLibraryRequested: { leave(); root.showLibrary() } }
    component TextLabel: Label { color: root.cream; font.pixelSize: 14 }
    component Action: Button {
        id: button
        focusPolicy: Qt.StrongFocus
        Accessible.name: text
        contentItem: Text { text: button.text; color: root.cream; font.pixelSize: 14; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        background: Rectangle { radius: 10; color: button.down ? "#4a3c32" : button.hovered ? "#34393e" : "transparent"; border.width: button.activeFocus ? 2 : 0; border.color: root.accent }
    }
    component SettingsTab: TabButton {
        id: tab
        contentItem: Text { text: tab.text; color: root.cream; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14 }
        background: Rectangle { color: tab.checked ? "#4b3931" : "#333237"; radius: 9; border.color: tab.activeFocus ? root.accent : "transparent" }
    }
    component Surface: Rectangle { color: preferences.opaque ? "#212429" : "#f0212429"; radius: 22; border.color: "#45474b"; border.width: 1 }
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
        id: bar; property bool ready: false; visible: ready && !externalBar && !playMode.modeActive; width: Screen.width; height: 40; color: "transparent"; flags: Qt.FramelessWindowHint
        Component.onCompleted: { if(!externalBar)session.configure(bar,"bar"); ready=true }
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
        id: dock; width: Math.min(Screen.width-32,960); height: 76; color: "transparent"; flags: Qt.FramelessWindowHint
        property bool ready: false
        Component.onCompleted: { session.configure(dock,"dock"); ready=true }
        visible: ready && !playMode.modeActive
        Surface { width: dockItems.implicitWidth+24; height: 68; anchors.centerIn: parent; radius: 20 }
        RowLayout {
            id: dockItems; anchors.centerIn: parent; spacing: 5
            Action { text: "▦"; Layout.preferredWidth: 48; Layout.preferredHeight: 54; onClicked: root.showApps(); ToolTip.visible: hovered; ToolTip.text: "Applications · Super+Space" }
            Repeater {
                model: appLauncher.applications.slice(0,4)
                delegate: Action {
                    required property var modelData
                    Layout.preferredWidth: 55; Layout.preferredHeight: 54
                    text: modelData.name
                    contentItem: Image { source: "image://apps/"+modelData.appId; sourceSize.width: 40; sourceSize.height: 40; fillMode: Image.PreserveAspectFit }
                    onClicked: appLauncher.launch(modelData.appId)
                    ToolTip.visible: hovered; ToolTip.text: modelData.name
                    scale: hovered ? 1.12 : 1
                    Behavior on scale { NumberAnimation { duration: preferences.reducedMotion ? 0 : 150; easing.type: Easing.OutCubic } }
                    background: Rectangle { anchors.margins: 6; radius: 12; color: "#30343a"; border.color: parent.activeFocus ? root.accent : "#484b50" }
                }
            }
            Rectangle { Layout.preferredHeight: 34; Layout.preferredWidth: 1; color: "#675b55" }
            Repeater {
                model: session.windows.slice(0,6)
                delegate: Item {
                    required property var modelData
                    Layout.preferredWidth: 63; Layout.preferredHeight: 54
                    Action { anchors.fill: parent; text: modelData.title; contentItem: Image { source: "image://apps/"+modelData.appId; sourceSize.width: 32; sourceSize.height: 32; fillMode: Image.PreserveAspectFit; anchors.margins: 10 } onClicked: session.windowAction(modelData.id,"focus"); ToolTip.visible: hovered; ToolTip.text: modelData.title+(modelData.minimized?" · Minimized":"") }
                    Rectangle { width: modelData.focused ? 16 : 5; height: 3; radius: 2; anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; color: modelData.minimized ? root.muted : root.accent; Behavior on width { NumberAnimation { duration: preferences.reducedMotion ? 0 : 150 } } }
                }
            }
            Action { text: "Play"; Layout.preferredWidth: 64; Layout.preferredHeight: 54; onClicked: root.showConsole(); ToolTip.visible: hovered; ToolTip.text: "Game Mode · Super+G" }
            Action { text: "⚙"; Layout.preferredWidth: 40; Layout.preferredHeight: 54; onClicked: settingsWindow.visible=!settingsWindow.visible; ToolTip.visible: hovered; ToolTip.text: "Settings and windows" }
        }
    }
    // Original Tamber Game Library with retained advanced management controls.
    Window {
        id: gamesWindow
        width: Math.min(1050, Screen.width-50); height: Math.min(680, Screen.height-70)
        flags: Qt.FramelessWindowHint; color: "transparent"
        property var games: gameLibrary.games.filter(a => a.name.toLowerCase().includes(gameSearch.text.toLowerCase()))
        property var selected: games.length ? games[Math.max(0,Math.min(gameGrid.currentIndex,games.length-1))] : null
        onVisibleChanged: controller.active=visible
        Connections { target: gameLibrary; function onLaunched() { gamesWindow.visible=false } }
        Connections { target: controller; function onAction(name) {
            if(!gamesWindow.visible)return;
            if(name==="back"){gamesWindow.visible=false;return}
            if(name==="accept"&&gamesWindow.selected){gameLibrary.launch(gamesWindow.selected.appId);return}
            if(name==="favorite"&&gamesWindow.selected){gameLibrary.favorite(gamesWindow.selected.appId);return}
            gameGrid.forceActiveFocus();
            let step=(name==="left"?-1:name==="right"?1:name==="up"?-Math.max(1,Math.floor(gameGrid.width/gameGrid.cellWidth)):Math.max(1,Math.floor(gameGrid.width/gameGrid.cellWidth)));
            gameGrid.currentIndex=Math.max(0,Math.min(gameGrid.count-1,gameGrid.currentIndex+step));gameGrid.positionViewAtIndex(gameGrid.currentIndex,GridView.Contain)
        } }
        Component.onCompleted: session.configure(gamesWindow,"games")
        Rectangle { anchors.fill: parent; radius: 24; color: "#ee14171b"; border.color: "#52575d"; border.width: 1 }
        Item {
            anchors.fill: parent; focus: true
            Keys.onEscapePressed: { if(manage.visible)manage.visible=false;else gamesWindow.visible=false }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 28; spacing: 14
                RowLayout {
                    spacing: 18
                    ColumnLayout {
                        Text { text: "TAMBER / PLAY"; font.pixelSize: 13; font.bold: true; font.letterSpacing: 3; color: "#e6a56a" }
                        Text { text: "Made for play."; font.pixelSize: 29; font.bold: true; color: "#f0f1f3" }
                    }
                    Item { Layout.fillWidth: true }
                    Action { text: "Manage"; onClicked: manage.visible=!manage.visible }
                    Action { text: "Refresh"; onClicked: { appLauncher.refresh(); gameLibrary.refresh() } }
                    Action { text: "Close"; onClicked: gamesWindow.visible=false }
                }
                Rectangle { Layout.fillWidth: true; height: 1; color: "#394047" }
                TextField {
                    id: gameSearch
                    Layout.fillWidth: true; Layout.preferredHeight: 48
                    placeholderTextColor: "#aab4bb"; placeholderText: "Search your library · native games and emulators"; onTextChanged: gameGrid.currentIndex=0; color: "#f0f1f3"; font.pixelSize: 16
                    background: Rectangle { color: "#292f35"; radius: 12; border.color: gameSearch.activeFocus ? "#e6a56a" : "#555e66" }
                    Keys.onEscapePressed: { if(manage.visible)manage.visible=false;else gamesWindow.visible=false }
                    Keys.onDownPressed: { gameGrid.forceActiveFocus(); gameGrid.currentIndex=0 }
                    onAccepted: if(gamesWindow.games.length)gameLibrary.launch(gamesWindow.games[0].appId)
                }
                GridView {
                    id: gameGrid; Layout.fillWidth: true; Layout.fillHeight: true; clip: true; focus: true
                    cellWidth: 196; cellHeight: 258; model: gamesWindow.games; keyNavigationWraps: true
                    Keys.onPressed: function(event) { if(event.key===Qt.Key_F && (event.modifiers & Qt.ControlModifier)){gameSearch.forceActiveFocus();event.accepted=true} else if(event.key===Qt.Key_M && (event.modifiers & Qt.ControlModifier)){manage.visible=true;artPath.forceActiveFocus();event.accepted=true} else if(event.key===Qt.Key_F && gamesWindow.selected){gameLibrary.favorite(gamesWindow.selected.appId);event.accepted=true} }
                    Keys.onReturnPressed: if(currentIndex>=0 && currentIndex<gamesWindow.games.length) gameLibrary.launch(gamesWindow.games[currentIndex].appId)
                    Keys.onEscapePressed: { if(manage.visible)manage.visible=false;else gamesWindow.visible=false }
                    delegate: Rectangle {
                        required property var modelData; required property int index
                        width: 182; height: 242; radius: 15
                        color: gameGrid.currentIndex===index ? "#394653" : "#252a30"
                        border.width: gameGrid.currentIndex===index ? 2 : 1
                        border.color: gameGrid.currentIndex===index ? "#e6a56a" : "#41484e"
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 14; spacing: 10
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 164; color: "#171c22"; radius: 10
                                clip: true
                                Image { anchors.fill: parent; anchors.margins: modelData.art ? 0 : 32; source: modelData.art || ("image://apps/"+modelData.appId); fillMode: Image.PreserveAspectFit }
                                Text { anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 8; visible: !modelData.art && modelData.favorite; text: "★ FAVORITE"; color: "#ffffff"; style: Text.Outline; styleColor: "#111111"; font.pixelSize: 10 }
                            }
                            Text { text: modelData.name; color: "#f0f1f3"; font.pixelSize: 15; font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                            Text { text: modelData.platform; color: "#aab4bb"; font.pixelSize: 11 }
                        }
                        MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: gameGrid.currentIndex=index; onClicked: gameLibrary.launch(modelData.appId) }
                    }
                    Text { anchors.centerIn: parent; visible: gameGrid.count===0; text: gameSearch.text ? "No matching games" : "No games detected. Install a game with a Game category desktop entry."; color: "#aab4bb"; font.pixelSize: 15; width: parent.width-40; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "D-pad / arrows  Navigate    A / Enter  Play    B / Esc  Back"; color: "#9ba7ad"; font.pixelSize: 12; Layout.fillWidth: true }
                    Action { text: gamesWindow.selected && gamesWindow.selected.favorite ? "★ Saved" : "☆ Favorite"; enabled: !!gamesWindow.selected; onClicked: gameLibrary.favorite(gamesWindow.selected.appId) }
                }
                Text { text: controller.status; color: "#9ba7ad"; font.pixelSize: 11 }
                Text { text: gameLibrary.status; color: "#e6a56a"; font.pixelSize: 12 }
            }
        }

        Rectangle {
            id: manage; visible: false; Keys.onEscapePressed: visible=false; onVisibleChanged: { controller.active=gamesWindow.visible&&!visible; if(!visible&&gamesWindow.visible)gameGrid.forceActiveFocus() } anchors.fill: parent; anchors.margins: 20; radius: 18; color: "#24282e"; border.color: "#69727b"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 24; spacing: 10
                Text { text: "Library management"; color: "#f0f1f3"; font.pixelSize: 24 }
                Text { text: "Selected: "+(gamesWindow.selected ? gamesWindow.selected.name : "none"); color: "#c0c8cf" }
                TextField { id: artPath; Layout.fillWidth: true; placeholderText: "Absolute path to your cover image (PNG / JPG / SVG)" }
                RowLayout {
                    Action { text: "Import cover"; enabled: !!gamesWindow.selected; onClicked: gameLibrary.artwork(gamesWindow.selected.appId,artPath.text) }
                    Action { text: "Hide selected"; enabled: !!gamesWindow.selected; onClicked: gameLibrary.hide(gamesWindow.selected.appId) }
                    Action { text: "Restore hidden"; onClicked: gameLibrary.restoreHidden() }
                }
                Text { text: "Add a RetroArch profile · supply your own legally obtained game and core"; color: "#c0c8cf"; wrapMode: Text.Wrap; Layout.fillWidth: true }
                TextField { id: profileName; Layout.fillWidth: true; placeholderText: "Game name" }
                TextField { id: runnerPath; Layout.fillWidth: true; placeholderText: "Absolute path to RetroArch executable" }
                TextField { id: romPath; Layout.fillWidth: true; placeholderText: "Absolute path to ROM" }
                TextField { id: corePath; Layout.fillWidth: true; placeholderText: "Absolute path to libretro core (.so)" }
                Action { text: "Add profile"; onClicked: gameLibrary.addEmulator(profileName.text,runnerPath.text,romPath.text,corePath.text) }
                Text { text: gameLibrary.status; color: "#e6a56a"; Layout.fillWidth: true; wrapMode: Text.Wrap }
                Item { Layout.fillHeight: true }
                Action { text: "Done"; onClicked: manage.visible=false }
            }
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
                        width: results.width; height: 54; text: modelData.name
                        contentItem: RowLayout { spacing: 16; Image { source: "image://apps/"+modelData.appId; sourceSize.width: 32; sourceSize.height: 32; Layout.preferredWidth: 32; Layout.preferredHeight: 32 } TextLabel { text: modelData.name; Layout.fillWidth: true; elide: Text.ElideRight } TextLabel { text: "↵"; color: root.muted } }
                        background: Rectangle { radius: 12; color: results.currentIndex===index ? "#363b40" : "transparent"; border.color: parent.activeFocus ? root.accent : "transparent" }
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
                TabBar { id: tabs; Layout.fillWidth: true; background: Rectangle { color: "transparent" } SettingsTab { text: "Appearance" } SettingsTab { text: "Sound and network" } SettingsTab { text: "Windows" } }
                StackLayout {
                    currentIndex: tabs.currentIndex; Layout.fillWidth: true; Layout.fillHeight: true
                    ColumnLayout {
                        spacing: 10
                        TextLabel { text: "Your workspace, considered."; font.pixelSize: 21 }
                        CheckBox { text: "Reduce animation"; checked: preferences.reducedMotion; onToggled: preferences.reducedMotion=checked; palette.windowText: root.cream; palette.base: "#383238"; palette.button: "#383238"; palette.highlight: root.accent }
                        CheckBox { text: "Opaque panels"; checked: preferences.opaque; onToggled: preferences.opaque=checked; palette.windowText: root.cream; palette.base: "#383238"; palette.button: "#383238"; palette.highlight: root.accent }
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
