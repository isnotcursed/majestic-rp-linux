#!/usr/bin/env bash
set -euo pipefail

REPOSITORY_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${PACKAGE_VERSION:-$(sed 's/^v//' "$REPOSITORY_ROOT/VERSION")}"
BUILD_ROOT="$REPOSITORY_ROOT/build/appimage"
APPDIR="$BUILD_ROOT/MajesticLinux.AppDir"
OUTPUT_DIR="$REPOSITORY_ROOT/dist-packages"
APPIMAGE_TOOL="$BUILD_ROOT/appimagetool-x86_64.AppImage"
APPIMAGE_TOOL_SHA256="95cbe7cce9717fce90c484e34052ee7c7f1d7635b33c12525b4776826a7d29b6"

rm -rf -- "$APPDIR" "$BUILD_ROOT/pyinstaller-dist" "$BUILD_ROOT/pyinstaller-work"
mkdir -p "$APPDIR/usr/bin" \
  "$APPDIR/usr/lib/majestic-linux-runner" \
  "$APPDIR/usr/share/applications" \
  "$APPDIR/usr/share/doc/majestic-linux-runner" \
  "$APPDIR/usr/share/icons/hicolor/scalable/apps" \
  "$APPDIR/usr/share/metainfo" \
  "$OUTPUT_DIR"

python3 -m PyInstaller \
  --noconfirm \
  --clean \
  --onefile \
  --name majestic-linux-core \
  --distpath "$BUILD_ROOT/pyinstaller-dist" \
  --workpath "$BUILD_ROOT/pyinstaller-work" \
  --specpath "$BUILD_ROOT" \
  "$REPOSITORY_ROOT/packaging/appimage_entry.py"

install -m 0755 "$BUILD_ROOT/pyinstaller-dist/majestic-linux-core" "$APPDIR/usr/bin/majestic-linux-core"
install -m 0755 "$REPOSITORY_ROOT/install-and-run-majestic-proton.sh" "$APPDIR/usr/bin/majestic-linux-wrapper"
install -m 0755 "$(command -v node)" "$APPDIR/usr/bin/node"
cp -a "$REPOSITORY_ROOT/packaging/asar/node_modules" "$APPDIR/usr/lib/majestic-linux-runner/"
install -m 0644 "$REPOSITORY_ROOT/examples/majestic-runner.example.conf" \
  "$APPDIR/usr/share/doc/majestic-linux-runner/majestic-runner.example.conf"
install -m 0644 "$REPOSITORY_ROOT/README.md" "$APPDIR/usr/share/doc/majestic-linux-runner/README.md"
install -m 0644 "$REPOSITORY_ROOT/LICENSE" "$APPDIR/usr/share/doc/majestic-linux-runner/LICENSE"
install -m 0644 "$REPOSITORY_ROOT/packaging/majestic-linux.svg" \
  "$APPDIR/usr/share/icons/hicolor/scalable/apps/majestic-linux.svg"
install -m 0644 "$REPOSITORY_ROOT/packaging/io.github.isnotcursed.majestic-linux-runner.metainfo.xml" \
  "$APPDIR/usr/share/metainfo/io.github.isnotcursed.majestic-linux-runner.metainfo.xml"
cp "$REPOSITORY_ROOT/packaging/majestic-linux.svg" "$APPDIR/majestic-linux.svg"

cat > "$APPDIR/usr/bin/asar" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
: "${APPDIR:?APPDIR is required}"
exec "$APPDIR/usr/bin/node" \
  "$APPDIR/usr/lib/majestic-linux-runner/node_modules/@electron/asar/bin/asar.js" "$@"
EOF
chmod 0755 "$APPDIR/usr/bin/asar"

cat > "$APPDIR/AppRun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
APPDIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export APPDIR
export PATH="$APPDIR/usr/bin:$PATH"
export MAJESTIC_RUNNER_BIN="$APPDIR/usr/bin/majestic-linux-core"
exec "$APPDIR/usr/bin/majestic-linux-wrapper" "$@"
EOF
chmod 0755 "$APPDIR/AppRun"

cat > "$APPDIR/io.github.isnotcursed.majestic-linux-runner.desktop" <<'EOF'
[Desktop Entry]
Name=Majestic RP Linux Runner
Comment=Запуск Majestic RP через Proton
Exec=majestic-linux
Icon=majestic-linux
Terminal=true
Type=Application
Categories=Game;
StartupNotify=true
EOF
cp "$APPDIR/io.github.isnotcursed.majestic-linux-runner.desktop" \
  "$APPDIR/usr/share/applications/io.github.isnotcursed.majestic-linux-runner.desktop"

curl --fail --location --proto '=https' --tlsv1.2 \
  --output "$APPIMAGE_TOOL" \
  "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
printf '%s  %s\n' "$APPIMAGE_TOOL_SHA256" "$APPIMAGE_TOOL" | sha256sum --check --strict
chmod 0755 "$APPIMAGE_TOOL"

OUTPUT="$OUTPUT_DIR/majestic-linux-runner-${VERSION}-x86_64.AppImage"
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 VERSION="$VERSION" \
  "$APPIMAGE_TOOL" "$APPDIR" "$OUTPUT"
chmod 0755 "$OUTPUT"
sha256sum "$OUTPUT" > "$OUTPUT.sha256"
printf 'Built %s\n' "$OUTPUT"
