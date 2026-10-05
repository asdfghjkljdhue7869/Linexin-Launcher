import QtQuick

ShaderEffect {
    id: gb
    property Item rootRef: null
    property var washSource: null
    property variant wash: washSource
    property bool glassOn: true
    property real tier: 0
    property bool shown: false
    property color tintSrc: "transparent"
    property real hover: 0
    property real rad: 1.0
    property url shader: Qt.resolvedUrl("glass_pill.frag.qsb")
    property vector4d region: Qt.vector4d(0, 0, 0.1, 0.1)
    property vector4d tintV: Qt.vector4d(tintSrc.r, tintSrc.g, tintSrc.b, tintSrc.a)
    property vector2d pxSize: Qt.vector2d(width, height)
    property Item flick1: null
    property Item flick2: null
    property Item flick3: null
    visible: glassOn && width > 0 && height > 0
    fragmentShader: shader
    Behavior on hover {
        SpringAnimation { spring: 3.5; damping: 0.22; epsilon: 0.005 }
    }
    Behavior on tintSrc {
        ColorAnimation { duration: 180 }
    }
    function updateRegion() {
        if (!rootRef || rootRef.width <= 0 || rootRef.height <= 0 || width <= 0 || height <= 0) return;
        var g = mapToItem(rootRef, 0, 0);
        region = Qt.vector4d(g.x / rootRef.width, g.y / rootRef.height, width / rootRef.width, height / rootRef.height);
    }
    function findFlicks() {
        var found = [];
        var p = parent;
        while (p && found.length < 3) {
            if (p.contentY !== undefined && p.flickableDirection !== undefined) found.push(p);
            p = p.parent;
        }
        flick1 = found.length > 0 ? found[0] : null;
        flick2 = found.length > 1 ? found[1] : null;
        flick3 = found.length > 2 ? found[2] : null;
    }
    function fast() {
        Qt.callLater(updateRegion);
    }
    function schedule() {
        Qt.callLater(updateRegion);
        regionTimer.restart();
    }
    Timer {
        id: regionTimer
        interval: 450
        onTriggered: gb.updateRegion()
    }
    Timer {
        id: slowTick
        interval: 900
        repeat: true
        running: gb.visible && gb.shown
        onTriggered: gb.updateRegion()
    }
    Component.onCompleted: {
        findFlicks();
        schedule();
    }
    onShownChanged: schedule()
    onWidthChanged: schedule()
    onHeightChanged: schedule()
    Connections {
        target: gb.rootRef
        ignoreUnknownSignals: true
        function onWidthChanged() { gb.schedule(); }
        function onHeightChanged() { gb.schedule(); }
    }
    Connections {
        target: gb.parent
        ignoreUnknownSignals: true
        function onXChanged() { gb.schedule(); }
        function onYChanged() { gb.schedule(); }
    }
    Connections {
        target: gb.flick1
        ignoreUnknownSignals: true
        function onContentYChanged() { gb.fast(); }
        function onContentXChanged() { gb.fast(); }
    }
    Connections {
        target: gb.flick2
        ignoreUnknownSignals: true
        function onContentYChanged() { gb.fast(); }
        function onContentXChanged() { gb.fast(); }
    }
    Connections {
        target: gb.flick3
        ignoreUnknownSignals: true
        function onContentYChanged() { gb.fast(); }
        function onContentXChanged() { gb.fast(); }
    }
}
