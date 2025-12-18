extends Node2D

## Arena - Main combat scene controller

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal crystal_damaged(damage: int, remaining_health: int)
signal enemy_spawned(enemy: Node2D)
signal statue_placed(statue: Node2D, grid_pos: Vector2i)

# References
@onready var enemy_path: Path2D = $EnemyPath
@onready var placement_grid: Node2D = $PlacementGrid
@onready var statues_container: Node2D = $Statues
@onready var enemies_container: Node2D = $Enemies
@onready var projectiles_container: Node2D = $Projectiles
@onready var crystal: Node2D = $Crystal
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var wave_manager: Node = $WaveManager
@onready var ui_layer: CanvasLayer = $UI

# Arena settings
const GRID_SIZE = Vector2(64, 64)
const GRID_COLS = 16
const GRID_ROWS = 10
const GRID_OFFSET = Vector2(64, 60)

# State
var grid_cells: Array[Array] = []  # 2D array: true = occupied
var active_enemies: Array[Node] = []
var wave_in_progress: bool = false
var spawning_in_progress: bool = false  # Track if spawn sequence is still running

# Preloaded scenes
var statue_scene: PackedScene = preload("res://scenes/entities/statue.tscn")
var enemy_scene: PackedScene = preload("res://scenes/entities/enemy.tscn")


func _ready() -> void:
	_setup_grid()
	_setup_crystal()
	print("[Arena] Ready - Grid: %dx%d" % [GRID_COLS, GRID_ROWS])


func _setup_grid() -> void:
	# Initialize grid array
	grid_cells.clear()
	for x in range(GRID_COLS):
		var column: Array = []
		for y in range(GRID_ROWS):
			column.append(false)  # false = empty, true = occupied
		grid_cells.append(column)
	
	# Create visual grid indicators
	for x in range(GRID_COLS):
		for y in range(GRID_ROWS):
			var cell = ColorRect.new()
			cell.name = "Cell_%d_%d" % [x, y]
			cell.size = GRID_SIZE - Vector2(4, 4)
			cell.position = grid_to_world(Vector2i(x, y)) - GRID_SIZE / 2 + Vector2(2, 2)
			cell.color = Color(0.2, 0.3, 0.2, 0.3)
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			placement_grid.add_child(cell)


func _setup_crystal() -> void:
	# Create crystal visual
	var crystal_shape = CircleShape2D.new()
	crystal_shape.radius = 40
	$Crystal/CrystalArea/CrystalCollision.shape = crystal_shape
	
	# Simple crystal visual (placeholder)
	var crystal_visual = $Crystal/CrystalSprite
	crystal_visual.texture = _create_placeholder_texture(Color(0.3, 0.6, 1.0, 0.8), 32)


## Grid helpers
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return GRID_OFFSET + Vector2(grid_pos) * GRID_SIZE + GRID_SIZE / 2


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local_pos = world_pos - GRID_OFFSET
	return Vector2i(int(local_pos.x / GRID_SIZE.x), int(local_pos.y / GRID_SIZE.y))


