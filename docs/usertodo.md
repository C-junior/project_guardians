# User TODO - Project Guardians

> [!NOTE]
> These are tasks that require your creative input, decision-making, or external actions. The game can be developed without these, but they will enhance the final product.

---

## ✅ Completed - Shop & Inventory Rebuild (MVP)

### Shop System (Rebuilt for MVP)
- ✅ Deleted old `shop_ui.tscn` and `shop_manager.gd`
- ✅ Created new `equipment_shop_ui.tscn` focused on 6 MVP runes
- ✅ Created new `equipment_shop_ui.gd` with MVP pool (Power, Range, Quickstep, Keen, Channel, Guard runes)
- ✅ Created new `equipment_shop_card.tscn` and `.gd` for item display
- ✅ Shop now shows 3 random runes + 2 random MVP statues per refresh
- ✅ Integrated with GameManager for purchases

### Inventory System (Rebuilt for MVP)
- ✅ Deleted old `inventory_ui.tscn` and `inventory_ui.gd`
- ✅ Created new `statue_inventory_ui.tscn` simplified for statues + equipment
- ✅ Created new `statue_inventory_ui.gd` with drag-and-drop support
- ✅ Shows statues with tier indicators and equipped items
- ✅ Shows equipment (runes) available to equip
- ✅ Detail panel shows stats, equipment slots, and abilities

### GameManager Updates
- ✅ Added `add_statue_to_inventory()` method
- ✅ Added `apply_equipment_to_statue()` method
- ✅ Added `get_max_equipment_slots_for_tier()` method
- ✅ Added "equipment" to player_inventory dictionary

### Main Controller Updates
- ✅ Updated `main.gd` to use new `equipment_shop_ui` and `statue_inventory_ui`
- ✅ Updated `main.tscn` scene references
- ✅ Added `_on_equipment_purchased()` and `_on_statue_purchased()` handlers
- ✅ All drag-and-drop and placement logic updated

---

## 🎨 Art & Visual Assets

### High Priority
- [ ] **Create Hero Statue Sprites** - The existing class portraits work but animated statue versions would be ideal
  - Recommended size: 128x128 or larger
  - Consider 4 visual tiers: Base → Enhanced → Awakened → Divine
  - Current classes: Knight, Mage, Archer, Paladin, Berserker, Guardian, Cleric, Assassin, Druid, Necrodancer

- [ ] **Create Map Tileset** - For the arena backgrounds
  - Medieval/fantasy stone paths
  - Grass, dirt, mystical rune-marked tiles
  - Placement grid indicators

### Medium Priority
- [ ] **UI Theme Graphics**
  - Shop panel frames (medieval fantasy style)
  - Button styles (stone/gold aesthetic)
  - Health/cooldown bar designs

- [ ] **Additional Enemy Sprites**
  - Dragon Whelp (flying enemy)
  - Shielded Knight
  - Shadow Imp
  - Troll Brute

- [ ] **Equipment/Runa Icons** - 6 icons for MVP runes
  - Power Rune (orange/red flame)
  - Range Rune (blue arrow)
  - Quickstep Rune (yellow lightning)
  - Keen Rune (gold crosshair)
  - Channel Rune (purple swirl)
  - Guard Rune (green shield)

- [ ] **Effect Sprites/Particles**
  - Attack projectiles per statue type
  - Ability VFX (chain lightning, ground slam, ice prison, etc.)
  - Evolution merge sparkles

### Low Priority
- [ ] **Alternative Arena Backgrounds** (for variety in later waves)
- [ ] **Boss-specific sprites** (larger, more detailed)
- [ ] **Artifact icons** (already have 13, might want more)

---

## 🎵 Audio (LAST PHASE)

### Music
- [ ] **Main Menu Theme** - Epic medieval orchestral
- [ ] **Combat Theme** - Intense, escalating battle music
- [ ] **Preparation Phase Theme** - Calm, strategic mood
- [ ] **Boss Battle Theme** - Climactic, urgent

### Sound Effects
- [ ] Attack sounds per statue type
- [ ] Enemy death sounds per type
- [ ] UI clicks, purchases, rerolls
- [ ] Ability activation sounds
- [ ] Win/lose jingles

---

## 📝 Creative Decisions Needed

### Game Balance (After Prototype)
- [ ] Review and adjust statue costs
- [ ] Fine-tune enemy health/damage curves
- [ ] Balance artifact effects
- [ ] Adjust gold economy

### Story/Lore (Optional Enhancement)
- [ ] Write heroine backstories
- [ ] Create world lore document
- [ ] Design flavor text for artifacts
- [ ] Name the kingdom/realm being defended

### Monetization/Distribution (Future)
- [ ] Decide on platform(s) (PC, mobile, web)
- [ ] Consider monetization strategy (premium, ads, cosmetics)
- [ ] Create store page assets if publishing

---

## 🔧 Technical Tasks

- [ ] **Test new Shop + Inventory flow** in Godot editor
- [ ] **Verify equipment application** to statues works
- [ ] **Test drag-and-drop** statue placement from inventory
- [ ] **Export testing** - Test builds on target platforms
- [ ] **Get feedback** - Share prototype with testers

---

## 🎯 Next MVP Implementation Steps

Following `MVP_IMPLEMENTATION_PLAN.md`:

### Phase 1: Reposicionamento (Shop + In-Combat)
- [ ] Implement shop-phase reposition (move placed statues during shop)
- [ ] Add 1 in-combat relocate charge per wave
- [ ] Highlight valid cells for movement
- [ ] Add relocate charges to HUD

### Phase 2: Role Passives
- [ ] Add role tags to 5 MVP statues
- [ ] Implement Frontline passive (mitigation when exposed)
- [ ] Implement Precision DPS passive (bonus when isolated)
- [ ] Implement Support passive (aura for nearby allies)
- [ ] Add visual indicators for active passives

### Phase 3: Statue-Bound Equipment
- [ ] Ensure equipment applies to statues correctly
- [ ] Show equipment slots on statue detail panel
- [ ] Integrate equipment bonuses into combat stats

### Phase 4: Soft Aggro
- [ ] Implement threat system
- [ ] Allow some enemies to target statues
- [ ] Add focus indicators

### Phase 5: Boss Phases
- [ ] Script Goblin Boss with 2 phases
- [ ] Add phase transition at 50% HP
- [ ] Add battlefield disruption mechanics

---

*Last Updated: 11 de Abril de 2026*
*Status: Shop & Inventory rebuilt for MVP ✅*
