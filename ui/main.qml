import QtQuick 6.4
import QtQuick.Controls 6.4
import QtQuick.Layouts 6.4
import QtQuick.Shapes 6.4
import QtMultimedia 6.4

ApplicationWindow {
    width: 800
    height: 600
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint
    title: "QML File Manager"

    property bool hiddenFilesVisible: false
    property int selectedIndex: -1

    // Add aspect ratio for width / height
    property real fileItemAspectRatio: 0.8  // width = height * 0.8 (adjust as you want)

    // Minimum size
    property int minFileItemHeight: 200
    property int minFileItemWidth: 160

    // Dynamically calculated height based on window height (e.g. 40% of window height)
    property int fileItemHeight: Math.max(minFileItemHeight, height * 0.4)
    // Width based on height and aspect ratio with min width
    property int fileItemWidth: Math.max(minFileItemWidth, fileItemHeight * fileItemAspectRatio)


    property var iconMap: ({
        "png": "assets/icons/image.png",
        "jpg": "assets/icons/image.png",
        "jpeg": "assets/icons/image.png",
        "gif": "assets/icons/image.png",
        "bmp": "assets/icons/image.png",
        "svg": "assets/icons/image.png",

        "pdf": "assets/icons/pdf.png",
        "doc": "assets/icons/doc.png",
        "docx": "assets/icons/doc.png",
        "xls": "assets/icons/xls.png",
        "xlsx": "assets/icons/xls.png",
        "ppt": "assets/icons/ppt.png",
        "pptx": "assets/icons/ppt.png",
        "txt": "assets/icons/txt.png",
        "md": "assets/icons/txt.png",

        "mp3": "assets/icons/audio.png",
        "wav": "assets/icons/audio.png",
        "ogg": "assets/icons/audio.png",
        "flac": "assets/icons/audio.png",

        "mp4": "assets/icons/video.png",
        "avi": "assets/icons/video.png",
        "mkv": "assets/icons/video.png",
        "mov": "assets/icons/video.png",

        "zip": "assets/icons/archive.png",
        "rar": "assets/icons/archive.png",
        "7z": "assets/icons/archive.png",
        "tar": "assets/icons/archive.png",
        "gz": "assets/icons/archive.png",
        "xz": "assets/icons/archive.png",

        "js": "assets/icons/code.png",
        "qml": "assets/icons/code.png",
        "html": "assets/icons/html.png",
        "css": "assets/icons/css.png",
        "cpp": "assets/icons/cpp.png",
        "c": "assets/icons/code.png",
        "h": "assets/icons/code.png",
        "py": "assets/icons/python.png",
        "json": "assets/icons/json.png"
    })

    function getIconByExtension(ext) {
        ext = ext.toLowerCase()
        return iconMap[ext] ? iconMap[ext] : "assets/icons/file.png"
    }

    Item {
        id: topBarWrapper
        width: parent.width
        height: 60
        z: 99

        property bool buttonsVisible: false

        Timer {
            id: hideTimer
            interval: 5000
            repeat: false
            onTriggered: topBarWrapper.buttonsVisible = false
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                topBarWrapper.buttonsVisible = true
                hideTimer.restart()
            }
        }

        Row {
            id: drivebuttons
            spacing: 10
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10
            visible: topBarWrapper.buttonsVisible
            z: 99

            Rectangle {
                width: 50
                height: 50
                radius: 12
                color: Qt.rgba(0.102, 0.102, 0.184, 0.3)
                border.color: Qt.rgba(0.102, 0.102, 0.184, 0.8)
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: fileModel.openPath("/home/bharat/") // Home folder
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Image {
                        source: "assets/icons/harddisk.png"
                        width: 32
                        height: 32
                    }

                    Text {
                        text: "Home"
                        font.pixelSize: 9
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }

            Rectangle {
                width: 50
                height: 50
                radius: 12
                color: Qt.rgba(0.102, 0.102, 0.184, 0.3)
                border.color: Qt.rgba(0.102, 0.102, 0.184, 0.8)
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: fileModel.openPath("/run/media/bharat/") // Drives folder
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Image {
                        source: "assets/icons/drive2.png"
                        width: 32
                        height: 32
                    }

                    Text {
                        text: "Drives"
                        font.pixelSize: 9
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }

    // Consolidate keyboard handling into Flickable for clarity
    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: rowItem.width
        interactive: true
        clip: true
        focus: true  // Ensure it can receive keyboard input
        Keys.priority: Keys.BeforeItem  // Make sure it processes first
        Keys.enabled: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Home) {
                selectedIndex = 0
                scrollAnim.stop()
                scrollAnim.to = 0
                scrollAnim.start()
                console.log("Home pressed, scroll to start")
                event.accepted = true
            } else if (event.key === Qt.Key_End) {
                selectedIndex = fileModel.files.length - 1
                scrollAnim.stop()
                scrollAnim.to = contentWidth - width
                scrollAnim.start()
                console.log("End pressed, scroll to end")
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                fileModel.openItem(0)  // index 0 is ".." (parent dir)
                event.accepted = true
            } else if (event.key === Qt.Key_H && (event.modifiers & Qt.ControlModifier)) {
                hiddenFilesVisible = !hiddenFilesVisible
                fileModel.setShowHidden(hiddenFilesVisible)
                console.log("Ctrl+H toggled. Hidden files visible:", hiddenFilesVisible)
                event.accepted = true
            } else if (event.key === Qt.Key_Left) {
                if (selectedIndex > 0) {
                    selectedIndex -= 1
                    scrollToSelected()
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Right) {
                if (selectedIndex < fileModel.files.length - 1) {
                    selectedIndex += 1
                    scrollToSelected()
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
                if (selectedIndex >= 0 && selectedIndex < fileModel.files.length) {
                    fileModel.openItem(selectedIndex)
                }
                event.accepted = true
            }

        }


        //make scroll horizontal with vertical wheel
        WheelHandler {
            id: wheelHandler
            target: flick
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            orientation: Qt.Vertical

            onWheel: (event) => {
                var delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y * 1.17;
                scrollAnim.stop();
                scrollAnim.to = flick.contentX - delta;
                scrollAnim.start();
                event.accepted = true;
            }
        }

        PropertyAnimation {
            id: scrollAnim
            target: flick
            property: "contentX"
            duration: 150
            easing.type: Easing.OutQuad
        }

        Item {
            id: container
            width: rowItem.width
            height: flick.height

            transform: Translate {
                y: -flick.contentX * 0.089
            }

            Row {
                id: rowItem
                property real itemWidth: Math.max(ApplicationWindow.window.height * 0.3, 180)
                spacing: -itemWidth * 0.3  // 30% overlap; tweak as needed
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: fileModel.files.length


                    delegate: Item {
                        width: fileItemWidth
                        height: fileItemHeight
                        y: index * height * 0.05

                        property string filePath: fileModel.filePathAt(index)
                        property string fileName: fileModel.files[index]
                        property bool isFolder: fileModel.isDir(index)
                        property string thumbnailSource: ""
                        property bool loaded: false

                        property bool isSelected: index === selectedIndex


                        // Center X of card relative to flickable content
                        property real cardCenterX: x + width / 2


                        Timer {
                            interval: 50
                            repeat: false
                            running: true
                            onTriggered: {
                                if (!loaded && fileItem.visible && fileModel.files.length > 0) {
                                    let result = fileManager.generate_thumbnail(filePath);
                                    if (result !== "") {
                                        thumbnailSource = "file://" + result;
                                        loaded = true;
                                    }
                                }
                            }
                        }

                        Shape {

                            property bool active: hovered ? true : (index === selectedIndex)



                            id: fileItem
                            width: parent.width
                            height: parent.height
                            y: active ? -parent.height * 0.25 : 0

                            z: active ? 1000 : index

                            opacity: {
                                var leftEdge = flick.contentX
                                var rightEdge = flick.contentX + flick.width
                                var fadeWidth = 100

                                if (cardCenterX < leftEdge + fadeWidth)
                                    return Math.max(0, (cardCenterX - leftEdge) / fadeWidth)
                                    else if (cardCenterX > rightEdge - fadeWidth)
                                        return Math.max(0, (rightEdge - cardCenterX) / fadeWidth)
                                        else
                                            return 1
                            }

                            property bool hovered: false
                            property real hoverLift: -ApplicationWindow.window.height * 0.25


                            layer.enabled: true
                            layer.smooth: true

                            states: [
                                State {
                                    name: "active"
                                    when: fileItem.active
                                    PropertyChanges { target: fileItem; y: hoverLift }
                                },
                                State {
                                    name: "inactive"
                                    when: !fileItem.active
                                    PropertyChanges { target: fileItem; y: 0 }
                                }
                            ]


                            transitions: [
                                Transition {
                                    from: "*"
                                    to: "*"
                                    NumberAnimation {
                                        properties: "y"
                                        duration: 250
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            ]


                            ShapePath {
                                strokeColor: (fileItem.hovered || isSelected) ? "#ffaa33" : "#33aaff"
                                strokeWidth: (fileItem.hovered || isSelected) ? 6 : 4
                                fillColor: (fileItem.hovered || isSelected) ? "#aacc55cc" : Qt.rgba(0.102, 0.102, 0.184, 0.8)

                                startX: 0
                                startY: 0

                                PathLine { x: width * 0.85; y: 0 }           // was 170 of 200 width = 0.85
                                PathLine { x: width; y: height * 0.12 }      // was 200,30 and 30/250 = 0.12
                                PathLine { x: width; y: height }             // was 200,250
                                PathLine { x: 0; y: height }                  // was 0,250
                                PathLine { x: 0; y: 0 }
                            }


                            Text {
                                anchors.top: parent.top
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.topMargin: 10
                                text: fileName
                                font.pixelSize: 14
                                color: "white"
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width - 20
                                z: 10
                            }

                            Rectangle {
                                width: parent.width * 0.9
                                height: parent.height * 0.8
                                anchors.top: parent.top
                                anchors.topMargin: 40
                                color: "transparent"  // Optional: helps debug layout

                                Image {
                                    id: fileImage
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectFit
                                    visible: !isFolder
                                    cache: true

                                    source: {
                                        if (thumbnailSource !== "") {
                                            return thumbnailSource
                                        } else {
                                            var ext = fileName.indexOf('.') !== -1 ? fileName.split('.').pop().toLowerCase() : ""
                                            return getIconByExtension(ext)
                                        }
                                    }
                                }
                            }


                            Image {
                                id: folderIcon
                                source: "assets/icons/folder.png"
                                width: parent.width * 0.75
                                height: parent.height * 0.75
                                anchors.centerIn: parent
                                anchors.margins: 10
                                visible: isFolder
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.RightButton | Qt.LeftButton

                                onEntered: {
                                    fileItem.hovered = true
                                    selectedIndex = index
                                }
                                onExited: fileItem.hovered = false

                                onClicked: function(mouse) {
                                    selectedIndex = index;   // select the clicked item

                                    if (mouse.button === Qt.LeftButton) {
                                        fileModel.openItem(index)
                                    } else if (mouse.button === Qt.RightButton) {
                                        contextMenu.itemIndex = index
                                        contextMenu.popup()
                                    }
                                }

                            }

                            transform: Rotation {
                                origin.x: width / 2
                                origin.y: height / 2
                                axis { x: 0; y: 1; z: 0 }
                                angle: (x - flick.contentX - flick.width / 2) / flick.width * 90
                            }
                        }
                    }

                }
            }
        }
    }

    Item {
        anchors.fill: parent
        z: -1

        Rectangle {
            anchors.fill: parent
            radius: 10  // Rounded corners
            color: Qt.rgba(0, 0, 1, 0.2) // semi-transparent dark blueish
        }
    }

    Rectangle {
        width: 30
        height: 30
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        radius: 4
        color: Qt.rgba(0, 0, 1, 0.08)
        z: 100

        Text {
            anchors.centerIn: parent
            text: "✕"
            font.pixelSize: 18
            color: "#33aaff"  // Optional: customize color
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.quit()
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }


    Dialog {
        id: renameDialog
        title: "Rename File"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        property int renameIndex: -1

        ColumnLayout {
            TextField {
                id: renameField
                placeholderText: "Enter new file name"
                Layout.fillWidth: true
            }
        }

        onAccepted: {
            var newName = renameField.text.trim();
            if (newName.length > 0) {
                // Simple validation for invalid characters (example)
                var invalidChars = /[\/\\:*?"<>|]/;
                if (invalidChars.test(newName)) {
                    console.log("Invalid characters in filename!");
                    // Could show an error message here
                    return;
                }
                fileModel.renameItem(renameIndex, newName);
            }
        }
    }

    Menu {
        id: contextMenu
        property int itemIndex: -1

        MenuItem {
            text: "Rename"
            onTriggered: {
                renameDialog.renameIndex = contextMenu.itemIndex
                renameField.text = fileModel.files[contextMenu.itemIndex] || ""
                renameDialog.open()
            }
        }
        MenuItem {
            text: "Copy"
            onTriggered: fileModel.copyItem(contextMenu.itemIndex)
        }
        MenuItem {
            text: "Cut"
            onTriggered: fileModel.cutItem(contextMenu.itemIndex)
        }
        MenuItem {
            text: "Paste"
            onTriggered: fileModel.pasteItem()
        }
    }

    Connections {
        target: fileManager
        function onThumbnailGenerated(message) {
            console.log("Thumbnail generated:", message)
            // update fileModel or delegate thumbnails here
        }
    }

    function scrollToSelected() {
        if (selectedIndex < 0 || selectedIndex >= rowItem.children.length)
            return;

        var item = rowItem.children[selectedIndex];
        var targetX = item.x + item.width / 2 - flick.width / 2;

        targetX = Math.max(0, Math.min(targetX, flick.contentWidth - flick.width));

        scrollAnim.stop()
        scrollAnim.to = targetX
        scrollAnim.start()
    }


}
