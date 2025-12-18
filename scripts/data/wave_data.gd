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
## Improved difficulty curve with gradual enemy introduction
static func generate_wave(wave_num: int) -> WaveData:
	var wave = WaveData.new()
	wave.wave_number = wave_num
	wave.is_boss_wave = (wave_num % 5 == 0)
	
	# Base enemy count scales more gradually
	var base_count = 4 + (wave_num * 2)
	
	# Smooth difficulty curve with gradual enemy introduction
	match wave_num:
		1:
			# Tutorial: Small goblin wave
			wave.spawn_groups.append({"enemy_id": "goblin", "count": 6, "delay": 0.0})
		2:
			# Still goblins, slightly more
			wave.spawn_groups.append({"enemy_id": "goblin", "count": 8, "delay": 0.0})
		3:
			# Introduce 1-2 orcs among goblins
			wave.spawn_groups.append({"enemy_id": "goblin", "count": 8, "delay": 0.0})
			wave.spawn_groups.append({"enemy_id": "orc", "count": 2, "delay": 1.0})
		4:
			# More orcs, preparing for first boss
			wave.spawn_groups.append({"enemy_id": "goblin", "count": 7, "delay": 0.0})
			wave.spawn_groups.append({"enemy_id": "orc", "count": 4, "delay": 0.5})
		5:
			# BOSS WAVE: Goblin King
			wave.spawn_groups.append({"enemy_id": "goblin", "count": 6, "delay": 0.0})
			wave.spawn_groups.append({"enemy_id": "orc", "count": 3, "delay": 0.5})
		6:
			# Introduce slimes
			wave.spawn_groups.append({"enemy_id": "goblin", "count": 8, "delay": 0.0})
			wave.spawn_groups.append({"enemy_id": "orc", "count": 5, "delay": 0.5})
			wave.spawn_groups.append({"enemy_id": "slime", "count": 2, "delay": 1.0})
		7:
			# Mixed waves ramp up
			wave.spawn_groups.append({"enemy_id": "goblin", "count": 6, "delay": 0.0})
			wave.spawn_groups.append({"enemy_id": "orc", "count": 6, "delay": 0.5})
			wave.spawn_groups.append({"enemy_id": "slime", "count": 3, "delay": 0.5})
		8:
			# Introduce necromancers
			wave.spawn_groups.append({"enemy_id": "goblin", "count": 5, "delay": 0.0})
			wave.spawn_groups.append({"enemy_id": "orc", "count": 6, "delay": 0.5})
			wave.spawn_groups.append({"enemy_id": "slime", "count": 3, "delay": 0.5})
			wave.spawn_groups.append({"enemy_id": "necromancer", "count": 1, "delay": 1.5})
		9:
			# Preparing for Orc Warlord
			wave.spawn_groups.append({"enemy_id": "goblin", "count": 6, "delay": 0.0})
			wave.spawn_groups.append({"enemy_id": "orc", "count": 8, "delay": 0.5})
			wave.spawn_groups.append({"enemy_id": "slime", "count": 4, "delay": 0.5})
			wave.spawn_groups.append({"enemy_id": "necromancer", "count": 2, "delay": 1.0})
		10:
			# BOSS WAVE: Orc Warlord
			wave.spawn_groups.append({"enemy_id": "goblin", "count": 5, "delay": 0.0})
			wave.spawn_groups.append({"enemy_id": "orc", "count": 8, "delay": 0.5})
			wave.spawn_groups.append({"enemy_id": "slime", "count": 4, "delay": 0.5})
			wave.spawn_groups.append({"enemy_id": "necromancer", "count": 2, "delay": 1.0})
		_:
			# Waves 11+: Procedural scaling with new enemy types
			var goblin_count = max(3, base_count / 4)
			var orc_count = max(4, base_count / 3)
			var slime_count = max(2, base_count / 6)
			var necro_count = max(1, base_count / 8)
			
			# Add new enemy types at higher waves
			if wave_num >= 11 and wave_num <= 12:
				# Introduce trolls and shadow imps
				wave.spawn_groups.append({"enemy_id": "goblin", "count": goblin_count, "delay": 0.0})
				wave.spawn_groups.append({"enemy_id": "orc", "count": orc_count, "delay": 0.5})
				wave.spawn_groups.append({"enemy_id": "troll", "count": 2, "delay": 1.0})
				wave.spawn_groups.append({"enemy_id": "shadow_imp", "count": 3, "delay": 0.5})
			elif wave_num >= 13 and wave_num <= 14:
				# Add shielded knights
				wave.spawn_groups.append({"enemy_id": "orc", "count": orc_count, "delay": 0.0})
				wave.spawn_groups.append({"enemy_id": "shielded_knight", "count": 3, "delay": 0.5})
				wave.spawn_groups.append({"enemy_id": "troll", "count": 3, "delay": 1.0})
				wave.spawn_groups.append({"enemy_id": "shadow_imp", "count": 4, "delay": 0.5})
				wave.spawn_groups.append({"enemy_id": "necromancer", "count": 2, "delay": 1.5})
			elif wave_num == 15:
				# BOSS WAVE: Necromancer Lord
				wave.spawn_groups.append({"enemy_id": "shielded_knight", "count": 4, "delay": 0.0})
				wave.spawn_groups.append({"enemy_id": "necromancer", "count": 3, "delay": 0.5})
				wave.spawn_groups.append({"enemy_id": "troll", "count": 2, "delay": 1.0})
			elif wave_num >= 16 and wave_num <= 19:
				# Introduce dragon whelps (flying)
				wave.spawn_groups.append({"enemy_id": "orc", "count": orc_count, "delay": 0.0})
				wave.spawn_groups.append({"enemy_id": "shielded_knight", "count": 4, "delay": 0.5})
				wave.spawn_groups.append({"enemy_id": "dragon_whelp", "count": 3 + (wave_num - 16), "delay": 0.5})
				wave.spawn_groups.append({"enemy_id": "troll", "count": 3, "delay": 1.0})
				wave.spawn_groups.append({"enemy_id": "necromancer", "count": 2, "delay": 1.5})
			elif wave_num == 20:
				# BOSS WAVE: Ancient Dragon
				wave.spawn_groups.append({"enemy_id": "dragon_whelp", "count": 5, "delay": 0.0})
				wave.spawn_groups.append({"enemy_id": "shielded_knight", "count": 5, "delay": 0.5})
				wave.spawn_groups.append({"enemy_id": "troll", "count": 3, "delay": 1.0})
			else:
				# Endless mode (21+): Full chaos mix
				wave.spawn_groups.append({"enemy_id": "orc", "count": orc_count, "delay": 0.0})
				wave.spawn_groups.append({"enemy_id": "shielded_knight", "count": 4, "delay": 0.5})
				wave.spawn_groups.append({"enemy_id": "dragon_whelp", "count": 4, "delay": 0.5})
				wave.spawn_groups.append({"enemy_id": "troll", "count": 4, "delay": 0.5})
				wave.spawn_groups.append({"enemy_id": "necromancer", "count": 3, "delay": 1.0})
				wave.spawn_groups.append({"enemy_id": "shadow_imp", "count": 5, "delay": 0.5})
	
	# Add boss if boss wave (waves 5, 10, 15, 20...)
	if wave.is_boss_wave:
		var boss_id = "goblin_boss"  # Default: Wave 5
		
		# Use map data for boss selection if available
		if GameManager and GameManager.current_map:
			boss_id = GameManager.current_map.get_boss_for_wave(wave_num)
		else:
			# Fallback to hardcoded defaults
			if wave_num >= 20:
				boss_id = "ancient_dragon"
			elif wave_num >= 15:
				boss_id = "necromancer_lord"
			elif wave_num >= 10:
				boss_id = "orc_boss"
		
		if boss_id != "":
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
