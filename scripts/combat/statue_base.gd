extends CharacterBody2D

## Statue (Tower) Base Script
## Handles attack, targeting, abilities, and visual updates

signal ability_used(ability_name: String)
signal died()
signal attacked(target: Node, damage: float)

# Data
var statue_data: Resource
var evolution_tier: int = 0

# Position
var grid_position: Vector2i
var arena: Node2D

# Stats (calculated from data + tier)
var damage: float
var attack_speed: float
var attack_range: float
var max_health: float
var current_health: float
var ability_cooldown: float

# State
var current_target: Node = null
var ability_ready: bool = false
var is_attacking: bool = false
var in_blade_storm: bool = false  # For Shadow Dancer ability
var applied_upgrades: Array = []   # Track applied upgrades

# Modifiers from artifacts
var damage_modifier: float = 1.0
var attack_speed_modifier: float = 1.0
var cooldown_modifier: float = 1.0
var range_modifier: float = 0.0

# References
@onready var sprite: Sprite2D = $Sprite
@onready var tier_glow: Sprite2D = $TierGlow
@onready var range_indicator: Sprite2D = $RangeIndicator
@onready var attack_timer: Timer = $AttackTimer
@onready var ability_timer: Timer = $AbilityTimer
@onready var health_bar: ProgressBar = $HealthBar
@onready var ability_ready_indicator: Sprite2D = $AbilityReady
@onready var attack_range_area: Area2D = $AttackRange


func _ready() -> void:
	attack_timer.timeout.connect(_on_attack_timer)
	ability_timer.timeout.connect(_on_ability_ready)
	
	# Hide range indicator by default
	if range_indicator:
		range_indicator.visible = false


func setup(data: Resource, tier: int = 0) -> void:
	statue_data = data
	evolution_tier = tier
	
	# Calculate stats from data and tier
	var stats = data.get_stats_for_tier(tier)
	damage = stats.damage
	attack_speed = stats.attack_speed
	attack_range = stats.range
	max_health = stats.health
	ability_cooldown = stats.cooldown
	current_health = max_health
	
	# Apply GameManager modifiers
	_apply_global_modifiers()
	
	# Set up visuals (with null safety)
	if data.portrait_texture and sprite:
		sprite.texture = data.portrait_texture
	
	# Set up attack range collision
	var attack_collision = get_node_or_null("AttackRange/CollisionShape")
	if attack_collision:
		var shape = CircleShape2D.new()
		shape.radius = attack_range + range_modifier
		attack_collision.shape = shape
	
	# Set up range indicator visual
	if range_indicator:
		_setup_range_indicator()
	
	# Set up tier glow
	if tier_glow:
		_setup_tier_glow()
	
	# Set up attack timer
	if attack_timer:
		var actual_speed = attack_speed * attack_speed_modifier
		attack_timer.wait_time = 1.0 / actual_speed
		attack_timer.start()
	
	# Start ability cooldown
	_start_ability_cooldown()
	
	# Update health bar
	_update_health_bar()
	
	print("[Statue] %s (Tier %d) placed - DMG: %.1f, SPD: %.2f, RNG: %.0f" % [
		data.display_name, tier, damage * damage_modifier, attack_speed * attack_speed_modifier, attack_range + range_modifier
	])


func _apply_global_modifiers() -> void:
	damage_modifier = GameManager.get_damage_multiplier()
	attack_speed_modifier = GameManager.get_attack_speed_multiplier()
	cooldown_modifier = GameManager.get_cooldown_multiplier()
	range_modifier = GameManager.get_range_bonus()


