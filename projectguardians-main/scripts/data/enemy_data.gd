extends Resource
class_name EnemyData

## EnemyData Resource - Defines an enemy type

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var sprite_texture: Texture2D

@export_group("Stats")
@export var max_health: float = 50.0
@export var move_speed: float = 50.0  # Pixels per second
@export var damage_to_crystal: int = 10
@export var gold_reward: int = 5

@export_group("Type Flags")
@export var is_flying: bool = false
@export var is_boss: bool = false
@export var is_undead: bool = false
@export var is_demon: bool = false

@export_group("Special Abilities")
@export var can_teleport: bool = false
@export var teleport_cooldown: float = 5.0
@export var teleport_distance: float = 100.0

@export var can_summon: bool = false
@export var summon_cooldown: float = 8.0
@export var summon_enemy_id: String = ""
@export var summon_count: int = 2

@export var has_shield: bool = false
@export var frontal_armor: float = 0.75  # 75% damage reduction from front

@export var splits_on_death: bool = false
@export var split_enemy_id: String = ""
@export var split_count: int = 2

@export_group("Visuals")
@export var scale_factor: float = 1.0
@export var tint_color: Color = Color.WHITE


## Get health scaled by wave number
func get_scaled_health(wave: int) -> float:
	var scaling = 1.0 + (wave * 0.15)  # 15% more health per wave
	if is_boss:
		scaling *= 5.0  # Bosses have 5x base scaling
	return max_health * scaling


## Get speed scaled by wave number (slight increase)
func get_scaled_speed(wave: int) -> float:
	var scaling = 1.0 + (wave * 0.02)  # 2% faster per wave
	return move_speed * scaling


## Get gold reward scaled by wave
func get_scaled_gold(wave: int) -> int:
	var scaling = 1.0 + (wave * 0.05)  # 5% more gold per wave
	if is_boss:
		scaling *= 10.0  # Bosses drop 10x gold
	return int(gold_reward * scaling)
