---
name: saas-backend
description: "EasyCasher online SaaS backend — Laravel API project location, stack, and local dev setup"
metadata:
  node_type: memory
  type: project
---

The online SaaS build lives in a SEPARATE folder from the Flutter repo. Flutter app ([[project-overview]]) is the reference/spec only. Started 2026-07-06 from scratch.

## CRITICAL REQUIREMENT — offline-first POS + sync (user, 2026-07-06)
The **POS part must keep working with NO internet** (internet shutdowns are common in the target region). When connection returns, it must **sync** local data up/down automatically. This shapes the whole design:
- **Client-generated UUID primary keys** on all POS-created data (orders, order items) so offline inserts never collide across devices → server accepts client-supplied ids.
- Every synced table carries `updated_at` (and ideally a `deleted_at`/soft-delete + `version`) for conflict resolution (last-write-wins baseline; orders are append-only so trivial to sync).
- Catalog (categories, menu, tables) = server-authoritative → POS pulls it down and caches locally (Flutter Drift/SQLite already does this).
- Orders/payments = created offline on POS → queued locally → pushed up on reconnect. Never block a sale on the network.
- Plan a `POST /api/sync` (batch push + pull-since-timestamp) endpoint later. Design models sync-friendly NOW.

## Location
- **Laravel API:** `/workspaces/easycasher-saas/api`  (NOT inside the Flutter Saas-POS repo)
- Planned sibling: `/workspaces/easycasher-saas/dashboard` (Vue.js, not created yet)

## Stack (confirmed)
- **Laravel 13.18** (composer pulled current stable; user said "Laravel 12" but 13 is newer & compatible — using 13 unless user needs 12 pinned)
- **PostgreSQL 17** + **Redis 7** — run as Docker containers, NOT Laravel Sail (Sail's heavy image build was too slow in Codespace)
- Redis PHP client = **predis** (composer), because the phpredis extension isn't in this PHP build

## Local dev environment (Codespace)
- Docker containers: `easycasher-pg` (postgres:17, port 5432, user/db=easycasher, pass=secret) and `easycasher-redis` (redis:7-alpine, port 6379). Recreate with `docker run` if gone.
- `.env`: DB_HOST=127.0.0.1, DB_DATABASE=easycasher, DB_USERNAME=easycasher, DB_PASSWORD=secret; REDIS_CLIENT=predis, REDIS_HOST=127.0.0.1
- **IMPORTANT gotcha:** the Codespace PHP 8.4 is a custom source build at `/home/codespace/.php/current` WITHOUT pgsql. We compiled `pdo_pgsql.so` from PHP 8.4.15 source and enabled it via `/usr/local/php/8.4.15/ini/conf.d/20-pdo_pgsql.ini`. If PHP is rebuilt/reset, this must be redone (download php-8.4.15 source, `cd ext/pdo_pgsql`, phpize, configure --with-pdo-pgsql, make, copy .so to `/usr/local/php/8.4.15/extensions/`).
- Run server: `cd /workspaces/easycasher-saas/api && php artisan serve` → boots HTTP 200.

## Multi-tenancy design (Step 2 — DONE 2026-07-06)
- Model = **single-database, row-level tenancy**. `tenants` table = one restaurant business (the SaaS customer). Every business table carries `tenant_id`.
- `users` extended: `tenant_id` (FK), `role` (admin|manager|cashier|kitchen|waiter), `pin` (4-digit POS login, unique per tenant), email/password now nullable (staff may use PIN only). `pin`+`password` are in `$hidden`.
- **Auth = Laravel Sanctum** API tokens. Endpoints in `routes/api.php`:
  - `POST /api/register` — creates tenant + owner(admin), 14-day trial, returns token
  - `POST /api/login` — email+password → token
  - `POST /api/logout` (auth) — revokes current token
  - `GET /api/me` (auth) — current user + tenant
- Reusable **`BelongsToTenant` trait** (`app/Models/Concerns/`) + **`TenantScope`** (`app/Models/Scopes/`) auto-filter reads and auto-fill `tenant_id` on writes. Apply to business models in Step 3. NOT applied to User (avoids Sanctum auth-resolution recursion).
- Demo seed: tenant "Demo Restaurant"; owner **owner@demo.test / password** (pin 9999); staff Ahmed/waiter(1234), Sara/cashier(5678), Kitchen(1111), Manager(0000).

## Status (2026-07-06)
- ✅ Step 1 DONE: Laravel scaffolded, Postgres+Redis wired, migrations run, HTTP 200, Redis ping OK.
- ✅ Step 2 DONE: multi-tenancy + Sanctum auth. Verified end-to-end via curl (register 201, login, /me, 401 without token).
- ✅ Step 3 (catalog) DONE 2026-07-06: ported Flutter menu to tenant-scoped, **sync-ready** models — `categories`, `menu_items` (jsonb modifier_groups + is_available), `restaurant_tables`. All use **UUID string PKs (HasUuids) + SoftDeletes + BelongsToTenant**. CRUD API: `apiResource` categories / menu-items / tables under auth:sanctum (index/store/update/destroy; store accepts optional client-supplied uuid `id` for offline creates). Seeder ports 5 categories, 18 items (with modifiers), 20 tables into Demo Restaurant. Tenant isolation PROVEN via curl (new tenant sees 0; creating 1 doesn't affect demo's 5).
- ⏭️ Next: Step 3b **orders + order_items** (the offline-created/push-up data) + the **sync engine** (`POST /api/sync` batch push + pull-since-timestamp) — directly serves the offline-first requirement above. Then staff-management CRUD, Step 4 subscriptions, Vue dashboard, Talabat/Careem.
- Not a git repo yet / not pushed — ask user before pushing code (per [[feedback]]).
