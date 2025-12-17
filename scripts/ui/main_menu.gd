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
	# Open the Aether Sanctum (meta-progression) UI
	var main = get_parent()
	if main:
		var sanctum = main.get_node_or_null("MetaProgressionUI")
		if sanctum:
			# Hide main menu while sanctum is open
			visible = false
			sanctum.open()
			# Connect to close signal if not already
			if not sanctum.sanctum_closed.is_connected(_on_sanctum_closed):
				sanctum.sanctum_closed.connect(_on_sanctum_closed)
		else:
			print("[Menu] MetaProgressionUI not found in Main scene")
	else:
		print("[Menu] Could not find parent Main node")


func _on_settings_pressed() -> void:
	# TODO: Open settings
	print("[Menu] Settings not yet implemented")


func _on_quit_pressed() -> void:
	get_tree().quit()


## Called when sanctum closes to show menu again
func _on_sanctum_closed() -> void:
	visible = true
	_update_essence_display()  # Refresh in case player spent essence