## Refresh modifiers from artifacts (called when new artifacts are acquired)
## This allows already-placed statues to benefit from newly purchased artifacts
func refresh_global_modifiers() -> void:
	_apply_global_modifiers()
	
	# Update attack timer with new speed modifier
	if attack_timer:
		var actual_speed = attack_speed * attack_speed_modifier
		attack_timer.wait_time = 1.0 / actual_speed
	
	# Update ability cooldown with new modifier (if ability is on cooldown)
	if ability_timer and ability_timer.time_left > 0:
		var remaining_percent = ability_timer.time_left / ability_timer.wait_time
		ability_timer.wait_time = ability_cooldown * cooldown_modifier
		ability_timer.start(ability_timer.wait_time * remaining_percent)
	
	# Update range collision
	var attack_collision = get_node_or_null("AttackRange/CollisionShape")
	if attack_collision and attack_collision.shape:
		attack_collision.shape.radius = attack_range + range_modifier
	
	# Update range indicator visual
	if range_indicator:
		_setup_range_indicator()
	
	print("[Statue] %s modifiers refreshed - DMG: %.0f%%, SPD: %.0f%%, CD: %.0f%%, RNG: +%.0f" % [
		statue_data.display_name if statue_data else "Unknown",
		(damage_modifier - 1.0) * 100,
		(attack_speed_modifier - 1.0) * 100,
		(1.0 - cooldown_modifier) * 100,
		range_modifier
	])


func _setup_range_indicator() -> void:
	# Create circular range indicator texture
	var size = int((attack_range + range_modifier) * 2)
	if size < 10:
		size = 10  # Minimum size to avoid issues
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2, size / 2)
	var radius = size / 2.0
	
	# Use statue's effect color if available, otherwise default green
	var base_color = Color(0.3, 0.8, 0.3)
	if statue_data and statue_data.get("effect_color"):
		base_color = statue_data.effect_color
	
	var border_width = 4.0  # Thicker border for visibility
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x, y).distance_to(center)
			if dist <= radius and dist >= radius - border_width:
				# Ring border - more visible
				image.set_pixel(x, y, Color(base_color.r, base_color.g, base_color.b, 0.7))
			elif dist <= radius:
				# Fill - subtle but visible
				image.set_pixel(x, y, Color(base_color.r, base_color.g, base_color.b, 0.15))
	
	range_indicator.texture = ImageTexture.create_from_image(image)


func _setup_tier_glow() -> void:
	if evolution_tier > 0:
		tier_glow.visible = true
		var colors = [
			Color.WHITE,           # Base (not shown)
			Color(0.4, 0.8, 0.4),  # Enhanced - green
			Color(0.4, 0.4, 1.0),  # Awakened - blue
			Color(1.0, 0.8, 0.2)   # Divine - gold
		]
		tier_glow.modulate = colors[evolution_tier]
		tier_glow.texture = sprite.texture


var _was_mouse_over: bool = false

func _process(delta: float) -> void:
	# Apply health regeneration from artifacts (like Healing Spring)
	var regen_rate = GameManager.get_statue_health_regen()
	if regen_rate > 0 and current_health < max_health:
		current_health = min(current_health + (max_health * regen_rate * delta), max_health)
		_update_health_bar()
	
	# Mouse hover detection (reliable fallback using position polling)
	var mouse_pos = get_global_mouse_position()
	var distance = global_position.distance_to(mouse_pos)
	var hover_radius = 50.0  # Radius for hover detection
	var is_mouse_over = distance < hover_radius
	
	if is_mouse_over and not _was_mouse_over:
		# Mouse just entered
		_on_mouse_entered()
	elif not is_mouse_over and _was_mouse_over:
		# Mouse just exited
		_on_mouse_exited()
	
	_was_mouse_over = is_mouse_over
	
	# Find target if none
	if current_target == null or not is_instance_valid(current_target):
		current_target = _find_target()
	
	# Rotate to face target
	if current_target and is_instance_valid(current_target):
		var direction = (current_target.position - position).normalized()
		sprite.flip_h = direction.x < 0


func _on_attack_timer() -> void:
	if current_target and is_instance_valid(current_target):
		_attack(current_target)


