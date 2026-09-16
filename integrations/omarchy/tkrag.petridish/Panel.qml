import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "parser.js" as Parser

// The Omarchy-bar counterpart of the xbar/SwiftBar menu bar and the Cinnamon
// panel applet: `🧫 working/total` in the bar, running sessions at the top of
// the dropdown, the rest grouped by bucket. Clicking a project opens its
// directory in the file manager.
//
// All content decisions — labels, ordering, the dirty/working markers — live
// in menubar.rs, shared with macOS and Cinnamon, so the frontends can't drift
// apart. This file only runs `petridish menubar` and renders what it prints.
Panel {
  id: root
  moduleName: "tkrag.petridish"
  ipcTarget: "tkrag.petridish"
  manageIpc: false

  // Set by BarWidget.qml so the popup anchors under the bar icon.
  property var anchorItem: null

  readonly property int refreshIntervalSec: Math.max(5, Number(setting("refreshIntervalSec", 30)) || 30)
  readonly property string configuredBinaryPath: String(setting("binaryPath", "") || "")

  property string barLabel: "🧫 ?"
  property string barTooltip: "petridish — project fleet"
  property var menuLines: []

  // Resolved fresh on every refresh (not cached) via a login shell so
  // ~/.cargo/bin and ~/.local/bin are found even when the shell process
  // itself was launched without a shell in its ancestry — the same
  // not-launched-from-a-shell problem xbar has on macOS and the Cinnamon
  // applet solves by searching GLib's PATH directly. `bash -lc` gets us the
  // same search for free, sourced from the user's own shell rc.
  function menubarScript() {
    var override = root.configuredBinaryPath.trim()
    if (override !== "") return "exec " + Util.shellQuote(override) + " menubar"
    return (
      'bin="$(command -v petridish 2>/dev/null || true)"; ' +
      '[ -z "$bin" ] && [ -x "$HOME/.cargo/bin/petridish" ] && bin="$HOME/.cargo/bin/petridish"; ' +
      '[ -z "$bin" ] && [ -x "$HOME/.local/bin/petridish" ] && bin="$HOME/.local/bin/petridish"; ' +
      '[ -z "$bin" ] && exit 127; ' +
      'exec "$bin" menubar'
    )
  }

  function notFoundLines() {
    return [{
      kind: "item",
      text: "petridish binary not found (PATH, ~/.cargo/bin, ~/.local/bin) — set it in the widget settings",
      indent: false,
      params: { color: "#888888" }
    }]
  }

  function refresh() {
    if (menuProc.running) return
    menuProc.running = true
  }

  function openHref(href) {
    Qt.openUrlExternally(href)
  }

  Component.onCompleted: refresh()
  onConfiguredBinaryPathChanged: refresh()

  Process {
    id: menuProc
    command: ["bash", "-lc", root.menubarScript()]
    onExited: function(exitCode) {
      if (exitCode === 127) {
        root.barLabel = "🧫 ?"
        root.menuLines = root.notFoundLines()
      }
    }
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        // exitCode 127 (binary not found) already rendered its own message;
        // an empty stream from that path would otherwise blank the panel.
        if (text.trim() === "") return
        var parsed = Parser.parseMenubarText(text)
        root.barLabel = parsed.title
        root.menuLines = parsed.lines
      }
    }
  }

  PopupCard {
    id: card
    anchorItem: root.anchorItem
    bar: root.bar
    owner: root
    open: root.opened
    contentWidth: card.fittedContentWidth(Style.space(320))
    contentHeight: card.fittedContentHeight(listView.contentHeight, Style.space(420))

    ListView {
      id: listView
      anchors.fill: parent
      clip: true
      interactive: contentHeight > height
      model: root.menuLines
      delegate: rowDelegate
    }
  }

  Component {
    id: rowDelegate

    Item {
      id: rowItem
      required property var modelData
      readonly property var line: rowItem.modelData || { kind: "item", text: "", indent: false, params: {} }
      readonly property var lineParams: line.params || {}
      readonly property bool isSeparator: line.kind === "separator"
      readonly property bool isHeader: !isSeparator && !line.indent && Object.keys(lineParams).length === 0
      readonly property string href: String(lineParams.href || "")
      readonly property bool isRefresh: lineParams.refresh === "true"
      readonly property bool clickable: href !== "" || isRefresh

      width: listView.width
      height: isSeparator ? Style.space(9) : rowText.implicitHeight + Style.space(8)

      PanelSeparator {
        visible: rowItem.isSeparator
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
      }

      MouseArea {
        visible: !rowItem.isSeparator
        anchors.fill: parent
        enabled: rowItem.clickable
        hoverEnabled: rowItem.clickable
        cursorShape: rowItem.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
          if (rowItem.isRefresh) root.refresh()
          else if (rowItem.href !== "") root.openHref(rowItem.href)
        }

        Text {
          id: rowText
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: rowItem.line.indent ? Style.space(16) : Style.space(4)
          anchors.rightMargin: Style.space(4)
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          elide: Text.ElideRight
          text: rowItem.line.text || ""
          color: rowItem.lineParams.color ? rowItem.lineParams.color : Color.foreground
          font.bold: rowItem.isHeader
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }
      }
    }
  }
}
