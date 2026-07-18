# EasyCasher — Project Notes

> The living context document. Everything an engineer (or an AI assistant) needs
> to understand this system, its decisions, and its open work. Secrets are
> deliberately absent — credentials live nowhere in this repo.
>
> Last updated: 2026-07-19.

## 1. What this is

**EasyCasher** is a Foodics-style restaurant POS SaaS with three pieces:

```
                ┌─────────────────────────────────────────────┐
                │        CLOUD (DigitalOcean droplet)         │
                │        app.easycasherorder.online           │
                │  ┌───────────────────────────────────┐      │
                │  │  LARAVEL API (repo: easycasher-saas/api) │
                │  │  Postgres · Sanctum · multi-tenant │      │
                │  │  subscription gate → HTTP 402      │      │
                │  └──────┬──────────────────┬─────────┘      │
                │  ┌──────┴───────┐   ┌──────┴────────┐       │
                │  │ WEB CONSOLE  │   │ SUPER ADMIN   │       │
                │  │ (Vue, owner) │   │ (/admin, us)  │       │
                │  └──────────────┘   └───────────────┘       │
                └──────────────▲──────────────────────────────┘
                               │ HTTPS /api/sync (60s heartbeat
                               │ + after each sale; offline-first)
                ┌──────────────┴──────────────────────────────┐
                │  RESTAURANT                                  │
                │  ┌────────────────────────────────────┐      │
                │  │ FLUTTER POS "the till" (THIS repo) │      │
                │  │ Windows desktop EXE · local SQLite │      │
                │  │ works fully offline                │      │
                │  └───────────────┬────────────────────┘      │
                │                  │ LAN websocket :8765       │
                │  ┌───────────────┴────────────────────┐      │
                │  │ KITCHEN DISPLAY (same EXE, KDS mode)│     │
                │  └────────────────────────────────────┘      │
                └──────────────────────────────────────────────┘
```

- **This repo (`Saas-POS`)** = the Flutter Windows till.
- **`easycasher-saas`** = monorepo: `api/` Laravel backend + `dashboard/` Vue web console (its built `dist/` is served from the droplet).
- **`easycasher`** (repo) = the OLD pre-SaaS client. Legacy, do not develop.

## 2. The governing rule

> **The till operates. The web manages. The cloud owns the data and the subscription.**

- Till (cashier, offline-capable): register, tables, kitchen, delivery dispatch + cash collection, shifts/Z-report, receipts.
- Web (owner/manager): menu, staff, drivers, delivery areas, customers, reports, expenses, purchases, subscription. Read-only where money physically moves at the till.
- Cloud (us): tenants, plans, trials, suspension (super-admin console at `/admin`).

## 3. Key design decisions (settled — don't relitigate casually)

1. **Offline-first till.** All reference data (menu, tables, staff, drivers, areas, customers) mirrors into local SQLite (`easycasher_pos.db` — never `easycasher.db`, that's the legacy app's file). Sales queue in a KV outbox and sync when online; a queued sale must never be lost. Migrations must be **additive** (`onUpgrade` used to drop tables — that was a landmine; never reintroduce it).
2. **Subscription enforcement, offline too.** Server returns 402 when lapsed; the till caches entitlement and enforces locally: warning (≤7d) → grace (3d) → locked. Locked blocks **new orders only** — settling open checks, Z-report, and sync always work. Clock-tamper guard: effective now = max(device clock, latest server time seen).
3. **Delivery cash = cash-on-delivery, collected at the till.** "Out for Delivery" sends the order out **unpaid** (local pending list, grouped by driver). When the driver returns, the cashier taps Collect → it becomes a completed cash sale, lands in the shift, and syncs **already stamped `driver_settled_at`** so the web's "cash owed" list never shows it. The web is **read-only** for delivery cash and driver assignment (owner watches; cashier operates).
4. **No open shift → no selling.** All three sell actions (Send to Kitchen, Out for Delivery, Pay Now) are blocked until a shift is opened with a counted float. Closing asks for the physical count BEFORE revealing expected cash (honest variance). Closed shifts are immutable.
5. **Every order type goes to the kitchen.** Dine-in fires a KDS ticket on Send to Kitchen; takeaway on payment; delivery on send-out. Bumping a *ready* takeaway/delivery ticket clears it (nothing to settle later); dine-in stays until the table pays.
6. **LAN KDS link (no internet needed).** The till hosts a websocket server on **port 8765**; kitchen devices (same EXE in "Kitchen Display only" mode) dial the till's IP and live-mirror the board. State-based protocol (full snapshot every change) so screens can't diverge; a kitchen "bump" is a request the till applies and rebroadcasts. Set the till address in Settings BEFORE flipping a device to KDS mode; a manager can "Exit KDS mode" from the board header. Windows Firewall must allow the app on first run.
7. **Tax comes from Settings** (`taxMultiplierProvider`: percent → fraction, zero when disabled). It was once a hardcoded 0 — never do that again.
8. **Order numbers**: claim (bump) the counter BEFORE reading the number, in every path. Read-then-bump caused live duplicate order numbers.
9. **Server-side authorization is real**: money-moving and management endpoints require admin/manager server-side (`manager` middleware / `authorizeManager()`); the frontend permission map is not a security boundary. `/sync` cannot void or rewrite money on a completed order (voiding needs a manager PIN via the dedicated endpoint). Public auth endpoints are rate-limited.
10. **Sync contract gotcha**: `SyncController::ORDER_FIELDS` filters with `Arr::only` — a misspelled key is silently dropped, and any new synced column must ALSO be in `Order::$fillable` (that omission is exactly why driver settlement silently failed once).