func _find_target() -> Node:
	if not arena:
		return null
	
	var enemies_in_range = arena.get_enemies_in_range(position, attack_range + range_modifier)
	if enemies_in_range.is_empty():
		return null
	
	# Filter by targeting restrictions
	var valid_enemies: Array[Node] = []
	for enemy in enemies_in_range:
		if not enemy or not is_instance_valid(enemy):
			continue
		var flying = enemy.enemy_data.is_flying if enemy.enemy_data else false
		if flying and not statue_data.can_attack_flying:
			continue
		if not flying and not statue_data.can_attack_ground:
			continue
		valid_enemies.append(enemy)
	
	if valid_enemies.is_empty():
		return null
	
	# Apply target priority
	match statue_data.target_priority:
		0:  # Nearest
			return _get_nearest(valid_enemies)
		1:  # Strongest (most health)
			return _get_strongest(valid_enemies)
		2:  # Weakest (least health)
			return _get_weakest(valid_enemies)
		3:  # First (furthest along path)
			return _get_first(valid_enemies)
		4:  # Last (earliest on path)
			return _get_last(valid_enemies)
	
	return valid_enemies[0]


func _get_nearest(enemies: Array[Node]) -> Node:
	var nearest: Node = null
	var min_dist = 99999.0
	for enemy in enemies:
		var dist = position.distance_to(enemy.position)
		if dist < min_dist:
			min_dist = dist
			nearest = enemy
	return nearest


func _get_strongest(enemies: Array[Node]) -> Node:
	var strongest: Node = null
	var max_health = 0.0
	for enemy in enemies:
		if enemy.current_health > max_health:
			max_health = enemy.current_health
			strongest = enemy
	return strongest


func _get_weakest(enemies: Array[Node]) -> Node:
	var weakest: Node = null
	var min_health = 99999.0
	for enemy in enemies:
		if enemy.current_health < min_health:
			min_health = enemy.current_health
			weakest = enemy
	return weakest


func _get_first(enemies: Array[Node]) -> Node:
	var first: Node = null
	var max_progress = 0.0
	for enemy in enemies:
		if enemy.path_progress > max_progress:
			max_progress = enemy.path_progress
			first = enemy
	return first


func _get_last(enemies: Array[Node]) -> Node:
	var last: Node = null
	var min_progress = 99999.0
	for enemy in enemies:
		if enemy.path_progress < min_progress:
			min_progress = enemy.path_progress
			last = enemy
	return last


func _attack(target: Node) -> void:
	if not target or not is_instance_valid(target):
		return
	
	var final_damage = damage * damage_modifier
	var is_crit = false
	
	# JUICE: Critical hit system
	var crit_chance = 0.08  # Base 8% crit chance
	var crit_multiplier = 1.75  # 175% damage on crit
	
	# Check for crit (blade storm has higher crit chance)
	if in_blade_storm:
		crit_chance = 0.5  # 50% crit during blade storm
	
	if randf() < crit_chance:
		is_crit = true
		final_damage *= crit_multiplier
	
	# Execute damage bonus (from Executioner's Stone)
	if target.has_method("get_hp_percent"):
		var hp_percent = target.get_hp_percent()
		var execute_mult = GameManager.get_execute_damage_mult(hp_percent)
		if execute_mult > 1.0:
			final_damage *= execute_mult
	
	# Get effect color from statue data
	var effect_color = statue_data.effect_color if statue_data.get("effect_color") else Color.WHITE
	
	if statue_data.is_melee:
		# Melee: instant damage with impact effect
		target.take_damage(final_damage, self)
		# Melee impact effect
		if arena:
			EffectsManager.create_impact(arena, target.position, effect_color, 6)
	else:
		# Ranged: spawn visual projectile with trail
		_spawn_projectile(target, final_damage, is_crit)
		# Muzzle flash effect
		if arena:
			EffectsManager.create_muzzle_flash(arena, position, effect_color)
	
	# JUICE: Critical hit visual feedback
	if is_crit and arena:
		_show_crit_effect(target)
	
	attacked.emit(target, final_damage)
	
	# Animation feedback - attack pulse (bigger for crits)
	var pulse_scale = 0.6 if is_crit else 0.55
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(pulse_scale, pulse_scale), 0.05)
	tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 0.1)
	# Color flash on attack (orange for crit)
	var flash_color = Color(1.0, 0.6, 0.2) if is_crit else effect_color
	tween.parallel().tween_property(sprite, "modulate", flash_color, 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)


