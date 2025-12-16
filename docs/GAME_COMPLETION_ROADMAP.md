# 🎮 Project Guardians - Game Completion Roadmap
## Balance & Features Analysis by Senior Game Designer + Problem-Solving Developer

> *"A great tower defense game isn't just about placing towers—it's about creating moments of tension, triumph, and strategic discovery."*

---

## 📊 Current State Assessment

### ✅ What's Working Well
| System | Status | Notes |
|--------|--------|-------|
| **7 Unique Statues** | ✅ Complete | All with abilities, targeting, range |
| **Evolution System** | ✅ Complete | 4 tiers with stat scaling |
| **Shop System** | ✅ Complete | Statues, artifacts, consumables, upgrades |
| **Inventory System** | ✅ Complete | With upgrade application |
| **Blessing System** | ✅ Complete | 5 starting blessings |
| **Basic Combat** | ✅ Complete | Crits, damage numbers, effects |
| **Wave Generation** | ⚠️ Basic | Procedural but lacks variety |
| **Enemy Variety** | ⚠️ Limited | 7 enemies, only 2 bosses |

### ❌ Critical Gaps for Full Game
| Missing | Impact | Priority |
|---------|--------|----------|
| **Meta-Progression** | Players have no reason to replay | 🔴 HIGH |
| **Difficulty Scaling** | Game becomes trivial or impossible | 🔴 HIGH |
| **Enemy Variety** | Waves feel samey after wave 10 | 🔴 HIGH |
| **Tutorial/Onboarding** | New players will be lost | 🟡 MEDIUM |
| **Audio System** | Silent gameplay feels lifeless | 🟡 MEDIUM |
| **Endless Mode** | No goal after wave 20 | 🟢 LOW |

---

## 🔴 PRIORITY 1: Balance Issues (Critical)

### 1.1 Statue Balance Audit

> **Problem:** Some statues are clearly superior, others feel useless.

| Statue | Issue | Recommended Fix |
|--------|-------|-----------------|
| **Sentinel** | Melee range limits usefulness | Increase damage to 20, add stun duration +0.5s |
| **Arcane Weaver** | Chain Lightning too strong early | Reduce bounce damage by 15% per bounce |
| **Huntress** | Piercing is situational | Add 20% crit chance innate bonus |
| **Divine Guardian** | Niche (only vs undead) | Add 10% damage buff aura to nearby statues |
| **Earthshaker** | Ground Slam too expensive (cooldown) | Reduce cooldown from ~15s to 12s |
| **Shadow Dancer** | Blade Storm is godlike | Reduce duration from 5s to 4s |
| **Frost Maiden** | Frozen Prison too powerful | Reduce freeze to 3s, add slow aftermath |

**Note:** Enemies don't attack statues, so HP-related stats are cosmetic. Focus on damage/utility balance.

**Implementation Priority:** Medium - Can be adjusted via `.tres` files

---

### 1.2 Economy Balance

> **Problem:** Gold income doesn't scale well; either feast or famine.

**Current Issues:**
- Wave 1: ~100g → Can afford almost nothing useful
- Wave 5+: Gold snowballs if you're winning
- Boss kill (200g) makes or breaks runs

**Recommended Fixes:**

```diff
## Economy Adjustments
- Wave completion bonus: 50g + (wave × 10)
+ Wave completion bonus: 75g + (wave × 15)

- Starting gold: 150g
+ Starting gold: 200g (allows 1 cheap statue OR save for reroll)

- Reroll cost: 50g + 25g/reroll
+ Reroll cost: 30g + 20g/reroll (first reroll more accessible)
```

**Implementation:** Modify `GameManager.gd` constants

---

### 1.3 Difficulty Curve

> **Problem:** Difficulty spikes at wave 5 (first boss) and wave 10+.

**Current Wave Scaling:**
```
Wave 1-3: Goblins only → Too easy, players may over-invest
Wave 4:   First orcs → Sudden HP jump
Wave 5:   BOSS → Spike, unprepared players die here
Wave 6-9: Mixed → Manageable if you survived boss
Wave 10:  Boss + Necromancers → Often fatal
```

**Recommended Difficulty Curve:**

| Wave | Challenge Level | Notes |
|------|-----------------|-------|
| 1-2 | Tutorial | Only goblins, slow pace |
| 3-4 | Introduction | Add orcs gradually (1-2) |
| 5 | First Test (Mini-Boss) | Goblin King with reduced HP |
| 6-7 | Build-up | Mixed waves, moderate pressure |
| 8-9 | Preparation | Introduce necromancers (1) |
| 10 | Challenge | Orc Warlord (full boss) |
| 11+ | Escalating | Elite modifiers begin |

