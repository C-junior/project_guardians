extends Node2D

## Main Game Controller
## Manages game flow between menu, setup, combat, shop, and game over states

# Scene references
@onready var main_menu: CanvasLayer = $MainMenu
@onready var arena: Node2D = $Arena
@onready var hud: CanvasLayer = $HUD
@onready var shop_ui: CanvasLayer = $ShopUI
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var statue_selection_ui: CanvasLayer = $StatueSelectionUI
@onready var inventory_ui: CanvasLayer = $InventoryUI
@onready var ascension_ui: CanvasLayer = $AscensionUI

# Game over UI
@onready var waves_survived_label: Label = $GameOverScreen/Panel/VBox/WavesSurvivedLabel
@onready var essence_label: Label = $GameOverScreen/Panel/VBox/EssenceLabel
@onready var restart_button: Button = $GameOverScreen/Panel/VBox/RestartButton
@onready var menu_button: Button = $GameOverScreen/Panel/VBox/MenuButton

# Statue placement state
var pending_statue_to_place: Resource = null
var pending_statue_tier: int = 0  # Track tier for placement
var is_initial_placement: bool = false  # True when placing starting statue


func _ready() -> void:
	# Connect GameManager signals
	GameManager.game_state_changed.connect(_on_game_state_changed)
	
	# Connect arena signals (with null check)
	if arena:
		arena.wave_completed.connect(_on_wave_completed)
	else:
		push_error("[Main] Arena not found!")
	
	# Connect shop signals (with null check)
	if shop_ui:
		shop_ui.item_purchased.connect(_on_item_purchased)
		shop_ui.shop_closed.connect(_on_shop_closed)
	else:
		push_error("[Main] ShopUI not found!")
	
	# Connect statue selection UI signals
	if statue_selection_ui:
		statue_selection_ui.statue_selected.connect(_on_starting_statue_selected)
		statue_selection_ui.back_to_menu.connect(_on_statue_selection_back)
	else:
		push_warning("[Main] StatueSelectionUI not found - will use fallback flow")
	
	# Connect inventory UI signals
	if inventory_ui:
		inventory_ui.place_statue_requested.connect(_on_inventory_place_statue)
		if inventory_ui.has_signal("ascension_requested"):
			inventory_ui.ascension_requested.connect(_on_ascension_requested)
	
	# Connect ascension UI signals
	if ascension_ui:
		ascension_ui.ascension_completed.connect(_on_ascension_completed)
		ascension_ui.ascension_cancelled.connect(_on_ascension_cancelled)
	
	# Connect HUD signals
	if hud:
		hud.inventory_button_pressed.connect(_on_hud_inventory_pressed)
		hud.shop_button_pressed.connect(_on_hud_shop_pressed)
		hud.start_wave_button_pressed.connect(_on_hud_start_wave_pressed)
	
	# Connect game over buttons
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	
	# Load saved progress
	GameManager.load_meta_progression()
	
	# Start at menu
	_show_main_menu()



func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	match new_state:
		GameManager.GameState.MENU:
			_show_main_menu()
		GameManager.GameState.SETUP:
			_show_setup()
		GameManager.GameState.COMBAT:
			_show_combat()
		GameManager.GameState.SHOP:
			_show_shop()
		GameManager.GameState.GAME_OVER:
			_show_game_over()


func _show_main_menu() -> void:
	if main_menu:
		main_menu.visible = true
	if arena:
		arena.visible = false
	if hud:
		hud.visible = false
	if shop_ui:
		shop_ui.visible = false
	if game_over_screen:
		game_over_screen.visible = false
	if statue_selection_ui:
		statue_selection_ui.visible = false
	if inventory_ui:
		inventory_ui.visible = false


func _show_setup() -> void:
	if main_menu:
		main_menu.visible = false
	if game_over_screen:
		game_over_screen.visible = false
	
	# Show statue selection UI
	if statue_selection_ui:
		statue_selection_ui.open()
	else:
		# Fallback: skip selection and use random statue
		_use_fallback_starting_statue()


func _show_combat() -> void:
	if main_menu:
		main_menu.visible = false
	if arena:
		arena.visible = true
	if hud:
		hud.visible = true
	if shop_ui:
		shop_ui.visible = false
	if game_over_screen:
		game_over_screen.visible = false
	if statue_selection_ui:
		statue_selection_ui.visible = false


func _show_shop() -> void:
	if shop_ui:
		shop_ui.open_shop()
	# Show inventory button/panel in shop
	if inventory_ui:
		inventory_ui.visible = true


