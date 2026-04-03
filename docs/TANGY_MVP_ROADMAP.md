# Tangy-Style MVP Roadmap

## Goal

Build one polished adaptation slice of Project Guardians that proves these four mechanics together:

- tactical repositioning
- clear role identity
- statue-bound equipment
- enemy pressure with readable boss behavior

This roadmap is intentionally broken into small steps so we can ship value continuously.

## Phase 0 - Lock The Slice

### Step 1. Freeze the MVP rules

Status:

- Complete

Locked output:

- Map: `The Sacred Grove`
- Run length: `8 waves`
- Final boss: `Goblin Boss` on wave 8
- Statue roster: `Sentinel`, `Huntress`, `Divine Guardian`, `Frost Maiden`, `Arcane Weaver`
- Equipment pool: `Power Rune`, `Range Rune`, `Quickstep Rune`, `Keen Rune`, `Channel Rune`, `Guard Rune`

Definition of done:

- The scope is written down and not expanded during implementation
- The canonical frozen spec lives in `docs/TANGY_MVP_ADAPTATION.md`

### Step 2. Add adaptation flags to data

Work:

- Add role/passive fields to `StatueData`
- Add optional map flag for Tangy-style adaptation mode
- Add relocate charge count to run state

Definition of done:

- We can turn the adaptation slice on without breaking the current base loop

## Phase 1 - Repositioning

### Step 3. Support moving placed statues during shop

Work:

- Select a placed statue
- Pick it up
- Move it to another empty cell
- Keep upgrades/equipment attached

Likely files:

- `scripts/combat/arena.gd`
- `scripts/main.gd`
- `scripts/ui/inventory_ui.gd`

Definition of done:

- A placed statue can be moved during shop without selling and rebuying it

### Step 4. Add a limited in-combat relocate action

Work:

- Add 1 relocate charge per wave
- Trigger relocate from HUD or selected statue panel
- Move only to valid empty cells
- Add short cast time or brief disable window after moving

Definition of done:

- The player can rescue or reposition one statue mid-wave, but cannot spam movement

### Step 5. Add move feedback

Work:

- Highlight valid cells
- Show blocked cells clearly
- Show relocate charges on HUD
- Add simple VFX/SFX hook point for statue transfer

Definition of done:

- Moving a statue is readable and feels intentional

## Phase 2 - Role Identity

### Step 6. Add role tags to the MVP statues

Work:

- Sentinel -> Frontline
- Huntress -> Precision DPS
- Divine Guardian -> Support
- Frost Maiden -> Control Support
- Arcane Weaver -> Flexible DPS/Control

Definition of done:

- Every MVP statue has one primary tactical job

### Step 7. Implement one passive per role

Work:

- Frontline: mitigation/threat when exposed
- Precision DPS: isolation or uninterrupted-fire bonus
- Support: aura benefit to nearby allies

Likely files:

- `scripts/combat/statue_base.gd`
- `scripts/data/statue_data.gd`

Definition of done:

- Battlefield placement changes actual combat output

### Step 8. Add passive state indicators

Work:

- Icon, tint, or ring when a passive is active
- Tooltip text explaining why the bonus is on/off

Definition of done:

- The player can understand positioning bonuses without reading external docs

## Phase 3 - Statue-Bound Equipment

### Step 9. Convert MVP upgrades into statue equipment

Work:

- Reframe current upgrades as runes/equipment attached to one statue
- Keep slot limits based on current upgrade slot logic
- Show attached equipment in tooltip/details

Likely files:

- `scripts/combat/statue_base.gd`
- `scripts/ui/inventory_ui.gd`
- `scripts/data/upgrade_data.gd`

Definition of done:

- Equipment meaningfully belongs to a specific statue

### Step 10. Build the first equipment pool

Recommended MVP pool:

- Power Rune
- Range Rune
- Quickstep Rune
- Keen Rune
- Channel Rune
- Guard Rune

Definition of done:

- At least 6 equipment items exist and support different build choices

### Step 11. Tighten shop generation for the slice

Work:

- Bias the shop toward equipment and statues relevant to the adaptation test
- Reduce noise from systems outside the slice

Definition of done:

- Test runs reliably surface the new mechanics

## Phase 4 - Enemy Pressure

### Step 12. Add soft aggro rules

Work:

- Give some enemies permission to target statues
- Give frontline statues extra threat
- Pick a simple target rule first: nearest exposed statue or highest threat in range

Likely files:

- `scripts/combat/enemy_base.gd`
- `scripts/combat/arena.gd`

Definition of done:

- Backline mistakes are punishable, and frontlines matter

### Step 13. Add focus indicators

Work:

- Show which statue is being targeted
- Add a small aggro/focus icon or line
- Surface this in tooltip or HUD if needed

Definition of done:

- The player can react to pressure instead of guessing

## Phase 5 - Boss Adaptation

### Step 14. Pick one MVP boss and script 2 phases

Recommended first boss:

- Goblin Boss or Orc Boss, whichever is simpler to retune

Phase example:

- Phase 1: crystal rush and add summons
- Phase 2: lane slam or statue-targeting sweep

Definition of done:

- The boss demands at least one formation adjustment during the fight

### Step 15. Add one battlefield disruption mechanic

Examples:

- temporary danger zones
- lane sweep
- statue focus mark
- summon pack behind frontline

Definition of done:

- Repositioning is required by the boss, not just optional

## Phase 6 - Balance The Slice

### Step 16. Retune wave pacing around movement decisions

Work:

- Lower enemy count if needed
- Increase pressure windows where reposition matters
- Make sure relocate is useful but not mandatory every few seconds

Definition of done:

- Waves feel tactical, not just stat-check heavy

### Step 17. Tune the economy around equipment choices

Work:

- Make the player choose between new statue, equipment, or reroll
- Avoid easy "buy everything" shops

Definition of done:

- The adaptation loop creates real tradeoffs

### Step 18. Run three test builds

Test cases:

- Frontline-heavy build
- Huntress isolation build
- Support/control build

Definition of done:

- All three builds can clear the MVP slice with different strengths

## Phase 7 - MVP Exit Checklist

Ship the MVP when all are true:

- Shop-phase reposition works
- One in-combat relocate works
- Three role passives are active and visible
- Equipment is statue-bound and readable
- Some enemies pressure statues instead of only pathing
- One boss has at least two tactical phases
- One map can be completed with the new rules

## Suggested Build Order

If we want the safest implementation order, build in this sequence:

1. shop-phase reposition
2. role passives
3. passive feedback
4. statue-bound equipment
5. in-combat relocate
6. soft aggro
7. boss phases
8. balance pass

This order keeps the project playable at each stage and lets us test the adaptation loop early.
