# EasyCasher POS — the till

The Flutter Windows point-of-sale terminal of the EasyCasher restaurant SaaS.
Offline-first: sells, prints, runs the kitchen board and cash shifts with no
internet, and syncs to the cloud when connected.

> 📖 **Start here: [docs/PROJECT_NOTES.md](docs/PROJECT_NOTES.md)** — the full
> system picture, settled design decisions, current state, and open work.
> That document is the project's memory; read it before changing anything.

## The system at a glance

| Piece | Repo | Who uses it |
|---|---|---|
| **This till** (Flutter, Windows) | `Saas-POS` | Cashiers & kitchen, in the restaurant |
| Web console + API (Vue + Laravel) | `easycasher-saas` | Restaurant owners; our super-admin |
| Legacy client (do not develop) | `easycasher` | — |

## Quick commands

```bash
flutter analyze          # must stay clean
flutter test             # must stay green
flutter run -d windows   # run the till (debug)
flutter build windows --release
# → ship the whole build/windows/x64/runner/Release/ folder (portable, no installer)
```

## Two things you must never do

1. Reintroduce a destructive database migration (`onUpgrade` must stay additive —
   the local DB holds unsynced sales).
2. Commit `.claude/` or any credentials — the gitignore blocks it for a reason.
