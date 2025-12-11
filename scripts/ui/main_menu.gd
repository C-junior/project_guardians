extends CanvasLayer

## Main Menu Controller

@onready var new_game_button: Button = $TitleContainer/NewGameButton
@onready var progression_button: Button = $TitleContainer/ProgressionButton
@onready var settings_button: Button = $TitleContainer/SettingsButton
@onready var quit_button: Button = $TitleContainer/QuitButton
@onready var essence_label: Label = $EssenceDisplay/EssenceLabel


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	progression_button.pressed.connect(_on_progression_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Update essence display
	_update_essence_display()


func _update_essence_display() -> void:
	essence_label.text = str(GameManager.aether_essence)


func _on_new_game_pressed() -> void:
	# Find the main controller and start game
	var main = get_parent()
	if main and main.has_method("start_new_game"):
		main.start_new_game()


func _on_progression_pressed() -> void:
	# TODO: Open meta-progression shop
	print("[Menu] Meta-Progression not yet implemented")


func _on_settings_pressed() -> void:
	# TODO: Open settings
	print("[Menu] Settings not yet implemented")


func _on_quit_pressed() -> void:
	get_tree().quit()
