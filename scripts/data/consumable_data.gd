extends Resource
class_name ConsumableData

## ConsumableData Resource - Single-use items for one wave

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_texture: Texture2D

@export_group("Shop")
@export var base_cost: int = 100

@export_group("Effects")
@export var abilities_start_ready: bool = false     # Battle Horn effect
@export var gold_multiplier: float = 0.0            # Gold Fever effect (e.g., 1.0 = 2x gold)
@export var crystal_health_boost: float = 0.0       # Stone Walls effect (e.g., 0.3 = +30%)
@export var enemy_slow_percent: float = 0.0         # Slow Time effect (e.g., 0.25 = 25% slower)
@export var damage_boost: float = 0.0               # Temporary damage boost
@export var attack_speed_boost: float = 0.0         # Temporary speed boost


## Get effect description for UI
func get_effect_description() -> String:
	var effects: Array = []
	
	if abilities_start_ready:
		effects.append("All abilities start ready")
	if gold_multiplier > 0:
		effects.append("+%d%% gold this wave" % int(gold_multiplier * 100))
	if crystal_health_boost > 0:
		effects.append("+%d%% crystal health" % int(crystal_health_boost * 100))
	if enemy_slow_percent > 0:
		effects.append("Enemies %d%% slower" % int(enemy_slow_percent * 100))
	if damage_boost > 0:
		effects.append("+%d%% damage" % int(damage_boost * 100))
	if attack_speed_boost > 0:
		effects.append("+%d%% attack speed" % int(attack_speed_boost * 100))
	
	return " • ".join(effects) if effects.size() > 0 else "No effect"
