#!/usr/bin/env bash

repository_root() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
}

package_version() {
  local root="$1"
  if [[ -n "${PACKAGE_VERSION:-}" ]]; then
    printf '%s\n' "${PACKAGE_VERSION#v}"
  else
    sed 's/^v//' "$root/VERSION"
  fi
}

install_shared_files() {
  local root="$1" destination="$2"
  mkdir -p "$destination/usr/share/applications"
  install -D -m 0755 "$root/install-and-run-majestic-proton.sh" "$destination/usr/bin/majestic-linux"
  install -D -m 0644 "$root/examples/majestic-runner.example.conf" \
    "$destination/usr/share/doc/majestic-linux-runner/majestic-runner.example.conf"
  install -D -m 0644 "$root/README.md" "$destination/usr/share/doc/majestic-linux-runner/README.md"
  install -D -m 0644 "$root/LICENSE" "$destination/usr/share/doc/majestic-linux-runner/LICENSE"
  install -D -m 0644 "$root/packaging/majestic-linux.svg" \
    "$destination/usr/share/icons/hicolor/scalable/apps/majestic-linux.svg"

  mkdir -p "$destination/usr/lib/majestic-linux-runner"
  mkdir -p "$destination/usr/lib/majestic-linux-runner/python"
  cp -a "$root/majestic_linux" "$destination/usr/lib/majestic-linux-runner/python/"
  find "$destination/usr/lib/majestic-linux-runner/python" -type d -name __pycache__ \
    -prune -exec rm -rf -- {} +
  find "$destination/usr/lib/majestic-linux-runner/python" -type f -name '*.pyc' -delete
  cp -a "$root/packaging/asar/node_modules" "$destination/usr/lib/majestic-linux-runner/"

  cat > "$destination/usr/bin/asar" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
exec node /usr/lib/majestic-linux-runner/node_modules/@electron/asar/bin/asar.js "$@"
EOF
  chmod 0755 "$destination/usr/bin/asar"

  install -D -m 0644 "$root/packaging/io.github.isnotcursed.majestic-linux-runner.metainfo.xml" \
    "$destination/usr/share/metainfo/io.github.isnotcursed.majestic-linux-runner.metainfo.xml"

  cat > "$destination/usr/share/applications/io.github.isnotcursed.majestic-linux-runner.desktop" <<'EOF'
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
}
