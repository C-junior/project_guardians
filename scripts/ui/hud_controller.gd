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

# Statue count display - dynamically created if not in scene
var statue_count_label: Label = null

# KillCounter
var kills_this_wave: int = 0

# Ability button scene
var ability_button_scene: PackedScene

# CRYSTAL DANGER EFFECTS
var danger_vignette: ColorRect = null
var danger_label: Label = null
var danger_pulse_timer: float = 0.0
var is_in_danger: bool = false

# TUTORIAL SYSTEM
var tutorial_panel: PanelContainer = null
var tutorial_label: Label = null
var tutorial_dismiss_btn: Button = null


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
	
	# Setup danger effects
	_setup_danger_effects()
	
	# Setup statue count display
	_setup_statue_count()
	
	# Setup tutorial panel
	_setup_tutorial_panel()


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
	
	# Show shop tutorial when first entering shop phase
	if _new_state == GameManager.GameState.SHOP:
		if TutorialManager:
			TutorialManager.show_tutorial("open_shop")


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
	wave_label.text = "Wave %d | Kills: %d" % [wave, kills_this_wave]
	
	# Reset kill counter for new wave
	kills_this_wave = 0
	
	# Show wave start announcement
	if wave > 0:
		show_wave_start(wave)


func _on_statue_placed(statue: Node) -> void:
	# Add ability button for this statue
	_add_ability_button(statue)
	# Update statue count display
	_update_statue_count()


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
		# Show ability tutorial when first ability becomes ready
		if TutorialManager:
			TutorialManager.show_tutorial("use_ability")
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


## JUICE: Enhanced wave start announcement
func show_wave_start(wave: int) -> void:
	# Get wave preview
	var preview = WaveData.get_wave_preview(wave)
	var is_boss_wave = (wave % 5 == 0)
	
	# Show boss wave tutorial on first boss wave (wave 5)
	if is_boss_wave and wave == 5:
		if TutorialManager:
			TutorialManager.show_tutorial("boss_wave")
	
	# Update wave start label with preview
	var wave_label_node = $WaveStartPanel/VBox/WaveStartLabel
	if is_boss_wave:
		wave_label_node.text = "⚔️ BOSS WAVE %d ⚔️" % wave
		wave_label_node.add_theme_color_override("font_color", Color.ORANGE)
		wave_label_node.add_theme_font_size_override("font_size", 36)  # Bigger for boss
	else:
		wave_label_node.text = "Wave %d" % wave
		wave_label_node.remove_theme_color_override("font_color")
		wave_label_node.add_theme_font_size_override("font_size", 28)
	
	# Add preview label if it doesn't exist
	var preview_label = $WaveStartPanel/VBox.get_node_or_null("PreviewLabel")
	if not preview_label:
		preview_label = Label.new()
		preview_label.name = "PreviewLabel"
		preview_label.add_theme_font_size_override("font_size", 14)
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		$WaveStartPanel/VBox.add_child(preview_label)
	preview_label.text = preview
	
	# JUICE: Start with scale 0 and animate in
	wave_start_panel.visible = true
	wave_start_panel.scale = Vector2.ZERO
	wave_start_panel.pivot_offset = wave_start_panel.size / 2
	wave_start_panel.modulate.a = 1.0
	
	var tween = create_tween()
	
	# Pop in with elastic effect
	tween.tween_property(wave_start_panel, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(wave_start_panel, "scale", Vector2.ONE, 0.1)
	
	# Boss wave gets extra effects
	if is_boss_wave:
		_boss_wave_effects()
	
	# Hold then fade out
	tween.tween_interval(2.0)
	tween.tween_property(wave_start_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.parallel().tween_property(wave_start_panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): 
		wave_start_panel.visible = false
		wave_start_panel.modulate.a = 1.0
		wave_start_panel.scale = Vector2.ONE
	)


## JUICE: Boss wave special effects
func _boss_wave_effects() -> void:
	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_offset = camera.offset
		var shake_tween = create_tween()
		for i in range(8):
			var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
			shake_tween.tween_property(camera, "offset", original_offset + offset, 0.03)
		shake_tween.tween_property(camera, "offset", original_offset, 0.05)
	
	# Red vignette flash
	var vignette = ColorRect.new()
	vignette.name = "BossVignette"
	vignette.color = Color(0.8, 0.0, 0.0, 0.3)
	vignette.anchors_preset = Control.PRESET_FULL_RECT
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)
	
	var flash_tween = create_tween().set_loops(2)
	flash_tween.tween_property(vignette, "color:a", 0.0, 0.15)
	flash_tween.tween_property(vignette, "color:a", 0.3, 0.15)
	flash_tween.set_loops(1)
	flash_tween.tween_property(vignette, "color:a", 0.0, 0.3)
	flash_tween.tween_callback(vignette.queue_free)


