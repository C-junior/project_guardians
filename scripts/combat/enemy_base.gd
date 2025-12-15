extends CharacterBody2D

## Enemy Base Script
## Handles path following, health, status effects, and special abilities

signal died(gold_reward: int)
signal reached_crystal(damage: int)
signal took_damage(amount: float, remaining: float)

# Data
var enemy_data: Resource
var wave_number: int = 1

# Pathing
var path: Path2D
var path_follow: PathFollow2D
var path_progress: float = 0.0
var arena: Node2D

# Stats (scaled by wave)
var max_health: float
var current_health: float
var move_speed: float
var damage_to_crystal: int
var gold_reward: int

# Status effects
var is_stunned: bool = false
var stun_timer: float = 0.0
var is_slowed: bool = false
var slow_amount: float = 0.0
var slow_timer: float = 0.0
var is_frozen: bool = false
var freeze_timer: float = 0.0

# Special abilities
var can_summon: bool = false
var can_teleport: bool = false
var has_shield: bool = false

# References
@onready var sprite: Sprite2D = $Sprite
@onready var shadow: Sprite2D = $Shadow
@onready var health_bar: ProgressBar = $HealthBar
@onready var stun_icon: Sprite2D = $StatusEffects/StunIcon
@onready var slow_icon: Sprite2D = $StatusEffects/SlowIcon
@onready var freeze_icon: Sprite2D = $StatusEffects/FreezeIcon
@onready var summon_timer: Timer = $SummonTimer
@onready var teleport_timer: Timer = $TeleportTimer


func _ready() -> void:
	summon_timer.timeout.connect(_on_summon_timer)
	teleport_timer.timeout.connect(_on_teleport_timer)


func setup(data: Resource, wave: int) -> void:
	enemy_data = data
	wave_number = wave
	
	# Calculate scaled stats
	max_health = data.get_scaled_health(wave)
	current_health = max_health
	move_speed = data.get_scaled_speed(wave)
	damage_to_crystal = data.damage_to_crystal
	gold_reward = data.get_scaled_gold(wave)
	
	# Set up visuals (with null safety)
	if data.sprite_texture:
		if sprite:
			sprite.texture = data.sprite_texture
		if shadow:
			shadow.texture = data.sprite_texture
	
	if sprite:
		sprite.scale = Vector2.ONE * data.scale_factor * 0.4
		sprite.modulate = data.tint_color
	
	# Set up hitbox
	var hitbox_collision = get_node_or_null("Hitbox/CollisionShape")
	if hitbox_collision:
		var shape = CircleShape2D.new()
		shape.radius = 20 * data.scale_factor
		hitbox_collision.shape = shape
	
	# Set up special abilities
	can_summon = data.can_summon
	can_teleport = data.can_teleport
	has_shield = data.has_shield
	
	if can_summon and summon_timer:
		summon_timer.wait_time = data.summon_cooldown
		summon_timer.start()
	
	if can_teleport and teleport_timer:
		teleport_timer.wait_time = data.teleport_cooldown
		teleport_timer.start()
	
	# Create path follow
	if path:
		path_follow = PathFollow2D.new()
		path_follow.loop = false
		path_follow.rotates = false
		path.add_child(path_follow)
	
	_update_health_bar()
	
	print("[Enemy] %s spawned - HP: %.0f, SPD: %.0f, Gold: %d" % [
		data.display_name, max_health, move_speed, gold_reward
	])


func _physics_process(delta: float) -> void:
	# Update status timers
	_update_status_effects(delta)
	
	# Don't move if frozen or stunned
	if is_frozen or is_stunned:
		return
	
	# Calculate actual speed
	var actual_speed = move_speed
	if is_slowed:
		actual_speed *= (1.0 - slow_amount)
	
	# Apply consumable slow (Slow Time)
	var consumable_slow = GameManager.get_enemy_slow_from_consumables()
	if consumable_slow > 0:
		actual_speed *= (1.0 - consumable_slow)
	
	# Move along path
	if path_follow:
		path_follow.progress += actual_speed * delta
		path_progress = path_follow.progress_ratio
		position = path_follow.global_position
		
		# Check if reached end
		if path_follow.progress_ratio >= 1.0:
			_reach_crystal()



