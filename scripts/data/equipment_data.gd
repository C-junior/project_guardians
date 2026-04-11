extends Resource
class_name EquipmentData

## EquipmentData — Runa equipável vinculada a uma estátua específica.
## Slots por tier: Base★=1, Enhanced★★=2, Awakened★★★=3, Divine★★★★=4
## Dois itens iguais podem ser combinados (merge) para criar uma versão +1 mais forte.

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_texture: Texture2D

@export_group("Shop")
@export_enum("Common", "Uncommon", "Rare", "Epic", "Legendary") var rarity: int = 0
@export var shop_cost: int = 150
## Which statue roles this equipment fits (empty = any role)
@export var allowed_roles: Array[String] = []

@export_group("Merge System")
## Nível do item: 0 = base, 1 = +1 (resultado de 2 iguais combinados), 2 = +2, etc.
@export var item_tier: int = 0
## Se true, dois exemplares deste item podem ser combinados para criar merge_result_id
@export var is_mergeable: bool = true
## ID do EquipmentData resultante do merge (ex: "power_rune_plus1"). Vazio = não pode mergear.
@export var merge_result_id: String = ""

# ── Stat bonuses ─────────────────────────────────────────────────────────────
@export_group("Stat Bonuses")
@export var bonus_damage_flat: float = 0.0          # Flat attack damage added
@export var bonus_damage_percent: float = 0.0       # e.g. 0.25 = +25%
@export var bonus_attack_speed: float = 0.0         # e.g. 0.15 = +15% faster
@export var bonus_range: float = 0.0                # Extra pixels of range
@export var bonus_crit_chance: float = 0.0          # 0.0–1.0 probability

# ── Threat / Aggro ────────────────────────────────────────────────────────────
@export_group("Threat & Aggro")
## Added to this statue's base_threat so enemies prefer targeting it
@export var bonus_threat: float = 0.0
## If > 0, statue draws enemy aggro within this radius when hit
@export var taunt_radius: float = 0.0

# ── Passive triggers ──────────────────────────────────────────────────────────
@export_group("Passive Triggers")
## Slow % applied to enemies hit by this statue (0.0 = none, 0.3 = 30% slow)
@export var on_hit_slow: float = 0.0
@export var on_hit_slow_duration: float = 1.2
## Burn damage per second applied on hit (0 = none)
@export var on_hit_burn_dps: float = 0.0
@export var on_hit_burn_duration: float = 2.0
## Execute: deal bonus_damage_percent * damage below hp_threshold % HP
@export var execute_hp_threshold: float = 0.0       # 0.0 = disabled, 0.3 = 30%
@export var execute_damage_mult: float = 1.5

# ── Economy ───────────────────────────────────────────────────────────────────
@export_group("Economy")
@export var gold_per_kill: int = 0                  # Flat gold added per kill by this statue

# ── Visuals ───────────────────────────────────────────────────────────────────
@export_group("Visuals")
## Tint applied to the statue sprite when this item is equipped
@export var statue_tint: Color = Color.WHITE
## Small glow ring color around the statue (alpha 0 = none)
@export var glow_color: Color = Color(0, 0, 0, 0)


# ── Helpers ───────────────────────────────────────────────────────────────────

func get_cost() -> int:
	var rarity_mult = [1.0, 1.35, 1.7, 2.1, 2.6]
	return int(shop_cost * rarity_mult[rarity])


func get_rarity_color() -> Color:
	var cols = [
		Color(0.7, 0.7, 0.7),   # Common   — grey
		Color(0.3, 0.85, 0.3),  # Uncommon — green
		Color(0.3, 0.5, 1.0),   # Rare     — blue
		Color(0.8, 0.3, 1.0),   # Epic     — purple
		Color(1.0, 0.6, 0.1),   # Legendary— orange
	]
	return cols[rarity]


func get_rarity_name() -> String:
	return ["Common", "Uncommon", "Rare", "Epic", "Legendary"][rarity]


## Human-readable tooltip line (used in shop and statue inspect)
func get_stat_summary() -> String:
	var parts: Array[String] = []
	if bonus_damage_flat > 0:
		parts.append("+%.0f ATK" % bonus_damage_flat)
	if bonus_damage_percent > 0:
		parts.append("+%d%% DMG" % int(bonus_damage_percent * 100))
	if bonus_attack_speed > 0:
		parts.append("+%d%% SPD" % int(bonus_attack_speed * 100))
	if bonus_range > 0:
		parts.append("+%.0f RNG" % bonus_range)
	if bonus_crit_chance > 0:
		parts.append("+%d%% CRIT" % int(bonus_crit_chance * 100))
	if bonus_threat > 0:
		parts.append("+%.0f THREAT" % bonus_threat)
	if on_hit_slow > 0:
		parts.append("SLOW %d%%" % int(on_hit_slow * 100))
	if on_hit_burn_dps > 0:
		parts.append("BURN %.0f/s" % on_hit_burn_dps)
	if gold_per_kill > 0:
		parts.append("+%d GOLD/kill" % gold_per_kill)
	if execute_hp_threshold > 0:
		parts.append("EXECUTE <%d%% HP" % int(execute_hp_threshold * 100))
	return ", ".join(parts) if parts.size() > 0 else "No stat bonuses"


## Returns true if this equipment can be equipped on a statue with the given role
func is_compatible_with_role(role: String) -> bool:
	if allowed_roles.is_empty():
		return true
	return role in allowed_roles


## Returns display suffix for UI — "" for base, " +1", " +2" etc for merged tiers
func get_tier_display() -> String:
	if item_tier <= 0:
		return ""
	return " +%d" % item_tier


## Full display name including tier suffix
func get_full_name() -> String:
	return display_name + get_tier_display()


## Returns true if a merge is possible (item is mergeable and has a result defined)
func can_merge() -> bool:
	return is_mergeable and merge_result_id != ""
