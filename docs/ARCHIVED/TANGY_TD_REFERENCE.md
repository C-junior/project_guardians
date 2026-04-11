# Tangy TD - Game Design Reference Document

> **Source Material for Heroine Tower Development**
> Complete data extracted from Tangy TD (Cakez, 2026) for replication reference

---

## 1. Game Overview

**Title:** Tangy TD: Hero Tower Defense
**Developer:** Cakez (Solo Developer - 4 years development)
**Release Date:** March 9, 2026
**Genre:** Tower Defense / Roguelite / Hero-based
**Platform:** PC (Steam)
**Reviews:** 89% Positive on Steam
**Price Point:** $14.99 USD

### 1.1 Core Concept

Tangy TD is a tower defense roguelite where players control a witch (Tangy) who can:
- Place class-based towers (Defender, Archer, Healer)
- Equip towers with items that grant powerful abilities
- Combine items for synergistic builds
- Move towers freely during gameplay for tactical adjustments
- Progress through a massive skill tree (300+ nodes)

### 1.2 Key Features Summary

| Feature | Details |
|---------|---------|
| Classes | 3 unique classes with individual skill trees |
| Skill Tree | 300+ nodes per class |
| Items | 100+ unique combinable items |
| Equipment Slots | 4 slots per tower |
| Campaign | 8 missions with 6 unique bosses |
| Endless Mode | Ranked infinite mode with global leaderboards |
| Grid Type | Free placement (towers fully mobile) |
| Progression | Roguelite meta-progression between runs |

---

## 2. Class System

### 2.1 Class Overview

| Class | Role | Playstyle | Key Mechanic |
|-------|------|-----------|--------------|
| **Defender** | Tank / Frontline | Hold the line, absorb damage | High HP, damage mitigation, aggro control |
| **Archer** | DPS / Ranged | High burst damage from distance | **+20% damage when isolated** (Lone Ranger) |
| **Healer** | Support / Buffer | Restore HP, apply buffs, sustain frontline | Aura-based healing, buff application |

### 2.2 Defender Class Details

**Role:** Primary tank and frontline anchor
**Strengths:**
- High base HP and armor
- Can absorb and redirect enemy attacks
- Essential for protecting cores in late waves
- Aggro management capabilities

**Key Abilities (from skill tree):**
- Taunt / Force enemy targeting
- Shield allies behind frontline
- Damage reflection
- Area denial / Zone control

**Typical Stats Progression:**
- Base HP: Highest of all classes
- Attack: Low-Moderate
- Defense: Highest mitigation
- Utility: Aggro control, positioning

### 2.3 Archer Class Details

**Role:** Primary damage dealer (DPS)
**Strengths:**
- Highest damage output
- Long attack range
- Burst damage potential
- Critical hit scaling

**Key Mechanic - Lone Ranger:**
- **+20% damage when positioned alone** (no adjacent towers)
- This is a core skill tree node that defines Archer playstyle
- Encourages strategic spacing and isolation builds

**Typical Stats Progression:**
- Base HP: Lowest of all classes
- Attack: Highest of all classes
- Range: Longest reach
- Critical Chance: Scales with skill tree investment

### 2.4 Healer Class Details

**Role:** Support and sustain
**Strengths:**
- Restores ally HP
- Applies buffs (attack speed, damage, defense)
- Cleanses debuffs (at higher skill levels)
- Keeps frontline alive in extended fights

**Key Abilities:**
- Aura-based healing (area effect around tower)
- Single-target emergency heals
- Buff application (damage, speed, shields)
- Debuff removal (advanced skill nodes)

**Typical Stats Progression:**
- Base HP: Moderate
- Attack: Lowest
- Healing Power: Scales significantly with items
- Aura Radius: Expandable via skill tree

---

## 3. Skill Tree System

### 3.1 Overview

- **Total Nodes:** 300+ per class
- **Structure:** Branching paths with specialization options
- **Currency:** Skill Points earned from defeating enemies
- **Reset:** Full respec available (redistribute all points)

### 3.2 Skill Tree Categories

Each class tree contains nodes in these categories:

