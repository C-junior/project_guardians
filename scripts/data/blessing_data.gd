extends Resource
class_name BlessingData

## BlessingData Resource - Starting blessings chosen at run start

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_texture: Texture2D

@export_group("Effects")
## Starting statue ID (empty = none)
@export var starting_statue_id: String = ""
## Extra starting gold (added to base 150)
@export var extra_starting_gold: int = 0
## First purchase discount (0.5 = 50% off)
@export var first_purchase_discount: float = 0.0
## Global cooldown reduction (0.25 = 25% faster)
@export var cooldown_reduction: float = 0.0
## Crystal health multiplier (0.75 = +75%)
@export var crystal_health_bonus: float = 0.0


## Apply blessing effects at run start
func apply_effects() -> void:
	# Apply extra gold
	if extra_starting_gold > 0:
		GameManager.gold += extra_starting_gold
		print("[Blessing] Added %d extra starting gold" % extra_starting_gold)
	
	# Apply crystal health bonus
	if crystal_health_bonus > 0:
		var bonus = int(GameManager.crystal_max_health * crystal_health_bonus)
		GameManager.crystal_max_health += bonus
		GameManager.crystal_health += bonus
		print("[Blessing] Crystal health +%d" % bonus)
	
	# Starting statue is handled separately by main.gd
	# First purchase discount is checked in shop
	# Cooldown reduction is applied via GameManager queries