## JUICE: Enhanced wave complete celebration
func show_wave_complete() -> void:
	wave_complete_panel.visible = true
	wave_complete_panel.scale = Vector2.ZERO
	wave_complete_panel.pivot_offset = wave_complete_panel.size / 2
	wave_complete_panel.modulate.a = 1.0
	
	# Update completion label with stats
	var complete_label = wave_complete_panel.get_node_or_null("VBox/WaveCompleteLabel")
	if complete_label:
		var wave = GameManager.current_wave
		var gold_earned = 75 + (wave * 15)  # Match GameManager formula
		complete_label.text = "✨ WAVE %d COMPLETE! ✨" % wave
	
	# Add stats summary if not exists
	var stats_label = wave_complete_panel.get_node_or_null("VBox/StatsLabel")
	if not stats_label:
		stats_label = Label.new()
		stats_label.name = "StatsLabel"
		stats_label.add_theme_font_size_override("font_size", 16)
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		wave_complete_panel.get_node("VBox").add_child(stats_label)
	
	var gold_earned = 75 + (GameManager.current_wave * 15)
	stats_label.text = "Kills: %d | +%d Gold" % [kills_this_wave, gold_earned]
	
	# Show combo bonus if combo system active
	if ComboManager and ComboManager.current_combo > 1:
		stats_label.text += " (x%.1f combo!)" % ComboManager.get_combo_multiplier()
	
	# Victory green flash
	var victory_flash = ColorRect.new()
	victory_flash.name = "VictoryFlash"
	victory_flash.color = Color(0.3, 1.0, 0.3, 0.25)
	victory_flash.anchors_preset = Control.PRESET_FULL_RECT
	victory_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(victory_flash)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(victory_flash, "color:a", 0.0, 0.5)
	flash_tween.tween_callback(victory_flash.queue_free)
	
	# Spawn confetti particles! 🎉
	_spawn_confetti()
	
	# Panel animation
	var tween = create_tween()
	
	# Pop in with bounce
	tween.tween_property(wave_complete_panel, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(wave_complete_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# Hold then shrink out
	tween.tween_interval(1.8)
	tween.tween_property(wave_complete_panel, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(wave_complete_panel, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(wave_complete_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		wave_complete_panel.visible = false
		wave_complete_panel.modulate.a = 1.0
		wave_complete_panel.scale = Vector2.ONE
	)


## JUICE: Confetti particle effect for wave complete
func _spawn_confetti() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var confetti_colors = [
		Color(1.0, 0.3, 0.3),  # Red
		Color(0.3, 1.0, 0.3),  # Green
		Color(0.3, 0.3, 1.0),  # Blue
		Color(1.0, 1.0, 0.3),  # Yellow
		Color(1.0, 0.3, 1.0),  # Magenta
		Color(0.3, 1.0, 1.0),  # Cyan
	]
	
	for i in range(20):
		var confetti = ColorRect.new()
		confetti.size = Vector2(randf_range(8, 16), randf_range(8, 16))
		confetti.color = confetti_colors[randi() % confetti_colors.size()]
		confetti.position = Vector2(randf_range(0, viewport_size.x), -20)
		confetti.rotation = randf_range(0, TAU)
		confetti.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(confetti)
		
		# Animate falling with spin
		var fall_time = randf_range(1.5, 2.5)
		var end_y = viewport_size.y + 50
		var x_drift = randf_range(-100, 100)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(confetti, "position:y", end_y, fall_time).set_ease(Tween.EASE_IN)
		tween.tween_property(confetti, "position:x", confetti.position.x + x_drift, fall_time)
		tween.tween_property(confetti, "rotation", confetti.rotation + TAU * 2, fall_time)
		tween.tween_property(confetti, "modulate:a", 0.0, fall_time * 0.8).set_delay(fall_time * 0.2)
		tween.set_parallel(false)
		tween.tween_callback(confetti.queue_free)
	
	# Also spawn gold shower
	var gold_earned = 75 + (GameManager.current_wave * 15)
	_spawn_gold_shower(gold_earned)


## JUICE: Gold coin shower effect for wave complete
func _spawn_gold_shower(gold_amount: int) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var num_coins = min(gold_amount / 10, 30)  # 1 coin per 10 gold, max 30 coins
	
	for i in range(num_coins):
		var coin = Label.new()
		coin.text = "💰"
		coin.add_theme_font_size_override("font_size", 24)
		coin.position = Vector2(randf_range(viewport_size.x * 0.2, viewport_size.x * 0.8), -30)
		coin.rotation = randf_range(0, TAU)
		coin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(coin)
		
		# Animate falling with bounce at bottom
		var fall_time = randf_range(0.8, 1.2)
		var end_y = viewport_size.y - randf_range(50, 150)
		var x_drift = randf_range(-50, 50)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(coin, "position:y", end_y, fall_time).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_property(coin, "position:x", coin.position.x + x_drift, fall_time)
		tween.tween_property(coin, "rotation", coin.rotation + TAU, fall_time)
		tween.set_parallel(false)
		# Hold at bottom briefly then fade
		tween.tween_interval(0.5)
		tween.tween_property(coin, "modulate:a", 0.0, 0.3)
		tween.tween_callback(coin.queue_free)



func _process(delta: float) -> void:
	# Update ability buttons cooldown states
	for button in ability_bar.get_children():
		if button.has_meta("statue"):
			var statue = button.get_meta("statue")
			# Check if statue was freed (e.g., during ascension)
			if not is_instance_valid(statue):
				button.queue_free()
				continue
			_update_ability_button(button, statue)
	
	# Update danger effects based on crystal health
	_update_danger_effects(delta)


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


## Called when enemy is killed - shows gold float and updates kill counter
func on_enemy_killed(gold_amount: int, world_pos: Vector2) -> void:
	# Increment kill counter
	kills_this_wave += 1
	wave_label.text = "Wave %d | Kills: %d" % [GameManager.current_wave, kills_this_wave]
	
	# Show floating gold number that floats toward gold counter
	_show_gold_float(gold_amount, world_pos)


## Show floating gold number animation
func _show_gold_float(amount: int, world_pos: Vector2) -> void:
	var label = Label.new()
	label.text = "+%d 💰" % amount
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.GOLD)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Convert world position to screen position
	var viewport = get_viewport()
	var camera = viewport.get_camera_2d()
	var screen_pos: Vector2
	if camera:
		screen_pos = world_pos - camera.get_screen_center_position() + viewport.get_visible_rect().size / 2
	else:
		screen_pos = world_pos
	
	label.position = screen_pos
	label.z_index = 100
	add_child(label)
	
	# Float up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 50, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


## CRYSTAL DANGER EFFECTS: Setup vignette and danger label
func _setup_danger_effects() -> void:
	# Create red vignette overlay (hidden by default)
	danger_vignette = ColorRect.new()
	danger_vignette.name = "DangerVignette"
	danger_vignette.color = Color(1.0, 0.0, 0.0, 0.0)  # Red, fully transparent
	danger_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	danger_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger_vignette.z_index = 50  # Above most UI
	add_child(danger_vignette)
	
	# Create "DANGER!" label (hidden by default)
	danger_label = Label.new()
	danger_label.name = "DangerLabel"
	danger_label.text = "⚠️ DANGER! ⚠️"
	danger_label.add_theme_font_size_override("font_size", 32)
	danger_label.add_theme_color_override("font_color", Color.RED)
	danger_label.add_theme_color_override("font_outline_color", Color.BLACK)
	danger_label.add_theme_constant_override("outline_size", 4)
	danger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	danger_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	danger_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	danger_label.offset_top = 100
	danger_label.modulate.a = 0.0
	danger_label.z_index = 51
	add_child(danger_label)


## CRYSTAL DANGER EFFECTS: Update based on crystal health
func _update_danger_effects(delta: float) -> void:
	var danger_threshold = GameManager.crystal_max_health * 0.3
	var current_health = GameManager.crystal_health
	
	if current_health <= danger_threshold and current_health > 0:
		# IN DANGER!
		if not is_in_danger:
			is_in_danger = true
			print("[HUD] Crystal in danger! HP: %d/%d" % [current_health, GameManager.crystal_max_health])
		
		# Calculate danger intensity (0.0 to 1.0, higher when HP is lower)
		var danger_pct = float(current_health) / danger_threshold
		var intensity = 1.0 - danger_pct  # 0% HP = 1.0, 30% HP = 0.0
		
		# Update vignette opacity
		if danger_vignette:
			danger_vignette.color.a = 0.2 + (intensity * 0.3)  # 0.2 to 0.5 alpha
		
		# Pulse "DANGER!" text
		if danger_label:
			danger_pulse_timer += delta
			var pulse = abs(sin(danger_pulse_timer * 3.0))  # Pulse 3x per second
			danger_label.modulate.a = 0.5 + (pulse * 0.5)  # 0.5 to 1.0 alpha
			
			# Scale pulse for extra urgency
			var scale_pulse = 1.0 + (pulse * 0.15 * intensity)
			danger_label.scale = Vector2(scale_pulse, scale_pulse)
		
		# Screen shake (more intense as HP drops)
		if danger_pulse_timer >= 1.0 and intensity > 0.5:  # Only shake when very low
			danger_pulse_timer = 0.0
			_danger_screen_shake(intensity * 5.0)  # Max 5px shake
	else:
		# SAFE - hide danger effects
		if is_in_danger:
			is_in_danger = false
			print("[HUD] Crystal safe!")
		
		if danger_vignette:
			danger_vignette.color.a = 0.0
		if danger_label:
			danger_label.modulate.a = 0.0


## CRYSTAL DANGER EFFECTS: Small screen shake for danger
func _danger_screen_shake(intensity: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var original_offset = camera.offset
	var shake_tween = create_tween()
	for i in range(4):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		shake_tween.tween_property(camera, "offset", original_offset + offset, 0.05)
	shake_tween.tween_property(camera, "offset", original_offset, 0.05)


## STATUE COUNT: Setup the statue count label in TopBar
func _setup_statue_count() -> void:
	# Try to find existing label in scene
	statue_count_label = get_node_or_null("TopBar/StatueCount")
	
	if not statue_count_label:
		# Create label dynamically if not in scene
		statue_count_label = Label.new()
		statue_count_label.name = "StatueCount"
		statue_count_label.add_theme_font_size_override("font_size", 16)
		statue_count_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))  # Gold-ish
		statue_count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		statue_count_label.add_theme_constant_override("outline_size", 2)
		
		# Add to TopBar (after other elements)
		var top_bar = get_node_or_null("TopBar")
		if top_bar:
			top_bar.add_child(statue_count_label)
	
	# Initial update
	_update_statue_count()


## STATUE COUNT: Update the display
func _update_statue_count() -> void:
	if not statue_count_label:
		return
	
	var current = GameManager.placed_statues.size()
	var max_count = GameManager.get_max_statues()
	statue_count_label.text = "⚔️ %d/%d" % [current, max_count]
	
	# Color coding: yellow if near limit, red if at limit
	if current >= max_count:
		statue_count_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))  # Red
	elif current >= max_count - 1:
		statue_count_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))  # Yellow
	else:
		statue_count_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5))  # Gold


