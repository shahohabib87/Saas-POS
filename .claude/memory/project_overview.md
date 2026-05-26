---
name: project-overview
description: "EasyCasher Flutter POS app — architecture, features built, and current state"
metadata: 
  node_type: memory
  type: project
  originSessionId: 6caad047-0606-48d4-90fc-f50ba0cc1abc
---

## App: EasyCasher POS
Flutter + Riverpod + Drift (SQLite) restaurant POS system.

**GitHub:** github.com/shahohabib87/easycasher (private, branch: master)

## Architecture
- `lib/core/database/app_database.dart` — Drift SQLite DB, all tables and queries
- `lib/core/database/database_provider.dart` — Riverpod `appDatabaseProvider`
- Features are organized under `lib/features/<feature>/`

## Database Tables (SQLite via Drift)
- `categories`, `menu_items` — menu data
- `staff_members` — staff with roles and PINs
- `role_perms` — per-role permission toggles
- `restaurant_tables` — table layout
- `orders`, `order_items` — completed order history
- `settings_kv` — key-value app settings

## Seeded Data (first launch only)
Staff: Admin(9999), Ahmed/waiter(1234), Sara/cashier(5678), Kitchen(1111), Manager(0000)
Categories: All, Burgers, Pizza, Drinks, Desserts, Sides
Menu: 18 items with modifiers and IQD prices
Tables: 20 tables with varying capacities

## Features Built (as of 2026-05-25)
- Login screen with PIN pad and staff roles
- Cashier screen: menu grid, cart, modifiers, order types
- Kitchen Display Screen (KDS) — 3-column layout
- Payment screen: cash/card, tip, split, discount
- Receipt screen — shows after payment (improved today)
- Orders screen: Active and Completed tabs with detail dialog
- Tables management: add/edit/delete, status tracking
- Menu management: categories + products + modifiers (admin/manager)
- Settings: restaurant info, tax, service mode, staff management
- Dynamic role permissions system
- Delivery screens (exist but minimal)

## Recent Commits
- a9f3864 — Add Reports screen with sales analytics for admin/manager
- e7d85c6 — Improve receipt: fix order type, add subtotal/discount/tax, staff, address
- f3d778f — Migrate all providers to SQLite via Drift database
- 3e5c559 — Add permissions, menu management, dynamic tables, and order history
- c2f5879 — Add payment screen, settings, order types, IQD currency, KDS badges
- 0474534 — Add orders screen, KDS 3-column layout, void item, kitchen status chip
- 023dea8 — Initial commit - EasyCasher POS v0.1

## Target Architecture (Foodics model)
- **POS App** — Flutter tablet app (existing, keep building)
- **Backend API** — Laravel (PHP) hosted on Digital Ocean
- **Database** — MySQL on Digital Ocean (replace local SQLite)
- **Web Dashboard** — separate web app for owner/manager reports
- **Plan:** Finish POS app first → then build Laravel API → migrate POS from SQLite to API → build web dashboard

## Next Features to Build
1. Complete POS app features (delivery screen — reports screen is done)
2. Laravel + MySQL backend on Digital Ocean
3. Migrate Flutter POS from SQLite to Laravel API
4. Web dashboard for owner reports

**Why:** User confirmed Laravel + MySQL + Digital Ocean multiple times. Do NOT ask again.
**How to apply:** Always check this before suggesting next steps — build on what exists, don't duplicate.