func _show_game_over() -> void:
	if game_over_screen:
		game_over_screen.visible = true
	if waves_survived_label:
		waves_survived_label.text = "Waves Survived: %d" % GameManager.current_wave
	if essence_label:
		essence_label.text = "Aether Essence Earned: %d" % (GameManager.current_wave * 10)


func _on_wave_completed(wave_number: int) -> void:
	if hud and hud.has_method("show_wave_complete"):
		hud.show_wave_complete()
	# Small delay before shop opens
	await get_tree().create_timer(1.5).timeout
	GameManager.end_wave(true)


## Called when player selects starting statue
func _on_starting_statue_selected(statue_data: Resource) -> void:
	print("[Main] Starting statue selected: %s" % statue_data.display_name)
	
	# Add the selected statue to inventory
	GameManager.add_to_inventory(statue_data, "statues")
	
	# Prepare arena
	_reset_arena()
	
	# Make enemy path visible for debugging
	_set_path_visible(true)
	
	# Show arena and HUD (player will use inventory button to place)
	if arena:
		arena.visible = true
	if hud:
		hud.visible = true
	if inventory_ui:
		inventory_ui.visible = false  # Hidden until player clicks button
	
	print("[Main] Arena ready - use Inventory button to place statues, then Start Wave")


func _on_statue_selection_back() -> void:
	GameManager.current_state = GameManager.GameState.MENU


func _on_item_purchased(item: Resource, item_type: String) -> void:
	if item_type == "statue" and item:
		# Add to inventory instead of immediate placement
		GameManager.add_to_inventory(item, "statues")
		print("[Main] Statue added to inventory: %s" % item.display_name)
	elif item_type == "artifact" and item:
		GameManager.add_to_inventory(item, "artifacts")
		GameManager.add_artifact(item)
	elif item_type == "consumable" and item:
		GameManager.add_to_inventory(item, "consumables")


## Called when player wants to place a statue from inventory
func _on_inventory_place_statue(statue_data: Resource, tier: int = 0) -> void:
	if GameManager.has_in_inventory(statue_data, "statues"):
		pending_statue_to_place = statue_data
		pending_statue_tier = tier
		is_initial_placement = false
		
		# Hide inventory during placement
		if inventory_ui:
			inventory_ui.visible = false
		if shop_ui:
			shop_ui.visible = false
		
		_enter_placement_mode()


func _on_shop_closed() -> void:
	# Hide inventory when shop closes
	if inventory_ui:
		inventory_ui.visible = false
	# Wave starts via GameManager.start_next_wave()


func _enter_placement_mode() -> void:
	if not arena:
		return
	# Enable placement grid highlight
	if arena.placement_grid:
		for cell in arena.placement_grid.get_children():
			if cell is ColorRect:
				# Parse cell name safely (format: Cell_X_Y)
				var parts = cell.name.split("_")
				if parts.size() >= 3:
					var grid_x = int(parts[1])
					var grid_y = int(parts[2])
					if arena.is_cell_empty(Vector2i(grid_x, grid_y)):
						cell.color = Color(0.3, 0.8, 0.3, 0.5)


func _input(event: InputEvent) -> void:
	if not arena:
		return
	# Handle statue placement
	if pending_statue_to_place and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var grid_pos = arena.world_to_grid(get_global_mouse_position())
			if arena.is_cell_empty(grid_pos):
				# Place with correct tier
				arena.place_statue(pending_statue_to_place, grid_pos, pending_statue_tier)
				
				# If placing from inventory, remove from inventory with tier
				if not is_initial_placement:
					GameManager.remove_from_inventory(pending_statue_to_place, "statues", pending_statue_tier)
				
				pending_statue_to_place = null
				pending_statue_tier = 0
				_exit_placement_mode()
				
				# After placing, return to arena view (don't auto-start wave)
				is_initial_placement = false
				
				# Show feedback - player must use Start Wave button
				print("[Main] Statue placed! Use Start Wave button to begin combat.")
				
				# Show shop/inventory if in shop state
				if GameManager.current_state == GameManager.GameState.SHOP:
					if shop_ui:
						shop_ui.visible = true
					if inventory_ui:
						inventory_ui.visible = true
						inventory_ui.refresh()
						
		elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			# Cancel placement
			pending_statue_to_place = null
			_exit_placement_mode()
			
			if is_initial_placement:
				# Return to statue selection
				is_initial_placement = false
				if statue_selection_ui:
					statue_selection_ui.open()
			else:
				if shop_ui:
					shop_ui.visible = true
				if inventory_ui:
					inventory_ui.visible = true


