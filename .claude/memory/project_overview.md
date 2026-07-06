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

## Target Architecture (Foodics model) — refined 2026-07-06
- **POS App** — Flutter tablet app (existing) — now used as the reference/spec for the online build
- **Backend API** — **Laravel 12** (PHP) on a **Digital Ocean droplet** (we set the droplet up together; live details NOT yet captured in memory — capture IP + installed services)
- **Database** — **PostgreSQL** (upgraded from the earlier MySQL plan)
- **Cache/Queue/Realtime** — **Redis** (caching, queue workers, KDS broadcasting)
- **Web Dashboard** — **Vue.js** app for owner/manager reports + subscription management
- **Delivery integrations** — **Talabat, Careem** via Laravel queued jobs/webhooks (NOT separate microservices)
- **Payments + Subscriptions** — SaaS subscription billing (provider TBD; regional constraints matter)
- **Architecture style** — **modular monolith** in Laravel (modules: tenancy, menu, orders, billing, delivery); extract to services later only where scale demands. User floated "microservices"; recommended modular monolith + queue workers instead.
- **Goal** — fully online multi-tenant SaaS (everything online), separate from the Flutter project

## Next Features to Build
1. Capture DO droplet live state (IP, PHP/Nginx/Postgres/Redis installed?, any Laravel app deployed)
2. Scaffold Laravel 12 API — multi-tenant + auth (Sanctum) + first module (menu/orders from Flutter models)
3. Vue.js web dashboard (reports + subscription management)
4. Talabat/Careem + payment/subscription integrations

**Why:** User confirmed Laravel + Digital Ocean multiple times; refined DB to PostgreSQL + Redis and added Vue dashboard + delivery/payment integrations on 2026-07-06. Do NOT re-ask backend/hosting/POS-vs-web questions.
**How to apply:** Always check this before suggesting next steps — build on what exists, don't duplicate.
