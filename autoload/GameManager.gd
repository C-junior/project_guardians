extends Node

## GameManager - Global State Singleton
## Manages game state, player resources, and run data

# Signals
signal gold_changed(new_amount: int)
signal crystal_health_changed(new_health: int, max_health: int)
signal wave_changed(wave_number: int)
signal game_state_changed(new_state: GameState)
signal statue_placed(statue: Node)
signal enemy_killed(enemy: Node, gold_reward: int)
signal inventory_changed()

# Enums
enum GameState { MENU, SETUP, COMBAT, SHOP, PAUSED, GAME_OVER }

# Game State
var current_state: GameState = GameState.MENU:
	set(value):
		current_state = value
		game_state_changed.emit(value)

# Player Resources
var gold: int = 150:
	set(value):
		gold = max(0, value)
		gold_changed.emit(gold)

var aether_essence: int = 0  # Meta-progression currency

# Crystal (Base) Health
var crystal_max_health: int = 100
var crystal_health: int = 100:
	set(value):
		crystal_health = clamp(value, 0, crystal_max_health)
		crystal_health_changed.emit(crystal_health, crystal_max_health)
		if crystal_health <= 0:
			_on_crystal_destroyed()

# Wave Tracking
var current_wave: int = 0:
	set(value):
		current_wave = value
		wave_changed.emit(current_wave)

# Shop State
var reroll_count: int = 0
var reroll_base_cost: int = 50
var reroll_increment: int = 25

# Current Run Data
var placed_statues: Array[Node] = []
var active_artifacts: Array[Resource] = []
var active_consumables: Array = []  # Can hold Resource or Dictionary
var current_blessing: Resource = null
var selected_starting_statue: Resource = null

# Player Inventory (persists during run)
# Format: { "statues": [{"data": Resource, "count": int}], "artifacts": [...], "consumables": [...] }
var player_inventory: Dictionary = {
	"statues": [],
	"artifacts": [],
	"consumables": []
}

# Speed Control
var game_speed: float = 1.0

# Meta-Progression (persisted)
var unlocked_statues: Array[String] = ["sentinel", "arcane_weaver", "huntress"]
var unlocked_artifacts: Array[String] = []
var unlocked_blessings: Array[String] = ["warriors_resolve", "merchants_fortune", "ancient_power"]
var permanent_gold_bonus: int = 0
var starting_statue_count: int = 1


func _ready() -> void:
	print("[GameManager] Initialized")


## Start a new run
func start_new_run() -> void:
	gold = 150 + permanent_gold_bonus
	crystal_health = crystal_max_health
	current_wave = 0
	reroll_count = 0
	placed_statues.clear()
	active_artifacts.clear()
	active_consumables.clear()
	current_blessing = null
	selected_starting_statue = null
	_reset_inventory()
	current_state = GameState.SETUP  # Go to setup phase first
	print("[GameManager] New run started - entering setup phase")


## Reset inventory for new run
func _reset_inventory() -> void:
	player_inventory = {
		"statues": [],
		"artifacts": [],
		"consumables": []
	}
	inventory_changed.emit()


## Called when combat wave ends
func end_wave(victory: bool) -> void:
	if victory:
		var wave_bonus = 50 + (current_wave * 10)
		add_gold(wave_bonus)
		print("[GameManager] Wave %d complete! Bonus: %d gold" % [current_wave, wave_bonus])
		current_state = GameState.SHOP
		reroll_count = 0  # Reset reroll cost each wave
	else:
		_on_crystal_destroyed()


## Start next combat wave
func start_next_wave() -> void:
	current_wave += 1
	current_state = GameState.COMBAT
	active_consumables.clear()  # Consumables only last one wave
	print("[GameManager] Starting Wave %d" % current_wave)


## Gold Management
func add_gold(amount: int) -> void:
	var bonus_multiplier = 1.0
	# Check for gold-boosting artifacts
	for artifact in active_artifacts:
		if artifact.has_method("get_gold_multiplier"):
			bonus_multiplier += artifact.get_gold_multiplier()
	gold += int(amount * bonus_multiplier)


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false


func can_afford(amount: int) -> bool:
	return gold >= amount


## Reroll System
func get_reroll_cost() -> int:
	return reroll_base_cost + (reroll_count * reroll_increment)


func reroll_shop() -> bool:
	var cost = get_reroll_cost()
	if spend_gold(cost):
		reroll_count += 1
		return true
	return false


## Statue Management
func register_statue(statue: Node) -> void:
	placed_statues.append(statue)
	statue_placed.emit(statue)


func unregister_statue(statue: Node) -> void:
	placed_statues.erase(statue)


## Artifact Management
func add_artifact(artifact: Resource) -> void:
	active_artifacts.append(artifact)
	# Apply any immediate effects
	if artifact.has_method("on_acquired"):
		artifact.on_acquired(self)


## Speed Control
func set_game_speed(speed: float) -> void:
	game_speed = clamp(speed, 0.0, 3.0)
	Engine.time_scale = game_speed


func pause_game() -> void:
	if current_state == GameState.COMBAT:
		current_state = GameState.PAUSED
		Engine.time_scale = 0.0


func resume_game() -> void:
	if current_state == GameState.PAUSED:
		current_state = GameState.COMBAT
		Engine.time_scale = game_speed


