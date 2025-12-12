extends Resource
class_name WaveData

## WaveData Resource - Defines enemies for a single wave

@export_group("Wave Info")
@export var wave_number: int = 1
@export var is_boss_wave: bool = false

@export_group("Spawns")
## Array of dictionaries: {"enemy_id": String, "count": int, "delay": float}
@export var spawn_groups: Array[Dictionary] = []

@export_group("Timing")
@export var spawn_interval: float = 1.0  # Seconds between enemy spawns
@export var group_delay: float = 3.0     # Delay between spawn groups
@export var initial_delay: float = 2.0   # Delay before first spawn


## Generate spawn sequence for this wave
## Returns array of {"enemy_id": String, "spawn_time": float}
func get_spawn_sequence() -> Array[Dictionary]:
	var sequence: Array[Dictionary] = []
	var current_time = initial_delay
	
	for group in spawn_groups:
		var enemy_id = group.get("enemy_id", "goblin")
		var count = group.get("count", 1)
		var group_specific_delay = group.get("delay", 0.0)
		
		current_time += group_specific_delay
		
		for i in range(count):
			sequence.append({
				"enemy_id": enemy_id,
				"spawn_time": current_time
			})
			current_time += spawn_interval
		
		current_time += group_delay
	
	return sequence


## Create a procedural wave based on wave number
static func generate_wave(wave_num: int) -> WaveData:
	var wave = WaveData.new()
	wave.wave_number = wave_num
	wave.is_boss_wave = (wave_num % 5 == 0)
	
	# Base enemy count scales with wave
	var base_count = 5 + (wave_num * 2)
	
	# Determine enemy composition based on wave
	if wave_num <= 3:
		# Early waves: mostly goblins
		wave.spawn_groups.append({"enemy_id": "goblin", "count": base_count, "delay": 0.0})
	elif wave_num <= 6:
		# Mid-early: goblins + orcs
		wave.spawn_groups.append({"enemy_id": "goblin", "count": base_count / 2, "delay": 0.0})
		wave.spawn_groups.append({"enemy_id": "orc", "count": base_count / 3, "delay": 0.0})
	elif wave_num <= 10:
		# Mid: mixed + trolls
		wave.spawn_groups.append({"enemy_id": "goblin", "count": base_count / 3, "delay": 0.0})
		wave.spawn_groups.append({"enemy_id": "orc", "count": base_count / 3, "delay": 0.0})
		wave.spawn_groups.append({"enemy_id": "slime", "count": base_count / 6, "delay": 0.0})
	else:
		# Late: full mix
		wave.spawn_groups.append({"enemy_id": "goblin", "count": base_count / 4, "delay": 0.0})
		wave.spawn_groups.append({"enemy_id": "orc", "count": base_count / 4, "delay": 0.0})
		wave.spawn_groups.append({"enemy_id": "slime", "count": base_count / 6, "delay": 0.0})
		wave.spawn_groups.append({"enemy_id": "necromancer", "count": base_count / 8, "delay": 0.0})
	
	# Add boss if boss wave
	if wave.is_boss_wave:
		var boss_id = "goblin_boss"  # Wave 5: Goblin King
		if wave_num >= 10:
			boss_id = "orc_boss"  # Wave 10+: Orc Warlord
		wave.spawn_groups.append({"enemy_id": boss_id, "count": 1, "delay": 2.0})
	
	return wave


## Get readable preview of wave composition
static func get_wave_preview(wave_num: int) -> String:
	var wave = generate_wave(wave_num)
	var preview_parts: Array = []
	
	for group in wave.spawn_groups:
		var enemy_id = group.get("enemy_id", "")
		var count = group.get("count", 0)
		if count > 0 and enemy_id != "":
			var enemy_name = enemy_id.capitalize().replace("_", " ")
			preview_parts.append("%d %s" % [count, enemy_name])
	
	if wave.is_boss_wave:
		return "⚔️ BOSS WAVE: " + ", ".join(preview_parts)
	else:
		return ", ".join(preview_parts)
