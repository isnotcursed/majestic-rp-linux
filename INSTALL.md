# Установка

Для ветки `6.3.4` поддерживается установка из исходников. Пакеты upstream могут
содержать другой код и не обязаны включать патч совместимости с Launcher 6.3.4.

## Требования

- Python 3.11 или новее;
- Steam и GTA V Legacy (AppID `271590`);
- рабочий Proton-префикс GTA V Legacy;
- свежий Proton и `protontricks`;
- CLI `asar` из `@electron/asar` в `PATH`;
- официальный `MajesticLauncherSetup.exe`.

Проверьте команды:

```bash
python3 --version
protontricks --version
asar --version
```

## Установка из исходников

```bash
git clone --branch 6.3.4 https://github.com/isnotcursed/majestic-rp-linux.git
cd majestic-rp-linux
chmod +x install-and-run-majestic-proton.sh
```

Выберите способ получения официального установщика:

```bash
./install-and-run-majestic-proton.sh setup
```

Интерактивное меню предлагает загрузку с официального CDN или выбор локального
файла. Для автоматизации используйте явный вариант:

```bash
./install-and-run-majestic-proton.sh setup --download

# или
./install-and-run-majestic-proton.sh setup \
  --installer "/абсолютный/путь/MajesticLauncherSetup.exe"
```

Меню создаёт `~/.config/majestic-runner/majestic-runner.conf` из безопасного
шаблона и записывает туда выбранный путь. Пути Steam, Proton, compatdata и GTA
обычно следует оставить пустыми для автоопределения.

## Первый запуск

Сначала один раз запустите GTA V Legacy через Steam. Затем выполните:

```bash
./install-and-run-majestic-proton.sh doctor
./install-and-run-majestic-proton.sh --dry-run install
./install-and-run-majestic-proton.sh install
./install-and-run-majestic-proton.sh run
```

Совместимость, ограничения и политика обновлений описаны в
[README.md](README.md).
