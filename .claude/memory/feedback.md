---
name: feedback
description: How the user likes to work and communicate
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 6caad047-0606-48d4-90fc-f50ba0cc1abc
---

- Explain Git concepts in plain language — user is learning (staging, commits, push, branches)
- Use analogies for technical concepts (e.g. "staging = putting items in a shopping basket")
- Always offer to run commands on behalf of the user ("want me to commit for you?")
- When showing code locations, use clickable markdown links like [file.dart](path/to/file.dart#L42)
- Always commit and push memory files to GitHub after saving them — user wants memory synced across devices
- Ask before pushing **code** to GitHub — user wants to control when code changes go public
- Keep responses concise — user reads carefully, no need for long explanations
- When user asks "what to do next", give 2-3 clear options ranked by priority

- NEVER ask again about backend language or hosting — confirmed multiple times: **Laravel 12 + Digital Ocean droplet**. DB refined to **PostgreSQL + Redis** (2026-07-06). Adds Vue.js dashboard + Talabat/Careem + subscription billing. Architecture = **modular monolith, NOT microservices**.
- NEVER ask again about POS vs web separation — user wants the Foodics model (separate web dashboard + POS app)

**Why:** User is building a real product and learning dev tools simultaneously — needs guidance not just code.
**How to apply:** Balance teaching with doing. Explain the why, not just the how.
