#!/bin/bash
# Builds Island.app next to this script. Needs the Xcode Command Line Tools (xcode-select --install).
set -e
cd "$(dirname "$0")"

swift build -c release

APP="Island.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/Island "$APP/Contents/MacOS/Island"

cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Island</string>
    <key>CFBundleDisplayName</key><string>Island</string>
    <key>CFBundleIdentifier</key><string>dev.arora.island</string>
    <key>CFBundleExecutable</key><string>Island</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSAppleEventsUsageDescription</key><string>Island controls Music and Spotify for the now-playing card, and System Events / Finder for the Dark Mode and Empty Trash buttons.</string>
</dict>
</plist>
EOF

# Ad-hoc signature so macOS attributes the Accessibility / Automation prompts to the app itself.
codesign --force --deep --sign - "$APP"

echo
echo "Built $APP"
echo "Run it:         open $APP"
echo "fn+W needs Accessibility access: System Settings → Privacy & Security → Accessibility → + → $APP"
