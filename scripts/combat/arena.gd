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


## Statue placement
func place_statue(statue_data: Resource, grid_pos: Vector2i, tier: int = 0) -> Node2D:
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
	
	GameManager.register_statue(statue)
	statue_placed.emit(statue, grid_pos)
	print("[Arena] Placed %s at %s" % [statue_data.display_name, str(grid_pos)])
	
	return statue


func remove_statue(statue: Node2D) -> void:
	if statue and statue.is_inside_tree():
		free_cell(statue.grid_position)
		GameManager.unregister_statue(statue)
		statue.queue_free()


## Enemy spawning
func spawn_enemy(enemy_data: Resource) -> Node2D:
	var enemy = enemy_scene.instantiate()
	enemy.position = spawn_point.position
	enemy.path = enemy_path
	enemy.arena = self
	
	# IMPORTANT: Add to tree BEFORE setup so @onready vars are ready
	enemies_container.add_child(enemy)
	enemy.setup(enemy_data, GameManager.current_wave)
	
	active_enemies.append(enemy)
	
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.reached_crystal.connect(_on_enemy_reached_crystal.bind(enemy))
	
	enemy_spawned.emit(enemy)
	return enemy


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
	if wave_in_progress and active_enemies.is_empty():
		wave_in_progress = false
		wave_completed.emit(GameManager.current_wave)
		GameManager.end_wave(true)


## Wave management
func start_wave(wave_data: Resource) -> void:
	wave_in_progress = true
	wave_started.emit(wave_data.wave_number)
	
	# Apply consumable effects at wave start
	_apply_consumable_effects()
	
	# Spawn enemies according to wave data
	var spawn_sequence = wave_data.get_spawn_sequence()
	for spawn_info in spawn_sequence:
		await get_tree().create_timer(spawn_info.spawn_time).timeout
		if not wave_in_progress:
			break
		
		var enemy_resource = _load_enemy_resource(spawn_info.enemy_id)
		if enemy_resource:
			spawn_enemy(enemy_resource)


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
