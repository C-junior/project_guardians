extends Resource
class_name StatueData

## StatueData Resource - Defines a heroine statue type

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var portrait_texture: Texture2D

@export_group("Base Stats")
@export var base_damage: float = 10.0
@export var attack_speed: float = 1.0  # Attacks per second
@export var attack_range: float = 150.0  # Pixels
@export var max_health: float = 100.0
@export var base_crit_chance: float = 0.0  # Base critical hit chance (0.0 - 1.0)

@export_group("Ability")
@export var ability_name: String = ""
@export var ability_description: String = ""
@export var ability_cooldown: float = 10.0  # Seconds
@export var ability_icon: Texture2D

@export_group("Shop")
@export_enum("Common", "Uncommon", "Rare", "Epic", "Legendary") var rarity: int = 0
@export var base_cost: int = 300

@export_group("Targeting")
@export_enum("Nearest", "Strongest", "Weakest", "First", "Last") var target_priority: int = 0
@export var can_attack_flying: bool = true
@export var can_attack_ground: bool = true

@export_group("Visuals")
@export var projectile_texture: Texture2D
@export var projectile_speed: float = 400.0
@export var is_melee: bool = false
@export var effect_color: Color = Color(1.0, 1.0, 1.0)  # Primary effect color
@export var secondary_effect_color: Color = Color(0.8, 0.8, 0.8)  # Secondary effect color
@export var has_aura: bool = false  # Show persistent aura


## Calculate stats for a given evolution tier (0-3)
func get_stats_for_tier(tier: int) -> Dictionary:
	var multipliers = [1.0, 1.4, 1.8, 2.5]  # Base, Enhanced, Awakened, Divine
	var mult = multipliers[clamp(tier, 0, 3)]
	
	return {
		"damage": base_damage * mult,
		"attack_speed": attack_speed * (1.0 + (tier * 0.15)),  # Slight speed boost per tier
		"range": attack_range + (tier * 10),  # +10 range per tier
		"health": max_health * mult,
		"cooldown": ability_cooldown * (1.0 - (tier * 0.1))  # 10% faster cooldown per tier
	}


## Get cost for this statue at given rarity
func get_cost() -> int:
	var rarity_multipliers = [1.0, 1.3, 1.6, 2.0, 2.5]
	return int(base_cost * rarity_multipliers[rarity])


## Get tier name
static func get_tier_name(tier: int) -> String:
	var names = ["Base", "Enhanced", "Awakened", "Divine"]
	return names[clamp(tier, 0, 3)]


## Get rarity color
func get_rarity_color() -> Color:
	var colors = [
		Color.GRAY,      # Common
		Color.GREEN,     # Uncommon
		Color.BLUE,      # Rare
		Color.PURPLE,    # Epic
		Color.ORANGE     # Legendary
	]
	return colors[rarity]
