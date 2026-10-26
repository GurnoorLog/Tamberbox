import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

// Original Tamber console surface. No Sony code, imagery or UI assets.
Window {
    id: console
    width: Screen.width; height: Screen.height
    color: "#11171d"; flags: Qt.FramelessWindowHint
    property bool modeActive: false
    property bool reducedMotion: false
    signal reducedMotionRequested()
    signal advancedLibraryRequested()
    property int section: 0
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
    property var sections: ["Home", "Library", "Apps", "Media", "Emulators", "Favorites", "System"]
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
    property bool selectedGame: selected && !!selected.platform
    property var activeWindow: selected ? session.windows.find(w => w.appId===selected.appId.replace(/\.desktop$/, "")) : null
    property color cream: "#f2eee6"
    property color muted: "#9da9b3"
    property color accent: "#e6ae80"
    onEntriesChanged: selection=Math.max(0,Math.min(selection,entries.length-1))
    Component.onCompleted: session.configure(console,"console")
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
        if(activeWindow){runningId=activeWindow.id;wasFullscreen=activeWindow.fullscreen;session.windowAction(runningId,"focus");session.windowAction(runningId,"fullscreen-on");visible=false;return}
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
    Connections { target: controller; function onAction(name) { console.navigate(name) } }
    Timer {
        interval: 300; running: console.modeActive && !console.visible; repeat: true
        onTriggered: {
            if(console.pendingId) {
                const found=session.windows.find(w=>w.appId===console.pendingId);
                if(found){console.runningId=found.id;console.wasFullscreen=found.fullscreen;console.pendingId="";session.windowAction(found.id,"fullscreen-on");session.windowAction(found.id,"focus")}
                else if(++console.waitTicks>50){console.pendingId="";console.visible=true;console.notice="Launch requested. No matching Wayland window appeared. Use Apps or return to Desktop to inspect it."}
            } else if(console.runningId && !session.windows.some(w=>w.id===console.runningId)) {
                console.runningId="";console.visible=true;
            }
        }
    }
    Timer {
        interval: 200; running: true; repeat: true
        property string previous: ""
        onTriggered: {
            const value=JSON.stringify({visible:console.visible,modeActive:console.modeActive,width:console.width,height:console.height,section:console.section,selection:console.selection,zone:console.zone,details:console.details,count:console.entries.length,selected:console.selected?console.selected.appId:"",filter:console.filterIndex,pending:console.pendingId,running:console.runningId});
            if(value!==previous){previous=value;session.consoleState(value)}
        }
    }
    component Copy: Text { color: console.cream; font.family: "Sans Serif"; font.pixelSize: 15; elide: Text.ElideRight }
    component KeyButton: Button {
        id: keyButton
        property bool selected: false
        focusPolicy: Qt.StrongFocus
        Accessible.name: text
        contentItem: Copy { text: keyButton.text; color: keyButton.selected || keyButton.activeFocus ? "#151b21" : console.cream; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { radius: 10; color: keyButton.selected || keyButton.activeFocus ? console.accent : keyButton.hovered ? "#35404a" : "#222d36"; border.color: "#45515b"; border.width: keyButton.activeFocus?2:1; Behavior on color { ColorAnimation { duration: console.reducedMotion?0:120 } } }
    }
    Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: "#222d36" } GradientStop { position: 0.65; color: "#11171d" } GradientStop { position: 1; color: "#171e26" } } }
    // Calm, original landscape asset; no purchased or scraped game art.
    Image { anchors.fill: parent; source: "qrc:/brand/wallpapers/quiet-ridge.svg"; fillMode: Image.PreserveAspectCrop; opacity: 0.12 }
    FocusScope {
        id: navigation; anchors.fill: parent; focus: true
        Keys.onPressed: function(event) {
            if(event.key===Qt.Key_Escape){console.navigate("back");event.accepted=true}
            else if(event.key===Qt.Key_Left){console.navigate("left");event.accepted=true}
            else if(event.key===Qt.Key_Right){console.navigate("right");event.accepted=true}
            else if(event.key===Qt.Key_Up){console.navigate("up");event.accepted=true}
            else if(event.key===Qt.Key_Down){console.navigate("down");event.accepted=true}
            else if(event.key===Qt.Key_Return || event.key===Qt.Key_Enter){console.navigate("accept");event.accepted=true}
            else if(event.key===Qt.Key_F && (event.modifiers & Qt.ControlModifier)){search.forceActiveFocus();event.accepted=true}
            else if(event.key===Qt.Key_F){console.favorite();event.accepted=true}
            else if(event.key===Qt.Key_M && console.selectedGame){manage.visible=true;coverPath.forceActiveFocus();event.accepted=true}
            else if(event.key===Qt.Key_Tab){console.zone=(console.zone+1)%3;event.accepted=true}
            else if(event.key===Qt.Key_PageDown || event.key===Qt.Key_PageUp){console.chooseSection((console.section+(event.key===Qt.Key_PageDown?1:6))%7);console.zone=1;event.accepted=true}
            else if(event.key===Qt.Key_R && console.section===1){console.filterIndex=(console.filterIndex+1)%4;console.selection=0;event.accepted=true}
        }
        ColumnLayout {
            anchors.fill: parent; anchors.leftMargin: 52; anchors.rightMargin: 52; anchors.topMargin: 28; anchors.bottomMargin: 22; spacing: 22
            RowLayout {
                Layout.fillWidth: true; spacing: 12
                Image { source: "qrc:/brand/tamber-llama.svg"; Layout.preferredWidth: 24; Layout.preferredHeight: 32; fillMode: Image.PreserveAspectFit }
                Copy { text: "TAMBER / PLAY"; font.pixelSize: 14; font.letterSpacing: 3; font.weight: Font.DemiBold }
                Item { Layout.fillWidth: true }
                Copy { text: "GAME MODE"; color: console.muted; font.pixelSize: 11; font.letterSpacing: 2 }
                KeyButton { text: "Return to Desktop"; onClicked: console.leave(); Layout.preferredHeight: 36; Layout.preferredWidth: 168 }
            }
            RowLayout {
                spacing: 8
                Repeater {
                    model: console.sections
                    KeyButton { required property string modelData; required property int index; text: modelData; selected: console.section===index; Layout.preferredWidth: modelData==="Emulators"?120:100; Layout.preferredHeight: 42; opacity: console.zone===0 || console.section===index ? 1 : 0.72; onClicked: {console.chooseSection(index);console.zone=1;navigation.forceActiveFocus()} }
                }
                Item { Layout.fillWidth: true }
            }
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent; spacing: 16; visible: console.section!==6
                    RowLayout {
                        Copy { text: console.section===0 ? "Ready when you are." : console.sections[console.section]; font.pixelSize: 32; font.weight: Font.DemiBold; Layout.fillWidth: true }
                        KeyButton { visible: console.section===1; text: console.filters[console.filterIndex]+"  · R"; Layout.preferredWidth: 160; onClicked: {console.filterIndex=(console.filterIndex+1)%4;console.selection=0} }
                        TextField {
                            id: search; Layout.preferredWidth: 240; Layout.preferredHeight: 40; color: console.cream; placeholderTextColor: console.muted; placeholderText: "Search  ·  Ctrl F"; text: console.query; onTextEdited: {console.query=text;console.selection=0}
                            background: Rectangle { color: "#202a33"; radius: 10; border.color: search.activeFocus?console.accent:"#3b4751" }
                            onAccepted: {navigation.forceActiveFocus();console.zone=1}
                            Keys.onEscapePressed: {console.query="";text="";navigation.forceActiveFocus()}
                            Keys.onDownPressed: {navigation.forceActiveFocus();console.zone=1}
                        }
                    }
                    // Horizontal focus rail remains spatially stable across game/app categories.
                    ListView {
                        id: cards; Layout.fillWidth: true; Layout.preferredHeight: 192; orientation: ListView.Horizontal; spacing: 16; clip: true; model: console.entries; currentIndex: console.selection
                        highlightMoveDuration: console.reducedMotion?0:180
                        delegate: Item {
                            required property var modelData; required property int index
                            width: 160; height: 188
                            Rectangle {
                                anchors.fill: parent; anchors.margins: 4; radius: 16; color: console.selection===index?"#35414b":"#222d36"; border.width: console.selection===index?2:1; border.color: console.selection===index?console.accent:"#3b4751"
                                scale: console.selection===index?1:0.95
                                Behavior on scale { NumberAnimation { duration: console.reducedMotion?0:160; easing.type: Easing.OutCubic } }
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 12; spacing: 8
                                    Image { source: modelData.art || (modelData.platform==="RetroArch" ? "qrc:/brand/application.svg" : "image://apps/"+modelData.appId); fillMode: Image.PreserveAspectFit; Layout.fillWidth: true; Layout.fillHeight: true; sourceSize.width: 256; sourceSize.height: 256 }
                                    Copy { text: (modelData.favorite?"★  ":"")+modelData.name; Layout.fillWidth: true; font.pixelSize: 14; font.weight: Font.DemiBold }
                                }
                            }
                            MouseArea { anchors.fill: parent; onClicked: {console.selection=index;console.zone=1;navigation.forceActiveFocus()} onDoubleClicked: console.launchSelected() }
                        }
                        Copy { anchors.centerIn: parent; visible: cards.count===0; width: parent.width; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; text: console.query ? "Nothing matches this search." : console.section===4 ? "Add an emulator profile from Library management." : "Nothing here yet. Your installed applications and saved library appear here."; color: console.muted }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.fillHeight: true; radius: 18; color: "#d71b252e"; border.color: "#35414b"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 24; spacing: 24
                            Image { visible: !!console.selected; source: console.selected ? console.selected.art || (console.selected.platform==="RetroArch"?"qrc:/brand/application.svg":"image://apps/"+console.selected.appId) : ""; fillMode: Image.PreserveAspectFit; Layout.preferredWidth: 140; Layout.fillHeight: true; sourceSize.width: 320; sourceSize.height: 320 }
                            ColumnLayout {
                                spacing: 8; Layout.fillWidth: true
                                Copy { text: console.selected ? (console.selected.platform || "APPLICATION")+ (console.selected.collection?"  /  "+console.selected.collection:"") : "YOUR LIBRARY"; color: console.accent; font.pixelSize: 11; font.letterSpacing: 2; Layout.fillWidth: true }
                                Copy { text: console.selected ? console.selected.name : "Make it yours."; font.pixelSize: 30; font.weight: Font.DemiBold; Layout.fillWidth: true }
                                Copy { text: console.details && console.selected ? console.selected.appId : console.selected && console.selected.lastPlayed ? "Last launched "+Qt.formatDateTime(new Date(console.selected.lastPlayed),"d MMM · HH:mm") : "Installed locally. Ready to launch."; color: console.muted; Layout.fillWidth: true; font.pixelSize: 13 }
                                RowLayout {
                                    spacing: 10
                                    Repeater {
                                        model: console.selectedGame ? [console.activeWindow?"Resume":"Play",console.selected && console.selected.favorite?"Saved":"Favorite","Manage",console.details?"Less":"Details"] : [console.activeWindow?"Resume":"Open"]
                                        KeyButton { required property string modelData; required property int index; text: modelData; enabled: !!console.selected; selected: console.zone===2 && console.actionIndex===index; Layout.preferredWidth: 110; Layout.preferredHeight: 40; onClicked: {console.actionIndex=index;console.act()} }
                                    }
                                }
                            }
                        }
                    }
                }
                ColumnLayout {
                    anchors.fill: parent; visible: console.section===6; spacing: 18
                    Copy { text: "Your system. Your space."; font.pixelSize: 32; font.weight: Font.DemiBold }
                    GridLayout {
                        columns: 4; rowSpacing: 14; columnSpacing: 14; Layout.fillWidth: true; Layout.fillHeight: true
                        Repeater {
                            model: ["Game Mode", "Network", "Audio", "Controllers", "Storage", "Display", "Power & exit", "System info"]
                            Rectangle {
                                required property string modelData; required property int index
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 16; color: console.selection===index?"#303d48":"#202b34"; border.color: console.selection===index?console.accent:"#3a4650"; border.width: console.selection===index?2:1
                                ColumnLayout {
                                    anchors.fill: parent; anchors.margins: 20; spacing: 12
                                    Copy { text: modelData; font.pixelSize: 18; Layout.fillWidth: true }
                                    Text { color: console.muted; font.pixelSize: 13; wrapMode: Text.Wrap; Layout.fillWidth: true; Layout.fillHeight: true; text: [console.reducedMotion?"Reduced motion enabled":"Smooth transitions enabled",session.network,session.audio,controller.status,Number(console.info.storageAvailableGiB || 0).toFixed(1)+" GiB available in home storage",console.width+" × "+console.height+" · compositor output","Return safely to desktop. Shutdown / reboot integration pending.",(console.info.os || "")+"\n"+(console.info.architecture || "")][index] }
                                    Copy { text: ["Enter · Toggle motion","Enter · Status","Enter · Mute / unmute","Mapping support pending","Enter · Refresh","Enter · Details","Enter · Exit Game Mode","Enter · Details"][index]; color: console.accent; font.pixelSize: 11; Layout.fillWidth: true }
                                }
                                MouseArea { anchors.fill: parent; onClicked: {console.selection=index;console.systemAction();navigation.forceActiveFocus()} }
                            }
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Copy { text: console.notice || "← →  Select    ↑ ↓  Move focus    Enter  Confirm    Esc  Back    PgUp / PgDn  Sections"; color: console.muted; font.pixelSize: 12; Layout.fillWidth: true }
                Copy { text: console.zone===0?"NAVIGATION":console.zone===2?"ACTIONS":"BROWSE"; color: console.accent; font.pixelSize: 10; font.letterSpacing: 2 }
            }
        }
    }
    Rectangle {
        id: manage; anchors.fill: parent; visible: false; color: "#f211171d"; onVisibleChanged: {controller.active=console.visible&&!visible;if(!visible)navigation.forceActiveFocus()}
        Keys.onEscapePressed: visible=false
        Rectangle {
            width: Math.min(720,parent.width-80); height: 430; anchors.centerIn: parent; color: "#222d36"; radius: 20; border.color: "#52606b"
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 32; spacing: 16
                Copy { text: "Make it your library."; font.pixelSize: 28 }
                Copy { text: console.selected ? console.selected.name : "No selection"; color: console.muted }
                TextField { id: coverPath; Layout.fillWidth: true; placeholderText: "Absolute path to a local cover image" }
                KeyButton { text: "Import artwork"; enabled: console.selectedGame; onClicked: console.notice=gameLibrary.artwork(console.selected.appId,coverPath.text)?"Artwork imported":gameLibrary.status }
                RowLayout {
                    TextField { id: collectionName; Layout.fillWidth: true; placeholderText: "Collection name (blank removes membership)"; maximumLength: 48 }
                    KeyButton { text: "Save collection"; enabled: console.selectedGame; onClicked: gameLibrary.collection(console.selected.appId,collectionName.text) }
                }
                Copy { text: console.notice; color: console.accent; Layout.fillWidth: true }
                Item { Layout.fillHeight: true }
                RowLayout {
                    KeyButton { text: "Advanced library"; onClicked: {manage.visible=false;console.advancedLibraryRequested()} }
                    Item { Layout.fillWidth: true }
                    KeyButton { text: "Done"; onClicked: manage.visible=false }
                }
            }
        }
    }
}