## JUICE: Show critical hit effect
func _show_crit_effect(target: Node) -> void:
	# Create "CRIT!" text
	var crit_label = Label.new()
	crit_label.text = "CRIT!"
	crit_label.add_theme_font_size_override("font_size", 24)
	crit_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))  # Orange
	crit_label.add_theme_color_override("font_outline_color", Color.BLACK)
	crit_label.add_theme_constant_override("outline_size", 4)
	crit_label.position = target.position - Vector2(25, 80)
	crit_label.z_index = 100
	arena.add_child(crit_label)
	
	# Pop animation
	crit_label.scale = Vector2.ZERO
	var tween = arena.create_tween()
	tween.tween_property(crit_label, "scale", Vector2(1.3, 1.3), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(crit_label, "scale", Vector2.ONE, 0.1)
	tween.tween_property(crit_label, "position:y", crit_label.position.y - 30, 0.4)
	tween.parallel().tween_property(crit_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(crit_label.queue_free)
	
	# Extra particles for crit
	EffectsManager.create_impact(arena, target.position, Color(1.0, 0.6, 0.2), 10)


func _spawn_projectile(target: Node, projectile_damage: float, is_crit: bool = false) -> void:
	# Visual projectile with trail effect
	if not target or not is_instance_valid(target):
		return
	
	# Use orange for crits, else normal effect color
	var effect_color = Color(1.0, 0.6, 0.2) if is_crit else (statue_data.effect_color if statue_data.get("effect_color") else Color.WHITE)
	
	if arena:
		# Create visual projectile that moves and deals damage on hit
		EffectsManager.create_projectile_trail(
			arena,
			position,
			target,
			effect_color,
			statue_data.projectile_speed,
			projectile_damage,
			self
		)
	else:
		# Fallback: simple projectile
		var distance = position.distance_to(target.position)
		var travel_time = distance / statue_data.projectile_speed
		await get_tree().create_timer(travel_time).timeout
		if target and is_instance_valid(target):
			target.take_damage(projectile_damage, self)


## Ability system
func _start_ability_cooldown() -> void:
	ability_ready = false
	ability_ready_indicator.visible = false
	ability_timer.wait_time = ability_cooldown * cooldown_modifier
	ability_timer.start()


func _on_ability_ready() -> void:
	ability_ready = true
	ability_ready_indicator.visible = true
	
	# Pulse animation
	var tween = create_tween().set_loops()
	tween.tween_property(ability_ready_indicator, "modulate:a", 1.0, 0.5)
	tween.tween_property(ability_ready_indicator, "modulate:a", 0.5, 0.5)


## Force ability to be ready (used by Battle Horn consumable)
func make_ability_ready() -> void:
	ability_timer.stop()
	_on_ability_ready()


## Apply an upgrade to this statue
func apply_upgrade(upgrade: Resource) -> void:
	if not upgrade:
		return
	
	# Add to tracking
	applied_upgrades.append(upgrade)
	
	# Apply all effects
	if upgrade.get("damage_multiplier") and upgrade.damage_multiplier > 0:
		damage_modifier += upgrade.damage_multiplier
		print("[Statue] %s damage +%.0f%%" % [statue_data.display_name, upgrade.damage_multiplier * 100])
	
	if upgrade.get("attack_speed_multiplier") and upgrade.attack_speed_multiplier > 0:
		attack_speed_modifier += upgrade.attack_speed_multiplier
		# Update attack timer
		if attack_timer:
			attack_timer.wait_time = 1.0 / (attack_speed * attack_speed_modifier)
		print("[Statue] %s attack speed +%.0f%%" % [statue_data.display_name, upgrade.attack_speed_multiplier * 100])
	
	if upgrade.get("range_bonus") and upgrade.range_bonus > 0:
		range_modifier += upgrade.range_bonus
		# Update attack range collision
		var attack_collision = get_node_or_null("AttackRange/CollisionShape")
		if attack_collision and attack_collision.shape:
			attack_collision.shape.radius = attack_range + range_modifier
		if range_indicator:
			_setup_range_indicator()
		print("[Statue] %s range +%.0f" % [statue_data.display_name, upgrade.range_bonus])
	
	if upgrade.get("cooldown_reduction") and upgrade.cooldown_reduction > 0:
		cooldown_modifier -= upgrade.cooldown_reduction
		cooldown_modifier = max(0.1, cooldown_modifier)
		print("[Statue] %s cooldown -%.0f%%" % [statue_data.display_name, upgrade.cooldown_reduction * 100])
	
	# Visual feedback - flash gold
	_flash_upgrade_effect()


## Get applied upgrades (for ascension return)
func get_applied_upgrades() -> Array:
	return applied_upgrades.duplicate()


func _flash_upgrade_effect() -> void:
	var original_modulate = modulate
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.GOLD, 0.2)
	tween.tween_property(self, "modulate", original_modulate, 0.3)


func use_ability() -> void:
	if not ability_ready:
		return
	
	ability_ready = false
	ability_ready_indicator.visible = false
	
	# JUICE: Ability activation effects!
	_ability_activation_juice()
	
	# Get base statue ID (strip _awaken suffix for awakened statues)
	var base_id = statue_data.id
	if base_id.ends_with("_awaken"):
		base_id = base_id.substr(0, base_id.length() - 7)  # Remove "_awaken"
	
	# Execute ability based on statue type (using base ID)
	match base_id:
		"sentinel":
			_ability_shield_bash()
		"arcane_weaver":
			_ability_chain_lightning()
		"huntress":
			_ability_piercing_arrow()
		"divine_guardian":
			_ability_radiant_smite()
		"earthshaker":
			_ability_ground_slam()
		"shadow_dancer":
			_ability_blade_storm()
		"frost_maiden":
			_ability_frozen_prison()
		_:
			print("[Statue] WARNING: Unknown ability for statue ID: %s (base: %s)" % [statue_data.id, base_id])
	
	ability_used.emit(statue_data.ability_name)
	_start_ability_cooldown()


## JUICE: Ability activation effects
func _ability_activation_juice() -> void:
	# Brief time slowdown for "hitstop" feel (100ms at 0.3x speed)
	Engine.time_scale = 0.3
	await get_tree().create_timer(0.03).timeout  # 0.03 real seconds = 0.1 game seconds feel
	Engine.time_scale = GameManager.game_speed  # Restore to current game speed
	
	# Get ability color (use statue's effect color)
	var ability_color = statue_data.effect_color if statue_data and statue_data.get("effect_color") else Color(1.0, 0.9, 0.4)
	
	# Statue power-up glow effect
	var original_modulate = sprite.modulate
	var glow_tween = create_tween()
	glow_tween.tween_property(sprite, "modulate", ability_color * 2.0, 0.1)  # Bright flash
	glow_tween.tween_property(sprite, "modulate", original_modulate, 0.2)
	
	# Scale up briefly (power surge feel)
	var original_scale = sprite.scale
	var scale_tween = create_tween()
	scale_tween.tween_property(sprite, "scale", original_scale * 1.3, 0.1).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(sprite, "scale", original_scale, 0.15).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
	
	# Screen shake
	_screen_shake(0.12, 5.0)


## Specific abilities
func _ability_shield_bash() -> void:
	# Stun enemies in cone
	var enemies = arena.get_enemies_in_range(position, attack_range + 50)
	for enemy in enemies:
		if enemy.has_method("apply_stun"):
			enemy.apply_stun(2.0)
	
	# Visual effect: Yellow shockwave ring
	if arena:
		EffectsManager.create_shockwave(arena, position, Color(1.0, 0.9, 0.3), attack_range + 50, 0.4)
	
	# Screen shake effect
	_screen_shake(0.15, 5.0)
	
	print("[Ability] Shield Bash - Stunned %d enemies" % enemies.size())


func _ability_chain_lightning() -> void:
	if not current_target or not is_instance_valid(current_target):
		return
	
	var hit_enemies: Array[Node] = [current_target]
	var chain_damage = damage * damage_modifier * 1.5
	
	current_target.take_damage(chain_damage, self)
	
	# Visual: Lightning bolt to first target
	var lightning_color = Color(0.4, 0.7, 1.0)
	if arena:
		EffectsManager.create_lightning(arena, position, current_target.position, lightning_color)
	
	# Chain to 3 more enemies
	for i in range(3):
		var last_hit = hit_enemies[-1]
		var nearby = arena.get_enemies_in_range(last_hit.position, 100)
		for enemy in nearby:
			if enemy not in hit_enemies:
				enemy.take_damage(chain_damage, self)
				# Visual: chain lightning between enemies
				if arena:
					EffectsManager.create_lightning(arena, last_hit.position, enemy.position, lightning_color)
				hit_enemies.append(enemy)
				break
	
	print("[Ability] Chain Lightning - Hit %d enemies" % hit_enemies.size())


func _ability_piercing_arrow() -> void:
	if not current_target:
		return
	
	var direction = (current_target.position - position).normalized()
	var pierce_damage = damage * damage_modifier * 2.0
	
	# Visual: Golden arrow trail
	var arrow_color = Color(1.0, 0.9, 0.4)
	if arena:
		EffectsManager.create_arrow_trail(arena, position, direction, arrow_color, 400.0)
	
	# Hit all enemies in a line
	for enemy in arena.active_enemies:
		if not enemy or not is_instance_valid(enemy):
			continue
		# Check if enemy is roughly in the line direction
		var to_enemy = (enemy.position - position).normalized()
		if direction.dot(to_enemy) > 0.9:
			enemy.take_damage(pierce_damage, self)
			# Impact effect on each hit enemy
			if arena:
				EffectsManager.create_impact(arena, enemy.position, arrow_color, 4)
	
	print("[Ability] Piercing Arrow fired")


func _ability_radiant_smite() -> void:
	# Deal bonus damage to undead/demons
	var smite_damage = damage * damage_modifier * 3.0
	var enemies = arena.get_enemies_in_range(position, attack_range + 50)
	
	# Visual: Holy burst explosion
	if arena:
		EffectsManager.create_holy_burst(arena, position)
		EffectsManager.create_shockwave(arena, position, Color(1.0, 1.0, 0.7), attack_range + 50, 0.3)
	
	for enemy in enemies:
		var bonus = 1.0
		if enemy.enemy_data and (enemy.enemy_data.is_undead or enemy.enemy_data.is_demon):
			bonus = 2.0
		enemy.take_damage(smite_damage * bonus, self)
	
	# Heal nearby statues
	for statue in GameManager.placed_statues:
		if statue == self:
			continue
		if position.distance_to(statue.position) <= 150:
			statue.heal(statue.max_health * 0.2)
			# Visual: healing particles on healed statues
			if arena:
				EffectsManager.create_heal_particles(arena, statue.position)
	
	print("[Ability] Radiant Smite - Hit %d enemies" % enemies.size())


func _ability_ground_slam() -> void:
	var slam_damage = damage * damage_modifier * 2.5
	var enemies = arena.get_enemies_in_range(position, attack_range + 30)
	
	# Visual: Brown/gray shockwave + screen shake
	if arena:
		EffectsManager.create_shockwave(arena, position, Color(0.6, 0.4, 0.2), attack_range + 30, 0.5)
		EffectsManager.create_impact(arena, position, Color(0.5, 0.4, 0.3), 12)
	_screen_shake(0.3, 8.0)
	
	for enemy in enemies:
		enemy.take_damage(slam_damage, self)
		if enemy.has_method("apply_slow"):
			enemy.apply_slow(0.5, 4.0)
	
	print("[Ability] Ground Slam - Hit %d enemies" % enemies.size())


func _ability_blade_storm() -> void:
	in_blade_storm = true
	attack_timer.wait_time /= 3.0  # Triple attack speed
	
	# Visual: Purple spinning aura around statue
	var aura: Node2D = null
	if arena:
		aura = EffectsManager.create_spinning_aura(self, Color(0.6, 0.2, 0.8), 5.0)
	
	# Visual feedback: purple glow during blade storm
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.8, 0.5, 1.0), 0.3)
	
	await get_tree().create_timer(5.0).timeout
	
	in_blade_storm = false
	var actual_speed = attack_speed * attack_speed_modifier
	attack_timer.wait_time = 1.0 / actual_speed
	
	# Restore normal color
	var end_tween = create_tween()
	end_tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)
	
	print("[Ability] Blade Storm ended")


