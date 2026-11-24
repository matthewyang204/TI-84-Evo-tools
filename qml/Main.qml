import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.example.tiscreen

Controls.ApplicationWindow {
    id: root
    width: 760
    height: 640
    minimumWidth: 420
    minimumHeight: 360
    visible: true
    title: qsTr("TI Calculator")

    CaptureBackend { id: backend }

    function openPage(page) {
        pageStack.replace(page)
    }

    function navigate(index) {
        navigationTabs.currentIndex = index
        switch (index) {
        case 0:
            openPage(homePage)
            break
        case 1:
            openPage(screenPage)
            break
        case 2:
            openPage(filesPage)
            break
        case 3:
            openPage(sendPage)
            break
        }
    }

    function localPathFromUrl(value) {
        const url = value.toString()
        if (url.startsWith("file:///")) {
            const path = decodeURIComponent(url.substring(8))
            return Qt.platform.os === "windows" ? path : "/" + path
        }
        if (url.startsWith("file://")) {
            const path = decodeURIComponent(url.substring(7)).replace(/\//g,
                Qt.platform.os === "windows" ? "\\" : "/")
            return Qt.platform.os === "windows" ? "\\\\" + path : "/" + path
        }
        return decodeURIComponent(url)
    }

    header: Controls.ToolBar {
        RowLayout {
            anchors.fill: parent

            Controls.ToolButton {
                text: qsTr("Navigation")
                onClicked: navigationDrawer.open()
            }

            Controls.Label {
                Layout.fillWidth: true
                text: [qsTr("Main Menu"), qsTr("Screen Capture"),
                       qsTr("Device Files"), qsTr("Send Files")][navigationTabs.currentIndex]
                font.bold: true
            }
        }
    }

    Controls.Drawer {
        id: navigationDrawer
        width: Math.min(root.width * 0.8, 320)
        height: root.height
        edge: Qt.LeftEdge

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Controls.Label {
                Layout.fillWidth: true
                text: qsTr("TI Calculator")
                font.pixelSize: 22
                font.bold: true
            }

            Controls.Button {
                Layout.fillWidth: true
                text: qsTr("Main Menu")
                onClicked: {
                    root.navigate(0)
                    navigationDrawer.close()
                }
            }

            Controls.Button {
                Layout.fillWidth: true
                text: qsTr("Screen Capture")
                onClicked: {
                    root.navigate(1)
                    navigationDrawer.close()
                }
            }

            Controls.Button {
                Layout.fillWidth: true
                text: qsTr("Device Files")
                onClicked: {
                    root.navigate(2)
                    navigationDrawer.close()
                }
            }

            Controls.Button {
                Layout.fillWidth: true
                text: qsTr("Send Files")
                onClicked: {
                    root.navigate(3)
                    navigationDrawer.close()
                }
            }
        }
    }

    Controls.StackView {
        id: pageStack
        anchors.fill: parent
        initialItem: homePage
    }

    footer: Controls.TabBar {
        id: navigationTabs
        currentIndex: 0

        Controls.TabButton {
            text: qsTr("Menu")
            icon.name: "go-home"
            onClicked: root.navigate(0)
        }

        Controls.TabButton {
            text: qsTr("Capture")
            icon.name: "camera-photo"
            onClicked: root.navigate(1)
        }

        Controls.TabButton {
            text: qsTr("Files")
            icon.name: "folder"
            onClicked: root.navigate(2)
        }

        Controls.TabButton {
            text: qsTr("Send")
            icon.name: "document-send"
            onClicked: root.navigate(3)
        }
    }

    Component {
        id: homePage

        Controls.Page {
            title: qsTr("Main Menu")

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 32, 448)
                spacing: 16

                Controls.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("TI Calculator Tools")
                    font.pixelSize: 28
                    font.bold: true
                }

                Controls.Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    text: qsTr("Screen Capture")
                    icon.name: "camera-photo"
                    onClicked: root.navigate(1)
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: qsTr("Capture the calculator display and save it as a PNG.")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Controls.Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    text: qsTr("Check Device Files")
                    icon.name: "folder"
                    enabled: !backend.busy
                    onClicked: {
                        root.navigate(2)
                        backend.refreshFiles()
                    }
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: qsTr("Read programs, lists, images, and other variables from the device directory.")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Controls.Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    text: qsTr("Send a File")
                    icon.name: "document-send"
                    enabled: !backend.busy
                    onClicked: root.navigate(3)
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: qsTr("Choose a TI variable file on this computer and transfer it to the calculator.")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }

    Component {
        id: screenPage

        Controls.Page {
            id: capturePage
            title: qsTr("Screen Capture")

            Timer {
                id: autoCaptureTimer
                interval: autoCaptureInterval.value * 10
                running: autoCaptureSwitch.checked && capturePage.visible
                repeat: true
                onTriggered: {
                    if (!backend.busy) {
                        backend.capture(cursorCheck.checked)
                    }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.palette.alternateBase
                    radius: 4

                    Image {
                        anchors.fill: parent
                        anchors.margins: 16
                        source: backend.imageUrl
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        smooth: false
                        visible: source.toString().length > 0
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 64
                        visible: backend.imageUrl.length === 0 && !backend.busy

                        Controls.Label {
                            Layout.fillWidth: true
                            text: qsTr("No capture yet")
                            font.pixelSize: 20
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Controls.Label {
                            Layout.fillWidth: true
                            text: qsTr("Connect a supported TI calculator over USB.")
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    Controls.BusyIndicator {
                        anchors.centerIn: parent
                        running: backend.busy && !autoCaptureSwitch.checked
                        visible: running
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Controls.CheckBox {
                        id: cursorCheck
                        text: qsTr("Include cursor")
                        enabled: !backend.busy
                    }

                    Item { Layout.fillWidth: true }

                    Controls.Button {
                        text: qsTr("Capture Screen")
                        icon.name: "camera-photo"
                        enabled: !backend.busy
                        onClicked: backend.capture(cursorCheck.checked)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Controls.Switch {
                        id: autoCaptureSwitch
                        text: qsTr("Auto capture")
                    }

                    Item { Layout.fillWidth: true }

                    Controls.Label {
                        text: qsTr("Interval:")
                    }

                    Controls.SpinBox {
                        id: autoCaptureInterval
                        from: 1
                        to: 30000
                        value: 500
                        stepSize: 25
                        editable: true
                        enabled: autoCaptureSwitch.checked
                        Accessible.name: qsTr("Auto-capture interval in seconds")

                        textFromValue: function(value, locale) {
                            return Number(value / 100).toLocaleString(locale, "f", 2)
                        }

                        valueFromText: function(text, locale) {
                            return Math.round(Number.fromLocaleString(locale, text) * 100)
                        }
                    }

                    Controls.Label {
                        text: qsTr("seconds")
                    }
                }

                Controls.Label {
                    Layout.fillWidth: true
                    visible: autoCaptureSwitch.checked
                    text: qsTr("Very fast capture intervals, especially below 0.25 seconds, may cause connection issues or make the calculator temporarily unresponsive.")
                    wrapMode: Text.WordWrap
                }

                Controls.Label {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: backend.status
                    wrapMode: Text.WordWrap
                    color: backend.status.indexOf("failed") >= 0
                        ? "#b00020"
                        : root.palette.text
                }
            }
        }
    }

    Component {
        id: filesPage

        Controls.Page {
            id: deviceFilesPage
            title: qsTr("Device Files")
            property var deviceFiles: []
            property var selectedWireNames: []
            property bool refreshPending: false
            property var pendingGetFile: null
            property var pendingGetFiles: []
            property int pendingGetIndex: 0
            property var clipboardTypes: [
                { label: qsTr("Python source (15)"), value: 15 },
                { label: qsTr("Program (2)"), value: 2 },
                { label: qsTr("Number (0)"), value: 0 },
                { label: qsTr("List (1)"), value: 1 },
                { label: qsTr("Data (3)"), value: 3 },
                { label: qsTr("Complex number (4)"), value: 4 },
                { label: qsTr("Complex list (5)"), value: 5 },
                { label: qsTr("String (6)"), value: 6 },
                { label: qsTr("Y-variable (7)"), value: 7 },
                { label: qsTr("Picture (8)"), value: 8 },
                { label: qsTr("Settings (10)"), value: 10 },
                { label: qsTr("Window (12)"), value: 12 },
                { label: qsTr("Zoom (13)"), value: 13 },
                { label: qsTr("Table (14)"), value: 14 },
                { label: qsTr("Python bytecode (18)"), value: 18 }
            ]

            function extensionForType(type) {
                switch (type) {
                case 0: return "8xn2"
                case 1: return "8xl2"
                case 2: return "8xp2"
                case 3: return "8xd2"
                case 4: return "8ci2"
                case 5: return "8ca2"
                case 6: return "8xm2"
                case 7: return "8xy2"
                case 8: return "8xv2"
                case 10: return "8xs2"
                case 12: return "8xw2"
                case 13: return "8xz2"
                case 14: return "8xt2"
                case 15: return "py"
                case 18: return "8mp2"
                default: return "bin"
                }
            }

            function openGetDialog(file) {
                pendingGetFile = file
                pendingGetFiles = [file]
                pendingGetIndex = 0
                openPendingGetDialog()
            }

            function openPendingGetDialog() {
                if (backend.busy) return
                if (pendingGetIndex >= pendingGetFiles.length) {
                    pendingGetFile = null
                    pendingGetFiles = []
                    return
                }
                pendingGetFile = pendingGetFiles[pendingGetIndex]
                const folder = getFileDialog.currentFolder.toString().replace(/\/$/, "")
                getFileDialog.currentFile = folder + "/" + encodeURIComponent(
                    pendingGetFile.name + "." + extensionForType(pendingGetFile.type))
                getFileDialog.open()
            }

            function getSelectedFiles() {
                pendingGetFiles = deviceFiles.filter(function(file) {
                    return selectedWireNames.indexOf(file.wireName) >= 0
                        && file.wireName.length > 0
                })
                pendingGetIndex = 0
                openPendingGetDialog()
            }

            function toggleFileSelection(wireName, checked) {
                let updated = selectedWireNames.slice()
                const index = updated.indexOf(wireName)
                if (checked && index < 0) updated.push(wireName)
                if (!checked && index >= 0) updated.splice(index, 1)
                selectedWireNames = updated
            }

            function clearSelection() {
                selectedWireNames = []
            }

            function loadDeviceFiles() {
                try {
                    deviceFiles = JSON.parse(backend.filesJson)
                } catch (error) {
                    deviceFiles = []
                }
            }

            function refreshWhenReady() {
                if (refreshPending && !backend.busy) {
                    refreshPending = false
                    backend.refreshFiles()
                }
            }

            Component.onCompleted: {
                loadDeviceFiles()
                refreshPending = true
                refreshWhenReady()
            }

            Connections {
                target: backend
                function onFilesJsonChanged() {
                    deviceFilesPage.loadDeviceFiles()
                }
                function onBusyChanged() {
                    if (!backend.busy) {
                        deviceFilesPage.refreshWhenReady()
                        if (deviceFilesPage.pendingGetFiles.length > 0
                                && !getFileDialog.visible) {
                            deviceFilesPage.openPendingGetDialog()
                        }
                    }
                }
            }

            FileDialog {
                id: getFileDialog
                title: qsTr("Save calculator file")
                fileMode: FileDialog.SaveFile
                defaultSuffix: deviceFilesPage.pendingGetFile
                    ? deviceFilesPage.extensionForType(deviceFilesPage.pendingGetFile.type)
                    : "bin"
                nameFilters: [qsTr("All files (*)")]
                onAccepted: {
                    if (deviceFilesPage.pendingGetFile) {
                        const file = deviceFilesPage.pendingGetFile
                        backend.getFile(file.name, file.wireName, file.type,
                                        root.localPathFromUrl(selectedFile))
                        deviceFilesPage.pendingGetIndex += 1
                        deviceFilesPage.pendingGetFile = null
                        deviceFilesPage.openPendingGetDialog()
                    }
                }
                onRejected: {
                    deviceFilesPage.pendingGetFile = null
                    deviceFilesPage.pendingGetFiles = []
                    deviceFilesPage.pendingGetIndex = 0
                }
            }

            FileDialog {
                id: sendFromFilesDialog
                title: qsTr("Choose a TI-84 EVO file")
                fileMode: FileDialog.OpenFile
                nameFilters: [
                    qsTr("TI-84 EVO variable files (*.8xp2 *.8xpy2 *.8mp2)"),
                    qsTr("Python source files (*.py)"),
                    qsTr("All files (*)")
                ]
                onAccepted: {
                    const path = root.localPathFromUrl(selectedFile)
                    sendDialog.close()
                    backend.uploadFile(path)
                }
            }

            Controls.Dialog {
                id: sendDialog
                anchors.centerIn: parent
                width: Math.min(parent.width - 32, 440)
                modal: true
                title: qsTr("Send to calculator")
                standardButtons: Controls.Dialog.Cancel

                contentItem: ColumnLayout {
                    spacing: 12

                    Controls.Label {
                        Layout.fillWidth: true
                        text: qsTr("Choose an EVO file or send the current clipboard contents as a variable.")
                        wrapMode: Text.WordWrap
                    }

                    Controls.Button {
                        Layout.fillWidth: true
                        text: qsTr("Choose File…")
                        icon.name: "document-open"
                        onClicked: sendFromFilesDialog.open()
                    }

                    Controls.Label {
                        Layout.fillWidth: true
                        text: qsTr("Clipboard text is sent as UTF-8 variable data. Enter its name and choose the matching EVO type. Python source is packaged as type 15; type 18 bytecode must be sent as a native .8mp2 file.")
                        wrapMode: Text.WordWrap
                    }

                    Controls.Label {
                        text: qsTr("Variable name")
                    }

                    Controls.TextField {
                        id: clipboardVariableName
                        Layout.fillWidth: true
                        text: "PROGRAM"
                        maximumLength: 8
                        placeholderText: qsTr("1–8 letters")
                    }

                    Controls.Label {
                        text: qsTr("EVO type")
                    }

                    Controls.ComboBox {
                        id: clipboardVariableType
                        Layout.fillWidth: true
                        model: deviceFilesPage.clipboardTypes
                        textRole: "label"
                        currentIndex: 0
                    }

                    Controls.Button {
                        Layout.fillWidth: true
                        text: qsTr("Send Clipboard")
                        icon.name: "edit-paste"
                        enabled: !backend.busy && clipboardVariableName.text.length > 0
                        onClicked: {
                            const selectedType = deviceFilesPage.clipboardTypes[
                                clipboardVariableType.currentIndex].value
                            sendDialog.close()
                            backend.sendClipboard(clipboardVariableName.text,
                                                  selectedType)
                        }
                    }
                }
            }

            Controls.Dialog {
                id: deleteDialog
                anchors.centerIn: parent
                modal: true
                title: qsTr("Delete device file?")
                standardButtons: Controls.Dialog.Ok | Controls.Dialog.Cancel
                property var pendingFile: null

                contentItem: Controls.Label {
                    width: 352
                    text: deleteDialog.pendingFile
                        ? qsTr("Permanently delete %1 (type %2) from the calculator?")
                            .arg(deleteDialog.pendingFile.name)
                            .arg(deleteDialog.pendingFile.type)
                        : ""
                    wrapMode: Text.WordWrap
                }

                onAccepted: {
                    if (pendingFile) {
                        backend.deleteFile(pendingFile.name,
                                           pendingFile.wireName,
                                           pendingFile.type)
                    }
                    pendingFile = null
                }
                onRejected: pendingFile = null
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true

                    Controls.Button {
                        text: qsTr("Get")
                        icon.name: "document-save"
                        enabled: selectedWireNames.length > 0 && !backend.busy
                        onClicked: deviceFilesPage.getSelectedFiles()
                    }

                    Controls.Button {
                        text: qsTr("Clear selection")
                        enabled: selectedWireNames.length > 0
                        onClicked: deviceFilesPage.clearSelection()
                    }

                    Item { Layout.fillWidth: true }

                    Controls.Button {
                        text: qsTr("Send")
                        icon.name: "document-send"
                        enabled: !backend.busy
                        onClicked: sendDialog.open()
                    }

                    Controls.Button {
                        text: qsTr("Refresh")
                        enabled: !backend.busy
                        onClicked: backend.refreshFiles()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.palette.alternateBase
                    radius: 4

                    ListView {
                        id: deviceFileList
                        anchors.fill: parent
                        anchors.margins: 8
                        clip: true
                        spacing: 8
                        model: deviceFilesPage.deviceFiles

                        delegate: Controls.ItemDelegate {
                            required property var modelData
                            width: ListView.view.width
                            enabled: !backend.busy
                            onClicked: {
                                if (modelData.wireName.length > 0) {
                                    deviceFilesPage.toggleFileSelection(
                                        modelData.wireName,
                                        deviceFilesPage.selectedWireNames.indexOf(
                                            modelData.wireName) < 0)
                                }
                            }

                            contentItem: RowLayout {
                                spacing: 8

                                Controls.CheckBox {
                                    checked: deviceFilesPage.selectedWireNames.indexOf(
                                        modelData.wireName) >= 0
                                    enabled: modelData.wireName.length > 0 && !backend.busy
                                    Accessible.name: qsTr("Select %1").arg(modelData.name)
                                    onToggled: deviceFilesPage.toggleFileSelection(
                                        modelData.wireName, checked)
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Controls.Label {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Controls.Label {
                                        Layout.fillWidth: true
                                        text: qsTr("%1 bytes · type %2 · version %3 · %4")
                                            .arg(modelData.size)
                                            .arg(modelData.type)
                                            .arg(modelData.version)
                                            .arg(modelData.memory ? qsTr("archived") : qsTr("RAM"))
                                        opacity: 0.75
                                        elide: Text.ElideRight
                                    }
                                }

                                Controls.Button {
                                    Layout.minimumWidth: implicitWidth
                                    text: qsTr("Get")
                                    font.pixelSize: 12
                                    leftPadding: 6
                                    rightPadding: 6
                                    enabled: modelData.wireName.length > 0 && !backend.busy
                                    onClicked: deviceFilesPage.openGetDialog(modelData)
                                }

                                Controls.Button {
                                    Layout.minimumWidth: implicitWidth
                                    text: qsTr("Copy to clipboard")
                                    font.pixelSize: 12
                                    leftPadding: 6
                                    rightPadding: 6
                                    enabled: modelData.wireName.length > 0 && !backend.busy
                                    onClicked: backend.copyFile(modelData.name,
                                                               modelData.wireName,
                                                               modelData.type)
                                }

                                Controls.Button {
                                    Layout.minimumWidth: implicitWidth
                                    Layout.rightMargin: 16
                                    text: qsTr("Delete")
                                    font.pixelSize: 12
                                    leftPadding: 6
                                    rightPadding: 6
                                    enabled: modelData.wireName.length > 0 && !backend.busy
                                    onClicked: {
                                        deleteDialog.pendingFile = modelData
                                        deleteDialog.open()
                                    }
                                }
                            }
                        }

                        Controls.ScrollBar.vertical: Controls.ScrollBar {}
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 64
                        visible: deviceFileList.count === 0 && !backend.busy

                        Controls.Label {
                            Layout.fillWidth: true
                            text: qsTr("No device files loaded")
                            font.pixelSize: 20
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Controls.Label {
                            Layout.fillWidth: true
                            text: qsTr("Press Refresh to read files from the connected calculator.")
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                Controls.BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: backend.busy
                    visible: running
                }

                Controls.Label {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: backend.status
                    wrapMode: Text.WordWrap
                    color: backend.status.indexOf("failed") >= 0
                        ? "#b00020"
                        : root.palette.text
                }
            }
        }
    }

    Component {
        id: sendPage

        Controls.Page {
            id: sendFilePage
            title: qsTr("Send Files")
            property string selectedPath: ""

            FileDialog {
                id: fileDialog
                title: qsTr("Choose a TI calculator file")
                fileMode: FileDialog.OpenFile
                nameFilters: [
                    qsTr("TI-84 EVO variable files (*.8xp2 *.8xpy2 *.8mp2)"),
                    qsTr("Python programs (*.py)"),
                    qsTr("All files (*)")
                ]
                onAccepted: {
                    sendFilePage.selectedPath = root.localPathFromUrl(selectedFile)
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 32, 480)
                spacing: 16

                Controls.Label {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("Transfer to Calculator")
                    font.pixelSize: 24
                    font.bold: true
                }

                Controls.Label {
                    Layout.fillWidth: true
                    text: qsTr("Select a native TI-84 EVO .8xp2 program or a Python .py file. Python filenames must contain 1–8 letters.")
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }

                Controls.Button {
                    Layout.fillWidth: true
                    text: qsTr("Choose File…")
                    icon.name: "document-open"
                    enabled: !backend.busy
                    onClicked: fileDialog.open()
                }

                Controls.TextField {
                    Layout.fillWidth: true
                    text: sendFilePage.selectedPath
                    readOnly: true
                    placeholderText: qsTr("No host file selected")
                }

                Controls.Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    text: qsTr("Send to Device")
                    icon.name: "document-send"
                    enabled: sendFilePage.selectedPath.length > 0 && !backend.busy
                    onClicked: backend.uploadFile(sendFilePage.selectedPath)
                }

                Controls.BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    running: backend.busy
                    visible: running
                }

                Controls.Label {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: backend.status
                    wrapMode: Text.WordWrap
                    color: backend.status.indexOf("failed") >= 0
                        ? "#b00020"
                        : root.palette.text
                }
            }
        }
    }

    DropArea {
        anchors.fill: parent

        onDropped: function(drop) {
            if (backend.busy || drop.urls.length === 0) return
            backend.uploadFile(root.localPathFromUrl(drop.urls[0]))
            drop.acceptProposedAction()
        }
    }
}
