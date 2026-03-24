# Code Style & Conventions

- Dart with Flutter conventions
- Private fields prefixed with `_`
- StatefulWidget pattern with separate State class
- Services as singletons using factory + _internal pattern
- Localization: `'key'.tr()` from easy_localization
- Translations in `assets/translations/en.json` and `ru.json`
- Widgets use Material Design with rounded corners (12-16px radius)
- Colors from Theme.of(context).colorScheme
- Hive for local persistence with manual adapters
- Models extend Equatable