**Implementation:** Overhaul `wave_data.gd` → `generate_wave()`

---

## 🔴 PRIORITY 2: Missing Core Features

### 2.1 Meta-Progression System

> **GDD promises this but it's not implemented!**

**What's Needed:**
```
┌─────────────────────────────────────────────────────┐
│                 AETHER SANCTUM                      │
│   (Between-run progression screen)                  │
├─────────────────────────────────────────────────────┤
│  ⭐ Aether Essence: 1,250                           │
│                                                     │
│  🔓 UNLOCKS:                                        │
│  ├─ New Statue: Necrodancer [750 AE] - LOCKED      │
│  ├─ New Artifact: Blood Rune [300 AE] - UNLOCKED   │
│  └─ New Blessing: Divine Shield [400 AE] - LOCKED  │
│                                                     │
│  📈 PERMANENT UPGRADES:                             │
│  ├─ Starting Gold +25 [200 AE] - Lvl 0/5           │
│  ├─ Base Crit Chance +2% [150 AE] - Lvl 1/3        │
│  └─ Crystal Max HP +10% [200 AE] - Lvl 0/4         │
└─────────────────────────────────────────────────────┘
```

**Files to Create:**
- `scenes/ui/meta_progression_ui.tscn` - The sanctum screen
- `scripts/ui/meta_progression_ui.gd` - Controller
- `scripts/data/meta_unlock.gd` - Resource for unlocks

**Implementation Complexity:** HIGH (3-5 hours)

---

### 2.2 Elite Enemy System

> **Makes late-game waves more interesting**

**Elite Modifiers (Wave 8+):**

| Modifier | Effect | Visual |
|----------|--------|--------|
| **Enraged** | +50% damage, +30% speed | Red tint + particles |
| **Armored** | 40% damage reduction | Metallic shader |
| **Swift** | +80% movement speed | Motion blur trail |
| **Vampiric** | Heals 20% of damage dealt | Green health particles |
| **Splitting** | Spawns 2 mini versions on death | Pulsing glow |

**Implementation:**
- Add `elite_modifier: String` to enemy spawning
- Apply modifier effects in `enemy_base.gd → setup()`
- 15% chance for elite at wave 8+, 30% at wave 12+

---

### 2.3 Missing Enemy Types (GDD vs Reality)

**Currently Missing from GDD:**

| Enemy | Ability | Priority |
|-------|---------|----------|
| **Troll Brute** | Slow, very high HP, resists CC | HIGH |
| **Shadow Imp** | Teleports forward every 3s | MEDIUM |
| **Shielded Knight** | 75% frontal armor | MEDIUM |
| **Dragon Whelp** | Flying (only ranged can hit) | HIGH |

**Implementation:** Create 4 new `.tres` files in `/resources/enemies/`

---

### 2.4 Additional Bosses

**Currently:** Only 2 bosses (Goblin King, Orc Warlord)

**GDD Specifies:**
| Wave | Boss | Unique Mechanic |
|------|------|-----------------|
| 5 | Goblin King | Summons goblin swarms |
| 10 | Orc Warlord | War cry buffs all enemies |
| 15 | Necromancer Lord | Resurrects fallen enemies |
| 20 | Ancient Dragon | Flying, fire breath cone |

**Implementation:** Create boss resources + add boss AI behaviors

---

## 🟡 PRIORITY 3: Game Feel Enhancements

### 3.1 From JUICE_ENHANCEMENT_PLAN.md - Status

| Feature | Status | Priority |
|---------|--------|----------|
| Damage numbers | ✅ Implemented | - |
| Hit impact effects | ✅ Implemented | - |
| Kill celebration | ✅ Implemented | - |
| Critical hit system | ✅ Implemented | - |
| Combo system | ❌ Not started | MEDIUM |
| Wave celebrations | ❌ Not started | MEDIUM |
| Shop purchase juice | ❌ Not started | LOW |
| Evolution spectacle | ❌ Not started | HIGH |

### 3.2 Combo System (Recommended)

> **Creates exciting moment-to-moment gameplay**

```gdscript
# Design:
# - Track kills within 2 seconds of each other
# - Display combo counter: "x3 COMBO!"
# - Bonus gold at x5 (+5g), x10 (+15g), x20 (+50g)
# - Combo text grows larger/brighter with higher counts
```

**Files Needed:**
- `autoload/ComboManager.gd` - Singleton to track combos
- Update `enemy_base.gd → _die()` - Register kills
- Update `hud_controller.gd` - Display combo counter

