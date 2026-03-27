# Agent contract — Focus & Mindfulness MVP

## Firebase client config (Dart)

- **`lib/firebase_options.dart`** reads **`assets/env/firebase.env`** (loaded in `main.dart` via `flutter_dotenv`). On **web**, `main.dart` passes **`env/firebase.env`** to `dotenv.load` so the engine does not request `assets/assets/...`. **Commit `assets/env/firebase.env.example`; never commit `assets/env/firebase.env`.** (Root `.env` is unused but still gitignored if present.)
- **Android** still needs [`android/app/google-services.json`](android/app/google-services.json) from the Firebase console (or `flutterfire configure`); keep it out of public repos if your policy requires, and inject it in CI from secrets.
- **iOS/macOS** need `GoogleService-Info.plist` in `ios/Runner` (and macOS target) when you add those platforms — same rule: local/CI secret, not necessarily committed.
- Client API keys **are embedded in the shipped app** (including packaged `firebase.env`). **Security = Firestore/Storage Security Rules + optional App Check**, not hiding keys.

## Layout (`lib/`)

- `core/` — theme, routing, shared utilities
- `features/<feature>/` — `data/`, `domain/` (when needed), `presentation/` (includes `focus_practice/`, `profile/`)
- `widgets/` — shell and shared UI (`WarmCard`, etc.)

## Firestore paths (single source of truth)

| Collection        | Document fields (high level)                          |
| ----------------- | ------------------------------------------------------- |
| `users/{uid}`     | `email`, `createdAt`                                    |
| `sessions/{id}`   | `userId`, `type`, `duration`, `createdAt`, `meditationId?` |
| `mood_entries/{id}` | `userId`, `sessionId`, `moodBefore`, `moodAfter`, `note?`, `createdAt` |
| `meditations/{id}` | catalog metadata; `audioUrl` → Storage or CDN       |

### Firebase Storage — meditation audio

- **Object prefix:** `meditations/{meditationId}/` — use the same string as the Firestore doc id in `meditations/{id}`.
- **Recommended object name:** `audio.m4a` or `audio.mp3` (single file per doc).
- **Full path example:** `meditations/morning_grounding_5m/audio.m4a`
- **`audioUrl` in Firestore:** HTTPS download URL from `getDownloadURL` after upload (or your CDN). Seed file uses placeholders until upload.
- **Local drop folder (repo):** `firebase/storage/meditations/<meditationId>/` — optional; for files before `firebase storage:upload` / Console upload.

## Do not break (Phase 1+)

- **Auth:** `AuthService.signInWithEmail`, `signUpWithEmail`, `signOut`; `authStateProvider` stream.
- **Routing:** Shell tab order matches `app_router.dart` branches (**Home** → **Meditations** → **Breathing** `/focus` = timer + breathing tabs → **Profile** `/profile` = progress + account). Redirects: `/timer` and `/breathing` → `/focus`; `/progress` → `/profile`. Protected routes rely on `GoRouter` redirect + Firebase Auth.
- **On register:** create `users/{uid}` with `email` + `createdAt` (server timestamp).
- **Sessions:** `SessionRepository` — `logFocusSession` / `logMeditationSession` / `logBreathingSession` return **`Future<String>`** (new doc id); `watchSessions`; `duration` in **seconds**; `type` values under **Sessions (`sessions` types)** below.
- **Meditations:** `meditationRepositoryProvider`, `MeditationsScreen` → `/meditation/:id` player; Firestore field names above.

## Session duration unit

`sessions.duration` is stored as **integer seconds** (focus work length logged on work-phase completion). Clients and Firestore rules should treat it as seconds only.

## Phase 1 definition of done

Email/password sign up, sign in, sign out; unauthenticated users redirected to login; authenticated shell with five tabs; Firestore user profile doc on registration (rules must allow user to write own `users/{uid}`).

## Phase 2 definition of done

Focus timer: idle / running / pause; work then short break; defaults 25 / 5 minutes (configurable when idle); on work completion writes `sessions` with `type: focus` and `duration` (seconds); deadline persisted locally for resume; phase-end local notification (Android + iOS where supported); soundscape via `just_audio` (streamed preview URL — replace with bundled assets for offline); wakelock while a phase is actively running.

## Meditation model (`meditations/{id}`)

- **Fields:** `title` (string), `duration` (int, **seconds**), `category` (string), `audioUrl` (HTTPS URL from Storage or CDN).
- **Client:** `Meditation`, `MeditationRepository.watchCatalog`, `getById`; player route `/meditation/:id`.

## Phase 3 definition of done

Authenticated users see a Firestore-backed list with category filter chips; tapping an item opens the player with `just_audio` (play/pause, seek slider, position/duration). Seed data: `firebase/seed/meditations.json` — import each object as a document with matching **document id** (`id` field); you may strip the `id` key from stored fields or duplicate it for convenience.

## Sessions (`sessions` types)

- `type: 'focus'` — focus timer work phase completion; `duration` seconds (see above).
- `type: 'meditation'` — track reaches end (metadata duration) or user exits after ≥15s of playback (`position` seconds); `meditationId` set.
- `type: 'breathing'` — user stopped Breathing after ≥15s active time; `duration` seconds.

## Mood (`mood_entries`)

- Fields: `userId`, optional `sessionId`, `moodBefore` / `moodAfter` (int 1–5), optional `note`, `createdAt`.
- `MoodRepository`, `showMoodCheckInSheet`; Profile tab shows streak, weekly stacked chart, and mood trend (`ProgressOverviewContent`).
- After **focus** work phase, **meditation** log, or **breathing** log, the app opens the mood sheet with `sessionId` set when the user may still link `mood_entries` to that `sessions/{id}` doc. Focus uses `pendingFocusSessionMoodProvider` + `rootNavigatorKey` (see `main.dart` / `app_router.dart`).

## Phase 4 definition of done

Breathing: at least two presets, wall-clock phase sequence + ring animation, optional phase ticks; optional `sessions` log on stop after ≥15s (`type: 'breathing'`).

## Phase 5 definition of done

Progress: streak from session days; last-7-days stacked bar (focus vs mindfulness); sessions via `SessionRepository.watchSessions`. Mood: log sheet + recent list + 7-day average trend. Meditation and breathing log valid session types as above.

## Phase 6 (ongoing polish)

- Pure Dart tests: timer math, progress math (streak + weekly aggregation), breathing phase tests.
- UI: retry on Firestore list failures where surfaced; mood sheet shows SnackBar on write errors.

## Firebase setup

Replace placeholder config: run `dart pub global activate flutterfire_cli` then `flutterfire configure`. Swap `android/app/google-services.json` and iOS `GoogleService-Info.plist` with project files from the Firebase console.

If the console reports a missing index for `sessions` or `mood_entries` queries (`userId` + `createdAt`), create the suggested composite index linked from the error.