| Category | Description | Example Effects |
|----------|-------------|-----------------|
| **Core Stats** | Base attribute increases | +HP, +Attack, +Range, +Attack Speed |
| **Abilities** | Active/passive skills | Chain lightning, heal aura, taunt |
| **Synergies** | Conditional bonuses | Lone Ranger (+20% isolated damage) |
| **Utility** | Quality of life improvements | Extra equipment slots, cooldown reduction |
| **Ultimates** | End-game powerful nodes | Game-changing abilities |

### 3.3 Known Skill Tree Nodes

| Node Name | Class | Effect |
|-----------|-------|--------|
| **Lone Ranger** | Archer | +20% damage when no adjacent towers |
| **Aura Radius** | Healer | Increases healing aura area of effect |
| **Frontline** | Defender | Improved aggro generation and damage reduction |

*Note: Full 300+ node list not publicly documented. These are confirmed nodes from guides and patch notes.*

### 3.4 Skill Point Economy

- **Source:** Defeating enemies grants skill points
- **Spending:** Permanent investment in class skill tree
- **Persistence:** Roguelite progression - skills persist between runs
- **Respec:** Full reset allows retesting different builds

---

## 4. Item & Equipment System

### 4.1 Overview

- **Total Items:** 100+ unique items
- **Equipment Slots:** 4 slots per tower
- **Rarity Tiers:** S (Legendary), A (Epic), B (Rare), C (Uncommon), D (Common)
- **Crafting:** Cauldron system (v1.0.3) - sacrifice items for same-tier replacements
- **Synergy:** Items combine to create powerful build combinations

### 4.2 Item Rarity System

| Tier | Rarity | Color | Drop Frequency | Power Level |
|------|--------|-------|----------------|-------------|
| **S** | Legendary | Orange | Very Rare | Game-changing abilities |
| **A** | Epic | Purple | Rare | Strong unique effects |
| **B** | Rare | Blue | Uncommon | Solid stat bonuses |
| **C** | Uncommon | Green | Common | Moderate bonuses |
| **D** | Common | White | Very Common | Basic stat increases |

### 4.3 Confirmed Items List

#### S-Tier (Legendary) Items

| Item Name | Type | Effect |
|-----------|------|--------|
| **Wand of Lightning** | Weapon | Chain lightning that bounces to 4-5 enemies |
| **Pumpkin King** | Accessory | Summons a golem that explodes on death |

#### A-Tier (Epic) Items

| Item Name | Type | Effect |
|-----------|------|--------|
| **Emerald Bow** | Weapon | Arrows pierce through enemies + scaling damage (damage ramp) |
| **Venom Bow** | Weapon | Poison burst: applies 5 stacks of poison + slow effect |
| **Ban Hammer** | Weapon | 15% chance to stun target; stunned target takes +25% damage |
| **Ultra Vision Goggles** | Accessory | +40% attack range; prioritizes target with highest HP |

#### B-Tier (Rare) Items

| Item Name | Type | Effect |
|-----------|------|--------|
| **Ivy Bow** | Weapon | Root effect on hit: immobilizes target for 0.8 seconds |
| **Stone Hammer** | Weapon | Slam attack: AoE knockback every 8 hits |

#### Additional Items (v1.0.3 Patch)

- **8 new items** added in version 1.0.3
- Specific names and effects not publicly documented

### 4.4 Item Stats & Numbers Reference

| Item | Stat Values |
|------|-------------|
| Ban Hammer | 15% stun chance, +25% damage taken on stunned target |
| Ultra Vision Goggles | +40% range increase |
| Ivy Bow | 0.8s root duration |
| Venom Bow | 5 poison stacks + slow |
| Wand of Lightning | Chains to 4-5 enemies |
| Stone Hammer | AoE knockback every 8 hits |
| Archer Lone Ranger | +20% isolated damage |

### 4.5 Item Acquisition Methods

| Method | Description |
|--------|-------------|
| **Boss Drops** | Defeating bosses drops items (higher difficulty = better quality) |
| **Crafting (Cauldron)** | Sacrifice any item → choose replacement from same tier |
| **Box Opening** | Random item boxes from shop or rewards |
| **Wave Rewards** | Completing specific wave milestones |

### 4.6 Crafting System (Cauldron)

