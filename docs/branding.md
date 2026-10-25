# Логотипы

Источник — неизменённый SVG-экспорт трёх вариантов из Figma:
`tool/branding/designer_logos.svg`. Более ранний квадратный SVG не используется.

| Вариант | Фон | Знак | Где используется |
| --- | --- | --- | --- |
| Основной | `#4D55F5` | `#DAFF7C` | Иконка приложения, тёмная тема |
| Светлый | `#B0DD4E` | `#FFFFFF` | Светлая тема |
| Pick me | `#FF7AB5` | `#F9D9DA` | Розовая тема |

`AppLogoMark` выбирает готовый SVG по `AppPalette.flavor`. Плашка, скругления,
знак и отступы уже находятся в SVG: не добавляйте inset, отдельный фон или
`colorFilter`. Эти брендовые пары не связаны с цветами кнопок и текста.
Логотип с названием в AppBar и логотип загрузки используют этот виджет.
`AppLogo` остаётся монохромным знаком для явных запросов перекраски; его контуры
также взяты из нового экспорта, без старого дополнительного центрального кольца.

## Генерация

Команды проекта выполняются внутри существующего Podman-окружения разработки.
Укажите имя своего контейнера (в локальной конфигурации — `plate-dev`). Репозиторий
должен быть доступен в контейнере по тому же пути, что и на хосте; иначе замените
`-w "$PWD"` на путь репозитория внутри контейнера. Выполняйте команды от своего
UID, а не от root.

```bash
PROJECT_CONTAINER=plate-dev
podman exec --user "$(id -u)" -w "$PWD" -it "$PROJECT_CONTAINER" bash
```

Далее — внутри контейнера. Путь SDK берётся из локального, не коммитящегося
`android/local.properties`, который создаётся при настройке Flutter/Android:

```bash
FLUTTER_SDK="$(python3 -c 'from pathlib import Path; print(dict(line.split("=", 1) for line in Path("android/local.properties").read_text().splitlines() if "=" in line)["flutter.sdk"])')"
export PATH="$FLUTTER_SDK/bin:$PATH"
python3 tool/branding/generate_logos.py
dart run flutter_launcher_icons
```

Для Python-генератора нужен CairoSVG (например, пакет `python3-cairosvg`
в Debian/Ubuntu-контейнере); он не является runtime-зависимостью приложения.

Генератор разделяет экспорт на три SVG по границам плашек, сохраняя значения
`d` и `fill` каждого path без изменений. Из синего варианта создаёт:

- `assets/icons/app_icon_color.png` — основной непрозрачный PNG 1024×1024,
  с синим фоном до краёв; форму иконки задаёт ОС;
- `assets/icons/app_icon_foreground.png` — лаймовый знак на прозрачном фоне
  для adaptive icon.

PNG-мастера остаются в Git для генерации native-ресурсов, но не включены во
Flutter bundle: в `pubspec.yaml` явно перечислены только используемые SVG.

`flutter_launcher_icons` создаёт Android legacy-иконки пяти плотностей,
adaptive foreground и XML с постоянным синим фоном. Отступ adaptive foreground
задан явно (16%), чтобы знак помещался в безопасную область системных масок.
В репозитории нет iOS-проекта; генерация для iOS отключена, основной PNG
можно использовать при добавлении этой платформы.

## Проверка и превью

Запустите в том же контейнере с настроенным PATH:

```bash
LOGO_PREVIEW=1 flutter test \
  test/widgets/app_logo_test.dart test/design/logo_preview_test.dart
```

Превью настоящего Flutter-рендера: `build/previews/designer-logos.png`.
Оно показывает три темы и размеры 224, 80, 34 и 30 px. Тесты проверяют выбор
варианта, переключение темы без перекраски, точное сохранение исходных путей
и цветов, а также пиксели реального Flutter-рендера.
