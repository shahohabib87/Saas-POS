---
name: project-overview
description: "EasyCasher — Flutter POS system with delivery, kitchen display, cashier, and reporting features"
metadata: 
  node_type: memory
  type: project
  originSessionId: 02ddbef3-f0ab-4f03-8a9b-ddd3bc451b26
---

EasyCasher is a Flutter POS (Point of Sale) application targeting restaurant/food-service businesses. It supports Kurdish, Arabic, and English (multi-language from the start). The app name and package are `easycasher`.

**Why:** Built as a full-featured POS supporting offline-first use with a local SQLite database (Drift ORM), real-time order updates via WebSocket (KDS/kitchen display), and receipt printing.

**How to apply:** Treat this as a production Flutter app — feature flags, platform targets (Android, iOS, Windows), localization, and offline resilience all matter. Avoid web-only assumptions.

## Tech stack
- Flutter (Dart SDK ^3.11.5)
- State management: Riverpod (flutter_riverpod ^2.6.1)
- Navigation: go_router ^14.6.2
- Networking: Dio ^5.7.0
- Local DB (offline): Drift (SQLite) with drift_dev code generation
- Real-time: web_socket_channel (KDS / live orders)
- Local storage/settings: shared_preferences
- Localization: intl + flutter_localizations (Kurdish, Arabic, English)
- Charts: fl_chart (reports)
- Printing/receipts: printing + pdf packages
- UI: flutter_screenutil (responsive sizing), google_fonts

## Feature modules (lib/features/)
- auth
- cashier
- delivery
- kitchen (KDS)
- menu
- orders
- payment
- reports
- tables

## Folder structure
Each feature follows: models / providers / screens / widgets

## Other lib directories
- lib/core/: constants, theme, utils
- lib/routes/
- lib/services/
- lib/app/

## Platforms
Android, iOS, Windows (build directories present)
