# Project Guardians Tangy-Style MVP Adaptation

## Purpose

This document adapts Project Guardians toward the Tangy TD reference without turning the game into a clone. The goal is to keep the heroine-statue fantasy, shop loop, blessings, and evolution, while adding the tactical identity that makes Tangy feel distinct: repositioning, role clarity, equipment decisions, spacing bonuses, and enemy pressure.

## Current Project Baseline

The current game already has strong foundations:

- Wave combat, bosses, multiple enemy types, and map data
- Shop, inventory, consumables, blessings, and meta progression
- Statue placement, drag-and-drop deployment, upgrades, and evolution
- Manual abilities, target priorities, and visible combat feedback

Because of that, the MVP should focus on adaptation mechanics, not on rebuilding the whole game.

## Adaptation Goal

Shift Project Guardians from a "shop-heavy roguelite TD with evolutions" into a "tactical heroine defense roguelite" where the player wins by:

- Building a formation with clear frontline, damage, and support jobs
- Repositioning statues when the lane pressure changes
- Equipping a small number of meaningful statue-bound upgrades
- Using spacing and formation bonuses intentionally
- Reading enemy focus and reacting before the crystal collapses

## Design Rules For The MVP

1. Keep Project Guardians' identity first.
   The statues, sacred crystal, ascension flavor, and heroine roster stay as the main fantasy.

2. Borrow Tangy's structure, not its exact content.
   We want Tangy-like decision pressure, not a one-to-one copy of classes, items, or progression scale.

3. Add only mechanics that change decisions during a run.
   If a system does not change placement, timing, or build choices, it is not MVP-critical.

4. Reuse existing systems whenever possible.
   Drag-and-drop placement, upgrade slots, boss waves, map resources, and inventory UI should be extended instead of replaced.

## What Changes In The MVP

### 1. Formation-Based Play

The game currently rewards having stronger statues. The MVP should also reward putting the right statue in the right place.

Target outcome:

- Frontline statues want exposed positions
- DPS statues want clean firing lines or isolation
- Support/control statues want coverage over key allies

### 2. Repositioning Becomes A Core Action

Tangy's biggest influence should be mobility. Project Guardians currently supports placement well, but once combat begins the battlefield is mostly static.

MVP decision:

- Allow free reposition during shop/setup
- Add one limited in-combat reposition tool
- Make repositioning a tactical rescue tool, not full-time micro spam

Recommended MVP rule:

- Each wave grants 1 "Relocate" charge
- Relocate can move one placed statue to an empty valid cell
- Relocate has a short lockout or cast time so it cannot be abused

This captures Tangy's tactical feel without requiring fully free live dragging all the time.

### 3. Class Identity Is Added As Tactical Roles

Tangy has 3 strong class identities. Project Guardians has 7 statues already, so the MVP should group them into clear battlefield roles instead of reducing the roster.

Recommended role mapping:

- Frontline: Sentinel, Earthshaker
- Precision DPS: Huntress, Shadow Dancer, Arcane Weaver
- Support/Control: Divine Guardian, Frost Maiden

Each role should get one simple battlefield rule:

- Frontline bonus: gains mitigation or threat when closest to enemies
- Precision bonus: gains damage when isolated or when attacking uninterrupted
- Support bonus: grants aura healing, shields, or cooldown help to nearby allies

### 4. Upgrades Become Statue-Bound Equipment

Project Guardians already has upgrades and slot logic. The MVP should present these as per-statue equipment, because that is one of the clearest Tangy-style adaptations.

Recommended MVP approach:

- Keep global artifacts as run-level modifiers
- Reframe upgrades as statue equipment/runes
- Limit MVP equipment pool to 6-8 high-impact options
- Equipment stays attached to the statue, not the whole run

Good MVP equipment examples:

- Range Rune: plus range
- Power Rune: plus damage
- Guard Rune: plus health and threat
- Echo Rune: chance to repeat attack
- Venom Rune: poison on hit
- Focus Lens: bonus damage to highest-HP target

### 5. Positioning Synergies

This is where the Tangy adaptation becomes visible.

Recommended MVP synergies:

- Lone Hunt: Huntress gets bonus damage when no adjacent allied statues exist
- Sacred Line: Sentinel gains mitigation when placed ahead of all allies in its lane
- Sanctuary Aura: Divine Guardian heals or shields allies inside a radius
- Frost Zone: Frost Maiden slows enemies more when placed behind a frontline ally

Only 3-4 synergies are needed for MVP. They should be readable, visible, and easy to test.

### 6. Enemy Pressure And Soft Aggro

Tangy enemies fight back against the formation. In Project Guardians, enemies mostly pressure the crystal and do not create enough formation tension.

MVP goal:

- Add soft aggro, not a full tactical AI rewrite

Recommended MVP rule set:

- Some enemies can target statues before reaching the crystal
- Frontline statues generate more threat than backline statues
- HUD or world markers show which statue is being focused

This is enough to make frontline placement matter.

### 7. Bosses Need One Real Tactical Phase

Bosses already exist, but the MVP needs at least one boss that changes the player's positioning plan during the fight.

Recommended MVP boss pattern:

- Phase 1: pressures crystal directly
- Phase 2: switches to statue-targeting attack or lane sweep
- Phase 3: summons adds or creates unsafe zones

One polished boss with readable phase changes is more valuable than many bosses with only higher stats.

## MVP Scope

The MVP should target one polished adaptation slice, not the full final game.

### Included

- 1 map
- 8 to 10 waves
- 1 boss with at least 2 phases
- 4 to 5 statues tuned around role identity
- 6 to 8 statue-bound equipment items
- Limited in-combat reposition
- 3 to 4 positioning synergies
- Soft aggro/focus feedback

### Explicitly Not In MVP

- 300-node skill trees
- 100+ item pool
- Cauldron/crafting
- Endless mode rebalance
- Fully free real-time tower dragging with no limits
- Full boss roster rework

## Recommended Statue Set For The Adaptation Slice

Use a focused subset first:

- Sentinel as frontline anchor
- Huntress as isolated DPS check
- Divine Guardian as support aura unit
- Frost Maiden as control support
- Arcane Weaver as flexible DPS/control bridge

This set is enough to prove the adaptation loop before Earthshaker and Shadow Dancer are retuned into the new rules.

## System Mapping To Existing Code

These are the best current extension points:

- `scripts/combat/arena.gd`
  For relocate flow, placement rules, and tactical move validation
- `scripts/combat/statue_base.gd`
  For role passives, adjacency checks, aura effects, and equipment application
- `scripts/combat/enemy_base.gd`
  For soft aggro, statue-targeting enemies, and boss behavior hooks
- `scripts/ui/inventory_ui.gd`
  For equipment presentation and relocate interaction
- `autoload/GameManager.gd`
  For relocate charges, run flags, and adaptation-mode data
- `scripts/data/statue_data.gd`
  For role tags, passive definitions, and equipment compatibility

## MVP Success Criteria

The adaptation MVP is successful when:

- The player changes statue positions because of enemy pressure, not only because of shop purchases
- Huntress, Sentinel, and Divine Guardian feel different because of battlefield rules, not only stats
- At least one run can be won through smart formation decisions even without lucky shop rolls
- The boss forces one visible mid-fight reposition or frontline adjustment
- Equipment choices feel attached to a specific statue build, not just generic stat inflation

## Final Direction

Project Guardians should not become "Tangy with statues." The best version is "Project Guardians with Tangy-grade tactical readability."

That means:

- retain the statue fantasy
- keep evolution as a major differentiator
- add tactical formation play as the new center of the run

If we build the MVP around that, the adaptation will feel intentional instead of derivative.