func _ability_frozen_prison() -> void:
	var enemies = arena.get_enemies_in_range(position, attack_range)
	
	# Visual: Ice shockwave
	if arena:
		EffectsManager.create_shockwave(arena, position, Color(0.6, 0.9, 1.0), attack_range, 0.4)
	
	for enemy in enemies:
		if enemy.has_method("apply_freeze"):
			enemy.apply_freeze(4.0)
			# Visual: Ice crystals on frozen enemies
			if arena:
				EffectsManager.create_ice_crystals(arena, enemy.position, 4)
	
	print("[Ability] Frozen Prison - Froze %d enemies" % enemies.size())


## Screen shake utility
func _screen_shake(duration: float = 0.2, intensity: float = 5.0) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera:
		var original_offset = camera.offset
		var shake_tween = create_tween()
		for i in range(int(duration * 20)):
			var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			shake_tween.tween_property(camera, "offset", original_offset + offset, 0.05)
		shake_tween.tween_property(camera, "offset", original_offset, 0.05)


## Health and damage
func take_damage(amount: float) -> void:
	current_health -= amount
	_update_health_bar()
	
	# Damage flash
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE
	
	if current_health <= 0:
		_die()


func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	_update_health_bar()
	
	# Heal flash
	sprite.modulate = Color.GREEN
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE


func _update_health_bar() -> void:
	health_bar.value = (current_health / max_health) * 100


func _die() -> void:
	_hide_stats_tooltip()  # Clean up tooltip
	died.emit()
	arena.free_cell(grid_position)
	GameManager.unregister_statue(self)
	queue_free()


## UI interactions
func show_range() -> void:
	print("[Statue] show_range called - range_indicator exists: %s" % (range_indicator != null))
	if range_indicator:
		print("[Statue] range_indicator texture: %s" % (range_indicator.texture != null))
		if range_indicator.texture:
			print("[Statue] texture size: %s" % range_indicator.texture.get_size())
		print("[Statue] range_indicator z_index: %d, position: %s" % [range_indicator.z_index, range_indicator.position])
		print("[Statue] statue position: %s, attack_range: %s" % [global_position, attack_range])
		range_indicator.visible = true


func hide_range() -> void:
	print("[Statue] hide_range called")
	if range_indicator:
		range_indicator.visible = false


## Mouse hover handlers for range visualization
func _on_mouse_entered() -> void:
	print("[Statue] Mouse ENTERED on: %s" % (statue_data.display_name if statue_data else "unknown"))
	show_range()
	_show_stats_tooltip()


func _on_mouse_exited() -> void:
	print("[Statue] Mouse EXITED from: %s" % (statue_data.display_name if statue_data else "unknown"))
	hide_range()
	_hide_stats_tooltip()