**Introduced:** Version 1.0.3

**Mechanics:**
- Place any item into the Cauldron
- Item is consumed/destroyed
- Player receives a choice of replacement items **from the same tier**
- **Purpose:** Fix bad runs by converting unwanted items into useful options
- **No fixed recipes:** Dynamic selection based on available item pool

**Strategy Use:**
- Convert duplicate items into variety
- Pivot builds mid-run when key items aren't dropping
- Optimize late-game equipment distribution

---

## 5. Enemy System

### 5.1 Enemy Mechanics Overview

- **Wave Structure:** Enemies spawn in waves with exponentially increasing difficulty
- **Fight Back:** Enemies actively counter-attack (not just pathfinding puzzles)
- **Reactive AI:** Enemies respond to tower placement and pressure spikes
- **Positioning Matters:** Tower placement, timing, and threat management are critical

### 5.2 Enemy Behavior Patterns

| Behavior | Description |
|----------|-------------|
| **Standard Advance** | Move toward player base/core along path |
| **Counter-Attack** | Target and attack player towers directly |
| **Special Abilities** | Some enemies have unique attack patterns |
| **Boss Mechanics** | Phase transitions, armor phases, summoning minions |

---

## 6. Boss System

### 6.1 Boss Overview

- **Total Bosses:** 6 unique bosses
- **Distribution:** One boss per major mission/campaign stage
- **Mechanics:** Each boss has unique abilities and weaknesses
- **Phase System:** Most bosses have multiple phases with different behaviors

### 6.2 Confirmed Boss List

| Boss Name | Map Location | Key Mechanics | Weaknesses/Notes |
|-----------|--------------|---------------|------------------|
| **The Butcher** | Bay Harbour | Spike attack, summons catapults | Damage reduced ~15% in v1.0.2 |
| **The Warden** | Mountain Trail | Patrol pattern, wall-breaking | Requires strategic positioning |
| **Thorn** | Deep Forest | One-shot spike ability, high mobility | Kiting and crowd control effective |
| **The Hollow King** | The Vale | Summons waves of minions, phase transitions | Clear adds quickly |
| **The Iron Warden** | Irongate | Armor phases, siege machines | Armor penetration needed |
| **The Final Witch** | The Abyss | Mirror mechanics, AoE wipe attacks | Ultimate boss fight |

### 6.3 Boss Mechanics Explained

#### The Butcher (Bay Harbour)
- **Spike Attack:** Deals damage in area with spike projectiles
- **Catapult Summoning:** Calls in siege units that attack from range
- **Patch Note:** Damage output reduced by ~15% in v1.0.2 for balance

#### The Warden (Mountain Trail)
- **Patrol Pattern:** Moves in specific routes before attacking
- **Wall Breaking:** Can destroy defensive structures/barriers
- **Strategy:** Position towers to maximize damage during patrol phase

#### Thorn (Deep Forest)
- **One-Shot Spike:** Instant high-damage attack that can kill weakened towers
- **High Mobility:** Moves quickly across the battlefield
- **Counter:** Crowd control (root, stun) and kiting tactics

#### The Hollow King (The Vale)
- **Minion Summoning:** Spawns waves of additional enemies
- **Phase Transitions:** Changes behavior/abilities at health thresholds
- **Strategy:** Balance boss damage with add-clearing

#### The Iron Warden (Irongate)
- **Armor Phases:** Gains damage reduction shields periodically
- **Siege Machines:** Deploys mechanical units with high HP
- **Counter:** Armor-piercing items and focused fire

#### The Final Witch (The Abyss)
- **Mirror Mechanics:** Reflects damage or creates duplicate entities
- **AoE Wipes:** Area-of-effect attacks that can clear multiple towers
- **Role:** Final campaign boss, most complex mechanics

---

## 7. Campaign & Missions

### 7.1 Campaign Structure

- **Total Missions:** 8 main story missions
- **Boss Encounters:** 6 bosses distributed across missions
- **Difficulty Curve:** Exponential scaling between missions
- **Item Quality:** Higher mission difficulty increases drop quality

### 7.2 Mission List (Inferred from Boss Maps)

