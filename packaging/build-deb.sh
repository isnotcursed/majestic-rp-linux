#!/usr/bin/env bash
set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
ROOT="$(repository_root)"
VERSION="$(package_version "$ROOT")"
PACKAGE_ROOT="$ROOT/build/deb/root"
OUTPUT_DIR="$ROOT/dist-packages"

rm -rf -- "$ROOT/build/deb"
mkdir -p "$PACKAGE_ROOT/DEBIAN" "$OUTPUT_DIR"
install_shared_files "$ROOT" "$PACKAGE_ROOT"

cat > "$PACKAGE_ROOT/DEBIAN/control" <<EOF
Package: majestic-linux-runner
Version: $VERSION
Architecture: all
Maintainer: isnotcursed <64527830+isnotcursed@users.noreply.github.com>
Depends: bash, nodejs, python3 (>= 3.11)
Section: games
Priority: optional
Homepage: https://github.com/isnotcursed/majestic-rp-linux
Description: запуск Majestic RP через Proton
 Готовит Proton-префикс, устанавливает Windows-лаунчер Majestic и
 применяет совместимый с Linux патч к app.asar.
EOF

OUTPUT="$OUTPUT_DIR/majestic-linux-runner_${VERSION}_all.deb"
dpkg-deb --root-owner-group --build "$PACKAGE_ROOT" "$OUTPUT"
dpkg-deb --info "$OUTPUT"
dpkg-deb --contents "$OUTPUT" >/dev/null
SMOKE_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$SMOKE_ROOT"' EXIT
dpkg-deb --extract "$OUTPUT" "$SMOKE_ROOT"
"$SMOKE_ROOT/usr/bin/majestic-linux" setup --help >/dev/null
rm -rf -- "$SMOKE_ROOT"
trap - EXIT
sha256sum "$OUTPUT" > "$OUTPUT.sha256"
printf 'Built %s\n' "$OUTPUT"