var stats_tooltip: Control = null


func _show_stats_tooltip() -> void:
	if stats_tooltip:
		return  # Already showing
	
	if not statue_data:
		return
	
	# Create tooltip panel
	stats_tooltip = PanelContainer.new()
	stats_tooltip.z_index = 100
	stats_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.set_border_width_all(2)
	style.border_color = EvolutionManager.get_tier_color(evolution_tier)
	style.set_corner_radius_all(8)
	stats_tooltip.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_tooltip.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(vbox)
	
	# Name with tier stars
	var stars = ""
	for i in range(evolution_tier + 1):
		stars += "★"
	var title = Label.new()
	title.text = "%s %s (%s)" % [stars, statue_data.display_name, EvolutionManager.get_tier_name(evolution_tier)]
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", EvolutionManager.get_tier_color(evolution_tier))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)
	
	# Stats line (with modifiers applied)
	var final_damage = damage * damage_modifier
	var final_speed = attack_speed * attack_speed_modifier
	var final_range = attack_range + range_modifier
	
	var stats_label = Label.new()
	stats_label.text = "⚔️ DMG: %.0f  |  ⚡ SPD: %.2f  |  📏 RNG: %.0f" % [final_damage, final_speed, final_range]
	stats_label.add_theme_font_size_override("font_size", 11)
	stats_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stats_label)
	
	# Ability
	if statue_data.ability_name:
		var ability_label = Label.new()
		var cd_remaining = ability_timer.time_left if ability_timer else 0.0
		if ability_ready:
			ability_label.text = "🔥 %s (READY!)" % statue_data.ability_name
			ability_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		else:
			ability_label.text = "🔥 %s (%.1fs)" % [statue_data.ability_name, cd_remaining]
			ability_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
		ability_label.add_theme_font_size_override("font_size", 11)
		ability_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(ability_label)
	
	# Show upgrades if any
	if applied_upgrades.size() > 0:
		var upgrades_label = Label.new()
		var upgrade_names = []
		for upg in applied_upgrades:
			if upg.get("display_name"):
				upgrade_names.append(upg.display_name)
		upgrades_label.text = "⬆️ Upgrades: %s" % ", ".join(upgrade_names)
		upgrades_label.add_theme_font_size_override("font_size", 10)
		upgrades_label.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
		upgrades_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(upgrades_label)
	
	# Show modifiers if any are active
	var mod_texts = []
	if damage_modifier > 1.0:
		mod_texts.append("+%.0f%% DMG" % ((damage_modifier - 1.0) * 100))
	if attack_speed_modifier > 1.0:
		mod_texts.append("+%.0f%% SPD" % ((attack_speed_modifier - 1.0) * 100))
	if range_modifier > 0:
		mod_texts.append("+%.0f RNG" % range_modifier)
	if cooldown_modifier < 1.0:
		mod_texts.append("-%.0f%% CD" % ((1.0 - cooldown_modifier) * 100))
	
	if mod_texts.size() > 0:
		var mod_label = Label.new()
		mod_label.text = "📊 Bonuses: %s" % ", ".join(mod_texts)
		mod_label.add_theme_font_size_override("font_size", 10)
		mod_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
		mod_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(mod_label)
	
	# Add to scene
	get_tree().root.add_child(stats_tooltip)
	
	# Position above the statue
	stats_tooltip.position = get_viewport().get_canvas_transform() * (global_position - Vector2(100, 150))


func _hide_stats_tooltip() -> void:
	if stats_tooltip:
		stats_tooltip.queue_free()
		stats_tooltip = null


## Input event handler for mouse area (fallback for mouse detection)
func _on_mouse_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseMotion:
		# Mouse is over this area - show range
		if not range_indicator.visible:
			print("[Statue] Input event detected on: %s" % (statue_data.display_name if statue_data else "unknown"))
			show_range()


## Click to select for evolution
func _input(event: InputEvent) -> void:
	if not EvolutionManager.is_evolving:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Check if click is on this statue
		var mouse_pos = get_global_mouse_position()
		var distance = position.distance_to(mouse_pos)
		if distance < 40:  # Click radius
			EvolutionManager.select_statue(self)


## Handle right-click to cancel evolution
func _unhandled_input(event: InputEvent) -> void:
	if EvolutionManager.is_evolving and event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			EvolutionManager.cancel_evolution()
