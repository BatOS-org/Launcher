import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    visibility: Window.FullScreen
    title: qsTr("Launcher")

    color: "#111111"

    // Number of images from Python model
    readonly property int itemCount: imageModel.count

    // Currently selected index (0 .. itemCount-1)
    property int currentIndex: 0

    // Base size of the images (square)
    readonly property real baseSize: 500
    // Additional size increase for the active image (only slight)
    readonly property real activeExtra: 80
    // Spacing between images
    readonly property real spacing: 24

    // Keyboard navigation
    Shortcut {
        sequence: "Left"
        onActivated: {
            if (currentIndex > 0)
                currentIndex--
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: {
            if (currentIndex < itemCount - 1)
                currentIndex++
        }
    }

    Shortcut {
        sequences: ["Return", "Enter"]
        context: Qt.ApplicationShortcut
        onActivated: {
            imageModel.execApp(currentIndex)
        }
    }

    // Visible area (clipped)
    Item {
        id: viewport
        anchors.centerIn: parent
        width: window.width
        height: baseSize + activeExtra + spacing * 2
        clip: true

        // Movable row containing all items
        Row {
            id: row
            anchors.verticalCenter: parent.verticalCenter
            spacing: window.spacing

            // Important: ensure Row doesn't shrink/expand vertically based on children
            height: baseSize + activeExtra

            // Animation for horizontal movement
            Behavior on x {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            // Array to store references to delegate items
            property var itemRefs: []

            Repeater {
                id: repeater
                model: window.itemCount

                delegate: Item {
                    id: itemRoot
                    // Fixed size for the delegate item itself
                    width: window.baseSize + window.activeExtra + window.spacing
                    height: window.baseSize + window.activeExtra

                    Component.onCompleted: {
                        // Store reference to this item
                        row.itemRefs[index] = itemRoot
                    }

                    // Image + mask as a group
                    Item {
                        id: contentItem
                        anchors.centerIn: parent

                        // Size depends on whether this image is selected
                        // Always square: width == height
                        width: index === window.currentIndex
                               ? window.baseSize + window.activeExtra
                               : window.baseSize
                        height: width  // This ensures it stays square

                        Behavior on width {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        // The actual image (loaded from Python dict)
                        Image {
                            id: sourceItem
                            anchors.fill: parent
                            source: imageModel.getIcon(index)
                            visible: false
                        }

                        // MultiEffect with mask
                        MultiEffect {
                            source: sourceItem
                            anchors.fill: parent
                            maskEnabled: true
                            maskSource: mask

                            brightness: index === window.currentIndex ? 0.05 : -0.15
                            saturation: index === window.currentIndex ? 1.05 : 0.85

                            Behavior on brightness {
                                NumberAnimation { duration: 180 }
                            }
                            Behavior on saturation {
                                NumberAnimation { duration: 180 }
                            }
                        }

                        // Mask for rounded corners
                        Item {
                            id: mask
                            width: parent.width
                            height: parent.height
                            layer.enabled: true
                            visible: false

                            Rectangle {
                                width: parent.width
                                height: parent.height
                                radius: 40
                                color: "black"
                            }
                        }

                        // Optional: thin border around the active image
                        Rectangle {
                            anchors.fill: parent
                            radius: 40
                            color: "transparent"
                            border.color: index === window.currentIndex ? "#4fd1ff" : "transparent"
                            border.width: index === window.currentIndex ? 3 : 0

                            Behavior on border.width {
                                NumberAnimation { duration: 180 }
                            }
                            Behavior on border.color {
                                ColorAnimation { duration: 180 }
                            }
                        }
                    }

                    // Make non-selected images slightly more transparent
                    opacity: index === window.currentIndex ? 1.0 : 0.55
                    Behavior on opacity {
                        NumberAnimation { duration: 180 }
                    }

                    // Optional: Show name and description below the image
                    Column {
                        anchors.top: itemRoot.bottom
                        anchors.horizontalCenter: itemRoot.horizontalCenter
                        width: itemRoot.width
                        spacing: 4

                        Text {
                            text: imageModel.getName(index)
                            color: index === window.currentIndex ? "#ffffff" : "#aaaaaa"
                            font.pixelSize: 16
                            font.bold: index === window.currentIndex
                            anchors.horizontalCenter: parent.horizontalCenter
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            text: imageModel.getDescription(index)
                            color: index === window.currentIndex ? "#cccccc" : "#888888"
                            font.pixelSize: 12
                            anchors.horizontalCenter: parent.horizontalCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            width: parent.width * 0.8
                        }
                    }
                }
            }
        }
    }

    // Centering logic: set row.x so that the active item
    // is exactly in the middle of the viewport.
    function updateRowOffset() {
        if (currentIndex < 0 || currentIndex >= repeater.count)
            return

        var activeItem = row.itemRefs[currentIndex]
        if (!activeItem) {
            // Fallback if reference is not yet available
            return
        }

        // Position of the active item relative to the row
        var activeItemX = activeItem.x
        var activeItemWidth = activeItem.width

        // Center of the active item within the row:
        var activeItemCenterX = activeItemX + activeItemWidth / 2

        // We want: viewport.width/2 = activeItemCenterX + row.x
        // => row.x = viewport.width/2 - activeItemCenterX
        var targetX = (viewport.width / 2) - activeItemCenterX

        row.x = targetX
    }

    // Re-center when window width or currentIndex changes
    Connections {
        target: window
        function onWidthChanged() { updateRowOffset() }
        function onCurrentIndexChanged() { updateRowOffset() }
    }

    // Additionally, trigger an update after size changes of items
    Timer {
        id: relayoutTimer
        interval: 0
        running: false
        repeat: false
        onTriggered: updateRowOffset()
    }

    // Each time currentIndex changes, trigger another update after the
    // width animation (approx. 180ms) to correct any rounding errors.
    onCurrentIndexChanged: {
        // Re-adjust after the width animation (about 180ms)
        relayoutTimer.interval = 200
        relayoutTimer.start()
    }

    // Initial centering on startup (slightly delayed so layout is ready)
    Component.onCompleted: {
        updateRowOffsetTimer.start()
    }

    Timer {
        id: updateRowOffsetTimer
        interval: 40
        running: false
        repeat: false
        onTriggered: updateRowOffset()
    }
}