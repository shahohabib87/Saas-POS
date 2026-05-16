---
name: project-architecture
description: "EasyCasher target architecture — two service modes, four roles, build phases"
metadata: 
  node_type: memory
  type: project
  originSessionId: 02ddbef3-f0ab-4f03-8a9b-ddd3bc451b26
---

EasyCasher is structured to support two restaurant service models and four staff roles, matching Foodics' architecture.

**Why:** User wants feature parity with Foodics — two service modes (full service restaurant + quick service fast food) in one app.

**How to apply:** Always consider which service mode and role is affected when building a feature. Don't mix waiter logic into cashier screens.

## Two Service Modes
- **Full Service** — waiter takes order, pay at end (sit-down restaurants)
- **Quick Service** — customer orders at counter, pays immediately (fast food)

## Four Roles
- **Waiter** — table map, take order, send to kitchen, request bill (Full Service only)
- **Cashier** — payment, bill, void, open tables view (both modes)
- **Kitchen** — KDS screen, bump KOT status (both modes)
- **Manager** — everything + void approval, reports, staff management, menu management

## Order Flow
### Full Service: Order → KOT → Food → Bill → Pay
### Quick Service: Order → Pay → Receipt/Number → KOT → Food

## Build Phases
1. Auth + Roles (login with PIN, role-based routing) ← CURRENT
2. Waiter App (table map, menu, send to kitchen)
3. KDS Screen (KOT cards, bump status)
4. Cashier — Full Service (payment, bill, void)
5. Cashier — Quick Service (order + immediate pay, order number)
6. Reports (Z-report, void log, sales)
7. Delivery (online orders, call orders)

## Key Design Rules
- Payment timing: Full Service = end of meal, Quick Service = immediately
- Order identifier: Full Service = Table number, Quick Service = Order #001 (resets daily)
- Void requires manager PIN after KOT is sent
- KDS shows both service types with different identifiers
- Staff cannot access screens outside their role
