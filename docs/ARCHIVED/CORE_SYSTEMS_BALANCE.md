# 🎮 Core Systems Balance Document
## Project Guardians | Lead Game Designer

> *"Constraints breed creativity—the best runs are the ones where you couldn't have everything."*

---

## 📋 Document Overview

This document defines balance values for four core systems:
1. **Statue Placement Limit** — Maximum statues on the battlefield
2. **Rarity Stat Scaling** — Higher rarity = stronger stats
3. **Upgrade Slot System** — Per-statue upgrade capacity
4. **Consumable Rebalance** — Making consumables relevant

---

## 1. 🏰 Statue Placement Limit

### Design Philosophy
> *"The Grove can only sustain so many awakened guardians..."*

Forces **quality over quantity**. With only 4 slots, players can't have all 7 statue types—they must specialize. This creates:
- Meaningful build diversity
- Evolution becomes more valuable (upgrade existing vs. add new)
- Meta-progression reward: unlock more slots

### Balance Values

| Meta Level | Max Statues | Aether Cost | Cumulative |
|------------|-------------|-------------|------------|
| Base | 4 | Free | - |
| +1 | 5 | 400 AE | 400 AE |
| +2 | 6 | 600 AE | 1,000 AE |
| +3 | 7 | 1,000 AE | 2,000 AE |
| +4 | 8 | 1,500 AE | 3,500 AE |

### Implementation Notes
- Add `max_statues` to GameManager (default 4)
- Add `statue_slots_unlocked` to meta-progression (0-4)
- Check limit in `place_statue()` function
- UI: Show "X/Y Statues" in HUD

---

## 2. ⭐ Rarity Stat Scaling

### Design Philosophy
Higher rarity should **feel** more powerful—not just cost more. Players need the "oh yes!" moment when they see a Legendary in the shop.

### Stat Multipliers by Rarity

| Rarity | ID | Stat Mult | Cost Mult | Drop Weight |
|--------|-----|-----------|-----------|-------------|
| Common | 0 | 1.00× | 1.00× | 50% |
| Uncommon | 1 | 1.15× | 1.25× | 30% |
| Rare | 2 | 1.30× | 1.70× | 15% |
| Epic | 3 | 1.50× | 2.30× | 4% |
| Legendary | 4 | 1.80× | 2.85× | 1% |

### Example DPS by Rarity (Huntress, Base 25 DPS)

| Rarity | DPS | Cost |
|--------|-----|------|
| Common | 25.0 | 400g |
| Uncommon | 28.8 | 500g |
| Rare | 32.5 | 680g |
| Epic | 37.5 | 920g |
| Legendary | 45.0 | 1140g |

### Affected Stats
The rarity multiplier applies to:
- `base_damage`
- `attack_speed`

NOT affected (would break balance):
- `attack_range`
- `ability_cooldown`

### Implementation Notes
- Shop generates random rarity per statue offering
- Rarity is stored in inventory alongside tier
- Rarity visual: colored border/glow on portraits
  - Common: Gray
  - Uncommon: Green
  - Rare: Blue
  - Epic: Purple
  - Legendary: Orange/Gold

---

## 3. 🎴 Upgrade Slot System

### Design Philosophy
> *"Each statue can only bear so many enchantments..."*

Prevents stacking all upgrades on one "god statue." Creates:
- Meaningful upgrade distribution decisions
- Evolution incentive (more tier = more slots)
- Visual clarity of statue power level

### Slots by Evolution Tier

| Tier | Name | Upgrade Slots |
|------|------|---------------|
| 0 | ★ Base | 1 |
| 1 | ★★ Enhanced | 2 |
| 2 | ★★★ Awakened | 3 |
| 3 | ★★★★ Divine | 4 |

### Meta-Progression Bonus
| Upgrade | Effect | Aether Cost |
|---------|--------|-------------|
| Runic Mastery I | +1 base slot (all statues) | 500 AE |
| Runic Mastery II | +1 base slot (all statues) | 1000 AE |

With max upgrades: Base statue = 3 slots, Divine = 6 slots

### UI Mockup
```
┌─────────────────────────────────┐
│  THE HUNTRESS  ★★★   [Rare]    │
│  ┌────┐ ┌────┐ ┌────┐          │
│  │ ⚔️  │ │ 🏹  │ │    │ ← Slots │
│  │DMG+│ │RNG+│ │    │          │
│  └────┘ └────┘ └────┘          │
│  Upgrades: 2/3                  │
└─────────────────────────────────┘
```

### Implementation Notes
- Add `applied_upgrades: Array` to statue instance
- Add `get_max_upgrade_slots() -> int` based on tier + meta bonus
- Check slot availability before applying upgrade
- UI: Show filled/empty slot icons when selecting statue

---

## 4. ⚗️ Consumable Rebalance

### Design Philosophy
Consumables are currently ignored because they're **too expensive for temporary value**. Players hoard gold for permanent investments.

**Fix:** Make consumables cheap "panic buttons" that feel like free insurance.

### Price Rebalance

| Consumable | OLD Price | NEW Price | Change |
|------------|-----------|-----------|--------|
| Battle Horn | 100g | **50g** | -50% |
| Gold Fever | 150g | **75g** | -50% |
| Stone Walls | 75g | **40g** | -47% |
| Slow Time | 100g | **60g** | -40% |

### New Consumables

| Name | Effect | Cost | Drop Wave |
|------|--------|------|-----------|
| **Scout's Map** | Preview next wave composition | 25g | 1+ |
| **Arcane Surge** | +30% ability cooldown recovery this wave | 50g | 5+ |
| **Lucky Coin** | +15% chance for enemies to drop bonus gold | 45g | 3+ |

### Psychology
At 40-60g, consumables become **impulse buys**:
> "It's just 40g... I'll grab Stone Walls in case the boss is rough."

At 100g+:
> "That's 1/4 of a statue. Skip."

### Implementation Notes
- Update consumable `.tres` files with new costs
- Add new consumable resources
- Consider: shop always offers 1 consumable? (guaranteed visibility)

---

## 📊 Meta-Progression Summary

All new unlocks for Aether Sanctum:

| Unlock | Effect | Cost | Category |
|--------|--------|------|----------|
| Sacred Ground I | +1 max statue (5) | 400 AE | Statues |
| Sacred Ground II | +1 max statue (6) | 600 AE | Statues |
| Sacred Ground III | +1 max statue (7) | 1000 AE | Statues |
| Sacred Ground IV | +1 max statue (8) | 1500 AE | Statues |
| Runic Mastery I | +1 base upgrade slot | 500 AE | Upgrades |
| Runic Mastery II | +1 base upgrade slot | 1000 AE | Upgrades |

---

## ✅ Implementation Checklist

### Phase 1: Statue Limit
- [ ] Add `max_statues` variable to GameManager
- [ ] Add meta-progression for statue slots
- [ ] Block placement when limit reached
- [ ] Update HUD to show statue count

### Phase 2: Rarity Scaling
- [ ] Add rarity multiplier constants
- [ ] Apply multiplier in statue setup
- [ ] Store rarity in inventory
- [ ] Visual rarity indicators

### Phase 3: Upgrade Slots
- [ ] Add `applied_upgrades` to statue
- [ ] Add slot calculation based on tier
- [ ] Block upgrade if slots full
- [ ] UI slot display on statues

### Phase 4: Consumables
- [ ] Update consumable prices
- [ ] Create new consumable resources
- [ ] (Optional) Guarantee 1 consumable in shop

---

*Document Version: 1.0*
*Last Updated: December 17, 2024*
*Authored by: Lead Game Designer*