func _exit_placement_mode() -> void:
	if not arena or not arena.placement_grid:
		return
	# Reset placement grid colors
	for cell in arena.placement_grid.get_children():
		if cell is ColorRect:
			# Parse cell name safely (format: Cell_X_Y)
			var parts = cell.name.split("_")
			if parts.size() >= 3:
				var grid_x = int(parts[1])
				var grid_y = int(parts[2])
				if arena.is_cell_empty(Vector2i(grid_x, grid_y)):
					cell.color = Color(0.2, 0.3, 0.2, 0.3)


func _on_restart_pressed() -> void:
	GameManager.start_new_run()


func _on_menu_pressed() -> void:
	GameManager.current_state = GameManager.GameState.MENU


func _reset_arena() -> void:
	if not arena:
		return
	
	# Reset arena
	if arena.statues_container:
		for child in arena.statues_container.get_children():
			child.queue_free()
	if arena.enemies_container:
		for child in arena.enemies_container.get_children():
			child.queue_free()
	arena.grid_cells.clear()
	arena._setup_grid()
	
	# Clear HUD ability buttons
	if hud and hud.ability_bar:
		for child in hud.ability_bar.get_children():
			child.queue_free()


func _start_first_wave() -> void:
	# Start first wave
	GameManager.start_next_wave()
	
	# Generate wave and start combat
	var wave_data = WaveData.generate_wave(GameManager.current_wave)
	arena.start_wave(wave_data)


func _use_fallback_starting_statue() -> void:
	# Fallback when no statue selection UI
	var starting_statue = _get_random_starting_statue()
	if starting_statue:
		_on_starting_statue_selected(starting_statue)


func _get_random_starting_statue() -> Resource:
	# Check blessing for specific starting statue
	if GameManager.current_blessing:
		# Handle blessing effects
		pass
	
	# Get unlocked statues
	var unlocked = GameManager.get_unlocked_statue_resources()
	if unlocked.size() > 0:
		return unlocked[randi() % unlocked.size()]
	
	# Fallback
	return load("res://resources/statues/sentinel.tres")


## Called from main menu to start a new game
func start_new_game() -> void:
	GameManager.start_new_run()
	# GameManager will transition to SETUP state, which triggers _show_setup()


## HUD Button Handlers
func _on_hud_inventory_pressed() -> void:
	if inventory_ui:
		inventory_ui.visible = not inventory_ui.visible
		if inventory_ui.visible:
			inventory_ui.refresh()


func _on_hud_shop_pressed() -> void:
	# Open shop UI
	if shop_ui:
		shop_ui.open_shop()


func _on_hud_start_wave_pressed() -> void:
	# Check if at least one statue is placed
	if GameManager.placed_statues.is_empty():
		print("[Main] Cannot start wave - no statues placed!")
		return
	
	# Hide inventory and shop if open
	if inventory_ui:
		inventory_ui.visible = false
	if shop_ui:
		shop_ui.visible = false
	
	# Hide the path when combat starts (optional)
	# _set_path_visible(false)
	
	# Start the wave
	_start_first_wave()


## Enemy Path Visibility (for debugging)
func _set_path_visible(visible: bool) -> void:
	if arena and arena.has_node("EnemyPath"):
		var path = arena.get_node("EnemyPath")
		# Create a Line2D to visualize the path if not exists
		var line_name = "PathVisualization"
		var line = path.get_node_or_null(line_name)
		
		if visible:
			if not line:
				line = Line2D.new()
				line.name = line_name
				line.width = 4.0
				line.default_color = Color(1, 0.3, 0.3, 0.6)  # Red semi-transparent
				path.add_child(line)
			
			# Copy curve points to line
			if path.curve:
				line.clear_points()
				for i in range(path.curve.point_count):
					line.add_point(path.curve.get_point_position(i))
			
			line.visible = true
			print("[Main] Enemy path is now VISIBLE. To hide: call _set_path_visible(false)")
		else:
			if line:
				line.visible = false
			print("[Main] Enemy path is now HIDDEN")


## Ascension UI Handlers
func _on_ascension_requested() -> void:
	if ascension_ui:
		# Hide inventory and shop while ascension is open
		if inventory_ui:
			inventory_ui.visible = false
		if shop_ui:
			shop_ui.visible = false
		ascension_ui.open()


func _on_ascension_completed(_evolved_statue: Resource, _tier: int) -> void:
	print("[Main] Ascension completed!")
	# Show inventory again after ascension
	if GameManager.current_state == GameManager.GameState.SHOP:
		if inventory_ui:
			inventory_ui.visible = true
			inventory_ui.refresh()
		if shop_ui:
			shop_ui.visible = true


func _on_ascension_cancelled() -> void:
	print("[Main] Ascension cancelled")
	# Show inventory again
	if GameManager.current_state == GameManager.GameState.SHOP:
		if inventory_ui:
			inventory_ui.visible = true
		if shop_ui:
			shop_ui.visible = true
