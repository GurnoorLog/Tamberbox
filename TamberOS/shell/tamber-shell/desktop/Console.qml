import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings

// Original Tamber console surface. No Sony code, imagery or UI assets.
Window {
    id: playMode
    width: Screen.width; height: Screen.height
    color: "#11171d"; flags: Qt.FramelessWindowHint
    property bool modeActive: false
    property bool reducedMotion: false
    signal reducedMotionRequested()
    signal advancedLibraryRequested()
    Settings { id: atmosphere; category: "PlayAppearance"; property int lightLevel: 1 }
    property string clock: Qt.formatTime(new Date(),"HH:mm")
    Timer { interval: 1000; running: playMode.visible; repeat: true; onTriggered: playMode.clock=Qt.formatTime(new Date(),"HH:mm") }
    property int section: 0
    onSectionChanged: sectionFade.restart()
    property int selection: 0
    property int filterIndex: 0
    property int zone: 1 // 0 navigation, 1 content, 2 actions
    property int actionIndex: 0
    property bool details: false
    property string query: ""
    property string notice: ""
    property string pendingId: ""
    property string runningId: ""
    property bool wasFullscreen: false
    property int waitTicks: 0
    property var info: ({})
    property var sections: ["All games", "Library", "Apps", "Media", "Emulators", "Favorites", "System"]
    property var filters: ["Installed", "Recent", "Native", "Collections"]
    property var entries: {
        let games = gameLibrary.games.slice();
        let items;
        if(section===2 || section===3) {
            items=appLauncher.applications.filter(a => section===2 || (a.categories || []).indexOf("AudioVideo")>=0);
        } else {
            items=games.filter(a => (section!==4 || a.platform==="RetroArch") && (section!==5 || a.favorite));
            if(section===1 && filterIndex===1)items=items.filter(a=>!!a.lastPlayed);
            if(section===1 && filterIndex===2)items=items.filter(a=>a.platform==="Native");
            if(section===1 && filterIndex===3)items=items.filter(a=>!!a.collection);
            if(section===0 || (section===1 && filterIndex===1))items.sort((a,b)=>(b.lastPlayed || "").localeCompare(a.lastPlayed || ""));
        }
        return items.filter(a => (a.name+" "+(a.collection || "")).toLowerCase().includes(query.toLowerCase()));
    }
    property var selected: entries.length ? entries[Math.max(0,Math.min(selection,entries.length-1))] : null
    property bool selectedGame: !!selected && !!selected.platform
    property var activeWindow: selected ? session.windows.find(w => w.appId===selected.appId.replace(/\.desktop$/, "")) : null
    property color cream: "#f2eee6"
    property color muted: "#b3aaa3"
    property color accent: "#efb17c"
    onEntriesChanged: selection=Math.max(0,Math.min(selection,entries.length-1))
    Component.onCompleted: session.configure(playMode,"console")
    onVisibleChanged: { controller.active=visible && !manage.visible; if(visible){navigation.forceActiveFocus();info=session.systemInfo()} }
    function enter() { modeActive=true; visible=true; notice=""; navigation.forceActiveFocus() }
    function toggle() { if(visible)leave();else enter() }
    function leave() {
        visible=false; modeActive=false; pendingId="";
        if(runningId && !wasFullscreen)session.windowAction(runningId,"fullscreen-off");
        runningId="";
    }
    function chooseSection(n) { section=n; selection=0; details=false; query=""; search.text=""; actionIndex=0; notice="" }
    function launchSelected() {
        if(!selected)return;
        if(activeWindow){if(runningId!==activeWindow.id)wasFullscreen=activeWindow.fullscreen;runningId=activeWindow.id;session.windowAction(runningId,"focus");session.windowAction(runningId,"fullscreen-on");visible=false;return}
        const id=selected.appId;
        const ok=selectedGame ? gameLibrary.launch(id) : appLauncher.launch(id);
        if(ok){pendingId=id.replace(/\.desktop$/, "");waitTicks=0;visible=false;notice=""}
        else notice=selectedGame?gameLibrary.status:appLauncher.status;
    }
    function favorite() { if(selectedGame)gameLibrary.favorite(selected.appId) }
    function act() {
        if(actionIndex===0)launchSelected();
        else if(actionIndex===1)favorite();
        else if(actionIndex===2){manage.visible=true;coverPath.forceActiveFocus()}
        else details=!details;
    }
    function navigate(action) {
        if(!visible || manage.visible)return;
        if(action==="back") {
            if(details){details=false;zone=1}
            else if(query){query="";search.text="";navigation.forceActiveFocus()}
            else if(section!==0){chooseSection(0);zone=1}
            else leave();
        } else if(action==="favorite")favorite();
        else if(action==="accept") { if(zone===0){zone=1}else if(section===6){systemAction()}else if(zone===2){act()}else{details=true;zone=2;actionIndex=0} }
        else if(action==="up")zone=Math.max(0,zone-1);
        else if(action==="down")zone=Math.min(section===6?1:2,zone+1);
        else if(action==="left" || action==="right") {
            const delta=action==="left"?-1:1;
            if(zone===0)chooseSection((section+delta+sections.length)%sections.length);
            else if(section===6)selection=Math.max(0,Math.min(7,selection+delta));
            else if(zone===2)actionIndex=Math.max(0,Math.min(selectedGame?3:0,actionIndex+delta));
            else {selection=Math.max(0,Math.min(entries.length-1,selection+delta));cards.positionViewAtIndex(selection,ListView.Contain)}
        }
    }
    function systemAction() {
        if(selection===0)reducedMotionRequested();
        else if(selection===1)notice="Network: "+session.network+". Connection setup is available in desktop settings.";
        else if(selection===2)session.mute();
        else if(selection===3)notice=controller.status+" · Model-specific mapping is pending.";
        else if(selection===4)info=session.systemInfo();
        else if(selection===5)notice="Output scaling is available in desktop settings; this console uses the compositor output size.";
        else if(selection===6)leave();
        else notice=info.os+" · "+info.architecture+" · Linux "+info.kernel;
    }
    Connections { target: controller; function onAction(name) { playMode.navigate(name) } }
    Timer {
        interval: 300; running: playMode.modeActive && !playMode.visible; repeat: true
        onTriggered: {
            if(playMode.pendingId) {
                const found=session.windows.find(w=>w.appId===playMode.pendingId);
                if(found){playMode.runningId=found.id;playMode.wasFullscreen=found.fullscreen;playMode.pendingId="";session.windowAction(found.id,"fullscreen-on");session.windowAction(found.id,"focus")}
                else if(++playMode.waitTicks>50){playMode.pendingId="";playMode.visible=true;playMode.notice="Launch requested. No matching Wayland window appeared. Use Apps or return to Desktop to inspect it."}
            } else if(playMode.runningId && !session.windows.some(w=>w.id===playMode.runningId)) {
                playMode.runningId="";playMode.visible=true;
            }
        }
    }
    Timer {
        interval: 200; running: true; repeat: true
        property string previous: ""
        onTriggered: {
            const value=JSON.stringify({visible:playMode.visible,modeActive:playMode.modeActive,width:playMode.width,height:playMode.height,section:playMode.section,selection:playMode.selection,zone:playMode.zone,details:playMode.details,count:playMode.entries.length,selected:playMode.selected?playMode.selected.appId:"",filter:playMode.filterIndex,lightLevel:atmosphere.lightLevel,lightPhase:Number(lightField.phase.toFixed(3)),focusedTileWidth:cards.currentItem?Math.round(cards.currentItem.width):0,reducedMotion:playMode.reducedMotion,notice:playMode.notice,pending:playMode.pendingId,running:playMode.runningId});
            if(value!==previous){previous=value;session.consoleState(value)}
        }
    }
    component Copy: Text { color: playMode.cream; font.family: "Sans Serif"; font.pixelSize: 15; elide: Text.ElideRight }
    component KeyButton: Button {
        id: keyButton
        property bool selected: false
        focusPolicy: Qt.StrongFocus
        Accessible.name: text
        contentItem: Copy { text: keyButton.text; color: keyButton.selected || keyButton.activeFocus ? "#151b21" : playMode.cream; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 10; color: keyButton.selected || keyButton.activeFocus ? playMode.accent : keyButton.hovered ? "#35404a" : "#222d36"; border.color: "#45515b"; border.width: keyButton.activeFocus?2:1; Behavior on color { ColorAnimation { duration: playMode.reducedMotion?0:120 } } }
    }
    Rectangle { anchors.fill: parent; color: "#111011" }
    LightField { id: lightField; anchors.fill: parent; animate: playMode.visible && !playMode.reducedMotion; strength: [0,0.55,0.9][atmosphere.lightLevel] }
    Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "#00111011" } GradientStop { position: 0.56; color: "#70111011" } GradientStop { position: 1; color: "#d9111011" } } }
    Item {
        id: navigation; anchors.fill: parent; focus: true
        Keys.onPressed: function(event) {
            if(event.key===Qt.Key_Escape){playMode.navigate("back");event.accepted=true}
            else if(event.key===Qt.Key_Left){playMode.navigate("left");event.accepted=true}
            else if(event.key===Qt.Key_Right){playMode.navigate("right");event.accepted=true}
            else if(event.key===Qt.Key_Up){playMode.navigate("up");event.accepted=true}
            else if(event.key===Qt.Key_Down){playMode.navigate("down");event.accepted=true}
            else if(event.key===Qt.Key_Return || event.key===Qt.Key_Enter){playMode.navigate("accept");event.accepted=true}
            else if(event.key===Qt.Key_F && (event.modifiers & Qt.ControlModifier)){search.forceActiveFocus();event.accepted=true}
            else if(event.key===Qt.Key_B){atmosphere.lightLevel=(atmosphere.lightLevel+1)%3;event.accepted=true}
            else if(event.key===Qt.Key_F){playMode.favorite();event.accepted=true}
            else if(event.key===Qt.Key_M && playMode.selectedGame){manage.visible=true;coverPath.forceActiveFocus();event.accepted=true}
            else if(event.key===Qt.Key_Tab){playMode.zone=(playMode.zone+1)%3;event.accepted=true}
            else if(event.key===Qt.Key_PageDown || event.key===Qt.Key_PageUp){playMode.chooseSection((playMode.section+(event.key===Qt.Key_PageDown?1:6))%7);playMode.zone=1;event.accepted=true}
            else if(event.key===Qt.Key_R && playMode.section===1){playMode.filterIndex=(playMode.filterIndex+1)%4;playMode.selection=0;event.accepted=true}
        }
        ColumnLayout {
            anchors.fill: parent; anchors.leftMargin: 42; anchors.rightMargin: 42; anchors.topMargin: 24; anchors.bottomMargin: 22; spacing: 18
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Image { source: "qrc:/brand/tamber-llama.svg"; Layout.preferredWidth: 24; Layout.preferredHeight: 32; fillMode: Image.PreserveAspectFit }
                Copy { text: "TAMBER / PLAY"; font.pixelSize: 14; font.letterSpacing: 3; font.weight: Font.DemiBold }
                Item { Layout.fillWidth: true }
                TextField {
                            id: search; Layout.preferredWidth: 240; Layout.preferredHeight: 40; color: playMode.cream; placeholderTextColor: playMode.muted; placeholderText: "Search  ·  Ctrl F"; text: playMode.query; onTextEdited: {playMode.query=text;playMode.selection=0}
                            background: Rectangle { color: "#202a33"; radius: 10; border.color: search.activeFocus?playMode.accent:"#3b4751" }
                            onAccepted: {navigation.forceActiveFocus();playMode.zone=1}
                            Keys.onEscapePressed: {playMode.query="";text="";navigation.forceActiveFocus()}
                            Keys.onDownPressed: {navigation.forceActiveFocus();playMode.zone=1}
                        }
                Copy { text: playMode.clock; color: playMode.cream; font.pixelSize: 16 }
                KeyButton { text: "Return to Desktop"; onClicked: playMode.leave(); Layout.preferredHeight: 36; Layout.preferredWidth: 168 }
            }
            RowLayout {
                spacing: 8
                Repeater {
                    model: playMode.sections
                    KeyButton {
                        id: categoryButton
                        required property string modelData; required property int index
                        text: modelData; selected: playMode.section===index
                        Layout.preferredWidth: contentItem.implicitWidth+24; Layout.preferredHeight: 48
                        contentItem: Copy { text: modelData; color: categoryButton.selected?playMode.cream:playMode.muted; font.pixelSize: categoryButton.selected?25:17; font.weight: categoryButton.selected?Font.DemiBold:Font.Normal; verticalAlignment: Text.AlignVCenter }
                        background: Item { Rectangle { anchors.bottom: parent.bottom; width: 22; height: 2; radius: 1; color: playMode.accent; visible: playMode.section===index && playMode.zone===0 } }
                        onClicked: {playMode.chooseSection(index);playMode.zone=1;navigation.forceActiveFocus()}
                    }
                }
                Item { Layout.fillWidth: true }
                KeyButton { visible: playMode.section===1; text: playMode.filters[playMode.filterIndex]+"  · R"; Layout.preferredWidth: 160; onClicked: {playMode.filterIndex=(playMode.filterIndex+1)%4;playMode.selection=0} }
            }
            Item {
                id: contentPanel
                Layout.fillWidth: true; Layout.fillHeight: true
                NumberAnimation { id: sectionFade; target: contentPanel; property: "opacity"; from: 0.4; to: 1; duration: playMode.reducedMotion?0:180; easing.type: Easing.OutCubic }
                ColumnLayout {
                    anchors.fill: parent; spacing: 16; visible: playMode.section!==6
                    // Horizontal focus rail remains spatially stable across game/app categories.
                    ListView {
                        id: cards; Layout.fillWidth: true; Layout.preferredHeight: Math.min(360,playMode.height*0.35); orientation: ListView.Horizontal; spacing: 16; clip: true; model: playMode.entries; currentIndex: playMode.selection
                        highlightMoveDuration: playMode.reducedMotion?0:220
                        highlightRangeMode: ListView.ApplyRange; preferredHighlightBegin: 0; preferredHighlightEnd: width*0.45
                        delegate: Item {
                            required property var modelData; required property int index
                            property bool chosen: playMode.selection===index
                            width: chosen?Math.min(cards.width*0.40,640):Math.max(150,cards.height*0.57)
                            height: cards.height
                            Behavior on width { NumberAnimation { duration: playMode.reducedMotion?0:220; easing.type: Easing.OutCubic } }
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 3; radius: 14; clip: true
                                color: chosen?"#302720":"#1e1b1b"; border.width: chosen?2:1; border.color: chosen?playMode.accent:"#3a3431"
                                Image { anchors.fill: parent; anchors.margins: 2; source: modelData.art || ""; fillMode: Image.PreserveAspectCrop; opacity: 0.18; visible: !!modelData.art }
                                Image { anchors.fill: parent; anchors.margins: modelData.art?10:48; source: modelData.art || (modelData.platform==="RetroArch"?"qrc:/brand/application.svg":"image://apps/"+modelData.appId); fillMode: Image.PreserveAspectFit; sourceSize.width: 640; sourceSize.height: 400 }
                                Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 56; color: "#cc151212"; visible: !modelData.art
                                    Copy { anchors.fill: parent; anchors.margins: 12; text: modelData.name; font.pixelSize: 16; font.weight: Font.DemiBold; verticalAlignment: Text.AlignVCenter }
                                }
                                Copy { anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 14; text: "★"; color: playMode.accent; visible: !!modelData.favorite; font.pixelSize: 20 }
                            }
                            MouseArea { anchors.fill: parent; onClicked: {playMode.selection=index;playMode.zone=1;navigation.forceActiveFocus()} onDoubleClicked: playMode.launchSelected() }
                        }
                        Copy { anchors.centerIn: parent; visible: cards.count===0; width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; text: playMode.query ? "Nothing matches this search." : playMode.section===4 ? "Add an emulator profile from Library management." : "Nothing here yet. Your installed applications and saved library appear here."; color: playMode.muted }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; color: "transparent"
                        RowLayout {
                            anchors.fill: parent; anchors.topMargin: 8; spacing: 0

                            ColumnLayout {
                                spacing: 8; Layout.fillWidth: true; Layout.alignment: Qt.AlignTop
                                Copy { text: playMode.selected ? (playMode.selected.platform || "APPLICATION")+ (playMode.selected.collection?"  /  "+playMode.selected.collection:"") : "YOUR LIBRARY"; color: playMode.accent; font.pixelSize: 11; font.letterSpacing: 2; Layout.fillWidth: true }
                                Copy { text: playMode.selected ? playMode.selected.name : "Make it yours."; color: playMode.accent; font.pixelSize: 34; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                Copy { text: playMode.details && playMode.selected ? playMode.selected.appId : playMode.selected && playMode.selected.lastPlayed ? "Last launched "+Qt.formatDateTime(new Date(playMode.selected.lastPlayed),"d MMM · HH:mm") : "Installed locally. Ready to launch."; color: playMode.muted; Layout.fillWidth: true; font.pixelSize: 13 }
                                RowLayout {
                                    spacing: 10
                                    Repeater {
                                        // Stable delegates: changing a JS array model can delete layout items during a Qt 6.4 size-hint pass.
                                        model: 4
                                        KeyButton { required property int index; visible: playMode.selectedGame || index===0; text: [playMode.activeWindow?"Resume":playMode.selectedGame?"Play":"Open",playMode.selected && playMode.selected.favorite?"Saved":"Favorite","Manage",playMode.details?"Less":"Details"][index]; enabled: !!playMode.selected; selected: (playMode.zone===2 && playMode.actionIndex===index) || (playMode.zone!==2 && index===0); Layout.preferredWidth: 110; Layout.preferredHeight: 40; onClicked: {playMode.actionIndex=index;playMode.act()} }
                                    }
                                }
                            }
                        }
                    }
                }
                ColumnLayout {
                    anchors.fill: parent; visible: playMode.section===6; spacing: 18
                    Copy { text: "Your system. Your space."; font.pixelSize: 32; font.weight: Font.DemiBold }
                    GridLayout {
                        columns: 4; rowSpacing: 14; columnSpacing: 14; Layout.fillWidth: true; Layout.fillHeight: true
                        Repeater {
                            model: ["Game Mode", "Network", "Audio", "Controllers", "Storage", "Display", "Power & exit", "System info"]
                            Rectangle {
                                required property string modelData; required property int index
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; color: playMode.selection===index?"#303d48":"#202b34"; border.color: playMode.selection===index?playMode.accent:"#3a4650"; border.width: playMode.selection===index?2:1
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 20; spacing: 12
                                    Copy { text: modelData; font.pixelSize: 18; Layout.fillWidth: true }
                                    Text { color: playMode.muted; font.pixelSize: 13; wrapMode: Text.Wrap; Layout.fillWidth: true; Layout.fillHeight: true; text: [playMode.reducedMotion?"Reduced motion enabled":"Smooth transitions enabled",session.network,session.audio,controller.status,Number(playMode.info.storageAvailableGiB || 0).toFixed(1)+" GiB available in home storage",playMode.width+" × "+playMode.height+" · compositor output","Return safely to desktop. Shutdown / reboot integration pending.",(playMode.info.os || "")+"\n"+(playMode.info.architecture || "")][index] }
                                    Copy { text: ["Enter · Toggle motion","Enter · Status","Enter · Mute / unmute","Mapping support pending","Enter · Refresh","Enter · Details","Enter · Exit Game Mode","Enter · Details"][index]; color: playMode.accent; font.pixelSize: 11; Layout.fillWidth: true }
                                }
                                MouseArea { anchors.fill: parent; onClicked: {playMode.selection=index;playMode.systemAction();navigation.forceActiveFocus()} }
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Copy { text: playMode.notice || "← →  Select    ↑ ↓  Move focus    Enter  Confirm    Esc  Back    PgUp / PgDn  Sections    B  Atmosphere"; color: playMode.muted; font.pixelSize: 12; Layout.fillWidth: true }
                Copy { text: playMode.zone===0?"NAVIGATION":playMode.zone===2?"ACTIONS":"BROWSE"; color: playMode.accent; font.pixelSize: 10; font.letterSpacing: 2 }
            }
        }
    }
    Rectangle {
        id: manage; anchors.fill: parent; visible: false; color: "#f211171d"; onVisibleChanged: {controller.active=playMode.visible&&!visible;if(!visible)navigation.forceActiveFocus()}
        Keys.onEscapePressed: visible=false
        Rectangle {
            width: Math.min(720,parent.width-80); height: 430; anchors.centerIn: parent; color: "#222d36"; radius: 20; border.color: "#52606b"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 32; spacing: 16
                Copy { text: "Make it your library."; font.pixelSize: 28 }
                Copy { text: playMode.selected ? playMode.selected.name : "No selection"; color: playMode.muted }
                TextField { id: coverPath; Layout.fillWidth: true; placeholderText: "Absolute path to a local cover image" }
                KeyButton { text: "Import artwork"; enabled: playMode.selectedGame; onClicked: playMode.notice=gameLibrary.artwork(playMode.selected.appId,coverPath.text)?"Artwork imported":gameLibrary.status }
                RowLayout {
                    TextField { id: collectionName; Layout.fillWidth: true; placeholderText: "Collection name (blank removes membership)"; maximumLength: 48 }
                    KeyButton { text: "Save collection"; enabled: playMode.selectedGame; onClicked: gameLibrary.collection(playMode.selected.appId,collectionName.text) }
                }
                Copy { text: playMode.notice; color: playMode.accent; Layout.fillWidth: true }
                Item { Layout.fillHeight: true }
                RowLayout {
                    KeyButton { text: "Advanced library"; onClicked: {manage.visible=false;playMode.advancedLibraryRequested()} }
                    Item { Layout.fillWidth: true }
                    KeyButton { text: "Done"; onClicked: manage.visible=false }
                }
            }
        }
    }
}
