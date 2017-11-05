import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.0
import QtQuick.Layouts 1.0

import TreeViewModel 1.0
import Debugger 1.0
import StyleSettings 1.0
import IOWrapper 1.0
import FileIO 1.0

import "code"
import "controls" as Controls
import "containers"
import "view" as View
import "widgets" as Widgets

ApplicationWindow {
    visible: true
    width: 1000
    height: 800
    title: fileIO.source + ((fileIO.source) ?" - " :"") + qsTr("Advánc Ifj Creator")

    Rectangle {
        id: root
        state: "stopped"
        color: "white"
        anchors.fill: parent
    }

    Debugger {
        id: ifjDebugger

        model: debugStateView.model
        ioWrapper: consoleWidget.ioWrapper

        onProgramEnded: stopProgram()
    }

    FileDialog {
        id: fileDialog

        folder: shortcuts.documents
        selectMultiple: false
        selectExisting: (fileIO.actionType != "save")
        nameFilters: [ "IFJ files (*.IFJcode17)", "All files (*)" ]

        onAccepted: {
            fileIO.source = fileDialog.fileUrl
            if(fileIO.actionType == "open")
                codeEditor.code = fileIO.read()
            else if(fileIO.actionType == "save")
                fileIO.write(codeEditor.code)
            fileIO.actionType = ""
        }
    }

    FileIO {
        id: fileIO
        property string actionType: ""
    }

    Shortcut {
        sequence: "Ctrl+O"
        onActivated: openFile()
    }

    Shortcut {
        sequence: "Ctrl+S"
        onActivated: saveFile()
    }

    Shortcut {
        sequence: "F5"
        onActivated: {
            if(root.state == "stopped")
                runProgram()
            else if(root.state == "runningDebug")
                ifjDebugger.runToNextBreakpoint()
        }
    }

    Shortcut {
        sequence: "F6"
        onActivated: {
            if(root.state == "runningDebug")
                ifjDebugger.runToNextLine()
        }
    }

    // Main bar
    Rectangle {
        id: mainToolbar

        width: 55
        height: parent.height

        color: "#2f2f2f"

        Column {
            spacing: 0
            width: parent.width
            height: playButton.height * 3 + 2 * spacing

            anchors.bottom: parent.bottom
            anchors.bottomMargin: spacing
            anchors.horizontalCenter: parent.horizontalCenter

            Controls.IconButton {
                id: playButton

                iconSource: rootDir + "assets/images/playIcon.svg"
                width: parent.width
                height: width * 0.7

                onClicked: runProgram()
            }

            Controls.IconButton {
                id: playDebugButton

                iconSource: rootDir + "assets/images/playBugIcon.svg"
                width: parent.width
                height: playButton.height

                onClicked: debugProgram()
            }

            Controls.IconButton {
                id: stopButton

                enabled: false
                iconSource: rootDir + "assets/images/stopIcon.svg"
                width: parent.width
                height: playButton.height

                onClicked: stopProgram()
            }
        }
    }

    SplitView {
        orientation: Qt.Vertical

        anchors.top: root.top
        anchors.bottom: root.bottom
        anchors.left: mainToolbar.right
        anchors.right: root.right

        handleDelegate: Rectangle {
            height: 2
            color: "lightGray"
        }

        SplitView {
            id: editorSplitView

            orientation: Qt.Horizontal
            Layout.fillHeight: true

            handleDelegate: Rectangle {
                width: 2
                color: "lightGray"
            }

            CodeEditor {
                id: codeEditor

                width: 500
                height: parent.height
                Layout.fillWidth: true

                placeHolderText: "<b>File</b><br>
                                    - open file (Ctrl+O)<br>
                                    - save file (Ctrl+S)<br>
                                  <br><b>Run program</b><br>
                                    - run program (F5)<br>
                                    - debug run to next breakpoint (F5)<br>
                                    - debug run to next line (F6)<br>
                                  <br><b>Code</b><br>
                                    - show completer (Ctrl + Space)"
                lineNumbersPanelColor: "#f2f2f2"
                breakpoints: ifjDebugger.breakpoints
                currentLine: ifjDebugger.currentLine

                completer.width: 200
                completer.visibleItemCount: 6

                onToggleBreakpointRequest: ifjDebugger.toggleBreakpoint(line)
                onLinesAdded: ifjDebugger.handleAddedLines(lines)
                onLinesRemoved: ifjDebugger.handleRemovedLines(lines)
            }

            View.DebugStateView {
                id: debugStateView

                contentWidth: 500
                height: parent.height
            }
        }

        Widgets.ConsoleWidget {
            id: consoleWidget

            toolbarHeight: 25
            height: 300

            onRunToNextLineRequest: ifjDebugger.runToNextLine()
            onRunToNextBreakPointRequest: ifjDebugger.runToNextBreakpoint()
        }
    }

    function runProgram() {
        root.state = "running"
        stopButton.enabled = true;
        playButton.enabled = false;
        playDebugButton.enabled = false;
        consoleWidget.debugToolbarEnabled = false
        consoleWidget.clear()
        consoleWidget.write("Program started...\n")
        ifjDebugger.run(codeEditor.code)
    }

    function debugProgram() {
        root.state = "runningDebug"
        stopButton.enabled = true;
        playButton.enabled = false;
        playDebugButton.enabled = false;
        consoleWidget.debugToolbarEnabled = true
        consoleWidget.clear()
        debugStateView.show()
        consoleWidget.write("Debug started...\n")
        ifjDebugger.debug(codeEditor.code)
    }

    function stopProgram() {
        root.state = "stopped"
        stopButton.enabled = false;
        playButton.enabled = true;
        playDebugButton.enabled = true;
        consoleWidget.debugToolbarEnabled = false
        debugStateView.hide()
        consoleWidget.stopRead()
        ifjDebugger.stop()
        // TODO exit codes
        consoleWidget.write("\nProgram ended")
    }

    function saveFile() {
        if(fileIO.source == "") {
            fileIO.actionType = "save"
            fileDialog.visible = true
        }

        else
            fileIO.write(codeEditor.code)
    }

    function openFile() {
        fileIO.actionType = "open"
        fileDialog.visible = true
    }
 }
