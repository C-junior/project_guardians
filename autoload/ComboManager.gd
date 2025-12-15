extends Node

## ComboManager - Tracks kill combos and rewards
## Creates tension and excitement during waves with escalating rewards

signal combo_updated(combo: int, multiplier: float)
signal combo_ended(final_combo: int, bonus_gold: int)

# Combo state
var current_combo: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 2.5  # Seconds to get next kill before combo resets
const MAX_COMBO_TIME: float = 3.5  # Max time window for high combos

# Combo rewards
const COMBO_GOLD_THRESHOLD: int = 5  # Minimum combo for bonus gold
const COMBO_GOLD_PER_KILL: int = 2  # Extra gold per kill beyond threshold

# Visual feedback reference
var combo_label: Label = null
var combo_panel: PanelContainer = null


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if current_combo > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			_end_combo()
		else:
			# Flash warning when combo is about to expire
			if combo_timer < 0.8 and combo_label:
				var flash = sin(combo_timer * 15) * 0.3 + 0.7
				combo_label.modulate.a = flash


## Called when an enemy is killed
func register_kill() -> void:
	current_combo += 1
	
	# Extend timer (diminishing returns for very high combos)
	combo_timer = COMBO_WINDOW * (1.0 + min(current_combo * 0.1, 0.4))
	combo_timer = min(combo_timer, MAX_COMBO_TIME)
	
	# Calculate multiplier (for potential future use)
	var multiplier = get_combo_multiplier()
	
	combo_updated.emit(current_combo, multiplier)
	
	# Update UI
	_show_combo_ui()


## Get current combo damage/reward multiplier
func get_combo_multiplier() -> float:
	if current_combo < 3:
		return 1.0
	elif current_combo < 5:
		return 1.1
	elif current_combo < 10:
		return 1.2
	elif current_combo < 15:
		return 1.3
	else:
		return 1.5


## Get bonus gold for current combo
func get_combo_bonus_gold() -> int:
	if current_combo < COMBO_GOLD_THRESHOLD:
		return 0
	return (current_combo - COMBO_GOLD_THRESHOLD + 1) * COMBO_GOLD_PER_KILL


func _end_combo() -> void:
	if current_combo >= COMBO_GOLD_THRESHOLD:
		var bonus = get_combo_bonus_gold()
		GameManager.add_gold(bonus)
		combo_ended.emit(current_combo, bonus)
		_show_combo_end(bonus)
	
	current_combo = 0
	combo_timer = 0.0
	_hide_combo_ui()


func _show_combo_ui() -> void:
	# Create or update combo display
	var hud = get_node_or_null("/root/Main/HUD")
	if not hud:
		return
	
	if not combo_label:
		# Create combo UI elements
		combo_panel = PanelContainer.new()
		combo_panel.name = "ComboPanel"
		combo_panel.position = Vector2(20, 150)
		combo_panel.z_index = 50
		
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.1, 0.1, 0.15, 0.9)
		stylebox.set_corner_radius_all(8)
		stylebox.set_content_margin_all(10)
		combo_panel.add_theme_stylebox_override("panel", stylebox)
		
		combo_label = Label.new()
		combo_label.name = "ComboLabel"
		combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		combo_panel.add_child(combo_label)
		
		hud.add_child(combo_panel)
	
	# Update combo text
	combo_label.text = "🔥 x%d COMBO!" % current_combo
	
	# Scale based on combo size
	var font_size = 16 + min(current_combo, 10)
	combo_label.add_theme_font_size_override("font_size", font_size)
	
	# Color based on combo tier
	var color = Color.WHITE
	if current_combo >= 15:
		color = Color(1.0, 0.6, 0.2)  # Orange/gold
		combo_label.text = "🔥 x%d MEGA COMBO! 🔥" % current_combo
	elif current_combo >= 10:
		color = Color(1.0, 0.8, 0.3)  # Yellow
		combo_label.text = "🔥 x%d SUPER COMBO!" % current_combo
	elif current_combo >= 5:
		color = Color(0.4, 1.0, 0.5)  # Green
	
	combo_label.add_theme_color_override("font_color", color)
	
	# Pop animation
	if combo_panel:
		combo_panel.scale = Vector2(1.2, 1.2)
		var tween = combo_panel.create_tween()
		tween.tween_property(combo_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func _hide_combo_ui() -> void:
	if combo_panel:
		var tween = combo_panel.create_tween()
		tween.tween_property(combo_panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func():
			combo_panel.queue_free()
			combo_panel = null
			combo_label = null
		)


func _show_combo_end(bonus_gold: int) -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if not hud:
		return
	
	# Create "COMBO ENDED" message
	var end_label = Label.new()
	end_label.text = "COMBO ENDED!\n+%d 💰 BONUS!" % bonus_gold
	end_label.add_theme_font_size_override("font_size", 24)
	end_label.add_theme_color_override("font_color", Color.GOLD)
	end_label.add_theme_color_override("font_outline_color", Color.BLACK)
	end_label.add_theme_constant_override("outline_size", 3)
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Get viewport size correctly (CanvasLayer doesn't have get_viewport_rect)
	var viewport_size = get_viewport().get_visible_rect().size
	end_label.position = Vector2(viewport_size.x / 2 - 100, 200)
	hud.add_child(end_label)
	
	# Animate
	end_label.scale = Vector2.ZERO
	var tween = hud.create_tween()
	tween.tween_property(end_label, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(end_label, "scale", Vector2.ONE, 0.1)
	tween.tween_interval(1.5)
	tween.tween_property(end_label, "position:y", end_label.position.y - 50, 0.3)
	tween.parallel().tween_property(end_label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(end_label.queue_free)


## Reset combo (call at wave start)
func reset_combo() -> void:
	current_combo = 0
	combo_timer = 0.0
	_hide_combo_ui()