func _update_status_effects(delta: float) -> void:
	# Stun
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			stun_icon.visible = false
	
	# Slow
	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			is_slowed = false
			slow_amount = 0.0
			slow_icon.visible = false
	
	# Freeze
	if is_frozen:
		freeze_timer -= delta
		sprite.modulate = Color(0.5, 0.8, 1.0, 1.0)
		if freeze_timer <= 0:
			is_frozen = false
			sprite.modulate = enemy_data.tint_color if enemy_data else Color.WHITE
			freeze_icon.visible = false


## Take damage
func take_damage(amount: float, source: Node = null) -> void:
	var final_damage = amount
	
	# Frontal shield check
	if has_shield and source:
		var direction = (source.position - position).normalized()
		var facing = Vector2.RIGHT  # Enemies face right (toward crystal)
		if direction.dot(facing) > 0.5:
			final_damage *= (1.0 - enemy_data.frontal_armor)
	
	# Frozen enemies take more damage
	if is_frozen:
		final_damage *= 1.25
	
	current_health -= final_damage
	_update_health_bar()
	took_damage.emit(final_damage, current_health)
	
	# JUICE: Hit impact effects
	_hit_impact_effect(final_damage)
	
	# Floating damage number (juiced up!)
	_spawn_damage_number(final_damage)
	
	if current_health <= 0:
		_die()


## JUICE: Hit impact effect (flash + squash)
func _hit_impact_effect(damage: float) -> void:
	# White flash then color
	sprite.modulate = Color.WHITE
	
	# Squash effect (enemy gets "hit")
	var original_scale = sprite.scale
	var squash_scale = original_scale * Vector2(1.2, 0.8)  # Wider and shorter
	
	var hit_tween = create_tween()
	hit_tween.tween_property(sprite, "scale", squash_scale, 0.05)
	hit_tween.tween_property(sprite, "scale", original_scale, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	
	# Color flash
	await get_tree().create_timer(0.05).timeout
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.08).timeout
	
	# Restore color based on status
	if is_frozen:
		sprite.modulate = Color(0.5, 0.8, 1.0, 1.0)
	elif enemy_data:
		sprite.modulate = enemy_data.tint_color
	else:
		sprite.modulate = Color.WHITE


## JUICE: Enhanced damage numbers with scaling and colors
func _spawn_damage_number(damage: float) -> void:
	# Create floating damage text with JUICE!
	var label = Label.new()
	label.text = str(int(damage))
	
	# Random X offset so numbers don't stack
	var x_offset = randf_range(-25, 25)
	label.position = Vector2(x_offset, -50)
	
	# Scale font size based on damage (bigger damage = bigger number)
	var base_size = 16
	var size_bonus = min(damage / 50.0, 1.5)  # Max 1.5x bigger for big hits
	var font_size = int(base_size * (1.0 + size_bonus))
	label.add_theme_font_size_override("font_size", font_size)
	
	# Color based on damage type
	var damage_color = Color.WHITE
	if damage >= max_health * 0.3:  # Big hit = orange
		damage_color = Color(1.0, 0.6, 0.2)
	elif damage >= max_health * 0.15:  # Medium hit = yellow
		damage_color = Color(1.0, 0.9, 0.3)
	else:  # Normal hit = white
		damage_color = Color(1.0, 1.0, 1.0)
	
	label.add_theme_color_override("font_color", damage_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	add_child(label)
	
	# JUICE: Pop-in animation (scale up then normalize)
	label.scale = Vector2(0.5, 0.5)
	label.pivot_offset = label.size / 2
	
	var tween = create_tween()
	# Pop in
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)
	# Float up and fade
	tween.parallel().tween_property(label, "position:y", label.position.y - 40, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(label.queue_free)


func _update_health_bar() -> void:
	health_bar.value = (current_health / max_health) * 100.0
	
	# Color based on health
	if health_bar.value > 60:
		health_bar.modulate = Color.GREEN
	elif health_bar.value > 30:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED


## Get current HP as percentage (0.0 to 1.0) for execute damage calculation
func get_hp_percent() -> float:
	return current_health / max_health if max_health > 0 else 0.0


## Status effects
func apply_stun(duration: float) -> void:
	is_stunned = true
	stun_timer = duration
	stun_icon.visible = true
	
	# Stun visual
	sprite.modulate = Color.YELLOW


func apply_slow(amount: float, duration: float) -> void:
	is_slowed = true
	slow_amount = max(slow_amount, amount)  # Take stronger slow
	slow_timer = max(slow_timer, duration)
	slow_icon.visible = true


func apply_freeze(duration: float) -> void:
	is_frozen = true
	freeze_timer = duration
	freeze_icon.visible = true


## Special abilities
func _on_summon_timer() -> void:
	if can_summon and arena and enemy_data:
		for i in range(enemy_data.summon_count):
			var minion_data = load("res://resources/enemies/%s.tres" % enemy_data.summon_enemy_id)
			if minion_data:
				var minion = arena.spawn_enemy(minion_data)
				if minion and path_follow:
					minion.path_follow.progress = path_follow.progress * 0.9  # Spawn slightly behind
		print("[Enemy] %s summoned %d minions" % [enemy_data.display_name, enemy_data.summon_count])


func _on_teleport_timer() -> void:
	if can_teleport and path_follow:
		# Teleport forward
		path_follow.progress += enemy_data.teleport_distance
		position = path_follow.global_position
		
		# Teleport visual
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1)


