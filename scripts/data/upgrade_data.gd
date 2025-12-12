extends Resource
class_name UpgradeData

## UpgradeData Resource - Statue upgrades purchasable in shop

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_texture: Texture2D

@export_group("Shop")
@export var base_cost: int = 250

@export_group("Effects")
@export var damage_multiplier: float = 0.0       # e.g., 0.25 = +25% damage
@export var attack_speed_multiplier: float = 0.0 # e.g., 0.30 = +30% attack speed
@export var range_bonus: float = 0.0             # Flat range increase
@export var health_multiplier: float = 0.0       # e.g., 0.50 = +50% max health
@export var cooldown_reduction: float = 0.0      # e.g., 0.30 = 30% faster cooldowns


## Get effect description for UI
func get_effect_description() -> String:
	var effects: Array = []
	
	if damage_multiplier > 0:
		effects.append("+%d%% damage" % int(damage_multiplier * 100))
	if attack_speed_multiplier > 0:
		effects.append("+%d%% attack speed" % int(attack_speed_multiplier * 100))
	if range_bonus > 0:
		effects.append("+%.0f range" % range_bonus)
	if health_multiplier > 0:
		effects.append("+%d%% health" % int(health_multiplier * 100))
	if cooldown_reduction > 0:
		effects.append("-%d%% cooldown" % int(cooldown_reduction * 100))
	
	return " • ".join(effects) if effects.size() > 0 else "No effect"
