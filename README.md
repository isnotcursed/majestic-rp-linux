# Majestic RP Linux Runner — Launcher 6.3.4

Неофициальный Proton-раннер и патч совместимости для запуска **Majestic RP** с
**GTA V Legacy** на Linux. Ветка адаптирована под минифицированную структуру
Majestic Launcher 6.3.4.

> [!IMPORTANT]
> Для Majestic RP нужна GTA V Legacy (Steam AppID `271590`). GTA V Enhanced не
> поддерживается. Linux официально не поддерживается Majestic RP, Rockstar
> Games, Take-Two или Valve.

## Что изменено в этой версии

- добавлена совместимость с кодом выбора GTA в Launcher 6.3.4;
- отключено автообновление лаунчера, чтобы оно не заменяло пропатченный
  `app.asar`;
- перед изменением сохраняется оригинальный `app.asar.bak`;
- патч идемпотентен: повторный запуск не дублирует вставленный код;
- конфиг правильно читает пути и названия устройств с пробелами;
- добавлен интерактивный выбор официального установщика через shell-скрипт;
- удалены сторонний repacked-установщик, Discord bridge, sidecar runner,
  загрузка шрифта, экспериментальный Steam Overlay и автоматический repair GTA.

Репозиторий не содержит GTA V, Proton, Rockstar Games Launcher, Majestic
Launcher или клиентские файлы Majestic.

## Требования

- Python 3.11 или новее;
- лицензионная GTA V Legacy в Steam;
- созданный Proton-префикс AppID `271590`;
- Proton Experimental или другая свежая версия Proton;
- `protontricks`;
- CLI `asar` из пакета `@electron/asar`, доступный через `PATH`;
- официальный `MajesticLauncherSetup.exe` — скрипт может скачать его сам.

Проверьте зависимости:

```bash
python3 --version
protontricks --version
asar --version
```

## Подготовка GTA V Legacy

1. Установите **Grand Theft Auto V Legacy**, а не Enhanced.
2. Выберите Proton Experimental в настройках совместимости Steam.
3. Один раз запустите игру через Steam и дождитесь завершения первичной
   настройки Rockstar Games Launcher. После создания
   `steamapps/compatdata/271590` можно закрыть лаунчер — проходить пролог не
   требуется.

## Установка раннера

### Готовые пакеты

На странице [Releases](https://github.com/isnotcursed/majestic-rp-linux/releases)
публикуются три варианта для `x86_64`:

- `.deb` — Debian, Ubuntu и производные;
- `.rpm` — Fedora, openSUSE и производные;
- `.AppImage` — переносимый вариант без установки Python и Node.js в систему.

Для каждого коммита ветки `6.3.4` эти же файлы доступны как временные
артефакты workflow **Build Packages** во вкладке Actions. Постоянный GitHub
Release создаётся при публикации тега `v*` и содержит общий `SHA256SUMS`.

После установки `.deb` или `.rpm` запустите `majestic-linux` из терминала либо
ярлык **Majestic RP Linux Runner**. Для AppImage:

```bash
chmod +x majestic-linux-runner-*.AppImage
./majestic-linux-runner-*.AppImage
```

При первом запуске откроется терминальное меню: скачать официальный установщик
Majestic либо выбрать локальный `.exe`. После выбора раннер сохраняет конфиг,
определяет Steam, GTA V Legacy, Proton и compatdata, затем выполняет обычную
команду `run`. При следующих запусках меню уже не показывается. Если
автоопределение не удалось, выполните `majestic-linux doctor` и исправьте
параметры в `~/.config/majestic-runner/majestic-runner.conf`.

`.deb` и `.rpm` используют системные Python и Node.js; AppImage содержит их
внутри. Steam, GTA V Legacy, Proton и `protontricks` ни в один пакет не входят.

### Из исходников

```bash
git clone --branch 6.3.4 https://github.com/isnotcursed/majestic-rp-linux.git
cd majestic-rp-linux
chmod +x install-and-run-majestic-proton.sh
```

Запустите настройку установщика:

```bash
./install-and-run-majestic-proton.sh setup
```

Скрипт предложит:

1. скачать установщик с официального CDN Majestic;
2. выбрать уже скачанный локальный `MajesticLauncherSetup.exe`;
3. отменить настройку.

После скачивания проверяются размер и PE-заголовок файла, выводится SHA-256, а
путь безопасно записывается в `~/.config/majestic-runner/majestic-runner.conf`.

Для неинтерактивного запуска выбор всегда должен быть явным:

```bash
./install-and-run-majestic-proton.sh setup --download

# или
./install-and-run-majestic-proton.sh setup \
  --installer "/путь/к/MajesticLauncherSetup.exe"
```

Steam, GTA, compatdata и Proton определяются автоматически. Указывайте эти пути
в конфиге вручную только тогда, когда `doctor` не смог их найти.

## Проверка перед установкой

```bash
./install-and-run-majestic-proton.sh doctor
./install-and-run-majestic-proton.sh --dry-run install
```

Проверьте найденные пути GTA, Proton, compatdata и установщика.

## Установка и запуск

```bash
./install-and-run-majestic-proton.sh install
./install-and-run-majestic-proton.sh run
```

Первый запуск подготавливает существующий Proton-префикс GTA V Legacy,
запускает официальный установщик, устанавливает необходимые Wine-компоненты,
патчит `app.asar` и сохраняет оригинал как `app.asar.bak`.

Диагностические команды:

```bash
./install-and-run-majestic-proton.sh detect
./install-and-run-majestic-proton.sh env
./install-and-run-majestic-proton.sh doctor
./install-and-run-majestic-proton.sh analyze-crash
```

## Обновления Majestic Launcher

Автообновление лаунчера намеренно отключено. Новая версия может изменить имена
минифицированных переменных и структуру кода, поэтому старый патч может стать
небезопасным.

После выхода новой версии:

1. сохраните существующий `app.asar.bak`;
2. не применяйте старый патч принудительно;
3. обновите синтетические тесты совместимости;
4. проверьте распаковку, патч, сборку, синтаксис JavaScript и идемпотентность;
5. только после этого меняйте заявленную поддерживаемую версию.

## Разработка и тесты

```bash
bash -n install-and-run-majestic-proton.sh packaging/*.sh
python3 -m compileall -q majestic_linux
python3 -m unittest discover -s tests -v
git diff --check
```

Тесты используют небольшие синтетические JS-фрагменты. Не добавляйте в Git
бинарники Majestic, содержимое распакованного `app.asar`, игровые файлы, логи,
токены или данные аккаунтов.

## Известные ограничения

- В этой ветке проверен только Launcher 6.3.4.
- Основная поддерживаемая конфигурация — Steam и GTA V Legacy.
- Обновление лаунчера или клиента Majestic может снова нарушить совместимость.
- На драйверах NVIDIA серии 615 встречалось повреждение CEF/UI через несколько
  минут. GPU-ускорение отключено по умолчанию как возможное смягчение проблемы,
  но это не гарантированное исправление.
- Обычный GTA Online остаётся ограничен поддержкой BattlEye на Linux.

## Авторы и лицензия

Проект основан на открытом раннере
[digitalhorizongroup/majestic-rp-linux](https://github.com/digitalhorizongroup/majestic-rp-linux)
и распространяется по лицензии MIT из этого репозитория.
