#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OFFICIAL_INSTALLER_URL="https://cdn.majestic-files.net/launcher/cis/MajesticLauncherSetup.exe"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CONFIG_PATH="$CONFIG_HOME/majestic-runner/majestic-runner.conf"
CACHE_INSTALLER="$CACHE_HOME/majestic-runner/MajesticLauncherSetup.exe"

cd "$SCRIPT_DIR"

die() {
  printf 'Ошибка: %s\n' "$*" >&2
  exit 1
}

validate_installer() {
  local installer_path="$1"
  [[ -f "$installer_path" ]] || die "установщик не найден: $installer_path"

  local installer_size installer_magic
  installer_size="$(wc -c < "$installer_path")"
  [[ "$installer_size" -ge 1048576 ]] || die "установщик имеет подозрительно маленький размер: $installer_path"
  installer_magic="$(od -An -tx1 -N2 "$installer_path" | tr -d '[:space:]')"
  [[ "$installer_magic" == "4d5a" ]] || die "файл не является Windows PE: $installer_path"
}

ensure_config() {
  if [[ -f "$CONFIG_PATH" ]]; then
    return
  fi
  mkdir -p -- "$(dirname -- "$CONFIG_PATH")"
  cp -- "$SCRIPT_DIR/examples/majestic-runner.example.conf" "$CONFIG_PATH"
  printf 'Создан конфиг: %s\n' "$CONFIG_PATH"
}

save_installer_path() {
  local installer_path="$1"
  ensure_config
  BOOTSTRAP_CONFIG_PATH="$CONFIG_PATH" \
  BOOTSTRAP_INSTALLER_PATH="$installer_path" \
  python3 - <<'PY'
import os
from pathlib import Path

config_path = Path(os.environ["BOOTSTRAP_CONFIG_PATH"])
installer_path = Path(os.environ["BOOTSTRAP_INSTALLER_PATH"]).resolve()
replacements = {
    "MAJESTIC_INSTALLER_URL": "",
    "MAJESTIC_INSTALLER_PATH": f'"{installer_path}"',
}
lines = config_path.read_text(encoding="utf-8").splitlines()
seen = set()
result = []
for line in lines:
    key = line.split("=", 1)[0].strip() if "=" in line else ""
    if key in replacements:
        result.append(f"{key}={replacements[key]}")
        seen.add(key)
    else:
        result.append(line)
for key, value in replacements.items():
    if key not in seen:
        result.append(f"{key}={value}")
temporary = config_path.with_name(config_path.name + ".tmp")
temporary.write_text("\n".join(result) + "\n", encoding="utf-8")
temporary.replace(config_path)
print(f"Настроен официальный установщик: {installer_path}")
PY
}

download_official_installer() {
  local target_dir temporary_file
  target_dir="$(dirname -- "$CACHE_INSTALLER")"
  mkdir -p -- "$target_dir"
  temporary_file="$(mktemp "$target_dir/.MajesticLauncherSetup.exe.XXXXXX")"
  trap 'rm -f -- "$temporary_file"' RETURN

  printf 'Загрузка официального установщика:\n%s\n' "$OFFICIAL_INSTALLER_URL"
  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --proto '=https' --tlsv1.2 \
      --output "$temporary_file" "$OFFICIAL_INSTALLER_URL"
  elif command -v wget >/dev/null 2>&1; then
    wget --https-only --output-document="$temporary_file" "$OFFICIAL_INSTALLER_URL"
  else
    die "для автоматической загрузки нужен curl или wget"
  fi

  validate_installer "$temporary_file"
  mv -- "$temporary_file" "$CACHE_INSTALLER"
  trap - RETURN
  printf 'Сохранено: %s\n' "$CACHE_INSTALLER"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$CACHE_INSTALLER"
  fi
  save_installer_path "$CACHE_INSTALLER"
}

use_local_installer() {
  local installer_path="$1"
  [[ -n "$installer_path" ]] || die "путь к установщику не может быть пустым"
  if command -v realpath >/dev/null 2>&1; then
    installer_path="$(realpath -- "$installer_path")"
  fi
  validate_installer "$installer_path"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$installer_path"
  fi
  save_installer_path "$installer_path"
}

print_setup_help() {
  cat <<'EOF'
Использование:
  ./install-and-run-majestic-proton.sh setup
  ./install-and-run-majestic-proton.sh setup --download
  ./install-and-run-majestic-proton.sh setup --installer /path/to/MajesticLauncherSetup.exe

Интерактивная настройка предлагает скачать установщик с официального CDN
Majestic или выбрать существующий локальный файл. В неинтерактивном режиме
нужно явно указать --download или --installer.
EOF
}

setup_installer() {
  case "${1:-}" in
    --download)
      [[ $# -eq 1 ]] || die "--download не принимает дополнительные аргументы"
      download_official_installer
      ;;
    --installer)
      [[ $# -eq 2 ]] || die "для --installer требуется ровно один путь"
      use_local_installer "$2"
      ;;
    --help|-h)
      print_setup_help
      ;;
    "")
      [[ -t 0 ]] || die "для интерактивной настройки нужен терминал; используйте --download или --installer"
      printf '%s\n' \
        'Настройка установщика Majestic Launcher:' \
        '  1) Скачать с официального CDN Majestic' \
        '  2) Выбрать существующий локальный установщик' \
        '  3) Отмена'
      read -r -p 'Выберите [1-3]: ' choice
      case "$choice" in
        1) download_official_installer ;;
        2)
          read -r -p 'Путь к MajesticLauncherSetup.exe: ' installer_path
          use_local_installer "$installer_path"
          ;;
        3) exit 0 ;;
        *) die "неверный выбор: $choice" ;;
      esac
      ;;
    *)
      die "неизвестный параметр setup: $1"
      ;;
  esac
}

if [[ "${1:-}" == "setup" ]]; then
  shift
  setup_installer "$@"
  exit 0
fi

if [[ $# -eq 0 ]]; then
  exec python3 -m majestic_linux run
fi

exec python3 -m majestic_linux "$@"
