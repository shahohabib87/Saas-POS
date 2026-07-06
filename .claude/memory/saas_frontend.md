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
- **Codespace run gotcha:** `vite.config.ts` sets `server.allowedHosts: ['.app.github.dev','localhost']` or Vite blocks the forwarded domain. Forwarded URL = `https://$CODESPACE_NAME-5173.app.github.dev`. Only port 5173 needs forwarding (proxy reaches api server-side). To restart Vite, DON'T `pkill -f vite` (matches the shell cmd → kills it); kill by port: `ss -ltnp | grep :5173`.
- **Demoed live 2026-07-06 — user approved the UI ("looks nice").**
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

## Step F3 — POS register (DONE 2026-07-06)
- `views/PosView.vue` — full-screen `/pos` (no sidebar). Left = search + category pills + item grid (only `is_available` items); tap item → if it has `modifier_groups` open `ModifierDialog` else add directly. Right = cart aside: order-type toggle (dine_in/takeaway/delivery), line list with qty ±, Total, Clear, Charge.
- `stores/cart.ts` — Pinia cart: `lines[]` (key = `menuItemId|modifiersLabel` so same combo stacks), `add/inc/dec/remove/clear`, getters `count/subtotal/total/isEmpty`. **total==subtotal for now** (no tax/discount settings endpoint yet — F-later).
- `components/pos/ModifierDialog.vue` — per-group radio (single) / checkbox (multi) from `modifier_groups`; computes `unitPrice = base + Σ option.price` and `label = names.join(', ')`.
- `components/pos/PaymentDialog.vue` — cash/card toggle; cash: amount input + quick-cash buttons (rounded up) + live change; card: no change. Emits `{method, cashPaid, change}`.
- `lib/pos.ts` — `uuid()` = `crypto.randomUUID()` (client PK); `nextOrderNumber()` = daily-resetting local counter "001" in localStorage `easycasher.orderCounter`.
- `api/sync.ts` — `syncApi.push(orders)` → `POST /sync` with `{orders, last_synced_at}`. `SyncOrder`/`SyncOrderItem` types match backend ORDER_FIELDS/ITEM_FIELDS exactly.
- Checkout flow (`onPaymentConfirm`): builds `SyncOrder` (client uuid, order_number, staff_name from auth, placed_at=ISO now, items with uuids) → `syncApi.push([order])` → on success clear cart + toast "Order #NNN completed"; on 402 → "subscription expired" toast; on network fail → keeps cart (nothing lost), toast to retry. **Real offline queue = F4 (not built yet)** — currently a failed push just keeps the cart.
- ✅ Verified: `npm run build` clean. Simulated the exact checkout payload via `/sync`: order+item landed in `/orders` (qty, modifiers_label "Large, Extra Cheese", change 2000 all correct); re-push same uuid → still 1 order (idempotent). (Headless — no browser render check.)

