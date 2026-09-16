# Bar widget (Omarchy)

The Omarchy-bar counterpart of the [xbar/SwiftBar menu bar plugin](../../xbar/README.md)
and the [Cinnamon panel applet](../../cinnamon/README.md): `🧫 working/total` in the bar,
running sessions at the top of the dropdown, the rest grouped by bucket. Clicking a
project opens its directory in the file manager.

Like the other two, it is a thin presenter over one command:

```sh
petridish menubar
```

The widget runs that every 30 seconds (configurable), parses the output, and renders it.
All content decisions — labels, ordering, the dirty/working markers — live in
`menubar.rs`, shared with macOS and Cinnamon, so none of the frontends can drift apart.

## Install

```sh
cp -r integrations/omarchy/tkrag.petridish ~/.config/omarchy/plugins/
```

Then add it to the bar: Omarchy's settings UI may offer a bar-widget picker, or edit
`~/.config/omarchy/shell.json` directly and add `{"id": "tkrag.petridish"}` to one of
`bar.layout.left` / `.center` / `.right` (see `crmne.hyprmoncfg` or `omamail` for existing
examples in that file). Reload the shell for it to pick up a newly copied plugin
directory.

The widget needs the `petridish` binary. It runs `petridish menubar` through a login
shell (`bash -lc`), so it searches the same `PATH` your terminal would — including
`~/.cargo/bin` or `~/.local/bin` if your shell rc adds them — which sidesteps the
not-launched-from-a-shell problem xbar has on macOS and the Cinnamon applet solves by
searching explicit candidate paths. If your login shell's `PATH` still doesn't reach it,
set an explicit path in the widget's settings.

## Settings

- **Refresh interval (seconds)** — how often to re-run `petridish menubar` (default 30s,
  matching the xbar plugin's `.30s` convention).
- **petridish binary path** — explicit path to `petridish`, for installs outside what the
  login shell's `PATH` reaches.

## Uninstall

Remove it from the bar layout in `shell.json` (or via the Omarchy menu), then:

```sh
rm -rf ~/.config/omarchy/plugins/tkrag.petridish
```

## Development

The xbar-text parser (`parser.js`) is pure JS with no Quickshell/QML imports, tested with
node's built-in runner — no npm install needed:

```sh
make omarchy
```

It is a duplicate of `integrations/cinnamon/petridish@jkrag/parser.js`, not a shared
file — a plugin directory is copied whole into `~/.config/omarchy/plugins/`, so it can't
reach outside itself for a sibling integration's file. Keep the two in sync by hand.

`BarWidget.qml` is a thin bar-icon shell; `Panel.qml` owns the process/parse/render logic
and the dropdown. Debugging inside the shell: check `journalctl --user -f` while the
compositor session runs, or watch for QML console errors on shell reload.
