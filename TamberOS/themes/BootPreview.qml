import QtQuick
import QtQuick.Controls
Rectangle {
 width: 1280; height: 720; color: "#111114"
 Column {
  anchors.centerIn: parent; spacing: 24
  Image { source: "sddm/tamber/mascot.svg"; width: 130; height: 165; fillMode: Image.PreserveAspectFit; anchors.horizontalCenter: parent.horizontalCenter }
  Label { text: "TamberOS"; color: "#f1ece2"; font.pixelSize: 32; anchors.horizontalCenter: parent.horizontalCenter }
  Rectangle { width: 200; height: 3; radius: 2; color: "#42352d"; anchors.horizontalCenter: parent.horizontalCenter; Rectangle { width: 80; height: 3; radius: 2; color: "#ee9466" } }
 }
 Label { anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottomMargin: 28; text: "Visual preview · not a recorded device boot"; color: "#a99c91"; font.pixelSize: 12 }
}
