#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN_SRC="$ROOT/.build/release/CursorUsageMenubar"
INSTALL_DIR="$HOME/.local/bin"
APP_DIR="$HOME/Applications/Cursor Usage Menubar.app"
SYSTEM_APP_DIR="/Applications/Cursor Usage Menubar.app"
LABEL="com.cursorusage.menubar"
OLD_LABEL="com.linkjf.cursor-usage-menubar"

echo "Building..."
cd "$ROOT"
swift build -c release

# Stop a running instance so the new binary is the one that starts
pkill -x CursorUsageMenubar 2>/dev/null || true
sleep 1

mkdir -p "$INSTALL_DIR"
cp "$BIN_SRC" "$INSTALL_DIR/cursor-usage-menubar"
chmod +x "$INSTALL_DIR/cursor-usage-menubar"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_SRC" "$APP_DIR/Contents/MacOS/CursorUsageMenubar"
chmod +x "$APP_DIR/Contents/MacOS/CursorUsageMenubar"
cp "$ROOT/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>CursorUsageMenubar</string>
  <key>CFBundleIdentifier</key>
  <string>com.cursorusage.menubar</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>Cursor Usage Menubar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>2.0.1</string>
  <key>CFBundleVersion</key>
  <string>3</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>LSMultipleInstancesProhibited</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

# Remove LaunchAgent plists from earlier builds; login is a Login Item now
for label in "$LABEL" "$OLD_LABEL"; do
  launchctl bootout "gui/$(id -u)/${label}" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/${label}.plist"
done

# Finder shows /Applications ahead of ~/Applications. Keep that copy in sync when it is writable.
if [[ -w "/Applications" ]]; then
  rm -rf "$SYSTEM_APP_DIR"
  cp -R "$APP_DIR" "$SYSTEM_APP_DIR"
fi

# Launch from the bundle so the app registers Open at Login (on by default, first run only)
open "$APP_DIR"

echo
echo "Installed:"
echo "  CLI: $INSTALL_DIR/cursor-usage-menubar"
echo "  App: $APP_DIR"
echo
echo "Open at Login is ON by default."
echo "Turn it off in the app Settings or in System Settings > General > Login Items."
echo
echo "Menu bar shows API used % first, e.g. 48% | 7/16"
