extends Resource
class_name MetaUnlock

## MetaUnlock Resource - Defines an unlockable item in the Aether Sanctum

enum UnlockType { STATUE, ARTIFACT, BLESSING, UPGRADE }

@export_group("Identity")
@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var unlock_type: UnlockType = UnlockType.STATUE

@export_group("Cost")
@export var aether_cost: int = 100
@export var is_repeatable: bool = false  # For permanent upgrades
@export var max_level: int = 1  # For repeatable upgrades

@export_group("Effect")
## For STATUE/ARTIFACT/BLESSING: ID of the item to unlock
@export var unlock_item_id: String = ""
## For UPGRADE: stat to modify
@export var upgrade_stat: String = ""  # e.g., "starting_gold", "crit_chance"
@export var upgrade_value: float = 0.0  # Amount per level


## Get display text for unlock effect
func get_effect_text() -> String:
	match unlock_type:
		UnlockType.STATUE:
			return "Unlock %s statue" % display_name
		UnlockType.ARTIFACT:
			return "Add to shop pool"
		UnlockType.BLESSING:
			return "Add to blessing pool"
		UnlockType.UPGRADE:
			return "+%.0f %s per level" % [upgrade_value, upgrade_stat.replace("_", " ")]
	return ""
