# 🏰 Map 1: The Sacred Grove - Balance Document
## Project Guardians | Lead Game Designer Balance Sheet

> *"The first map is the player's teacher—every encounter must communicate a clear lesson."*

---

## 📋 Map Overview

| Attribute | Value |
|-----------|-------|
| **Map Name** | The Sacred Grove |
| **Theme** | Forest clearing with stone ruins, corrupted goblin territory |
| **Waves** | 1-20 (Final Boss: Goblin King) |
| **Difficulty** | Tutorial → Standard |
| **Primary Lesson** | Basic statue placement, economy management, evolution |

### The Map's Fantasy
The Sacred Crystal awakens in an ancient grove—once protected, now overrun by goblins. The player must rebuild the grove's defenses using dormant heroine statues and push back the corruption before it reaches the crystal.

---

## 🎯 Design Goals for Map 1

1. **Teach the Core Loop** - Place statues → Kill enemies → Earn gold → Shop → Repeat
2. **Gentle Introduction** - No flying enemies until Wave 16, no shields until Wave 13
3. **First Boss as Skill Check** - Wave 5 tests if player understands statue placement
4. **Evolution Discovery** - Players should naturally get duplicate statues by Wave 7-10
5. **Economy Clarity** - Gold income should feel predictable and manageable

---

## 👹 Enemy Roster - Map 1

### The Baseline Peasant: Goblin Scout
> All other enemies are balanced relative to this unit.

| Stat | Value | Notes |
|------|-------|-------|
| **HP** | 30 | 1.0x baseline |
| **Speed** | 70 | Fast (1.0x baseline) |
| **Crystal Damage** | 5 | Low |
| **Gold Reward** | 5g | Baseline gold value |
| **Threat Level** | ★☆☆☆☆ | Swarm enemy |

**The Test:** *"Do you have any damage at all?"*

---

### Enemy Scaling Table (Relative to Goblin)

| Enemy | HP | Speed | Crystal DMG | Gold | Threat | First Wave | The Test |
|-------|-----|-------|-------------|------|--------|------------|----------|
| **Goblin Scout** | 30 (1.0x) | 70 (1.0x) | 5 | 5g | ★☆☆☆☆ | 1 | Basic DPS check |
| **Orc Warrior** | 60 (2.0x) | 50 (0.7x) | 10 | 10g | ★★☆☆☆ | 3 | Tank awareness |
| **Slime** | 40 (1.3x) | 35 (0.5x) | 5 | 8g | ★★☆☆☆ | 6 | AOE damage check |
| **Troll Brute** | 150 (5.0x) | 30 (0.4x) | 25 | 20g | ★★★☆☆ | 11 | Priority targeting |
| **Necromancer** | 80 (2.7x) | 40 (0.6x) | 15 | 20g | ★★★★☆ | 8 | Focus fire check |
| **Shadow Imp** | 35 (1.2x) | 85 (1.2x) | 8 | 15g | ★★★☆☆ | 11 | Fast + Teleport |
| **Shielded Knight** | 100 (3.3x) | 40 (0.6x) | 20 | 18g | ★★★☆☆ | 13 | Flanking check |
| **Dragon Whelp** | 45 (1.5x) | 60 (0.9x) | 12 | 18g | ★★★★☆ | 16 | Ranged DPS check |

### Enemy Special Abilities

| Enemy | Ability | Mechanical Impact |
|-------|---------|-------------------|
| **Slime** | Splits into 2 Mini-Slimes on death | +2 enemies, 15 HP each |
| **Necromancer** | Summons 2 skeletons every 8s | Endless reinforcements if ignored |
| **Shadow Imp** | Teleports forward every 3s | Bypasses slow, unpredictable pathing |
| **Shielded Knight** | 75% frontal damage reduction | Requires rear attacks or abilities |
| **Dragon Whelp** | Flying | Only ranged/magic statues can hit |

---

## 👑 Boss Encounters

### Wave 5: Goblin King
> *"The first true test—catch players who over-invested in economy."*

| Stat | Value | Notes |
|------|-------|-------|
| **HP** | 200 | Requires ~10s of sustained DPS |
| **Speed** | 40 | Slow march, dramatic tension |
| **Crystal Damage** | 30 | Punishing if he reaches crystal |
| **Gold Reward** | 50g | Massive reward for first boss |
| **Ability** | Summons 3 Goblins every 6s | Forces split attention |

**Player Power Check:** By Wave 5, expect:
- 2-3 statues placed (1 from start + 1-2 purchased)
- ~600-700 total gold earned prior
- At least 1 ability available

**Failure State:** Player has only 1 statue with no upgrades → Goblin King overwhelms

---

### Wave 10: Orc Warlord
> *"Tests if the player has evolved their statues and managed economy."*