---

### 3.3 Evolution Spectacle

> **THE most important moment - player just powered up!**

**Missing Effects:**
- [ ] Particles spiral toward merge point
- [ ] Flash of light on completion
- [ ] New statue materializes with divine glow
- [ ] Tier stars appear one by one
- [ ] Brief time slowdown during merge

---

## 🟢 PRIORITY 4: Polish & Extras

### 4.1 Crystal Tension Effects

When crystal HP < 30%:
- Screen edge red vignette
- Crystal pulses/shakes
- "DANGER" text flash
- Heartbeat visual pulse

### 4.2 Tutorial System

**Suggested Flow:**
1. Wave 1: "Place your statue on the glowing tiles"
2. Wave 1: "Click ability button when it glows"
3. Wave 2: "Open shop between waves to buy items"
4. Wave 3: "Combine two identical statues to evolve"
5. Wave 5: "This is a BOSS wave—prepare wisely!"

### 4.3 Run Statistics Screen

After game over, show:
- Waves survived
- Total kills
- Highest combo
- Gold earned
- Favorite statue (most kills)
- Damage dealt

---

## 📋 Implementation Phases

### Phase 1: Balance & Bug Fixes (1-2 days)
- [ ] Adjust statue stats in `.tres` files
- [ ] Fix economy values in `GameManager.gd`
- [ ] Smooth difficulty curve in `wave_data.gd`
- [ ] Test waves 1-15 for feel

### Phase 2: Core Missing Features (3-5 days)
- [ ] Meta-progression UI + save/load
- [ ] Elite enemy modifiers
- [ ] 4 missing enemy types
- [ ] 2 missing bosses (Necromancer Lord, Ancient Dragon)

### Phase 3: Game Feel (2-3 days)
- [ ] Combo system
- [ ] Evolution spectacle
- [ ] Wave celebrations
- [ ] Crystal tension effects

### Phase 4: Polish (2-3 days)
- [ ] Tutorial prompts
- [ ] Run statistics screen
- [ ] Settings menu (volume prep for audio)
- [ ] Final balance pass

### Phase 5: Audio (when ready)
- [ ] Integrate sound effects
- [ ] Add background music
- [ ] UI sounds

---

## 🎯 Quick Wins (Do These First!)

These require minimal code and maximum impact:

### 1. Stat Tweaks (30 min)
Edit `.tres` files to balance statues:
```
sentinel.tres: base_damage = 20 (was 15)
shadow_dancer.tres: ability_cooldown = 14.0 (was 12)
```

### 2. Economy Boost (15 min)
In `GameManager.gd`:
```gdscript
const STARTING_GOLD = 200  # was 150
const WAVE_BASE_GOLD = 75  # was 50
```

### 3. First Reroll Discount (10 min)
In `shop_manager.gd`:
```gdscript
const BASE_REROLL_COST = 30  # was 50
const REROLL_INCREMENT = 20  # was 25
```

### 4. Gradual Orc Introduction (20 min)
In `wave_data.gd → generate_wave()`:
```gdscript
# Wave 3: Add 1-2 orcs instead of waiting until wave 4
elif wave_num == 3:
    wave.spawn_groups.append({"enemy_id": "goblin", "count": base_count - 2, "delay": 0.0})
    wave.spawn_groups.append({"enemy_id": "orc", "count": 2, "delay": 1.0})
```

---

## 🔍 Technical Debt Identified

| Issue | Location | Severity |
|-------|----------|----------|
| Magic numbers in wave generation | `wave_data.gd` | LOW |
| No object pooling for enemies | `arena.gd` | MEDIUM (perf) |
| Hardcoded boss IDs | `wave_data.gd:76-78` | LOW |
| Missing null checks in some signals | Various | LOW |

---

## ✅ Definition of Done: "Full Game"

The game is **complete** when:

1. ☐ Player can progress through 20 waves with satisfying difficulty
2. ☐ All 7 statues feel viable and distinct
3. ☐ At least 4 enemy types with unique behaviors
4. ☐ 4 bosses with unique mechanics
5. ☐ Meta-progression incentivizes replay
6. ☐ Tutorial teaches core mechanics
7. ☐ Visual/audio feedback on all actions
8. ☐ Run statistics feel rewarding to review
9. ☐ No obvious exploits or trivial strategies
10. ☐ Game runs smoothly at 60 FPS with 50+ enemies

---

*Last Updated: December 15, 2024*
*Authored by: Senior Game Designer + Problem-Solving Developer*