| Mission | Map Name | Boss | Theme |
|---------|----------|------|-------|
| 1-2 | Bay Harbour | The Butcher | Coastal/Industrial |
| 3 | Mountain Trail | The Warden | Highland/Path |
| 4 | Deep Forest | Thorn | Woodland/Nature |
| 5-6 | The Vale | The Hollow King | Valley/Dark |
| 7 | Irongate | The Iron Warden | Fortress/Siege |
| 8 | The Abyss | The Final Witch | Final confrontation |

*Note: Exact mission-to-boss mapping inferred from available data. May vary in-game.*

---

## 8. Game Modes

### 8.1 Campaign Mode

- **Description:** Structured story progression through 8 missions
- **Objective:** Complete all missions and defeat all 6 bosses
- **Difficulty:** Scales with mission number
- **Rewards:** Items, skill points, progression unlocks

### 8.2 Endless Mode (Ranked)

- **Description:** Infinite waves of enemies with never-stopping scaling
- **Objective:** Survive as long as possible
- **Scaling:** Exponential difficulty increase with each wave
- **Leaderboard:** Global ranking based on wave count / survival time
- **Crash Fix:** Waves 50+ stability fixed in v1.0.1

### 8.3 Difficulty System

- **Difficulty Impact:** Higher difficulty = better item drop quality
- **Risk vs Reward:** Players can choose harder challenges for better loot
- **Build Adaptation:** Different map/boss combinations require build adjustments

---

## 9. Core Gameplay Mechanics

### 9.1 Tower Movement System

- **Free Placement:** Towers can be placed anywhere on the map
- **Real-Time Repositioning:** Move towers during gameplay for tactical adjustments
- **No Grid Restriction:** Not locked to hex or square grid (free placement)
- **Strategy Implications:**
  - Archer isolation for Lone Ranger bonus
  - Healer aura positioning for maximum coverage
  - Defender frontline formation and spacing

### 9.2 Aggro System

**Introduced:** Version 1.0.2

- **Aggro Meter:** Visible indicator of enemy targeting priority
- **Replaced:** Instant "pull" boss mechanics from earlier versions
- **Function:** Shows which tower enemies are focusing
- **Strategy:** Use Defender taunts to protect vulnerable towers

### 9.3 Throwing Mechanic

- **Player Control:** Tangy (the witch) can throw items or interact with battlefield
- **Tactical Use:** Reposition objects, trigger effects, or assist towers
- **Timing:** Part of real-time tactical decision-making

### 9.4 Phase Transitions

- **Boss Phases:** Bosses change behavior at certain HP thresholds
- **Armor Phases:** Temporary damage reduction states (e.g., Iron Warden)
- **Adaptation Required:** Players must adjust strategy between phases

### 9.5 Synergy & Combination System

- **Item Combos:** 100+ crafting recipes for powerful combinations
- **Build Sinergy:** Items work together to create specific playstyles
- **Map-Specific Combos:** Different maps favor different synergies
- **Build Types:**
  - Safe farming builds (consistent damage, sustainability)
  - High-risk scaling builds (exponential power, fragile early)

---

## 10. Progression System

### 10.1 Roguelite Meta-Progression

| Element | Persistence | Description |
|---------|-------------|-------------|
| **Skill Tree** | ✅ Permanent | Skill points and nodes persist between runs |
| **Item Discovery** | ✅ Permanent | Unlocked items available in future runs |
| **Run Items** | ❌ Temporary | Items/equipment reset each run |
| **Partial Loss** | ⚠️ Roguelite | Some progress retained, not full wipe |

### 10.2 Progression Loop

```
Play Run → Defeat Enemies → Earn Skill Points
    ↓
Invest in Skill Tree → Stronger Future Runs
    ↓
Defeat Bosses → Better Quality Items
    ↓
Optimize Builds → Push Higher Waves/Missions
    ↓
Respec if Needed → Try Different Combinations
```

### 10.3 Build Archetypes

| Build Type | Focus | Risk Level | Description |
|------------|-------|------------|-------------|
| **Safe Farm** | Consistent damage, sustainability | Low | Reliable clears, slower scaling |
| **High-Risk Scale** | Exponential power growth | High | Fragile early, insane late-game numbers |
| **Defender Core** | Tank-heavy, attrition | Low-Medium | Outlast enemies through mitigation |
| **Archer Burst** | Isolated high DPS | Medium | Lone Ranger bonus maximization |
| **Healer Sustain** | Endurance through healing | Medium | Keep towers alive indefinitely |