| Stat | Value | Notes |
|------|-------|-------|
| **HP** | 400 | Serious tank |
| **Speed** | 35 | Slower than regular orcs |
| **Crystal Damage** | 50 | Cannot afford to let him through |
| **Gold Reward** | 75g | Major economy boost |
| **Ability** | War Cry - Buffs all enemies on screen | +30% damage, +20% speed for 5s |

**Player Power Check:** By Wave 10, expect:
- 4-5 statues (some evolved to ★★)
- 2-3 artifacts
- Understanding of ability timing

---

### Wave 15: Necromancer Lord
> *"Focus fire test—ignore him and drown in summons."*

| Stat | Value | Notes |
|------|-------|-------|
| **HP** | 600 | High HP pool |
| **Speed** | 30 | Very slow |
| **Crystal Damage** | 40 | Moderate |
| **Gold Reward** | 100g | End-game gold boost |
| **Ability** | Resurrects 2 fallen enemies every 5s | Nightmare if lots of dead enemies on field |

---

### Wave 20: Ancient Dragon
> *"The final exam—requires flying counters and full evolved team."*

| Stat | Value | Notes |
|------|-------|-------|
| **HP** | 1000 | True raid boss |
| **Speed** | 45 | Moderate |
| **Crystal Damage** | 100 | Instant threat |
| **Gold Reward** | 200g | Victory lap gold |
| **Ability** | Fire Breath Cone - 50 AOE damage | Can destroy weak statues |
| **Flying** | Only ranged/magic can damage | Forces comp diversity |

---

## 🗡️ Statue Balance (DPS Benchmarks)

### DPS Relative to Goblin HP (30 HP Baseline)

| Statue | Base Damage | Attack Speed | DPS | Time to Kill Goblin | Range | Role |
|--------|-------------|--------------|-----|---------------------|-------|------|
| **Sentinel** | 20 | 0.8/s | 16.0 | 1.88s | 80 (Melee) | Tank/Stun |
| **Arcane Weaver** | 20 | 0.7/s | 14.0 | 2.14s | 180 (Med) | AOE Chain |
| **Huntress** | 25 | 1.0/s | 25.0 | 1.20s | 220 (Long) | Single Target |
| **Divine Guardian** | 18 | 0.75/s | 13.5 | 2.22s | 150 (Med) | Anti-Undead |
| **Earthshaker** | 22 | 0.6/s | 13.2 | 2.27s | 100 (Short) | AOE Slow |
| **Shadow Dancer** | 15 | 1.2/s | 18.0 | 1.67s | 140 (Med) | Burst DPS |
| **Frost Maiden** | 16 | 0.8/s | 12.8 | 2.34s | 160 (Med) | CC/Freeze |

### Statue Tier Scaling

| Tier | Stat Multiplier | Example (Huntress DPS) |
|------|-----------------|------------------------|
| ★ Base | 1.0x | 25.0 DPS |
| ★★ Enhanced | 1.4x | 35.0 DPS |
| ★★★ Awakened | 1.8x | 45.0 DPS |
| ★★★★ Divine | 2.5x | 62.5 DPS |

---

## 💰 Economy Balance - Map 1

### Gold Income Per Wave

| Wave | Enemies | Enemy Gold | Wave Bonus | Total Gold | Cumulative |
|------|---------|------------|------------|------------|------------|
| 1 | 6 Goblins | 30g | 90g | **120g** | 320g |
| 2 | 8 Goblins | 40g | 105g | **145g** | 465g |
| 3 | 8 Gob + 2 Orc | 60g | 120g | **180g** | 645g |
| 4 | 7 Gob + 4 Orc | 75g | 135g | **210g** | 855g |
| 5 | Mixed + Boss | ~90g + 50g | 150g | **290g** | 1145g |
| 10 | Heavy Mix + Boss | ~180g + 75g | 225g | **480g** | ~2500g |

*Wave Bonus Formula:* `75g + (wave × 15)`

### Shop Pricing Tension

| Item Type | Cost Range | Can Afford After Wave... |
|-----------|------------|--------------------------|
| Common Statue | 350-400g | Wave 3 |
| Uncommon Statue | 450-550g | Wave 4-5 |
| Basic Artifact | 200-300g | Wave 2 |
| Premium Artifact | 350-450g | Wave 4 |
| Upgrade | 200-350g | Wave 2-3 |
| Consumable | 50-150g | Wave 1 |

### The Economic "Pinch Points"

> These are the moments where player feels gold-starved—creating tension.

1. **Wave 2-3:** Want second statue but can only afford consumable/artifact
2. **Wave 4:** Have ~350g but common statue costs 350g → Do I save for boss wave shop?
3. **Wave 6-8:** Duplicate statues appear → Evolution vs. new statue dilemma
4. **Wave 11+:** Upgrades become essential but compete with new statues

---

## 📈 Wave-by-Wave Balance Guide

### Tutorial Phase (Waves 1-4)

