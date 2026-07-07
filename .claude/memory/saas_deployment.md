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

## ⏭️ RESUME TOMORROW — first steps
1. Get discovery output the user was about to paste: `cat /etc/os-release`; PHP versions (`ls /usr/local/php*/ /opt/alt/php*`, `php -v`); `which psql node npm`; `systemctl is-active httpd nginx postgresql mariadb mysqld`; relay's `.env` DB_CONNECTION. → tailor exact steps.
2. Confirm: which domain/subdomain for EasyCasher (added in CWP? DNS → droplet IP?); is `easycasher-relay` related.
3. Then: (a) ensure PostgreSQL; (b) create CWP domain/user + docroots; (c) deploy key + git clone; (d) API: composer install --no-dev, .env (Postgres creds, APP_URL, key:generate), migrate --seed, storage perms; (e) frontend: npm ci && npm run build; (f) point docroots; (g) CWP AutoSSL/Let's Encrypt.
- Removed a premature Ubuntu-oriented `deploy/nginx-easycasher.conf` (wrong for CWP) — recreate an **Apache/CWP-appropriate** config instead.

## Push state at pause
- easycasher-saas local `5289128` (console additions) NOT yet on origin (`2c1640d`). User pushes from THEIR terminal: `cd /workspaces/easycasher-saas && unset GITHUB_TOKEN && gh auth setup-git && git push` (see [[saas-backend]] push gotcha).