## Game Over
func _on_crystal_destroyed() -> void:
	current_state = GameState.GAME_OVER
	# Award aether essence based on waves survived
	var earned_essence = current_wave * 10
	aether_essence += earned_essence
	print("[GameManager] Game Over! Survived %d waves. Earned %d Aether Essence" % [current_wave, earned_essence])
	# Save meta-progression
	save_meta_progression()


## Save/Load Meta-Progression
func save_meta_progression() -> void:
	var save_data = {
		"aether_essence": aether_essence,
		"unlocked_statues": unlocked_statues,
		"unlocked_artifacts": unlocked_artifacts,
		"unlocked_blessings": unlocked_blessings,
		"permanent_gold_bonus": permanent_gold_bonus,
		"starting_statue_count": starting_statue_count
	}
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("[GameManager] Progress saved")


func load_meta_progression() -> void:
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			file.close()
			if parse_result == OK:
				var data = json.data
				aether_essence = data.get("aether_essence", 0)
				unlocked_statues = data.get("unlocked_statues", unlocked_statues)
				unlocked_artifacts = data.get("unlocked_artifacts", unlocked_artifacts)
				unlocked_blessings = data.get("unlocked_blessings", unlocked_blessings)
				permanent_gold_bonus = data.get("permanent_gold_bonus", 0)
				starting_statue_count = data.get("starting_statue_count", 1)
				print("[GameManager] Progress loaded")


## Stat Modifiers from Artifacts
func get_damage_multiplier() -> float:
	var mult = 1.0
	for artifact in active_artifacts:
		if artifact.has_method("get_damage_multiplier"):
			mult += artifact.get_damage_multiplier()
	return mult


func get_attack_speed_multiplier() -> float:
	var mult = 1.0
	for artifact in active_artifacts:
		if artifact.has_method("get_attack_speed_multiplier"):
			mult += artifact.get_attack_speed_multiplier()
	return mult


func get_cooldown_multiplier() -> float:
	var mult = 1.0
	for artifact in active_artifacts:
		if artifact.has_method("get_cooldown_multiplier"):
			mult -= artifact.get_cooldown_reduction()  # Reduction is subtracted
	return max(0.1, mult)  # Minimum 10% cooldown


func get_range_bonus() -> float:
	var bonus = 0.0
	for artifact in active_artifacts:
		if artifact.has_method("get_range_bonus"):
			bonus += artifact.get_range_bonus()
	return bonus


## Inventory Management
func add_to_inventory(item: Resource, item_type: String) -> void:
	if not item:
		return
	
	var inventory_list = player_inventory.get(item_type, [])
	
	# Check if item already exists (for stackable items like statues)
	for entry in inventory_list:
		var entry_id = entry["data"].get("id") if entry["data"] else ""
		var item_id = item.get("id") if item else ""
		if entry["data"] == item or (entry_id != "" and item_id != "" and entry_id == item_id):
			entry["count"] += 1
			inventory_changed.emit()
			var name_str = item.get("display_name") if item.get("display_name") else str(item)
			print("[GameManager] Added %s to inventory (count: %d)" % [name_str, entry["count"]])
			return
	
	# New item
	inventory_list.append({"data": item, "count": 1})
	player_inventory[item_type] = inventory_list
	inventory_changed.emit()
	var name_str = item.get("display_name") if item.get("display_name") else str(item)
	print("[GameManager] Added new %s to inventory" % [name_str])


func remove_from_inventory(item: Resource, item_type: String) -> bool:
	if not item:
		return false
	
	var inventory_list = player_inventory.get(item_type, [])
	var item_id = item.get("id") if item else ""
	
	for i in range(inventory_list.size()):
		var entry = inventory_list[i]
		var entry_id = entry["data"].get("id") if entry["data"] else ""
		if entry["data"] == item or (entry_id != "" and item_id != "" and entry_id == item_id):
			entry["count"] -= 1
			if entry["count"] <= 0:
				inventory_list.remove_at(i)
			inventory_changed.emit()
			return true
	
	return false


func has_in_inventory(item: Resource, item_type: String) -> bool:
	var inventory_list = player_inventory.get(item_type, [])
	var item_id = item.get("id") if item else ""
	for entry in inventory_list:
		var entry_id = entry["data"].get("id") if entry["data"] else ""
		if entry["data"] == item or (entry_id != "" and item_id != "" and entry_id == item_id):
			return entry["count"] > 0
	return false


func get_inventory_items(item_type: String) -> Array:
	return player_inventory.get(item_type, [])


func get_inventory_count(item: Resource, item_type: String) -> int:
	var inventory_list = player_inventory.get(item_type, [])
	var item_id = item.get("id") if item else ""
	for entry in inventory_list:
		var entry_id = entry["data"].get("id") if entry["data"] else ""
		if entry["data"] == item or (entry_id != "" and item_id != "" and entry_id == item_id):
			return entry["count"]
	return 0


## Get all unlocked statue resources
func get_unlocked_statue_resources() -> Array[Resource]:
	var statues: Array[Resource] = []
	for statue_id in unlocked_statues:
		var path = "res://resources/statues/%s.tres" % statue_id
		if ResourceLoader.exists(path):
			var res = load(path)
			if res:
				statues.append(res)
	return statues
