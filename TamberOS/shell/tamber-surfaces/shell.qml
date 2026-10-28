import QtQuick
import Quickshell
import Quickshell.Wayland

// Optional GPU surface. The existing desktop remains responsible for launching
// applications, workspaces and Game Mode. No second top bar is created.
ShellRoot {
    PanelWindow {
        id: panel
        anchors { bottom: true; left: true }
        margins { bottom: 84; left: 16 }
        implicitWidth: 280
        implicitHeight: 112
        exclusiveZone: 0
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            radius: 24
            color: "#181512"
            border.color: "#574334"
            clip: true
            DMABufSurface {
                id: frames
                anchors.fill: parent
                anchors.margins: 12
                socketPath: Quickshell.env("TAMBER_DMABUF_SOCKET")
                fps: 24
                active: panel.visible && Quickshell.env("TAMBER_REDUCED_MOTION") !== "1"
            }
            Text {
                anchors.centerIn: parent
                visible: !frames.ready
                text: "GPU visualiser disconnected"
                color: "#bbae9f"
                font.pixelSize: 12
                font.family: "Inter"
            }
        }
    }
}