| Wave | Composition | Total HP | Expected DPS Needed | Lesson |
|------|-------------|----------|---------------------|--------|
| 1 | 6 Goblins | 180 HP | ~10 DPS | *Just have a statue* |
| 2 | 8 Goblins | 240 HP | ~12 DPS | *Position matters* |
| 3 | 8 Gob + 2 Orc | 360 HP | ~18 DPS | *Orcs are tougher* |
| 4 | 7 Gob + 4 Orc | 450 HP | ~22 DPS | *Prepare for boss* |

### First Test (Wave 5 - Boss)

| Component | HP | Priority |
|-----------|-----|----------|
| 6 Goblins | 180 HP | Low - Fodder |
| 3 Orcs | 180 HP | Medium |
| **Goblin King** | 200 HP | **HIGH - BOSS** |
| King's Summons | ~90 HP (3×30) | Medium - Clear adds |
| **TOTAL** | ~650 HP | Focus King! |

**Target Player State:** 2-3 statues, ~15-20 combined DPS

---

### Build-Up Phase (Waves 6-9)

| Wave | New Threat | Total HP | Expected DPS Needed |
|------|------------|----------|---------------------|
| 6 | Slimes (splitting) | ~500 HP | 25 DPS |
| 7 | More slimes | ~600 HP | 30 DPS |
| 8 | **Necromancer** (summons) | ~700 HP+ | 35 DPS + burst |
| 9 | Heavy mix | ~900 HP | 40 DPS |

### Second Boss (Wave 10)

**Orc Warlord Fight:**
- Kill adds before War Cry
- Save abilities for boss
- ~25-30 DPS required for comfortable clear

---

### Mid-Game Escalation (Waves 11-14)

| Wave | New Threat | The Test |
|------|------------|----------|
| 11-12 | Trolls + Shadow Imps | *Single target DPS + handling teleports* |
| 13-14 | Shielded Knights | *Flanking/abilities bypass shields* |

### Third Boss (Wave 15)

**Necromancer Lord Fight:**
- Don't let corpses pile up
- Focus fire immediately
- AOE to clear summons

---

### End-Game (Waves 16-20)

| Wave | Key Challenge |
|------|---------------|
| 16-19 | Dragon Whelps (flying) require ranged statues |
| 20 | Ancient Dragon + full enemy roster |

**Minimum Viable Comp for Wave 20:**
- 2+ ranged/magic statues (Arcane Weaver, Huntress, Frost Maiden)
- At least 1 ★★★ statue
- 3-4 artifacts

---

## ⚖️ Balance Tuning Levers

### If Players Find It Too Easy

| Lever | Adjustment | Impact |
|-------|------------|--------|
| Enemy HP Scaling | +10% per wave after 5 | More sustained DPS needed |
| Gold Income | -10g wave bonus | Slower power curve |
| Boss HP | +25% | Longer fights, more tension |
| Spawn Rate | -0.2s interval | Faster waves, less reaction time |

### If Players Find It Too Hard

| Lever | Adjustment | Impact |
|-------|------------|--------|
| Starting Gold | +50g (250 total) | Faster first statue |
| Wave 5 Boss HP | 200 → 150 | More forgiving first test |
| Enemy Speed | -10% all | More reaction time |
| Reroll Cost | 30g → 20g first | Better shop options |

---

## 🎮 Synergy Opportunities

### Statue Combos

| Combo | Statues | Why It Works |
|-------|---------|--------------|
| **The Stall** | Frost Maiden + Huntress | Freeze provides free DPS time |
| **Lightning Storm** | Arcane Weaver × 2 | Chain lightning overlaps devastate groups |
| **Tank & Spank** | Sentinel + Shadow Dancer | Stun + Blade Storm burst |
| **Holy Ground** | Divine Guardian + Earthshaker | Undead bonus + AOE slow |

### Artifact Synergies for Map 1

| Artifact | Best With | Why |
|----------|-----------|-----|
| War Banner (+15% DMG) | High attack speed statues | More procs |
| Ancient Tome (-25% CD) | Frost Maiden, Earthshaker | More CC uptime |
| Mystic Lens (+1 Range) | Huntress | Insane coverage |
| Soul Gem (+1g/kill) | Any | More reliable than boss dependent |

---

## 📝 Final Notes for Map 1

### Core Experience
Map 1 should feel like a **gentle ramp** with the first major skill check at Wave 5. Players who survive Wave 10 should feel competent. Reaching Wave 20 and defeating the Ancient Dragon should feel like a true accomplishment.

### Future Map Considerations
- **Map 2:** Introduce flying enemies earlier, more shield enemies
- **Map 3:** Elite modifiers from Wave 1, tighter economy
- **Map 4:** Boss gauntlet mode, no shop between some waves

---

*Document Version: 1.0*  
*Last Updated: December 17, 2024*  
*Authored by: Lead Game Designer*