---

## 11. Version History & Balance

### 11.1 Key Patches

| Version | Changes |
|---------|---------|
| **v1.0.0** | Initial release: 8 missions, 6 bosses, 3 classes, 300+ skill nodes |
| **v1.0.1** | Healer aura tooltip fix, Endless mode crash fix (wave 50+) |
| **v1.0.2** | Aggro Meter added (replaced boss instant pull), Butcher damage -15%, Shield Orb exploit fixed |
| **v1.0.3** | Cauldron crafting system added, 8 new items |

### 11.2 Balance Philosophy

- **Damage Numbers Goal:** "Make damage numbers go crazy" - exponential scaling is intentional
- **Build Diversity:** Regular patch updates with build recommendations
- **Exploit Fixes:** Quick response to unintended mechanics (Shield Orb exploit)
- **Boss Tuning:** Selective damage adjustments (Butcher -15%)

---

## 12. Technical & Design Notes

### 12.1 Visual Style

- **Art Style:** Vibrant pixel art
- **Tower Representation:** Class-based characters (Defender, Archer, Healer)
- **Enemy Design:** Varied per map/boss theme
- **UI:** Clean, accessible information display (aggro meter, skill tree, inventory)

### 12.2 Performance

- **Smooth Performance:** Optimized for various PC configurations
- **Wave 50+:** Required stability patch for late-game endless mode
- **Scaling:** Handles exponential number growth (large damage numbers)

### 12.3 Key Design Takeaways for Replication

1. **Free Tower Movement** - Not grid-locked, tactical repositioning is core
2. **Class Identity** - 3 distinct roles (Tank, DPS, Support) with clear purposes
3. **Skill Tree Depth** - 300+ nodes provide massive customization
4. **Item Synergy** - 100+ items with 4 slots = build diversity
5. **Roguelite Loop** - Permanent progression + run-based gameplay
6. **Boss Uniqueness** - 6 bosses with memorable mechanics, not stat sticks
7. **Exponential Scaling** - Numbers get absurd, that's the fun
8. **Real-Time Tactics** - Not set-and-forget, active decision-making matters

---

## 13. Reference Numbers Summary

### Quick Stats Table

| Category | Count |
|----------|-------|
| Classes | 3 |
| Skill Tree Nodes | 300+ |
| Unique Items | 100+ |
| Equipment Slots | 4 per tower |
| Campaign Missions | 8 |
| Unique Bosses | 6 |
| Crafting Recipes | 100+ |
| Game Modes | 2 (Campaign + Endless) |

### Confirmed Numeric Values

| Mechanic | Value |
|----------|-------|
| Archer Lone Ranger bonus | +20% damage |
| Ban Hammer stun chance | 15% |
| Ban Hammer damage amplification | +25% |
| Ultra Vision Goggles range | +40% |
| Ivy Bow root duration | 0.8 seconds |
| Venom Bow poison stacks | 5 stacks |
| Wand of Lightning chain targets | 4-5 enemies |
| Stone Hammer knockback frequency | Every 8 hits |
| Butcher damage nerf (v1.0.2) | -15% |

---

## 14. Application to Heroine Tower

### 14.1 Adaptation Notes


### 14.2 Recommended Priority

1. **High Priority:**
   - Unique boss mechanics (phases, abilities, not just HP/ATK scaling)
   - Equipment slots and item effects for heroines
   - Conditional bonuses (like Lone Ranger) for positioning strategy

2. **Medium Priority:**
   - Meta-progression skill tree (post-campaign content)
   - Tower repositioning during battles
   - Aggro/targeting visibility

3. **Lower Priority:**
   - Cauldron-style crafting (complex system addition)
   - 100+ item catalog (start with 20-30 core items)
   - Endless mode leaderboard (PvP foundation first)

---

*Document compiled from Tangy TD wiki, guides, patch notes, and Steam information.*
*Last Updated: April 2, 2026*