## Step F4 — offline PWA (DONE 2026-07-06)
- Deps: **`idb`** (IndexedDB wrapper), **`vite-plugin-pwa`** (service worker). Dev-only: `fake-indexeddb`, `tsx` (for the offline test).
- `lib/db.ts` — IndexedDB `easycasher` v1, 2 stores: `catalog` (keyPath 'key'; rows 'categories'/'menu_items') + `orders` (keyPath 'id' = order UUID → dedupes retries). Fns: `cacheCatalog`/`readCachedCatalog`, `queueOrder`/`pendingOrders`/`pendingCount`/`removeOrders`.
- `stores/network.ts` — Pinia: `online` (from `navigator.onLine`), `pending` (queued count), `syncing`. `init(onReconnect)` wires window online/offline events.
- `services/offline.ts` — the offline-first heart, NEVER throws to caller: `getCatalog()` (online→fetch+cache, offline→cached, returns `fromCache`), `submitOrder(order)` (ALWAYS `queueOrder` first, then `flush`; returns `{synced}`), `flush()` (push all queued via `syncApi.push`, remove server-`applied` ids), `refreshPendingCount()`.
- `main.ts` — `network.init(() => offline.flush())` + initial `refreshPendingCount()` → auto-flush on reconnect.
- `PosView.vue` — catalog via `offline.getCatalog()` (works offline; toasts "Offline — showing saved menu"); checkout via `offline.submitOrder()` → toast "completed ✓" (synced) or "saved — will sync when back online" (queued). Header shows **Online/Offline pill + "N pending"/"Syncing…" badge** (from network store). `onMounted` also flushes leftover queue.
- `vite.config.ts` — `VitePWA` (autoUpdate): manifest (name EasyCasher POS, theme #059669, start_url /pos, standalone, 192/512 icons); workbox precaches app shell (`globPatterns` js/css/html/png), `navigateFallbackDenylist:[/^\/api/]` (never SW-cache API — our IDB layer owns data). Icons `public/pwa-192.png`+`pwa-512.png` = solid emerald placeholders generated by a Node PNG encoder (**TODO: replace with real branded icons**).
- ✅ Verified: `npm run build` clean → `dist/sw.js` precache 25 entries. **Offline storage tested for real via fake-indexeddb + tsx** (catalog cache RW; queue starts empty→2 orders→retry same id stays 2 (no dup)→pending returned with items→removeOrders empties it). Push half already proven F3 (idempotent /sync). Full loop: offline queue → reconnect → flush → server applied → local removed.

## Step F5 — settings + tax/discount/tip (DONE 2026-07-06) — polish item #1
- `api/settings.ts` (`settingsApi.get/update`), `types.ts` `Settings` interface, `Tenant.settings` added.
- `stores/auth.ts` — added `applySettings(settings)` + `persist()` so saving settings updates the cached tenant (POS reads tax offline from `auth.tenant.settings`).
- `views/SettingsView.vue` (route `/settings`, sidebar ⚙️) — restaurant details (address/phone; name read-only), tax & currency (tax_rate %, tax_inclusive), service mode (quick/full radio cards). Admin/manager editable, others read-only. Saves via PUT /settings → `auth.applySettings`.
- `stores/cart.ts` — added `taxRate`/`taxInclusive`/`discountAmount`/`tip` state + getters: `taxableBase` (=subtotal−discount, ≥0), `tax` (exclusive: base×rate; inclusive: base−base/(1+rate)), `total` (inclusive: base+tip; exclusive: base+tax+tip). `setTaxConfig()`; `clear()` resets discount+tip.
- `components/pos/PaymentDialog.vue` — reworked: full breakdown (subtotal, discount input, tax line, tip input, total) + method cash/card/**split** (split = cash portion input, card auto = remainder). Emits `{method, cashPaid, cardPaid, change}`. Reads cart store directly (no more `total` prop).
- `PosView.vue` — `onMounted` sets tax config from `auth.tenant.settings`; cart footer shows subtotal+tax+total; order build sends real `discount_amount/tax/tip/card_paid`.
- ✅ Verified: build clean; cart math unit-tested via Pinia+tsx (exclusive 15%, discount, tip, inclusive mode, clear-reset all correct); full split order w/ tax+discount+tip pushed to /orders correctly (after fixing the [[saas-backend]] empty-modifiers_label sync bug).
- ⚠️ Deferred in #1: service_charge (no order column), receipt (that's polish #2). Tax rounding = `Math.round`.

## Step F6 — receipt (DONE 2026-07-06) — polish item #2
- `components/pos/ReceiptDialog.vue` — 80mm thermal-style receipt (monospace, dashed dividers): header (tenant name/address/phone from `auth.tenant.settings`), order # + type + date (`toLocaleString en-GB`) + staff, line items (`qty× name` + line total, modifiers under), totals (subtotal/discount/tax/tip/**TOTAL**), payment (method + cash/card/change), "Thank you". Shows "(saved offline — will sync)" when `offline` prop true. Buttons: "New order" (close) + "🖨️ Print" (`window.print()`).
- `style.css` — global `@media print` block: hide everything (`body *` visibility hidden), show only `.receipt-print`; neutralize `.receipt-overlay` (static, no backdrop); hide `.receipt-actions`. So printing yields just the receipt at 80mm.
- `PosView.vue` — after `offline.submitOrder`, instead of a toast, sets `receiptOrder`/`receiptOffline` → shows `ReceiptDialog`; closing it (`receiptOrder=null`) starts the next order. Cart already cleared.
- ✅ Build clean. Visual/print component — best confirmed in browser (reuses order data proven in #1 + cached tenant settings; works offline since all data is local).

## Step F7 — orders screen + void (DONE 2026-07-06) — polish item #3
- Backend: `OrderController@void` + route `POST /orders/{order}/void` (subscribed group). Body `{pin}` → finds a user in tenant with that pin AND role in [admin,manager] → else **403**; sets status='void' (idempotent). `index` now also accepts `?status=`. Verified: cashier pin 5678→403, manager pin 0000→void, status filter works.
- Frontend: `types.ts` Order expanded (full breakdown + `items?: OrderItem[]`). `api/orders.ts` added `get(id)` + `void(id,pin)`.
- `views/OrdersView.vue` (route `/orders`, sidebar 🧾) — "Today only" toggle (sends `from`), tabs All/Completed/Voided with counts (client-filtered), table (#, time, type, staff, method, total, status badge). Row click → `AppModal` detail (fetches with items via `orderApi.get`): breakdown + items; **Void** button reveals manager-PIN input → `orderApi.void` → updates row + detail. Voided rows dimmed + red badge.
- ✅ Build clean; void endpoint proven via curl (403/void/filter).

## Step F8 — KDS kitchen display (DONE 2026-07-06) — polish item #4
- Backend: `orders.kitchen_status` column (new|preparing|ready|done, default 'new' → every POS sale auto-enters kitchen queue; NOT in sync ORDER_FIELDS so re-sync won't reset it). `Order` fillable += kitchen_status. `OrderController@kds` (GET /kds — kitchen_status in [new,preparing,ready] AND status!=void, oldest-first FIFO, with items) + `@kitchenStatus` (POST /orders/{order}/kitchen, body `{kitchen_status}` in:new,preparing,ready,done). Verified: new order shows, bump new→preparing, done leaves queue, invalid 422.
- Frontend: `api/orders.ts` `kdsApi.list/bump` + `KitchenStatus` type; Order type += kitchen_status, table_number.
- `views/KdsView.vue` (route `/kds`, top-level full-screen dark board; sidebar 👨‍🍳 "Open KDS"). 3 columns New/Preparing/Ready; cards = #, "Xm ago" (recomputes via tick ref), type/table/staff, item lines+modifiers, one bump button (Start→Ready→Done; done drops card). **Polls GET /kds every 5s** (setInterval, cleared onUnmounted) — no websockets yet. Optimistic bump w/ resync-on-fail.
- ✅ Build clean; KDS + bump endpoints proven via curl. Full loop: POS sale → auto 'new' on KDS → bump → done.
- ⚠️ Deferred: real-time via Redis/websockets (currently 5s poll); role-based routing (any logged-in user can open KDS/POS); offline KDS.

## Next
- ⏭️ Later polish: #5 reports (sales analytics — by day/item/payment), #6 tables/dine-in flow. (#1 settings+tax, #2 receipt, #3 orders+void, #4 KDS — DONE)

## ⏸️ SESSION PAUSED 2026-07-06 (resume tomorrow)
- **RESUME AT: polish #5 — Reports** (sales analytics: totals by day, top items, payment-method breakdown; dashboard already has basic stat cards to build on).
- **⚠️ PENDING PUSH:** commits `28716a7` (#3 orders+void) + `27909b3` (#4 KDS) are committed locally in easycasher-saas but NOT yet pushed to GitHub. First thing next session: remind user to run `unset GITHUB_TOKEN && gh auth setup-git && git push` in their terminal (see [[saas-backend]] push gotcha). Everything through #2 (receipt, 7b9027e) IS pushed.
- Dev servers were shut down at end of session. To restart: pg+redis `docker start easycasher-pg easycasher-redis`; api `cd /workspaces/easycasher-saas/api && php artisan serve --host 0.0.0.0 --port=8000`; frontend `cd /workspaces/easycasher-saas/dashboard && npm run dev -- --port 5173`. Reseed if needed: `php artisan migrate:fresh --seed --force` (resets 14-day trial + demo data w/ 15% tax). (needs a tenant-settings endpoint on backend + wire into cart `total`); receipt print (`window.print` or backend PDF); dine-in tables flow (tables API exists); incremental catalog pull via `/sync` PULL + `last_synced_at` (currently full GET each online load); real PWA icons.
- Also revisit: `/sync` sits behind the `subscribed` 402 gate → a lapsed tenant's queued offline orders won't push until they renew (they stay safely queued). See [[saas-backend]] grace-period note.
- **Pushed to GitHub 2026-07-06:** part of the private monorepo **github.com/shahohabib87/easycasher-saas** (branch `main`) alongside `api/` — see [[saas-backend]]. Ask before pushing NEW code (per [[feedback]]).
