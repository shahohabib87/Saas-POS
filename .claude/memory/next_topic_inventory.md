---
name: next-topic-inventory
description: User wants to implement Foodics-style product and inventory management
metadata: 
  node_type: memory
  type: project
  originSessionId: aced4e0e-9bf1-4693-b6a3-afb73ea5f31e
---

User wants to implement product and inventory management similar to Foodics.

**Why:** EasyCasher is modeled after Foodics — user wants feature parity for inventory.

**How to apply:** When user asks about this topic, guide them through the Foodics-style approach:

## Foodics-style Product & Inventory Management

### 1. Products (Menu Items)
- Each product has: name, price, category, image, description, modifiers
- Products can be enabled/disabled (out of stock toggle)
- Already partially built in EasyCasher (menu management screen)

### 2. Ingredients / Raw Materials
- Each product is made of ingredients (e.g. Burger = Bun + Patty + Lettuce)
- Track stock quantity per ingredient (e.g. 50 buns in stock)
- When an order is placed → automatically deduct ingredients from stock

### 3. Inventory Tracking
- Low stock alerts when ingredient falls below a threshold
- Stock adjustment screen (add stock manually after delivery)
- Wastage recording
- Inventory history log

### 4. Units of Measure
- Each ingredient has a unit (kg, liters, pieces, etc.)

### Steps to implement in EasyCasher:
1. Add `ingredients` table to Drift DB (name, unit, current_stock, low_stock_threshold)
2. Add `product_ingredients` table (product_id, ingredient_id, quantity_used)
3. On order completion → deduct ingredient quantities
4. Add Inventory screen (view stock, adjust, see low stock alerts)
5. Link products to ingredients in menu management screen
