import QtQuick
import qs.Ui

// Thin bar-icon shell over Panel.qml, which owns all the state (binary
// resolution, the refresh timer, the parsed menu). Mirrors the
// BarWidget-loads-Panel split used by other bar-widget-plus-popup plugins
// (e.g. hyprmoncfg) rather than tailscale's single-file style, since keeping
// the process/parsing logic out of the button makes it easier to test in
// isolation later if that's ever worth doing.
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