## TUTORIAL SYSTEM: Setup the tutorial popup panel
func _setup_tutorial_panel() -> void:
	# Connect to TutorialManager signals
	if TutorialManager:
		TutorialManager.tutorial_shown.connect(_on_tutorial_shown)
		TutorialManager.tutorial_dismissed.connect(_on_tutorial_dismissed)
	
	# Create panel container
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.visible = false
	tutorial_panel.z_index = 100
	
	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.25, 0.95)
	style.border_color = Color(0.4, 0.7, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	tutorial_panel.add_theme_stylebox_override("panel", style)
	
	# Create VBox for content
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tutorial_panel.add_child(vbox)
	
	# Tutorial header
	var header = Label.new()
	header.text = "💡 TIP"
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)
	
	# Tutorial message
	tutorial_label = Label.new()
	tutorial_label.text = ""
	tutorial_label.add_theme_font_size_override("font_size", 16)
	tutorial_label.add_theme_color_override("font_color", Color.WHITE)
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_label.custom_minimum_size = Vector2(350, 0)
	vbox.add_child(tutorial_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)
	
	# Dismiss button
	tutorial_dismiss_btn = Button.new()
	tutorial_dismiss_btn.text = "Got it! ✓"
	tutorial_dismiss_btn.custom_minimum_size = Vector2(120, 35)
	tutorial_dismiss_btn.pressed.connect(_on_tutorial_dismiss_pressed)
	vbox.add_child(tutorial_dismiss_btn)
	
	# Center the panel
	tutorial_panel.set_anchors_preset(Control.PRESET_CENTER)
	tutorial_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tutorial_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	add_child(tutorial_panel)
	
	# Trigger first tutorial if this is a new run
	call_deferred("_check_initial_tutorials")


