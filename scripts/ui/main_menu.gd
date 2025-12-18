extends CanvasLayer

## Main Menu Controller with Map Selection

@onready var new_game_button: Button = $TitleContainer/NewGameButton
@onready var progression_button: Button = $TitleContainer/ProgressionButton
@onready var settings_button: Button = $TitleContainer/SettingsButton
@onready var quit_button: Button = $TitleContainer/QuitButton
@onready var essence_label: Label = $EssenceDisplay/EssenceLabel

# Map selection panel (created dynamically)
var map_select_panel: PanelContainer = null
var showing_map_select: bool = false


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	progression_button.pressed.connect(_on_progression_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Update essence display
	_update_essence_display()
	
	# Create map selection panel
	_create_map_select_panel()


func _update_essence_display() -> void:
	essence_label.text = str(GameManager.aether_essence)


func _on_new_game_pressed() -> void:
	# Show map selection instead of immediately starting
	_show_map_selection()


func _show_map_selection() -> void:
	if map_select_panel:
		map_select_panel.visible = true
		showing_map_select = true
		_populate_map_buttons()


func _hide_map_selection() -> void:
	if map_select_panel:
		map_select_panel.visible = false
		showing_map_select = false


func _create_map_select_panel() -> void:
	map_select_panel = PanelContainer.new()
	map_select_panel.name = "MapSelectPanel"
	map_select_panel.visible = false
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.2, 0.95)
	style.border_color = Color(0.4, 0.5, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(15)
	style.set_content_margin_all(30)
	map_select_panel.add_theme_stylebox_override("panel", style)
	
	# Create VBox
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	map_select_panel.add_child(vbox)
	
	# Header
	var header = Label.new()
	header.name = "Header"
	header.text = "🗺️ SELECT MAP"
	header.add_theme_font_size_override("font_size", 28)
	header.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)
	
	# Maps container
	var maps_container = VBoxContainer.new()
	maps_container.name = "MapsContainer"
	maps_container.add_theme_constant_override("separation", 15)
	vbox.add_child(maps_container)
	
	# Back button
	var back_btn = Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "← Back"
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(_hide_map_selection)
	vbox.add_child(back_btn)
	
	# Center the panel
	map_select_panel.set_anchors_preset(Control.PRESET_CENTER)
	map_select_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	map_select_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	add_child(map_select_panel)


func _populate_map_buttons() -> void:
	var maps_container = map_select_panel.get_node("VBox/MapsContainer")
	if not maps_container:
		return
	
	# Clear existing
	for child in maps_container.get_children():
		child.queue_free()
	
	# Add buttons for each map
	var maps = _get_available_maps()
	for map_data in maps:
		var btn = _create_map_button(map_data)
		maps_container.add_child(btn)


func _get_available_maps() -> Array:
	# Hardcode for now since static func can't be called easily
	var maps = []
	var paths = ["res://resources/maps/grove.tres", "res://resources/maps/citadel.tres"]
	for path in paths:
		var map = load(path)
		if map:
			maps.append(map)
	return maps


func _create_map_button(map_data: Resource) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(350, 70)
	
	# Difficulty stars
	var stars = "★".repeat(map_data.difficulty) + "☆".repeat(3 - map_data.difficulty)
	btn.text = "%s\n%s - %s" % [map_data.display_name, stars, map_data.description.substr(0, 40) + "..."]
	btn.add_theme_font_size_override("font_size", 16)
	
	btn.pressed.connect(_on_map_selected.bind(map_data))
	return btn


func _on_map_selected(map_data: Resource) -> void:
	# Set the map in GameManager
	GameManager.set_map(map_data)
	
	# Hide map selection
	_hide_map_selection()
	
	# Start the game
	var main = get_parent()
	if main and main.has_method("start_new_game"):
		main.start_new_game()
	
	print("[Menu] Selected map: %s" % map_data.display_name)


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
