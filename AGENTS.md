# Repository Guidelines

## Project Structure & Module Organization

This repository contains the Flutter application **粮知**. Application code lives in `lib/`; `lib/main.dart` is the current entry point. Widget and unit tests belong in `test/` and should mirror the source layout where practical. Native platform projects are under `android/` and `ios/`; edit them only for platform-specific configuration or integrations. Product requirements are documented in `memory_bank/prd.md`. Generated directories such as `.dart_tool/` and `build/` must not be committed.

No application asset directory is configured yet. When adding images, fonts, or other bundled resources, place them under a clear path such as `assets/images/` and declare them in `pubspec.yaml`.

## Build, Test, and Development Commands

- `flutter pub get` installs dependencies from `pubspec.lock`.
- `flutter run` launches the app on a connected device or emulator.
- `flutter analyze` checks Dart code against `analysis_options.yaml` and `flutter_lints`.
- `flutter test` runs all tests under `test/`.
- `dart format .` formats Dart sources using the standard formatter.
- `flutter build apk` or `flutter build ios` creates release artifacts for the relevant platform.

Run analysis and tests before opening a pull request.

## Coding Style & Naming Conventions

Use two-space indentation and let `dart format` control line wrapping. Follow Dart conventions: `UpperCamelCase` for types and widgets, `lowerCamelCase` for variables and methods, and `snake_case.dart` for filenames. Prefer small, composable widgets and `const` constructors when values are immutable. Keep platform-neutral logic in `lib/`, not inside native project folders.

## Testing Guidelines

Tests use Flutter's `flutter_test` framework. Name files with the `_test.dart` suffix, for example `test/home_page_test.dart`. Group related behavior and use descriptive test names. Add widget tests for rendering and interaction changes, and unit tests for extracted business logic. There is no enforced coverage threshold, but new behavior and bug fixes should include focused regression coverage.

## Commit & Pull Request Guidelines

Use the repository's established format: `<type>(<scope>): <subject>`, for example `feat(学习计划): 新增每日任务列表`. Common types include `feat`, `fix`, `test`, `docs`, `refactor`, and `chore`. Keep commits focused and subjects concise.

Do not push directly to `main` or `master`; use a development branch and pull request. PRs should explain the purpose and key changes, link relevant issues, list verification commands, and include screenshots or recordings for visible UI changes. Resolve conflicts locally and request at least one review before merging.

## Agent-Specific Instructions

These rules apply before and after agent-driven implementation work:

- Always read `memory_bank/architecture.md` in full before writing any code. The document must include the entire database schema.
- Always read `memory_bank/prd.md` in full before writing any code.
- After adding a major feature or completing a milestone, update `memory_bank/architecture.md`.