## 4. Environments & workflow

- **Home PC** (primary): full toolchain — Flutter, Node, SSH to droplet. Both repos live side by side (`Saas-POS-master`, `easycasher-saas`). Everything is developed, tested, and deployed from here.
- **Office laptop** (locked down, no installs, no terminal): use **github.dev** (press `.` on the repo) to edit + commit; ZIP downloads for reading. Cannot run anything. Optional future: code-server on the droplet for a browser IDE with terminal.
- **Deploys (web)**: build `dashboard/` locally (`npm ci && npm run build`), commit dist, push; on the droplet: `git reset --hard origin/main`, copy `dashboard/dist/*` → `/var/www/html/` (THE live docroot — not `api/public`), and `php84 artisan octane:reload` for API changes (the API runs under Octane — a normal file copy does NOT reload PHP).
- **Flutter release build**: `flutter build windows --release` → ship the whole `build/windows/x64/runner/Release/` folder (portable, no installer).
- Verification bar for changes: `flutter analyze` clean + `flutter test` green (64 tests as of writing); dashboard `npm run build` (includes vue-tsc) clean.

## 5. Current state (2026-07-19)

Recently completed, all pushed:
- Web Delivery page crash fixed (null driver on cash-owed) + orphaned test order cleaned.
- Security hardening: rate limits on login/pin-login, `/sync` void-bypass closed, manager gates on money movers + management CRUD, `is_super_admin` no longer mass-assignable, demo credentials removed from login screen, simulate endpoint gated.
- Till correctness: tax wired to settings, takeaway order numbers, real receipt printing (80mm PDF), shift-required-to-sell, phone type-ahead for delivery customers, all order types to KDS, LAN KDS link (verified live in both directions), startup dispose-race crash fixed.
- Delivery cash settlement model finished end-to-end (till collects; web watches).

## 6. Open work (priority order)

1. **Multi-branch** (designed 2026-07-19, NOT built). One tenant = brand; new `branches` table; per-branch: orders/tables/drivers/areas/shifts/stock; shared: menu/staff/customers/settings/subscription. Till picks its branch once in Device Settings; web gets a branch picker + "All branches" consolidated dashboard; plans gain `max_branches` (the per-location upsell). Migration auto-creates a "Main" branch and old tills keep working. Phases: backend foundation → web → till → plan enforcement (~1.5–2 weeks).
2. **PIN hashing** (deferred deliberately): PINs are plaintext in the DB and compared with `where('pin', ...)` in three places; hashing needs a candidate-fetch + `Hash::check`, a migration for existing PINs, AND a matching change for the till's offline PIN login. Do only with the ability to run both test suites — an auth bug locks out live tills.
3. **Payment provider**: `/subscribe` simulates payment (subscriptions are effectively free); no card processing anywhere. Product decision needed (Stripe etc.).
4. **Online Orders**: UI exists on both ends but there is no real aggregator integration; the web "simulate" tool fabricates orders (manager-gated).
5. Smaller: localization (KU/AR/EN advertised, not wired), split-bill is display-only, money handled as PHP floats server-side, missing FK constraints (dangling refs — the null-driver class of bug), `nextInvoiceNo` race, per-branch menu overrides (v2 of multi-branch).
6. **Ops**: rotate any credentials that ever appeared in old commits of this repo's history (they did — treat them as burned); keep `.claude/` out of git forever (it's gitignored for that reason).

## 7. For AI assistants reading this

This document IS the project memory. Trust its decisions unless the code
contradicts it (then the code wins — verify before acting). The till repo and
the web repo evolve together: changing the sync payload, order fields, or
delivery flow always means checking BOTH sides plus `Order::$fillable`.
