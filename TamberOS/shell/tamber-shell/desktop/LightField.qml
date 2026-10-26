import QtQuick

// Original procedural light ribbons, rendered on both software and accelerated Qt Quick.
Canvas {
    id: field
    property bool animate: false
    property real strength: 0.55
    property real phase: 0
    renderTarget: Canvas.Image
    onStrengthChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Component.onCompleted: requestPaint()
    Timer { interval: 66; running: field.animate && field.strength>0; repeat: true; onTriggered: {field.phase+=0.006;field.requestPaint()} }
    onPaint: {
        const ctx=getContext("2d");ctx.clearRect(0,0,width,height);
        if(strength<=0)return;
        const positions=[0.10,0.32,0.57,0.78,0.96];
        for(let i=0;i<positions.length;i++) {
            const x=width*positions[i];
            const bend=Math.sin(phase+i*1.7)*width*0.08;
            for(let halo=5;halo>=0;halo--) {
                ctx.beginPath();ctx.moveTo(x-width*0.10,-40);
                ctx.bezierCurveTo(x+width*0.12+bend,height*0.25,x-width*0.14-bend,height*0.65,x+width*0.04,height+40);
                ctx.lineWidth=halo===0?1.2:halo*5;
                ctx.strokeStyle=halo===0?"rgba(255,202,153,"+(strength*0.72)+")":"rgba(221,112,48,"+(strength*0.025)+")";
                ctx.stroke();
            }
        }
    }
}
