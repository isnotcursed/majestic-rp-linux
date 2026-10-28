#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OFFICIAL_INSTALLER_URL="https://cdn.majestic-files.net/launcher/cis/MajesticLauncherSetup.exe"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
CONFIG_PATH="$CONFIG_HOME/majestic-runner/majestic-runner.conf"
CACHE_INSTALLER="$CACHE_HOME/majestic-runner/MajesticLauncherSetup.exe"
CONFIG_TEMPLATE="$SCRIPT_DIR/examples/majestic-runner.example.conf"

if [[ ! -f "$CONFIG_TEMPLATE" ]]; then
  CONFIG_TEMPLATE="$SCRIPT_DIR/../share/doc/majestic-linux-runner/majestic-runner.example.conf"
fi

SYSTEM_PYTHONPATH="$SCRIPT_DIR/../lib/majestic-linux-runner/python"
if [[ -d "$SYSTEM_PYTHONPATH/majestic_linux" ]]; then
  export PYTHONPATH="$SYSTEM_PYTHONPATH${PYTHONPATH:+:$PYTHONPATH}"
fi

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
  [[ -f "$CONFIG_TEMPLATE" ]] || die "не найден шаблон конфига: $CONFIG_TEMPLATE"
  mkdir -p -- "$(dirname -- "$CONFIG_PATH")"
  cp -- "$CONFIG_TEMPLATE" "$CONFIG_PATH"
  printf 'Создан конфиг: %s\n' "$CONFIG_PATH"
}

save_installer_path() {
  local installer_path="$1"
  [[ "$installer_path" != *$'\n'* && "$installer_path" != *'"'* ]] || \
    die "путь к установщику содержит неподдерживаемые символы"
  ensure_config
  local temporary_config found_url=0 found_path=0 line
  temporary_config="$(mktemp "$(dirname -- "$CONFIG_PATH")/.majestic-runner.conf.XXXXXX")"
  trap 'rm -f -- "$temporary_config"' RETURN
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      MAJESTIC_INSTALLER_URL=*)
        printf 'MAJESTIC_INSTALLER_URL=\n' >> "$temporary_config"
        found_url=1
        ;;
      MAJESTIC_INSTALLER_PATH=*)
        printf 'MAJESTIC_INSTALLER_PATH="%s"\n' "$installer_path" >> "$temporary_config"
        found_path=1
        ;;
      *) printf '%s\n' "$line" >> "$temporary_config" ;;
    esac
  done < "$CONFIG_PATH"
  [[ "$found_url" -eq 1 ]] || printf 'MAJESTIC_INSTALLER_URL=\n' >> "$temporary_config"
  [[ "$found_path" -eq 1 ]] || printf 'MAJESTIC_INSTALLER_PATH="%s"\n' "$installer_path" >> "$temporary_config"
  mv -- "$temporary_config" "$CONFIG_PATH"
  trap - RETURN
  printf 'Настроен официальный установщик: %s\n' "$installer_path"
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
  if [[ ! -f "$CONFIG_PATH" ]]; then
    setup_installer
  fi
  if [[ -n "${MAJESTIC_RUNNER_BIN:-}" ]]; then
    exec "$MAJESTIC_RUNNER_BIN" run
  fi
  exec python3 -m majestic_linux run
fi

if [[ -n "${MAJESTIC_RUNNER_BIN:-}" ]]; then
  exec "$MAJESTIC_RUNNER_BIN" "$@"
fi
exec python3 -m majestic_linux "$@"
