#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
BIN="${1:-.build/debug}"
APP="${2:-dist/Fieldnotes.app}"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp -X "$BIN/Fieldnotes" "$APP/Contents/MacOS/Fieldnotes"
for bundle in "$BIN"/*.bundle; do cp -RXf "$bundle" "$APP/Contents/Resources/"; done
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleExecutable</key><string>Fieldnotes</string><key>CFBundleIdentifier</key><string>dev.fieldnotes.demo</string><key>CFBundleName</key><string>Fieldnotes</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleVersion</key><string>1</string><key>CFBundleShortVersionString</key><string>0.1</string><key>LSMinimumSystemVersion</key><string>14.5</string><key>NSHighResolutionCapable</key><true/></dict></plist>
PLIST

# Sign the assembled development app; copied Finder metadata invalidates signing.
chmod -R u+w "$APP"
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
codesign --verify --deep "$APP"
