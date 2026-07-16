---
name: flutter-pos-sync-plan
description: "Agreed plan (2026-07-16): connect the existing Flutter POS to the web's /api/sync contract for Foodics-style offline+cloud sync — implementation to start ~2026-07-16 evening from another device"
metadata: 
  node_type: memory
  type: project
  originSessionId: 71d65f73-1d3a-4971-9f33-059506b8ea6d
---

User decided NOT to build a new native POS — instead connect the existing Flutter app (this repo, /workspaces/Saas-POS, package `easycasher`) to the same cloud sync the web POS uses ([[offline-sync]]). Goal: Foodics parity — installable exe/APK Cashier + KDS + tablet that works offline and syncs.

Key findings (verified 2026-07-16):
- Flutter app is 100% local today: Drift/SQLite (`lib/core/database/app_database.dart`), dio in pubspec but **zero API calls, no auth, no sync code anywhere in lib/**.
- Feature modules already exist: auth, cashier, kitchen (KDS), tables, delivery, payment, reports, settings, menu, orders, locations. Windows/Android/iOS/Linux targets present.
- Server needs ZERO changes: `POST /api/sync` (easycasher-saas `api/app/Http/Controllers/SyncController.php`) is client-agnostic — idempotent upsert by client UUID, delta pull via `last_synced_at`, tombstones via withTrashed.

Agreed phases:
1. Login screen → Laravel Sanctum token, stored on device (first-time-online moment).
2. Initial pull → menu/categories/drivers/areas into Drift tables (replaces local-only menu entry).
3. Outbox → completed sales also written to a local sync queue with client UUIDs.
4. Sync service → same loop as web `dashboard/src/services/offline.ts`: push queue + last_synced_at, apply delta, 60s heartbeat, sync on reconnect.
5. Device-role mode switch (Cashier / KDS / Tablet) in one codebase.

**Why:** installed exe/APK avoids the PWA's fragility (cleared browser data wipes the IndexedDB queue); native app matches Foodics' commercial positioning.

**How to apply:** when the user returns (planned ~3h after 2026-07-16 session, possibly from another device), start with phases 1–2 against the current Flutter code; mirror the web client's sync semantics exactly (always-flush even with empty queue, server_time as next checkpoint, remove-only-applied from outbox).
