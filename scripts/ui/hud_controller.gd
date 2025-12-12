extends CanvasLayer

## HUD Controller - Manages in-game UI elements

signal inventory_button_pressed()
signal shop_button_pressed()
signal start_wave_button_pressed()

# References
@onready var wave_label: Label = $TopBar/WaveLabel
@onready var health_bar: ProgressBar = $TopBar/CrystalHealth/HealthBar
@onready var health_label: Label = $TopBar/CrystalHealth/HealthLabel
@onready var gold_label: Label = $TopBar/GoldContainer/GoldLabel
@onready var ability_bar: HBoxContainer = $AbilityBar
@onready var speed_1x: Button = $SpeedControls/Speed1x
@onready var speed_2x: Button = $SpeedControls/Speed2x
@onready var speed_3x: Button = $SpeedControls/Speed3x
@onready var pause_button: Button = $SpeedControls/PauseButton
@onready var wave_start_panel: PanelContainer = $WaveStartPanel
@onready var wave_complete_panel: PanelContainer = $WaveCompletePanel
@onready var inventory_button: Button = $ActionButtons/InventoryButton
@onready var shop_button: Button = $ActionButtons/ShopButton
@onready var start_wave_button: Button = $ActionButtons/StartWaveButton

# Ability button scene
var ability_button_scene: PackedScene


func _ready() -> void:
	# Connect to GameManager signals
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.crystal_health_changed.connect(_on_crystal_health_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.statue_placed.connect(_on_statue_placed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	
	# Speed control buttons
	speed_1x.pressed.connect(func(): _set_speed(1.0))
	speed_2x.pressed.connect(func(): _set_speed(2.0))
	speed_3x.pressed.connect(func(): _set_speed(3.0))
	pause_button.pressed.connect(_toggle_pause)
	
	# Action buttons
	inventory_button.pressed.connect(_on_inventory_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	start_wave_button.pressed.connect(_on_start_wave_pressed)
	
	# Initial update
	_on_gold_changed(GameManager.gold)
	_on_crystal_health_changed(GameManager.crystal_health, GameManager.crystal_max_health)
	_on_wave_changed(GameManager.current_wave)
	_update_action_buttons_visibility()


func _on_inventory_pressed() -> void:
	inventory_button_pressed.emit()


func _on_shop_pressed() -> void:
	# Only allow opening shop during SHOP phase
	if GameManager.current_state == GameManager.GameState.SHOP:
		shop_button_pressed.emit()


func _on_start_wave_pressed() -> void:
	# Only allow starting wave during SHOP or SETUP phase
	if GameManager.current_state != GameManager.GameState.COMBAT:
		start_wave_button_pressed.emit()


func _on_game_state_changed(_new_state: GameManager.GameState) -> void:
	_update_action_buttons_visibility()


func _update_action_buttons_visibility() -> void:
	# Shop button only visible during SHOP phase
	if shop_button:
		shop_button.visible = GameManager.current_state == GameManager.GameState.SHOP
	
	# Start wave button visible during SHOP or when setting up (not during combat)
	if start_wave_button:
		start_wave_button.visible = GameManager.current_state != GameManager.GameState.COMBAT


func _on_gold_changed(new_gold: int) -> void:
	gold_label.text = str(new_gold)
	
	# Gold pop animation
	var tween = create_tween()
	tween.tween_property(gold_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(gold_label, "scale", Vector2.ONE, 0.1)


func _on_crystal_health_changed(current: int, max_hp: int) -> void:
	var prev_health = health_bar.value
	health_bar.max_value = max_hp
	health_bar.value = current
	health_label.text = "%d/%d" % [current, max_hp]
	
	# Color based on health
	var health_percent = float(current) / float(max_hp)
	if health_percent > 0.6:
		health_bar.modulate = Color.GREEN
	elif health_percent > 0.3:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED
		# Low health warning flash
		var tween = create_tween().set_loops(3)
		tween.tween_property(health_bar, "modulate:a", 0.5, 0.2)
		tween.tween_property(health_bar, "modulate:a", 1.0, 0.2)
	
	# Screen edge flash when taking damage
	if current < prev_health:
		_show_damage_flash()


func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Wave %d" % wave
	
	# Show wave start announcement
	if wave > 0:
		show_wave_start(wave)


func _on_statue_placed(statue: Node) -> void:
	# Add ability button for this statue
	_add_ability_button(statue)


func _add_ability_button(statue: Node) -> void:
	var button = Button.new()
	button.custom_minimum_size = Vector2(60, 60)
	
	# Set icon/text based on statue type
	var ability_name = statue.statue_data.ability_name if statue.statue_data else "?"
	button.text = ability_name.substr(0, 1)  # First letter
	button.tooltip_text = ability_name
	
	# Store reference
	button.set_meta("statue", statue)
	
	# Connect
	button.pressed.connect(func(): _on_ability_button_pressed(statue))
	
	ability_bar.add_child(button)
	
	# Update button state based on ability cooldown
	_update_ability_button(button, statue)


func _update_ability_button(button: Button, statue: Node) -> void:
	# This should be called every frame to update cooldown visual
	if not is_instance_valid(statue):
		button.queue_free()
		return
	
	button.disabled = not statue.ability_ready
	
	if statue.ability_ready:
		button.modulate = Color(0.3, 1.0, 0.5)
	else:
		button.modulate = Color(0.5, 0.5, 0.5)


func _on_ability_button_pressed(statue: Node) -> void:
	if statue and statue.has_method("use_ability"):
		statue.use_ability()


func _set_speed(speed: float) -> void:
	GameManager.set_game_speed(speed)
	
	# Update button visuals
	speed_1x.modulate = Color.WHITE if speed == 1.0 else Color(0.6, 0.6, 0.6)
	speed_2x.modulate = Color.WHITE if speed == 2.0 else Color(0.6, 0.6, 0.6)
	speed_3x.modulate = Color.WHITE if speed == 3.0 else Color(0.6, 0.6, 0.6)


func _toggle_pause() -> void:
	if GameManager.current_state == GameManager.GameState.PAUSED:
		GameManager.resume_game()
		pause_button.text = "⏸️"
	else:
		GameManager.pause_game()
		pause_button.text = "▶️"


func show_wave_start(wave: int) -> void:
	$WaveStartPanel/VBox/WaveStartLabel.text = "Wave %d" % wave
	wave_start_panel.visible = true
	
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(wave_start_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): 
		wave_start_panel.visible = false
		wave_start_panel.modulate.a = 1.0
	)


func show_wave_complete() -> void:
	wave_complete_panel.visible = true
	
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(wave_complete_panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		wave_complete_panel.visible = false
		wave_complete_panel.modulate.a = 1.0
	)


func _process(_delta: float) -> void:
	# Update ability buttons cooldown states
	for button in ability_bar.get_children():
		if button.has_meta("statue"):
			var statue = button.get_meta("statue")
			# Check if statue was freed (e.g., during ascension)
			if not is_instance_valid(statue):
				button.queue_free()
				continue
			_update_ability_button(button, statue)


## Show red screen edge flash when crystal takes damage
func _show_damage_flash() -> void:
	# Create a red overlay for damage feedback
	var flash = ColorRect.new()
	flash.name = "DamageFlash"
	flash.color = Color(1, 0, 0, 0.3)
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	# Fade out quickly
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)
