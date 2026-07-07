---
name: saas-superadmin
description: "EasyCasher platform SUPER ADMIN console — above all tenants (built 2026-07-07)"
metadata:
  node_type: memory
  type: project
---

Platform super admin = the EasyCasher-company operator who sits ABOVE all restaurants (distinct from a tenant's `admin`/owner who only sees their own restaurant). Built 2026-07-07 (commit `2c1640d` on easycasher-saas `main`). See [[saas-backend]] / [[saas-frontend]].

## Login
- **superadmin@easycasher.test / password** (seeded). `users.is_super_admin=true`, `tenant_id=NULL` (belongs to no restaurant).
- On login the frontend routes super admins straight to **`/admin`** (SuperAdminView); they are BLOCKED from tenant screens, and regular users are blocked from `/admin` (router guard on `is_super_admin` + `meta.superAdmin`). main.ts skips `perms.load()` for super admins (no tenant).

## Backend
- `users.is_super_admin` boolean (migration 2026_07_07_180000); User fillable+cast.
- `EnsureSuperAdmin` middleware (alias **`super`**, registered bootstrap/app.php).
- `SuperAdminController` under `Route::prefix('admin')->middleware('super')` (inside auth:sanctum, OUTSIDE the tenant `subscribed` gate):
  - `GET /admin/stats` — tenants count, by-status, MRR (sum active tenants' plan price via join), total_orders/revenue (Order **withoutGlobalScope(TenantScope)** to cross tenants).
  - `GET /admin/tenants` — all restaurants w/ status/plan/dates + `withCount('users')` + per-tenant completed-order count & revenue (grouped Order query, scope bypassed).
  - `POST /admin/tenants/{tenant}/suspend` (status=suspended → their POS 402-locks), `/activate` (status=active +30d), `/extend-trial` ({days} default 14).
  - `GET /admin/plans`, `PUT /admin/plans/{plan}` (edit name/price/is_active).
- Tenant model has NO global scope so Tenant queries already see all; only Order/etc. need `withoutGlobalScope(TenantScope::class)`.
- Seeder: super admin user + 2nd tenant **Sunset Grill** (active/pro, owner@sunset.test) so the console has >1 restaurant.

## Frontend
- `api/admin.ts` (adminApi: stats/tenants/suspend/activate/extendTrial/plans/updatePlan); types `PlatformStats`, `PlatformTenant`; User gained `is_super_admin?`, tenant_id now `number|null`.
- `views/SuperAdminView.vue` (route `/admin`, dark full-page console): 6 stat cards (restaurants/active/trial/MRR/orders/revenue) + restaurants table (status badge, plan, ends, staff/orders/revenue) + row actions Suspend / Activate / +14d trial.
- ✅ Verified curl: super login (tenant null), stats (2 tenants, MRR 50000), tenants list, owner→/admin 403, suspend/activate/extend all work.

## Console additions (2026-07-07, commit `5289128`)
- **Editable plan pricing** — plans section (name/price/active) → `PUT /admin/plans/{plan}`.
- **Platform-admin management** — `GET /admin/admins`, `POST /admin/admins` (create super admin: name/email/password → is_super_admin true, tenant_id null), `DELETE /admin/admins/{user}` (revoke; guards: not-a-platform-admin 422, can't-remove-self 422, can't-remove-last 422). UI: list + add form + remove. Verified: plan 50k→60k, add admin (logs in as super), remove 204.
- **Restaurants-by-status bar chart** (active/trial/suspended/cancelled) from stats.

## ⏭️ Possible extensions: per-tenant drill-in; impersonate-tenant; audit log; platform charts over time (signups/MRR trend).
