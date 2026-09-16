import QtQuick
import qs.Ui

// Thin bar-icon shell over Panel.qml, which owns the binary resolution and
// the parsed menu. Mirrors the BarWidget-loads-Panel split used by other
// bar-widget-plus-popup plugins (e.g. hyprmoncfg) rather than tailscale's
// single-file style, since keeping the process/parsing logic out of the
// button makes it easier to test in isolation later if that's ever worth
// doing.
//
// The periodic refresh Timer lives here, not in Panel.qml, deliberately: a
// plugin's registered entry point (this file) is what the shell's hot-reload
// watches, but Panel.qml only exists to this file as a Loader.source URL, and
// a Timer declared inside it stopped firing after any edit to Panel.qml
// following the widget's first load — a QML component-cache issue with the
// engine keeping the pre-edit compiled Panel.qml alive under its Loader
// rather than recompiling the changed file. A Timer here, driving
// panelLoader.item.refresh(), doesn't depend on that path staying fresh.
BarWidget {
  id: root
  moduleName: "tkrag.petridish"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
  }

  readonly property string barLabel: panelLoader.item ? panelLoader.item.barLabel : "🧫 ?"
  readonly property string barTooltip: panelLoader.item ? panelLoader.item.barTooltip : "petridish — project fleet"
  readonly property int refreshIntervalSec: panelLoader.item ? panelLoader.item.refreshIntervalSec : 30

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    onTriggered: {
      if (panelLoader.item && panelLoader.item.refresh) panelLoader.item.refresh()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barLabel
    tooltipText: root.barTooltip
    onPressed: function() {
      if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
    }
  }
}
