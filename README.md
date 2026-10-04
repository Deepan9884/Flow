# Flow — Focus-oriented Todo App

A Flutter task manager built with **Riverpod** (state), **Isar** (local database),
and **Freezed** (models). Tasks support priorities, categories, subtasks,
wallpapers, custom sounds, reminders, recurrence, calendar + kanban views,
dark mode, and JSON backup.

## Prerequisites

- Flutter 3.19.x stable
- Java 17 (for the Android build)

## Run

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Verify

```bash
flutter analyze
flutter test
```

## Build a release APK

```bash
flutter build apk --release
# output: build/app/outputs/flutter-apk/app-release.apk
```

CI (`.github/workflows/build-apk.yml`) runs codegen, analyze, tests,
launcher icons, and uploads the release APK on every push to `main`.

> The `android/` folder intentionally contains only the hand-written
> `AndroidManifest.xml` (notification receivers, FileProvider) and
> `file_paths.xml`. CI regenerates the rest with
> `flutter create --platforms=android --project-name=flow_todo .`,
> which never overwrites those two files.

## Architecture

```
lib/
├── main.dart            # init order: Isar -> notifications -> app
├── app.dart             # Material 3 theme (light/dark from ThemeConfig)
├── main_shell.dart      # bottom-tab IndexedStack shell
├── core/
│   ├── db/              # Isar singleton + seed
│   └── theme/           # ThemeConfig model + notifier
├── features/
│   ├── tasks/           # models, providers, screens, utils
│   ├── categories/      # model + provider
│   ├── calendar/        # TableCalendar view (due dates + reminders)
│   ├── settings/        # theme, notifications, JSON backup, about
│   └── profile/         # static profile (auth planned)
├── services/            # notifications, media import, backup
└── widgets/             # banner card, tilt banner, wallpaper tile
test/                    # unit tests (sort order, recurrence)
```

Data flow: UI → `taskListProvider` / `categoryListProvider` / `themeProvider`
→ Isar write → reload + sort → rebuild. Notification scheduling is
best-effort and always runs *after* the state refresh, gated by the
`notificationsEnabled` setting.

## Feature status

| Area | Status |
|---|---|
| Tasks, subtasks, priorities, categories | Done |
| Due dates, reminders, custom sounds | Done |
| Recurrence (daily/weekly/monthly spawns next) | Done |
| Kanban drag-between-columns | Done |
| Calendar (due + reminder markers) | Done |
| Dark mode (all screens) | Done |
| Notifications kill-switch | Done |
| JSON export / import | Done |
| Release signing | Optional via repo secrets (else debug-signed) |

## Release signing (optional)

Without secrets, CI ships a debug-signed APK. For a Play-ready signature,
add these repository secrets, and CI will sign automatically:

| Secret | Content |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | keystore password |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key password |
| Cloud sync, collaboration, widgets | Planned |

## Contributing

Keep PRs small, run `flutter analyze` + `flutter test` before pushing,
and never commit `*.freezed.dart` / `*.g.dart` (CI generates them).
