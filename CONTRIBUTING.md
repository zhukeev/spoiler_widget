# Contributing

Thanks for helping improve `spoiler_widget`!

## Setup

1. Install Flutter (or use FVM).
2. Run `scripts/setup_hooks.sh` to enable git hooks.
3. Run `flutter pub get`.

## Development workflow

- Format: `dart format .`
- Analyze: `flutter analyze` and `flutter analyze` inside `example/`
- Tests: `flutter test` and `flutter test test/golden_test.dart`

## Release checks

Use `scripts/release_check.sh` to run format, analyze, tests, goldens, and
`dart pub publish --dry-run` in one go.
