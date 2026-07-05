# Kitchen Wish Well App

Flutter app skeleton following `架构.md`.

## Structure

- `lib/core`: config, constants, errors, network, router, storage, theme, utilities
- `lib/shared`: shared widgets, models, extensions
- `lib/features`: feature-first modules with `data`, `domain`, and `presentation` layers

## Development
chrome  启动命令
```
flutter run -d chrome --web-port=8080 --dart-define-from-file=config/test.env
````

```bash
flutter pub get
flutter run --dart-define-from-file=config/test.env
```

## Environments

Environment files:

- `config/test.env`
- `config/production.env`

Run on the iPhone 17 simulator with the test environment:

```bash
open -a Simulator
flutter run -d 1A384499-2531-4CFE-80E7-DF5C7A2D6450 --dart-define-from-file=config/test.env
```

Build iOS packages:

```bash
flutter build ios --release --dart-define-from-file=config/test.env
flutter build ios --release --dart-define-from-file=config/production.env
```

This folder is a framework skeleton only. Business pages and feature logic are intentionally not implemented yet.
