---
name: saas-deployment
description: "EasyCasher production deployment — Digital Ocean droplet is CWP/CentOS (NOT Ubuntu); resume point"
metadata:
  node_type: project
---

Deploying EasyCasher ([[saas-backend]] + [[saas-frontend]] at /workspaces/easycasher-saas) to the user's Digital Ocean droplet. Started 2026-07-07; **finishing 2026-07-08 (tomorrow)**.

## ⚠️ CRITICAL environment facts (discovered 2026-07-07)
- The droplet is **CentOS Web Panel (CWP)** on CentOS/AlmaLinux — **NOT a bare Ubuntu box**. So: NO apt, NO hand-rolled nginx/systemd — **work THROUGH the CWP panel** (domains, PHP selector, SSL, DB). CWP usually runs **Apache** (Laravel's public/.htaccess just works).
- **Another project already lives on it: `easycasher-relay`** (a Laravel app at `/home/ecrelay/easycasher-relay`, served via `public_html -> easycasher-relay/public`, user `ecrelay`). **DO NOT touch/collide with it.** (Unclear yet if related — ask user.)
- **Likely DB mismatch:** CWP ships **MySQL/MariaDB**, but EasyCasher is built on **PostgreSQL** (jsonb columns, `DATE()`/selectRaw). Must confirm Postgres is installed; if not, install it on CentOS (`dnf install postgresql-server`) OR port to MySQL (nontrivial — jsonb→json, raw SQL). **Prefer installing Postgres.**
- User HAS SSH root access + a domain (a different/spare domain, not yet specified which) to use for EasyCasher.

## Chosen deploy shape (single domain, no CORS)
- Serve **dashboard/dist** (Vue SPA static) at the domain root; route **/api** to the **api/** Laravel backend (public/index.php). Frontend axios baseURL stays `/api` (relative) — no CORS, no VITE env needed. On Apache/CWP this is a subdomain docroot + an /api alias, OR two subdomains (app + api) if the alias is fiddly. Decide once we see if CWP uses Apache or nginx.
- Private repo → get code onto droplet via a **deploy key** (generate on droplet, add to GitHub repo) or HTTPS + PAT.

## ✅ Discovery CONFIRMED (2026-07-08) — droplet facts
- **Droplet IP: `161.35.31.51`**. CWP admin at **`https://161.35.31.51:2087`** (self-signed). OS = **AlmaLinux 8.10** (el8/RHEL family).
- **PostgreSQL 16.14 installed + running** ✅ (`psql` at /usr/bin/psql). NO MySQL port needed — big win.
- **Composer 2.10.2** installed ✅ (/usr/local/bin/composer).
- **Apache (httpd) active** ✅; nginx inactive. mariadb/mysqld also active (unused by us).
- **PHP problem:** default CLI PHP = **8.1.34** (/usr/local/php). alt-php present: `/opt/alt/php81`, `/opt/alt/php-fpm81/82/83`. **NO 8.3 CLI** (`/opt/alt/php83` missing) and 8.3 FPM extensions (pgsql/mbstring) UNCONFIRMED. App needs **PHP ^8.3** (Laravel 13.18) for BOTH web (FPM) and CLI (composer/artisan). → must install/enable PHP 8.3 + exts (pdo_pgsql, mbstring, bcmath, curl, xml, fileinfo, openssl, tokenizer, ctype) via **CWP panel** (safest; don't disturb relay or global 8.1). Awaiting user's CWP PHP-menu labels + `.so` diagnostic.
- **Node on droplet = v14.15.3 (too old for Vite 8)** → **build frontend in the Codespace (Node 24) and upload `dist/`**; never build on droplet.

## ✅ Decisions locked (2026-07-08)
- **Host = `app.easycasherorder.online`** (subdomain; apex left free). Dedicated domain `easycasherorder.online`.
- **DNS = not set up yet.** User adds A record **`app` → 161.35.31.51** at their registrar (registrar name still TBD). Verify propagation before AutoSSL.
- Deploy shape: subdomain docroot serves Vue `dist/` + `.htaccess` SPA fallback + `api/` (Laravel public) routed at `/api`; axios baseURL `/api` (relative, no CORS). CWP AutoSSL for the cert.

## ⏭️ RESUME — next steps
1. **PHP 8.3:** from CWP PHP-FPM Selector/Version Switcher, install 8.3 + exts, assign to `app` subdomain; get an 8.3 CLI for composer/artisan. (Waiting on user's CWP menu + `.so` diagnostic.)
2. Create the `app.easycasherorder.online` subdomain in CWP (under an account — NOT ecrelay's).
3. Deploy key + git clone the private repo onto droplet (api/ only; dist built locally & uploaded).
4. API: composer install --no-dev, .env (Postgres creds, APP_URL=https://app.easycasherorder.online, key:generate), migrate --seed, storage perms.
5. Point docroot; CWP AutoSSL/Let's Encrypt.
- Removed a premature Ubuntu-oriented `deploy/nginx-easycasher.conf` (wrong for CWP) — recreate an **Apache/CWP-appropriate** config instead.

## Push state at pause
- easycasher-saas local `5289128` (console additions) NOT yet on origin (`2c1640d`). User pushes from THEIR terminal: `cd /workspaces/easycasher-saas && unset GITHUB_TOKEN && gh auth setup-git && git push` (see [[saas-backend]] push gotcha).