func is_cell_valid(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_COLS and grid_pos.y >= 0 and grid_pos.y < GRID_ROWS


func is_cell_empty(grid_pos: Vector2i) -> bool:
	if not is_cell_valid(grid_pos):
		return false
	return not grid_cells[grid_pos.x][grid_pos.y]


func occupy_cell(grid_pos: Vector2i) -> void:
	if is_cell_valid(grid_pos):
		grid_cells[grid_pos.x][grid_pos.y] = true
		# Update cell visual
		var cell = placement_grid.get_node_or_null("Cell_%d_%d" % [grid_pos.x, grid_pos.y])
		if cell:
			cell.color = Color(0.5, 0.3, 0.2, 0.5)


func free_cell(grid_pos: Vector2i) -> void:
	if is_cell_valid(grid_pos):
		grid_cells[grid_pos.x][grid_pos.y] = false
		var cell = placement_grid.get_node_or_null("Cell_%d_%d" % [grid_pos.x, grid_pos.y])
		if cell:
			cell.color = Color(0.2, 0.3, 0.2, 0.3)


## Statue placement with JUICE!
func place_statue(statue_data: Resource, grid_pos: Vector2i, tier: int = 0) -> Node2D:
	# Check statue limit first
	if not GameManager.can_place_statue():
		print("[Arena] Cannot place statue - limit reached (%d/%d)" % [GameManager.placed_statues.size(), GameManager.get_max_statues()])
		return null
	
	if not is_cell_empty(grid_pos):
		print("[Arena] Cannot place statue - cell occupied at %s" % str(grid_pos))
		return null
	
	var statue = statue_scene.instantiate()
	statue.position = grid_to_world(grid_pos)
	statue.grid_position = grid_pos
	statue.arena = self
	
	# IMPORTANT: Add to tree BEFORE setup so @onready vars are ready
	statues_container.add_child(statue)
	statue.setup(statue_data, tier)
	
	occupy_cell(grid_pos)
	
	# JUICE: Different celebration for evolution vs normal placement
	if tier > 0:
		_evolution_materialization(statue, grid_pos, tier)
	else:
		_placement_celebration(statue, grid_pos)
	
	GameManager.register_statue(statue)
	statue_placed.emit(statue, grid_pos)
	print("[Arena] Placed %s at %s" % [statue_data.display_name, str(grid_pos)])
	
	return statue


## JUICE: Statue placement celebration effect
func _placement_celebration(statue: Node2D, grid_pos: Vector2i) -> void:
	var world_pos = grid_to_world(grid_pos)
	
	# Get statue sprite for animation
	var sprite = statue.get_node_or_null("Sprite")
	if sprite:
		# Start small and scale up (materialization effect)
		var target_scale = sprite.scale
		sprite.scale = Vector2.ZERO
		sprite.modulate = Color(1.5, 1.5, 2.0, 0.5)  # Ghost blue glow
		
		var materialize_tween = create_tween()
		materialize_tween.tween_property(sprite, "scale", target_scale * 1.2, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		materialize_tween.parallel().tween_property(sprite, "modulate", Color(1.2, 1.2, 1.0, 1.0), 0.2)
		materialize_tween.tween_property(sprite, "scale", target_scale, 0.1).set_ease(Tween.EASE_IN_OUT)
		materialize_tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# Ground impact shockwave
	var impact_color = Color(0.4, 0.8, 0.4, 0.8)  # Green placement color
	EffectsManager.create_shockwave(self, world_pos, impact_color, 60.0, 0.25)
	
	# Sparkle particles
	for i in range(8):
		var sparkle = Node2D.new()
		sparkle.position = world_pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		sparkle.z_index = 10
		add_child(sparkle)
		
		var sparkle_drawer = _SparkleParticle.new()
		sparkle_drawer.particle_color = Color(0.8, 1.0, 0.8)
		sparkle.add_child(sparkle_drawer)
		
		var direction = Vector2(randf_range(-50, 50), randf_range(-80, -30))
		var sparkle_tween = create_tween()
		sparkle_tween.tween_property(sparkle, "position", sparkle.position + direction, 0.4).set_ease(Tween.EASE_OUT)
		sparkle_tween.parallel().tween_property(sparkle_drawer, "alpha", 0.0, 0.4)
		sparkle_tween.tween_callback(sparkle.queue_free)
	
	# Flash the grid cell
	var cell = placement_grid.get_node_or_null("Cell_%d_%d" % [grid_pos.x, grid_pos.y])
	if cell:
		var original_color = cell.color
		var flash_tween = create_tween()
		flash_tween.tween_property(cell, "color", Color(0.5, 1.0, 0.5, 0.8), 0.1)
		flash_tween.tween_property(cell, "color", original_color, 0.2)


## JUICE: SPECTACULAR evolution materialization effect for evolved statues!
func _evolution_materialization(statue: Node2D, grid_pos: Vector2i, tier: int) -> void:
	var world_pos = grid_to_world(grid_pos)
	
	# Get statue sprite for animation
	var sprite = statue.get_node_or_null("Sprite")
	if not sprite:
		return
	
	# Get tier color for effects
	var tier_color = EvolutionManager.get_tier_color(tier)
	var tier_name = EvolutionManager.get_tier_name(tier)
	
	# START: Statue appears with divine glow
	sprite.scale = Vector2.ZERO
	sprite.modulate = tier_color * 2.0  # Bright divine glow
	
	# 1. Materialization with dramatic scale-up and glow
	var appear_tween = create_tween()
	appear_tween.set_parallel(true)
	
	# Scale from 0 with overshoot (divine arrival)
	appear_tween.tween_property(sprite, "scale", sprite.scale * 1.3, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Glow intensifies then normalizes
	appear_tween.tween_property(sprite, "modulate", Color.WHITE, 0.4)
	
	# 2. Divine glow ring expands outward
	var glow_ring = Node2D.new()
	glow_ring.position = world_pos
	glow_ring.z_index = 10
	add_child(glow_ring)
	
	var glow_drawer = _EvolutionGlowRing.new()
	glow_drawer.color = tier_color
	glow_ring.add_child(glow_drawer)
	
	var ring_tween = create_tween()
	ring_tween.tween_property(glow_drawer, "radius", 80.0, 0.5).set_ease(Tween.EASE_OUT)
	ring_tween.parallel().tween_property(glow_drawer, "alpha", 0.0, 0.5)
	ring_tween.tween_callback(glow_ring.queue_free)
	
	# 3. Tier stars appear one by one above statue
	_animate_tier_stars(world_pos, tier, tier_color)
	
	# 4. Particle burst (more intense than normal placement)
	for i in range(20):
		var particle = Node2D.new()
		particle.position = world_pos
		particle.z_index = 12
		add_child(particle)
		
		var particle_drawer = _SparkleParticle.new()
		particle_drawer.particle_color = tier_color
		particle.add_child(particle_drawer)
		
		var angle = (i / 20.0) * TAU
		var direction = Vector2(cos(angle), sin(angle)) * randf_range(60, 100)
		var particle_tween = create_tween()
		particle_tween.tween_property(particle, "position", world_pos + direction, 0.6).set_ease(Tween.EASE_OUT)
		particle_tween.parallel().tween_property(particle_drawer, "alpha", 0.0, 0.6)
		particle_tween.tween_callback(particle.queue_free)
	
	# 5. Shockwave effect
	EffectsManager.create_shockwave(self, world_pos, tier_color, 100.0, 0.4)
	
	# 6. Evolution announcement text
	await get_tree().create_timer(0.15).timeout
	_show_evolution_text(world_pos, tier_name, tier_color)
	
	# 7. Final bounce to normal scale
	await appear_tween.finished
	var bounce_tween = create_tween()
	bounce_tween.tween_property(sprite, "scale", sprite.scale / 1.3, 0.15).set_ease(Tween.EASE_IN_OUT)


## Animate tier stars appearing one by one
func _animate_tier_stars(pos: Vector2, tier: int, color: Color) -> void:
	var stars_to_show = tier + 1  # Tier 0 = 1 star, Tier 1 = 2 stars, etc
	
	for i in range(stars_to_show):
		await get_tree().create_timer(0.12 * i).timeout
		
		# Create star
		var star = Node2D.new()
		star.position = pos + Vector2(-20 + i * 15, -80)
		star.z_index = 15
		add_child(star)
		
		var star_drawer = _TierStar.new()
		star_drawer.color = color
		star.add_child(star_drawer)
		
		# Pop in animation
		star.scale = Vector2.ZERO
		var star_tween = create_tween()
		star_tween.tween_property(star, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT)
		star_tween.tween_property(star, "scale", Vector2.ONE, 0.08)
		star_tween.tween_interval(1.0)
		star_tween.tween_property(star_drawer, "alpha", 0.0, 0.3)
		star_tween.tween_callback(star.queue_free)


## Show evolution text announcement
func _show_evolution_text(pos: Vector2, tier_name: String, color: Color) -> void:
	var label = Label.new()
	label.text = "%s EVOLVED!" % tier_name.to_upper()
	label.position = pos + Vector2(-80, -100)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.z_index = 20
	add_child(label)
	
	# Animate text
	label.scale = Vector2.ZERO
	label.modulate.a = 0.0
	var text_tween = create_tween()
	text_tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
	text_tween.parallel().tween_property(label, "modulate:a", 1.0, 0.15)
	text_tween.tween_property(label, "scale", Vector2.ONE, 0.1)
	text_tween.tween_interval(1.5)
	text_tween.tween_property(label, "position:y", label.position.y - 30, 0.3)
	text_tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3)
	text_tween.tween_callback(label.queue_free)


## Evolution glow ring effect
class _EvolutionGlowRing extends Node2D:
	var radius: float = 10.0
	var alpha: float = 0.8
	var color: Color = Color.WHITE
	
	func _process(_delta: float) -> void:
		queue_redraw()
	
	func _draw() -> void:
		var ring_color = color
		ring_color.a = alpha
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, ring_color, 4.0)
		# Inner glow
		var inner_color = color
		inner_color.a = alpha * 0.3
		draw_circle(Vector2.ZERO, radius * 0.8, inner_color)


## Tier star visual
class _TierStar extends Node2D:
	var color: Color = Color(1.0, 0.8, 0.2)
	var alpha: float = 1.0
	
	func _process(_delta: float) -> void:
		queue_redraw()
	
	func _draw() -> void:
		var star_color = color
		star_color.a = alpha
		var size = 8.0
		
		# 5-pointed star
		var points = PackedVector2Array()
		for i in range(10):
			var angle = (i / 10.0) * TAU - PI / 2
			var r = size if i % 2 == 0 else size * 0.4
			points.append(Vector2(cos(angle) * r, sin(angle) * r))
		
		draw_colored_polygon(points, star_color)
		# Inner bright core
		draw_circle(Vector2.ZERO, size * 0.2, Color.WHITE)




## Simple sparkle particle for placement effect
class _SparkleParticle extends Node2D:
	var particle_color: Color = Color.WHITE
	var alpha: float = 1.0
	
	func _process(_delta: float) -> void:
		queue_redraw()
	
	func _draw() -> void:
		var color = particle_color
		color.a = alpha
		# Star shape
		var size = 4.0 * alpha
		draw_line(Vector2(-size, 0), Vector2(size, 0), color, 2.0)
		draw_line(Vector2(0, -size), Vector2(0, size), color, 2.0)
		draw_line(Vector2(-size * 0.7, -size * 0.7), Vector2(size * 0.7, size * 0.7), color, 1.5)
		draw_line(Vector2(-size * 0.7, size * 0.7), Vector2(size * 0.7, -size * 0.7), color, 1.5)


func remove_statue(statue: Node2D) -> void:
	if statue and statue.is_inside_tree():
		free_cell(statue.grid_position)
		GameManager.unregister_statue(statue)
		statue.queue_free()


## Enemy spawning (with optional elite modifier)
func spawn_enemy(enemy_data: Resource, force_elite: int = -1) -> Node2D:
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_point.position
	enemy.path = enemy_path
	enemy.arena = self
	
	# IMPORTANT: Add to tree BEFORE setup so @onready vars are ready
	enemies_container.add_child(enemy)
	enemy.setup(enemy_data, GameManager.current_wave)
	
	# Apply elite modifier if specified or roll for random elite
	var elite_mod = force_elite
	if elite_mod == -1:
		elite_mod = _roll_elite_modifier(enemy_data)
	
	if elite_mod > 0:
		enemy.apply_elite(elite_mod)
	
	active_enemies.append(enemy)
	
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.reached_crystal.connect(_on_enemy_reached_crystal.bind(enemy))
	
	enemy_spawned.emit(enemy)
	return enemy


## Roll for elite modifier based on wave number
func _roll_elite_modifier(enemy_data: Resource) -> int:
	# Bosses don't become elites
	if enemy_data and enemy_data.is_boss:
		return 0
	
	var wave = GameManager.current_wave
	var elite_chance = 0.0
	
	# Elite spawn chances based on wave
	if wave >= 12:
		elite_chance = 0.30  # 30% at wave 12+
	elif wave >= 8:
		elite_chance = 0.15  # 15% at wave 8+
	
	if randf() < elite_chance:
		# Random elite type (1-5 for the 5 modifier types)
		return randi_range(1, 5)
	
	return 0


func _on_enemy_died(actual_gold: int, enemy: Node) -> void:
	var enemy_pos = enemy.position if enemy else Vector2.ZERO
	active_enemies.erase(enemy)
	
	# Notify HUD for gold animation and kill counter (actual_gold includes multipliers)
	var hud = get_node_or_null("/root/Main/HUD")
	if hud and hud.has_method("on_enemy_killed"):
		hud.on_enemy_killed(actual_gold, enemy_pos)
	
	_check_wave_complete()


func _on_enemy_reached_crystal(damage: int, enemy: Node) -> void:
	GameManager.crystal_health -= damage
	crystal_damaged.emit(damage, GameManager.crystal_health)
	active_enemies.erase(enemy)
	enemy.queue_free()
	_check_wave_complete()
	
	# Visual feedback
	_flash_crystal()


func _flash_crystal() -> void:
	var tween = create_tween()
	tween.tween_property($Crystal/CrystalSprite, "modulate", Color.RED, 0.1)
	tween.tween_property($Crystal/CrystalSprite, "modulate", Color(0.4, 0.8, 1, 1), 0.2)


func _check_wave_complete() -> void:
	# Wave only completes when spawning is done AND all enemies are dead
	if wave_in_progress and not spawning_in_progress and active_enemies.is_empty():
		wave_in_progress = false
		wave_completed.emit(GameManager.current_wave)
		GameManager.end_wave(true)


## Wave management
func start_wave(wave_data: Resource) -> void:
	wave_in_progress = true
	spawning_in_progress = true  # Mark spawning as in progress
	wave_started.emit(wave_data.wave_number)
	
	# Apply consumable effects at wave start
	_apply_consumable_effects()
	
	# Spawn enemies according to wave data
	var spawn_sequence = wave_data.get_spawn_sequence()
	print("[Arena] Wave %d spawn sequence: %d enemies" % [wave_data.wave_number, spawn_sequence.size()])
	for spawn_info in spawn_sequence:
		print("[Arena] Queue spawn: %s at t=%.1f" % [spawn_info.enemy_id, spawn_info.spawn_time])
	
	# Track last spawn time for proper timing
	var last_spawn_time = 0.0
	for spawn_info in spawn_sequence:
		var wait_time = spawn_info.spawn_time - last_spawn_time
		if wait_time > 0:
			await get_tree().create_timer(wait_time).timeout
		last_spawn_time = spawn_info.spawn_time
		
		# Don't break on wave_in_progress = false, we still need to spawn all enemies
		# Only break if game is completely over (crystal destroyed)
		if GameManager.current_state == GameManager.GameState.GAME_OVER:
			break
		
		var enemy_resource = _load_enemy_resource(spawn_info.enemy_id)
		if enemy_resource:
			spawn_enemy(enemy_resource)
		else:
			print("[Arena] Failed to load enemy: %s" % spawn_info.enemy_id)
	
	# All enemies spawned - mark spawning complete
	spawning_in_progress = false
	print("[Arena] Wave %d spawning complete" % wave_data.wave_number)
	
	# Check if wave is already complete (all enemies died during spawn sequence)
	_check_wave_complete()


## Apply consumable effects when wave starts
func _apply_consumable_effects() -> void:
	# Stone Walls: temporary crystal health boost
	var hp_boost = GameManager.get_crystal_health_boost()
	if hp_boost > 0:
		var bonus_hp = int(GameManager.crystal_max_health * hp_boost)
		GameManager.crystal_health += bonus_hp
		print("[Arena] Stone Walls active! +%d crystal HP" % bonus_hp)
	
	# Battle Horn: abilities start ready
	if GameManager.has_abilities_ready_consumable():
		for statue in GameManager.placed_statues:
			if statue and is_instance_valid(statue) and statue.has_method("make_ability_ready"):
				statue.make_ability_ready()
		print("[Arena] Battle Horn active! All abilities ready!")


func _load_enemy_resource(enemy_id: String) -> Resource:
	var path = "res://resources/enemies/%s.tres" % enemy_id
	if ResourceLoader.exists(path):
		return load(path)
	print("[Arena] Enemy resource not found: %s" % path)
	return null


## Get all enemies in range of a position
func get_enemies_in_range(pos: Vector2, attack_range: float) -> Array[Node]:
	var result: Array[Node] = []
	for enemy in active_enemies:
		if enemy and is_instance_valid(enemy):
			var dist = pos.distance_to(enemy.position)
			if dist <= attack_range:
				result.append(enemy)
	return result


## Get nearest enemy to position
func get_nearest_enemy(pos: Vector2, attack_range: float = 9999.0) -> Node:
	var nearest: Node = null
	var nearest_dist = attack_range
	
	for enemy in active_enemies:
		if enemy and is_instance_valid(enemy):
			var dist = pos.distance_to(enemy.position)
			if dist < nearest_dist:
				nearest = enemy
				nearest_dist = dist
	
	return nearest


## Placeholder texture generator
func _create_placeholder_texture(color: Color, size: int) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


## Input handling for placement
func _input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.SHOP:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var grid_pos = world_to_grid(get_global_mouse_position())
		if is_cell_empty(grid_pos):
			# This will be handled by shop UI when selecting a statue to place
			print("[Arena] Valid placement position: %s" % str(grid_pos))
