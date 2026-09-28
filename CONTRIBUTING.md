# Contributing to satr

Thanks for considering a contribution! satr is a minimalist, offline-first
journaling app — contributions that keep it calm, simple, and privacy-first
are especially welcome.

## Getting Started

1. Fork and clone the repo
2. Install dependencies:
```bash
   flutter pub get
```
3. Generate Hive adapters (required after cloning, and after editing any
   `@HiveType`/`@HiveField` model):
```bash
   dart run build_runner build --delete-conflicting-outputs
```
4. Run the app:
```bash
   flutter run
```

## Project Structure

satr follows a feature-first layout:

lib/
core/ # shared constants, theme, utilities, widgets
features/
<feature>/
data/ # models, repositories
application/ # Riverpod providers
presentation/ # screens, widgets


New code should follow this pattern — put a new feature's model, repository,
providers, and screens under its own `lib/features/<name>/` folder rather
than mixing concerns into existing folders.

## Tech Stack

- **State management:** Riverpod
- **Local storage:** Hive
- **Secure storage:** flutter_secure_storage (PIN only)

Please don't introduce a different state management or storage approach in
a PR — open an issue first if you think one is genuinely needed.

## Code Style

- Run `flutter analyze` before submitting — this repo uses
  `flutter_lints` and CI-equivalent checks should pass locally.
- Avoid hardcoded colors/spacing — use the tokens in
  `lib/core/theme/app_theme.dart` and `lib/core/constants/app_constants.dart`.
- Keep UI logic separate from business logic (widgets shouldn't talk to Hive
  or secure storage directly — go through a repository/provider).
- Comment non-obvious logic, especially around RTL/text-direction handling.

## Submitting a Pull Request

1. Keep PRs small and focused — one feature or fix per PR.
2. Use [Conventional Commits](https://www.conventionalcommits.org/) for
   commit messages (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`).
3. Describe what changed and why in the PR description. Screenshots/GIFs
   are appreciated for any UI change.
4. Link the issue your PR addresses, if there is one.

## Reporting Bugs / Suggesting Features

Open an issue and include:
- What you expected vs. what happened (for bugs)
- Steps to reproduce, if applicable
- Screenshots, if it's visual

## Design Philosophy

Before proposing a new feature, it's worth checking it fits satr's intent:
calm, minimal, offline-first, no accounts, no analytics. Feature requests
that add cloud sync, ads, or heavy UI dependencies are unlikely to be
accepted — but feel free to open an issue to discuss first.