#!/bin/bash
set -e
here="$(cd "$(dirname "$0")" && pwd)"
f=$(find "$here" -name DashboardRepresentation.qml -not -path "*/.git/*" | head -1)
[ -n "$f" ] || { echo "DashboardRepresentation.qml not found in repo"; exit 1; }
ui=$(dirname "$f")
dst="$HOME/.local/share/plasma/plasmoids/org.linexin.launcher/contents/ui"
[ -d "$dst" ] || { echo "plasmoid not installed at $dst, run the upstream install.sh first"; exit 1; }
cp -r "$ui"/. "$dst"/
mkdir -p "$HOME/.local/bin"
if [ -f "$here/tools/glass" ]; then
  cp "$here/tools/glass" "$HOME/.local/bin/glass"
  chmod +x "$HOME/.local/bin/glass"
fi
pkill -x plasmashell || true
sleep 1
setsid plasmashell --replace > /dev/null 2>&1 &
echo "installed"
