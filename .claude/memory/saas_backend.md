---
name: saas-backend
description: "EasyCasher online SaaS backend — Laravel API project location, stack, and local dev setup"
metadata:
  node_type: memory
  type: project
---

The online SaaS build lives in a SEPARATE folder from the Flutter repo. Flutter app ([[project-overview]]) is the reference/spec only. Started 2026-07-06 from scratch.

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

## Status (2026-07-06)
- ✅ Step 1 DONE: Laravel scaffolded, Postgres+Redis wired, migrations run, HTTP 200, Redis ping OK.
- ⏭️ Next: Step 2 multi-tenancy + auth (Sanctum); Step 3 port Flutter models (menu/orders/tables/staff); Step 4 subscriptions; then Vue dashboard; then Talabat/Careem.
- Not a git repo yet / not pushed — ask user before pushing code (per [[feedback]]).
