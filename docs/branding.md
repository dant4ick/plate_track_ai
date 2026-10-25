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

Команды проекта выполняются в существующем Podman-контейнере `plate-dev`.
Для Python-генератора нужен CairoSVG; он не является runtime-зависимостью
приложения. В текущем контейнере установлен пакет `python3-cairosvg`.

```bash
podman exec --user "$(id -u)" -w "$PWD" plate-dev \
  python3 tool/branding/generate_logos.py
podman exec --user "$(id -u)" -w "$PWD" plate-dev \
  /home/dant4ick/development/flutter/bin/dart run flutter_launcher_icons
```

Генератор разделяет экспорт на три SVG по границам плашек, сохраняя значения
`d` и `fill` каждого path без изменений. Из синего варианта создаёт:

- `assets/icons/app_icon_color.png` — основной непрозрачный PNG 1024×1024,
  с синим фоном до краёв; форму иконки задаёт ОС;
- `assets/icons/app_icon_foreground.png` — лаймовый знак на прозрачном фоне
  для adaptive icon.

`flutter_launcher_icons` создаёт Android legacy-иконки пяти плотностей,
adaptive foreground и XML с постоянным синим фоном. Отступ adaptive foreground
задан явно (16%), чтобы знак помещался в безопасную область системных масок.
В репозитории нет iOS-проекта; генерация для iOS отключена, основной PNG
можно использовать при добавлении этой платформы.

## Проверка и превью

```bash
podman exec --user "$(id -u)" -e LOGO_PREVIEW=1 -w "$PWD" plate-dev \
  /home/dant4ick/development/flutter/bin/flutter test \
  test/widgets/app_logo_test.dart test/design/logo_preview_test.dart
```

Превью настоящего Flutter-рендера: `build/previews/designer-logos.png`.
Оно показывает три темы и размеры 224, 80, 34 и 30 px. Тесты проверяют выбор
варианта, переключение темы без перекраски, точное сохранение исходных путей
и цветов, а также пиксели реального Flutter-рендера.