## Death with JUICE! 🎉
func _die() -> void:
	# Calculate base gold (with Soul Gem bonus)
	var base_gold = gold_reward + GameManager.get_gold_per_kill()
	
	# Calculate actual gold with multipliers (Golden Crown, Gold Fever)
	var gold_multiplier = GameManager.get_gold_multiplier()
	var actual_gold = int(base_gold * gold_multiplier)
	
	# Add gold to player (this applies the multiplier again, so pass base)
	GameManager.add_gold(base_gold)
	
	# JUICE: Death celebration effects!
	_death_celebration()
	
	# Spawn gold popup (show actual earned amount)
	_spawn_gold_popup(actual_gold)
	
	# Split on death
	if enemy_data.splits_on_death and arena:
		for i in range(enemy_data.split_count):
			var split_data = load("res://resources/enemies/%s.tres" % enemy_data.split_enemy_id)
			if split_data:
				var split = arena.spawn_enemy(split_data)
				if split and path_follow:
					split.path_follow.progress = path_follow.progress
				split.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	died.emit(actual_gold)
	
	# Clean up path follow
	if path_follow:
		path_follow.queue_free()
	
	queue_free()


## JUICE: Death celebration with particles and effects
func _death_celebration() -> void:
	# Determine effect intensity based on enemy type
	var is_elite = enemy_data.scale_factor >= 1.5 if enemy_data else false
	var is_boss = enemy_data.is_boss if enemy_data and enemy_data.get("is_boss") else false
	
	# Get enemy color for effects
	var effect_color = enemy_data.tint_color if enemy_data else Color.WHITE
	
	# Death particles (impact burst)
	if arena:
		var particle_count = 8 if not is_elite else 12
		EffectsManager.create_impact(arena, global_position, effect_color, particle_count)
	
	# Screen shake (subtle for normal, stronger for elite/boss)
	var shake_intensity = 3.0
	var shake_duration = 0.08
	if is_elite:
		shake_intensity = 6.0
		shake_duration = 0.12
	if is_boss:
		shake_intensity = 10.0
		shake_duration = 0.2
	
	_screen_shake(shake_duration, shake_intensity)
	
	# Death scale pop (enemy briefly expands then disappears)
	var death_tween = create_tween()
	death_tween.tween_property(sprite, "scale", sprite.scale * 1.3, 0.05)
	death_tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.1)


## Screen shake utility for death effects
func _screen_shake(duration: float = 0.1, intensity: float = 3.0) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_offset = camera.offset
		var shake_tween = create_tween()
		var shake_count = int(duration * 30)  # ~30 fps worth of shakes
		for i in range(shake_count):
			var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			shake_tween.tween_property(camera, "offset", original_offset + offset, duration / shake_count)
		shake_tween.tween_property(camera, "offset", original_offset, 0.03)


func _spawn_gold_popup(amount: int = -1) -> void:
	var show_gold = amount if amount > 0 else gold_reward
	var label = Label.new()
	label.text = "+%d" % show_gold
	label.position = Vector2(-15, -60)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.GOLD)
	add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", label.position.y - 40, 0.7)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)


## Reach crystal
func _reach_crystal() -> void:
	reached_crystal.emit(damage_to_crystal)
	
	if path_follow:
		path_follow.queue_free()
