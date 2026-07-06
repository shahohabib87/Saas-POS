---
name: saas-frontend
description: "EasyCasher web frontend — one Vue app (dashboard + POS), location, stack, and setup"
metadata:
  node_type: memory
  type: project
---

The EasyCasher frontend is **ONE Vue web app with two areas** (see [[feedback]] 2026-07-06 web-only decision — NO Flutter). Talks to the Laravel API ([[saas-backend]]).

## Location & stack
- **App:** `/workspaces/easycasher-saas/dashboard` (Vite project; sibling of `api/`)
- **Vue 3 + TypeScript + Vite 8**, **Tailwind CSS v4** (via `@tailwindcss/vite` plugin, `@import "tailwindcss"` in `src/style.css` — NO tailwind.config needed), **Pinia** (state), **vue-router 4**, **axios**.
- Two areas planned: (1) owner/manager **dashboard** (reports/menu/staff/subscription), (2) web **POS** register. POS to become an offline-first **PWA** (IndexedDB → `POST /api/sync`) later.

## Structure (Step F1 — DONE 2026-07-06)
- `src/api/client.ts` — single axios instance, `baseURL:'/api'`, request interceptor adds `Bearer` token. `setAuthToken()` sets/clears it.
- `src/stores/auth.ts` — Pinia store: `login()`, `logout()`, `restore()` (reloads session from localStorage key `easycasher.auth`), `setSession()`. Getters `isLoggedIn`, `isManager`. Token+user+tenant persisted to localStorage.
- `src/router/index.ts` — routes `/login` (public) + `/` (home, guarded). Global `beforeEach` guard: non-public route without login → `/login?redirect=...`; logged-in hitting `/login` → home.
- `src/views/LoginView.vue` — email+password form (prefilled owner@demo.test/password), Tailwind card UI.
- `src/views/HomeView.vue` — header (tenant + user + logout) + two cards (Dashboard / POS) as placeholders.
- `src/types.ts` — `User`, `Tenant`, `Role` interfaces matching API JSON.
- `src/main.ts` — mounts Pinia, calls `restore()` BEFORE router so guards see the session on refresh.

## Dev setup / how to run BOTH
- Backend: `cd /workspaces/easycasher-saas/api && php artisan serve --port=8000` (needs Docker pg+redis up; reseed with `php artisan migrate:fresh --seed --force` — resets the demo 14-day trial).
- Frontend: `cd /workspaces/easycasher-saas/dashboard && npm run dev` (port 5173).
- **Vite proxies `/api` → `http://127.0.0.1:8000`** (in `vite.config.ts`), so the browser hits one origin, no CORS.
- Build/typecheck: `npm run build` (runs `vue-tsc -b && vite build`).

## Verified (2026-07-06)
- `npm run build` passes (TS + Tailwind compile clean).
- Login works END-TO-END through the proxy: `POST /api/login` via :5173 → backend → returns Owner / Demo Restaurant / token. App serves HTTP 200.

## Step F2 — dashboard shell + Staff/Menu/Subscription (DONE 2026-07-06)
- **Nested routing**: `/` → `layouts/AppLayout.vue` (persistent sidebar) with children `''`(home)/`staff`/`menu`/`subscription`. `/pos` is a SEPARATE top-level route (full-screen, no sidebar) — placeholder `views/PosView.vue` for now. Guard unchanged.
- `layouts/AppLayout.vue` — dark sidebar (nav + "Open POS" + user/logout) + `SubscriptionBanner` + `<RouterView>`. Loads subscription on mount.
- `stores/subscription.ts` — Pinia store (`status`, `load()`) shared by banner + dashboard + subscription page.
- `components/SubscriptionBanner.vue` — red (lapsed) / amber (trial or ≤5 days) strip, else hidden.
- `components/AppModal.vue` — reusable modal (title + slot + close-on-backdrop).
- `views/DashboardView.vue` — 4 stat cards (staff/menu/orders/recent sales via `Promise.all` of staffApi+menuApi+orderApi) + subscription summary + recent-orders table.
- `views/StaffView.vue` — table + add/edit/delete modal. Blank pin/email/password on edit = keep unchanged. Surfaces Laravel 422 `errors` (e.g. dup PIN, last-admin).
- `views/MenuView.vue` — category filter pills + item cards, availability checkbox (**optimistic** toggle w/ revert), add/edit item modal, add-category modal.
- `views/SubscriptionView.vue` — current status + plan cards (Basic/Pro) with Choose/Renew; admin-only (guards role client-side too).
- **API service layer** (`src/api/*.ts`): `staff.ts`, `catalog.ts` (categoryApi+menuApi; `MenuItemPayload` sends price as NUMBER — reads back as decimal STRING), `subscription.ts`, `orders.ts`. `src/lib/format.ts` = `iqd()` formatter (no minor units).
- **GOTCHA (Tailwind v4):** `@apply` inside a Vue `<style scoped>` needs `@reference "tailwindcss";` at the top of that block or the build fails. Used for the `.input` class in Staff/Menu views.
- ✅ Verified: `npm run build` clean (TS+Tailwind); via Vite proxy all screen endpoints 200 (staff5/categories5/menu18/orders0/subscription/plans2); staff create→edit→delete (201/200/204) + menu-item create→toggle→delete all OK. (Headless — no browser render check; user opens :5173 via port-forward to view.)

## Next
- ⏭️ Step F3: POS register at `/pos` (menu grid → cart → modifiers → payment → build Order → `POST /sync`).
- Then F4: offline PWA (IndexedDB queue + service worker + sync-on-reconnect).
- Not a git repo yet / not pushed — ask user before pushing code (per [[feedback]]).
