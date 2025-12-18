extends Node

## TutorialManager - Handles contextual tutorial prompts for new players
## Autoload singleton - manages tutorial state and persistence

signal tutorial_shown(id: String, message: String)
signal tutorial_dismissed(id: String)

# Tutorial completion tracking
var completed_tutorials: Array[String] = []
var tutorials_enabled: bool = true

# Current active tutorial
var current_tutorial_id: String = ""

# Tutorial definitions
const TUTORIALS = {
	"place_statue": {
		"message": "📍 Drag a statue from your inventory onto the glowing green tiles!",
		"priority": 1
	},
	"use_ability": {
		"message": "⚡ Click the glowing ability button to unleash a powerful attack!",
		"priority": 2
	},
	"open_shop": {
		"message": "🛒 Browse the shop to buy new statues, artifacts, and consumables!",
		"priority": 3
	},
	"evolution": {
		"message": "✨ You have 3 identical statues! Open Ascension to evolve them into a stronger version!",
		"priority": 4
	},
	"boss_wave": {
		"message": "⚠️ BOSS WAVE incoming! Position your statues wisely and prepare your abilities!",
		"priority": 5
	},
	"start_wave": {
		"message": "⚔️ Click 'Start Wave' when you're ready to begin combat!",
		"priority": 1
	}
}


func _ready() -> void:
	_load_tutorial_progress()
	print("[TutorialManager] Initialized - %d tutorials completed" % completed_tutorials.size())


## Show a tutorial prompt if not already completed
func show_tutorial(id: String) -> bool:
	if not tutorials_enabled:
		return false
	
	if is_completed(id):
		return false
	
	if not TUTORIALS.has(id):
		push_warning("[TutorialManager] Unknown tutorial ID: %s" % id)
		return false
	
	# Don't interrupt if another tutorial is showing
	if current_tutorial_id != "":
		return false
	
	current_tutorial_id = id
	var tutorial = TUTORIALS[id]
	tutorial_shown.emit(id, tutorial.message)
	print("[TutorialManager] Showing tutorial: %s" % id)
	return true


## Mark a tutorial as completed
func complete_tutorial(id: String) -> void:
	if id in completed_tutorials:
		return
	
	completed_tutorials.append(id)
	current_tutorial_id = ""
	tutorial_dismissed.emit(id)
	_save_tutorial_progress()
	print("[TutorialManager] Completed tutorial: %s" % id)


## Dismiss current tutorial (same as complete)
func dismiss_current() -> void:
	if current_tutorial_id != "":
		complete_tutorial(current_tutorial_id)


## Check if tutorial is completed
func is_completed(id: String) -> bool:
	return id in completed_tutorials


## Reset all tutorials (for testing)
func reset_tutorials() -> void:
	completed_tutorials.clear()
	current_tutorial_id = ""
	_save_tutorial_progress()
	print("[TutorialManager] All tutorials reset")


## Save tutorial progress to GameManager's save data
func _save_tutorial_progress() -> void:
	# Use GameManager's save system
	if GameManager:
		GameManager.save_meta_progression()


## Load tutorial progress from save data
func _load_tutorial_progress() -> void:
	# Load from save file
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			var parse_result = json.parse(file.get_as_text())
			file.close()
			if parse_result == OK:
				var data = json.data
				completed_tutorials.assign(data.get("completed_tutorials", []))
