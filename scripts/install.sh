#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN_SRC="$ROOT/.build/release/CursorUsageMenubar"
INSTALL_DIR="$HOME/.local/bin"
APP_DIR="$HOME/Applications/Cursor Usage Menubar.app"
LABEL="com.cursorusage.menubar"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
OLD_LABEL="com.linkjf.cursor-usage-menubar"

echo "Building..."
cd "$ROOT"
swift build -c release

mkdir -p "$INSTALL_DIR"
cp "$BIN_SRC" "$INSTALL_DIR/cursor-usage-menubar"
chmod +x "$INSTALL_DIR/cursor-usage-menubar"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_SRC" "$APP_DIR/Contents/MacOS/CursorUsageMenubar"
chmod +x "$APP_DIR/Contents/MacOS/CursorUsageMenubar"

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
  <key>CFBundleName</key>
  <string>Cursor Usage Menubar</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>2.0.0</string>
  <key>CFBundleVersion</key>
  <string>2</string>
  <key>LSUIElement</key>
  <true/>
  <key>LSMultipleInstancesProhibited</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

# Remove legacy launch agent if present
launchctl bootout "gui/$(id -u)/${OLD_LABEL}" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/${OLD_LABEL}.plist"

mkdir -p "$(dirname "$PLIST")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>$APP_DIR/Contents/MacOS/CursorUsageMenubar</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

echo
echo "Installed:"
echo "  CLI: $INSTALL_DIR/cursor-usage-menubar"
echo "  App: $APP_DIR"
echo
echo "Launch at login is OFF by default."
echo "Enable it from the app Settings panel, or run:"
echo "  launchctl bootstrap gui/\$(id -u) '$PLIST'"
echo
echo "Menu bar shows API remaining first, e.g. 52% | 7/16"
