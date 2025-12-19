extends Resource
class_name MapData

## MapData Resource - Defines a game map with its settings and wave generation rules

@export_group("Map Info")
@export var id: String = "grove"
@export var display_name: String = "The Sacred Grove"
@export var description: String = "A peaceful forest clearing corrupted by goblins."
@export var difficulty: int = 1  # 1=Easy, 2=Medium, 3=Hard

@export_group("Wave Settings")
@export var total_waves: int = 20
@export var elite_start_wave: int = 11  # When elite modifiers begin
@export var flying_start_wave: int = 16  # When flying enemies appear
@export var shield_start_wave: int = 13  # When shielded enemies appear

@export_group("Economy")
@export var starting_gold_bonus: int = 0
@export var wave_gold_multiplier: float = 1.0

@export_group("Bosses")
@export var boss_wave_5: String = "goblin_boss"
@export var boss_wave_10: String = "orc_boss"
@export var boss_wave_15: String = "necromancer_lord"
@export var boss_wave_20: String = "ancient_dragon"
@export var boss_wave_25: String = ""  # Optional for longer maps

@export_group("Visual")
@export var background_color: Color = Color(0.15, 0.2, 0.15)
@export var path_color: Color = Color(0.4, 0.35, 0.25)

@export_group("Path Layout")
@export var path_count: int = 1  ## Number of enemy paths (1 = single, 2 = dual)
@export var path_selection_mode: int = 0  ## 0=random, 1=alternating, 2=wave-based
@export var arena_scene_path: String = ""  ## Optional custom arena scene for this map


## Get boss ID for a given wave
func get_boss_for_wave(wave: int) -> String:
	if wave >= 25 and boss_wave_25 != "":
		return boss_wave_25
	elif wave >= 20:
		return boss_wave_20
	elif wave >= 15:
		return boss_wave_15
	elif wave >= 10:
		return boss_wave_10
	elif wave >= 5:
		return boss_wave_5
	return ""


## Check if flying enemies should spawn
func can_spawn_flying(wave: int) -> bool:
	return wave >= flying_start_wave


## Check if shielded enemies should spawn
func can_spawn_shield(wave: int) -> bool:
	return wave >= shield_start_wave


## Check if elite modifiers should apply
func can_spawn_elite(wave: int) -> bool:
	return wave >= elite_start_wave
