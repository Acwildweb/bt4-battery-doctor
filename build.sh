#!/usr/bin/env bash
#
# Costruisce «BT4 Battery Doctor» come applicazione macOS a 64 bit universale
# (Apple Silicon + Intel) e la impacchetta in un bundle .app pronto all'uso.
#
# Non richiede Xcode: bastano i Command Line Tools, perché i due tagli vengono
# compilati in croce con swiftc e ricuciti con lipo.
#
# Uso:                     ./build.sh            -> dist/BT4 Battery Doctor.app
#        ./build.sh --run  -> compila e avvia
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="BT4 Battery Doctor"
BIN="BT4BatteryDoctor"
BUNDLE_ID="com.bt4.batterydoctor"
VERSION="1.0"
DEPLOY="13.0"
BUILD=".build/package"
OUT="dist"
SDK="$(xcrun --show-sdk-path)"

echo "▸ Pulizia"
rm -rf "$BUILD" "$OUT/$APP_NAME.app"
mkdir -p "$BUILD" "$OUT"

echo "▸ Icona"
xcrun swiftc -O Tools/make-icon.swift -o "$BUILD/make-icon"
"$BUILD/make-icon" "$BUILD/AppIcon.iconset" "$BUILD/AppIcon.icns"

echo "▸ Compilazione (release, ottimizzata)"
for arch in arm64 x86_64; do
  echo "  · $arch"
  xcrun swiftc -O -wmo -parse-as-library \
    -target "${arch}-apple-macos${DEPLOY}" -sdk "$SDK" \
    -o "$BUILD/$BIN-$arch" Sources/BT4BatteryDoctor/*.swift
done

echo "▸ Binario universale"
lipo -create "$BUILD/$BIN-arm64" "$BUILD/$BIN-x86_64" -output "$BUILD/$BIN"

echo "▸ Bundle .app"
APP="$OUT/$APP_NAME.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD/$BIN" "$APP/Contents/MacOS/$BIN"
chmod +x "$APP/Contents/MacOS/$BIN"
cp "$BUILD/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
printf 'APPL????' > "$APP/Contents/PkgInfo"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleName</key><string>$APP_NAME</string>
	<key>CFBundleDisplayName</key><string>$APP_NAME</string>
	<key>CFBundleExecutable</key><string>$BIN</string>
	<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
	<key>CFBundleIconFile</key><string>AppIcon</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleShortVersionString</key><string>$VERSION</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>LSMinimumSystemVersion</key><string>$DEPLOY</string>
	<key>NSHighResolutionCapable</key><true/>
	<key>NSPrincipalClass</key><string>NSApplication</string>
	<key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
	<key>NSHumanReadableCopyright</key><string>Diagnosi per celle 18650/21700/26650 su tester BT4-1CHN.</string>
</dict>
</plist>
PLIST

echo "▸ Firma ad-hoc"
codesign --force --sign - "$APP" >/dev/null 2>&1 || codesign --force --sign - "$APP"

echo
lipo -info "$APP/Contents/MacOS/$BIN"
echo "✓ Fatto: $APP"
du -sh "$APP" | awk '{print "  dimensione: "$1}'

if [[ "${1:-}" == "--run" ]]; then
  echo "▸ Avvio"
  open "$APP"
fi
