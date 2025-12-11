extends Resource
class_name ArtifactData

## ArtifactData Resource - Defines a passive artifact

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_texture: Texture2D

@export_group("Shop")
@export_enum("Common", "Uncommon", "Rare", "Epic", "Legendary") var rarity: int = 0
@export var base_cost: int = 200

@export_group("Effects - Multipliers")
@export var damage_multiplier: float = 0.0      # e.g., 0.15 = +15% damage
@export var attack_speed_multiplier: float = 0.0
@export var cooldown_reduction: float = 0.0     # e.g., 0.25 = 25% faster cooldowns
@export var range_bonus: float = 0.0            # Flat range increase

@export_group("Effects - Gold")
@export var gold_multiplier: float = 0.0        # e.g., 0.20 = +20% gold
@export var gold_per_kill: int = 0              # Flat gold per enemy kill

@export_group("Effects - Health")
@export var crystal_health_bonus: float = 0.0   # e.g., 0.5 = +50% crystal health
@export var statue_health_regen: float = 0.0    # HP per second

@export_group("Effects - Special")
@export var extra_shop_items: int = 0           # Additional shop slots
@export var reroll_cost_reduction: int = 0      # Flat reduction to reroll cost


## Get artifact cost
func get_cost() -> int:
	var rarity_multipliers = [1.0, 1.3, 1.6, 2.0, 2.5]
	return int(base_cost * rarity_multipliers[rarity])


## Interface methods for GameManager to query
func get_damage_multiplier() -> float:
	return damage_multiplier


func get_attack_speed_multiplier() -> float:
	return attack_speed_multiplier


func get_cooldown_reduction() -> float:
	return cooldown_reduction


func get_range_bonus() -> float:
	return range_bonus


func get_gold_multiplier() -> float:
	return gold_multiplier


## Called when artifact is acquired
func on_acquired(game_manager: Node) -> void:
	# Apply immediate effects like crystal health bonus
	if crystal_health_bonus > 0:
		var bonus_hp = int(game_manager.crystal_max_health * crystal_health_bonus)
		game_manager.crystal_max_health += bonus_hp
		game_manager.crystal_health += bonus_hp


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