## TUTORIAL SYSTEM: Show tutorial popup
func _on_tutorial_shown(id: String, message: String) -> void:
	if not tutorial_panel or not tutorial_label:
		return
	
	tutorial_label.text = message
	tutorial_panel.visible = true
	tutorial_panel.modulate.a = 0.0
	tutorial_panel.scale = Vector2(0.8, 0.8)
	tutorial_panel.pivot_offset = tutorial_panel.size / 2
	
	# Animate in
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tutorial_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(tutorial_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


## TUTORIAL SYSTEM: Hide tutorial popup
func _on_tutorial_dismissed(_id: String) -> void:
	if not tutorial_panel:
		return
	
	# Animate out
	var tween = create_tween()
	tween.tween_property(tutorial_panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(tutorial_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_callback(func(): tutorial_panel.visible = false)


## TUTORIAL SYSTEM: Dismiss button pressed
func _on_tutorial_dismiss_pressed() -> void:
	if TutorialManager:
		TutorialManager.dismiss_current()


## TUTORIAL SYSTEM: Check if we should show initial tutorials
func _check_initial_tutorials() -> void:
	# Wait a moment for game to initialize
	await get_tree().create_timer(1.0).timeout
	
	# Show placement tutorial if this is wave 0/1 and no statues placed
	if GameManager.current_wave <= 1 and GameManager.placed_statues.size() == 0:
		if TutorialManager:
			TutorialManager.show_tutorial("place_statue")
