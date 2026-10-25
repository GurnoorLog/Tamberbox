import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
Rectangle {
 id: root; width: 1280; height: 720; color: "#17181c"
 property bool preview: typeof sddm === "undefined"
 property string message: preview ? "Design preview · authentication disabled" : ""
 Image { anchors.fill: parent; source: "wallpaper.svg"; fillMode: Image.PreserveAspectCrop }
 Rectangle { anchors.fill: parent; color: "#8814171d" }
 ColumnLayout {
  anchors.centerIn: parent; width: 320; spacing: 18
  Image { source: "mascot.svg"; Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 96; Layout.preferredHeight: 118; fillMode: Image.PreserveAspectFit }
  Label { text: "Welcome back."; color: "#f1ece2"; font.pixelSize: 30; Layout.alignment: Qt.AlignHCenter }
  TextField {
   id: username; Layout.fillWidth: true; Layout.preferredHeight: 44; font.pixelSize: 16; placeholderText: "Username"; placeholderTextColor: "#b8aaa2"; Accessible.name: "Username"; color: "#f1ece2"; KeyNavigation.tab: password
   background: Rectangle { radius: 12; color: "#e529292e"; border.color: username.activeFocus?"#ee9466":"#665852" }
  }
  TextField {
   id: password; Layout.fillWidth: true; Layout.preferredHeight: 44; font.pixelSize: 16; placeholderText: "Password"; placeholderTextColor: "#b8aaa2"; Accessible.name: "Password"; echoMode: TextInput.Password; color: "#f1ece2"; onAccepted: login.clicked()
   background: Rectangle { radius: 12; color: "#e529292e"; border.color: password.activeFocus?"#ee9466":"#665852" }
  }
  ComboBox { id: sessions; Layout.fillWidth: true; Layout.preferredHeight: 42; palette.button: "#353238"; palette.buttonText: "#f1ece2"; model: root.preview ? ["TamberOS preview"] : sessionModel; textRole: root.preview ? "" : "name"; currentIndex: root.preview ? 0 : sessionModel.lastIndex; Accessible.name: "Desktop session" }
  Button {
   id: login; text: "Sign in"; Layout.fillWidth: true; Layout.preferredHeight: 44
   onClicked: { if(root.preview)root.message="Preview only — no credentials are submitted"; else { root.message="Signing in…"; sddm.login(username.text,password.text,sessions.currentIndex) } }
   contentItem: Text { text: login.text; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; color: "#211b17"; font.pixelSize: 16 }
   background: Rectangle { radius: 12; color: login.down?"#d78055":"#ee9466" }
  }
  Label { text: root.message; color: "#e0c5b3"; wrapMode: Text.Wrap; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12 }
 }
 Label { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 25; text: "T A M B E R O S"; color: "#bfb1a5"; font.pixelSize: 12 }
 Connections { target: root.preview ? null : sddm; function onLoginFailed() { root.message="Sign-in failed. Check your details."; password.text=""; password.forceActiveFocus() } }
}
