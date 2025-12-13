extends Node

## Effects Manager - Creates visual effects for combat
## Centralized system for spawning particles, shockwaves, trails, etc.

class_name EffectsManager

# Singleton instance
static var instance: EffectsManager

# Effect colors by style
const STYLE_COLORS = {
	0: { "primary": Color(1.0, 1.0, 1.0), "secondary": Color(0.8, 0.8, 0.8) },  # Normal
	1: { "primary": Color(1.0, 0.4, 0.1), "secondary": Color(1.0, 0.8, 0.2) },  # Fire
	2: { "primary": Color(0.3, 0.7, 1.0), "secondary": Color(0.6, 0.9, 1.0) },  # Ice  
	3: { "primary": Color(0.6, 0.2, 0.8), "secondary": Color(0.3, 0.1, 0.4) },  # Shadow
}

# Tier colors for glow effects
const TIER_COLORS = [
	Color(0.8, 0.8, 0.8),      # Base - gray/white
	Color(0.4, 0.9, 0.4),      # Enhanced - green
	Color(0.4, 0.6, 1.0),      # Awakened - blue
	Color(1.0, 0.85, 0.3),     # Divine - gold
]


func _ready() -> void:
	instance = self


## Create a shockwave ring effect (for Shield Bash, Ground Slam)
static func create_shockwave(parent: Node2D, pos: Vector2, color: Color, max_radius: float = 100.0, duration: float = 0.4) -> void:
	var shockwave = Node2D.new()
	shockwave.position = pos
	parent.add_child(shockwave)
	
	# Create the ring using draw
	var ring = _ShockwaveRing.new()
	ring.ring_color = color
	ring.max_radius = max_radius
	ring.duration = duration
	shockwave.add_child(ring)
	
	# Auto-cleanup
	var timer = parent.get_tree().create_timer(duration + 0.1)
	timer.timeout.connect(shockwave.queue_free)


## Create lightning bolt effect between two points
static func create_lightning(parent: Node2D, start_pos: Vector2, end_pos: Vector2, color: Color = Color(0.4, 0.7, 1.0), segments: int = 8) -> void:
	var lightning = _LightningBolt.new()
	lightning.start_point = start_pos
	lightning.end_point = end_pos
	lightning.bolt_color = color
	lightning.segments = segments
	parent.add_child(lightning)
	
	# Auto-cleanup after animation
	var timer = parent.get_tree().create_timer(0.3)
	timer.timeout.connect(lightning.queue_free)


## Create impact burst effect
static func create_impact(parent: Node2D, pos: Vector2, color: Color, particle_count: int = 8) -> void:
	for i in range(particle_count):
		var particle = _ImpactParticle.new()
		particle.position = pos
		particle.particle_color = color
		particle.direction = Vector2.from_angle(TAU * i / particle_count)
		parent.add_child(particle)


## Create muzzle flash effect
static func create_muzzle_flash(parent: Node2D, pos: Vector2, color: Color) -> void:
	var flash = _MuzzleFlash.new()
	flash.position = pos
	flash.flash_color = color
	parent.add_child(flash)


## Create projectile with trail
static func create_projectile_trail(parent: Node2D, start_pos: Vector2, target: Node2D, color: Color, speed: float = 400.0, damage: float = 0.0, source: Node = null) -> void:
	var projectile = _TrailedProjectile.new()
	projectile.position = start_pos
	projectile.target = target
	projectile.trail_color = color
	projectile.move_speed = speed
	projectile.damage = damage
	projectile.source = source
	parent.add_child(projectile)


## Create spinning aura effect (for Blade Storm)
static func create_spinning_aura(parent: Node2D, color: Color, duration: float = 5.0) -> Node2D:
	var aura = _SpinningAura.new()
	aura.aura_color = color
	aura.duration = duration
	parent.add_child(aura)
	return aura


## Create ice crystal effect
static func create_ice_crystals(parent: Node2D, pos: Vector2, count: int = 5) -> void:
	for i in range(count):
		var crystal = _IceCrystal.new()
		crystal.position = pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		parent.add_child(crystal)


## Create holy burst effect
static func create_holy_burst(parent: Node2D, pos: Vector2) -> void:
	var burst = _HolyBurst.new()
	burst.position = pos
	parent.add_child(burst)


## Create healing particles
static func create_heal_particles(parent: Node2D, pos: Vector2, color: Color = Color(0.3, 1.0, 0.5)) -> void:
	for i in range(6):
		var particle = _HealParticle.new()
		particle.position = pos + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		particle.particle_color = color
		parent.add_child(particle)


## Create arrow trail effect
static func create_arrow_trail(parent: Node2D, start_pos: Vector2, direction: Vector2, color: Color = Color(1.0, 0.9, 0.4), length: float = 300.0) -> void:
	var trail = _ArrowTrail.new()
	trail.position = start_pos
	trail.direction = direction
	trail.trail_color = color
	trail.trail_length = length
	parent.add_child(trail)


# ============ INNER CLASSES FOR EFFECTS ============

## Shockwave ring that expands outward
class _ShockwaveRing extends Node2D:
	var ring_color: Color = Color.YELLOW
	var max_radius: float = 100.0
	var duration: float = 0.4
	var current_radius: float = 0.0
	var alpha: float = 1.0
	var time: float = 0.0
	
	func _process(delta: float) -> void:
		time += delta
		var t = time / duration
		current_radius = max_radius * t
		alpha = 1.0 - t
		queue_redraw()
	
	func _draw() -> void:
		var color = ring_color
		color.a = alpha * 0.8
		draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, color, 4.0)
		color.a = alpha * 0.4
		draw_arc(Vector2.ZERO, current_radius * 0.8, 0, TAU, 24, color, 2.0)


## Lightning bolt with jagged segments
class _LightningBolt extends Node2D:
	var start_point: Vector2
	var end_point: Vector2
	var bolt_color: Color = Color(0.4, 0.7, 1.0)
	var segments: int = 8
	var points: PackedVector2Array = []
	var alpha: float = 1.0
	var time: float = 0.0
	
	func _ready() -> void:
		_generate_points()
	
	func _generate_points() -> void:
		points.clear()
		points.append(start_point)
		var direction = (end_point - start_point) / segments
		var perpendicular = direction.orthogonal().normalized()
		
		for i in range(1, segments):
			var base_pos = start_point + direction * i
			var offset = perpendicular * randf_range(-15, 15)
			points.append(base_pos + offset)
		
		points.append(end_point)
	
	func _process(delta: float) -> void:
		time += delta
		alpha = max(0, 1.0 - time * 4.0)
		if time > 0.05:
			_generate_points()  # Flicker effect
		queue_redraw()
	
	func _draw() -> void:
		if points.size() < 2:
			return
		var color = bolt_color
		color.a = alpha
		# Main bolt
		draw_polyline(points, color, 3.0)
		# Glow
		color.a = alpha * 0.5
		draw_polyline(points, color, 6.0)


## Impact particle that flies outward
class _ImpactParticle extends Node2D:
	var particle_color: Color = Color.WHITE
	var direction: Vector2 = Vector2.RIGHT
	var speed: float = 150.0
	var lifetime: float = 0.3
	var time: float = 0.0
	var size: float = 4.0
	
	func _process(delta: float) -> void:
		time += delta
		position += direction * speed * delta
		speed *= 0.95
		
		if time >= lifetime:
			queue_free()
		else:
			queue_redraw()
	
	func _draw() -> void:
		var alpha = 1.0 - (time / lifetime)
		var color = particle_color
		color.a = alpha
		draw_circle(Vector2.ZERO, size * alpha, color)


## Muzzle flash effect
class _MuzzleFlash extends Node2D:
	var flash_color: Color = Color.WHITE
	var time: float = 0.0
	var duration: float = 0.1
	
	func _process(delta: float) -> void:
		time += delta
		if time >= duration:
			queue_free()
		else:
			queue_redraw()
	
	func _draw() -> void:
		var alpha = 1.0 - (time / duration)
		var color = flash_color
		color.a = alpha
		draw_circle(Vector2.ZERO, 15 * alpha, color)
		color.a = alpha * 0.5
		draw_circle(Vector2.ZERO, 25 * alpha, color)


## Projectile with trail
class _TrailedProjectile extends Node2D:
	var target: Node2D
	var trail_color: Color = Color.WHITE
	var move_speed: float = 400.0
	var damage: float = 0.0
	var source: Node = null
	var trail_points: PackedVector2Array = []
	var max_trail_length: int = 10
	
	func _process(delta: float) -> void:
		if not target or not is_instance_valid(target):
			queue_free()
			return
		
		# Move toward target
		var direction = (target.position - position).normalized()
		position += direction * move_speed * delta
		
		# Update trail
		trail_points.insert(0, position)
		if trail_points.size() > max_trail_length:
			trail_points.resize(max_trail_length)
		
		# Check if reached target
		if position.distance_to(target.position) < 10:
			if target.has_method("take_damage"):
				target.take_damage(damage, source)
			# Impact effect
			EffectsManager.create_impact(get_parent(), position, trail_color, 6)
			queue_free()
		else:
			queue_redraw()
	
	func _draw() -> void:
		# Draw trail
		if trail_points.size() >= 2:
			for i in range(trail_points.size() - 1):
				var alpha = 1.0 - (float(i) / trail_points.size())
				var color = trail_color
				color.a = alpha * 0.6
				var width = 3.0 * alpha
				var local_start = trail_points[i] - position
				var local_end = trail_points[i + 1] - position
				draw_line(local_start, local_end, color, width)
		
		# Draw projectile head
		draw_circle(Vector2.ZERO, 5, trail_color)


## Spinning aura effect
class _SpinningAura extends Node2D:
	var aura_color: Color = Color.PURPLE
	var duration: float = 5.0
	var time: float = 0.0
	var rotation_speed: float = 5.0
	var blade_count: int = 4
	var radius: float = 40.0
	
	func _process(delta: float) -> void:
		time += delta
		rotation += rotation_speed * delta
		
		if time >= duration:
			queue_free()
		else:
			queue_redraw()
	
	func _draw() -> void:
		for i in range(blade_count):
			var angle = TAU * i / blade_count
			var pos = Vector2.from_angle(angle) * radius
			var color = aura_color
			color.a = 0.7
			# Draw blade shape
			var points = PackedVector2Array([
				pos + Vector2.from_angle(angle - 0.3) * 15,
				pos + Vector2.from_angle(angle) * 25,
				pos + Vector2.from_angle(angle + 0.3) * 15,
			])
			draw_colored_polygon(points, color)


## Ice crystal effect
class _IceCrystal extends Node2D:
	var time: float = 0.0
	var duration: float = 4.0
	var crystal_size: float
	
	func _ready() -> void:
		crystal_size = randf_range(8, 15)
		rotation = randf() * TAU
	
	func _process(delta: float) -> void:
		time += delta
		if time >= duration:
			queue_free()
		else:
			queue_redraw()
	
	func _draw() -> void:
		var alpha = 1.0 - (time / duration)
		var color = Color(0.6, 0.9, 1.0, alpha * 0.8)
		# Diamond shape
		var points = PackedVector2Array([
			Vector2(0, -crystal_size),
			Vector2(crystal_size * 0.5, 0),
			Vector2(0, crystal_size),
			Vector2(-crystal_size * 0.5, 0),
		])
		draw_colored_polygon(points, color)
		# Outline
		color.a = alpha
		draw_polyline(points, color, 1.5)


## Holy burst effect
class _HolyBurst extends Node2D:
	var time: float = 0.0
	var duration: float = 0.5
	var max_radius: float = 60.0
	var ray_count: int = 8
	
	func _process(delta: float) -> void:
		time += delta
		if time >= duration:
			queue_free()
		else:
			queue_redraw()
	
	func _draw() -> void:
		var t = time / duration
		var alpha = 1.0 - t
		var radius = max_radius * t
		
		# Central glow
		var glow_color = Color(1.0, 1.0, 0.8, alpha * 0.6)
		draw_circle(Vector2.ZERO, radius * 0.5, glow_color)
		
		# Rays
		for i in range(ray_count):
			var angle = TAU * i / ray_count
			var ray_start = Vector2.from_angle(angle) * radius * 0.3
			var ray_end = Vector2.from_angle(angle) * radius
			var ray_color = Color(1.0, 1.0, 0.6, alpha)
			draw_line(ray_start, ray_end, ray_color, 3.0)


## Heal particle that floats upward
class _HealParticle extends Node2D:
	var particle_color: Color = Color(0.3, 1.0, 0.5)
	var time: float = 0.0
	var duration: float = 0.8
	var float_speed: float = 40.0
	
	func _process(delta: float) -> void:
		time += delta
		position.y -= float_speed * delta
		
		if time >= duration:
			queue_free()
		else:
			queue_redraw()
	
	func _draw() -> void:
		var alpha = 1.0 - (time / duration)
		var color = particle_color
		color.a = alpha
		# Plus sign
		draw_line(Vector2(-4, 0), Vector2(4, 0), color, 2)
		draw_line(Vector2(0, -4), Vector2(0, 4), color, 2)


## Arrow trail effect
class _ArrowTrail extends Node2D:
	var direction: Vector2 = Vector2.RIGHT
	var trail_color: Color = Color(1.0, 0.9, 0.4)
	var trail_length: float = 300.0
	var speed: float = 800.0
	var time: float = 0.0
	var travel_distance: float = 0.0
	
	func _process(delta: float) -> void:
		time += delta
		position += direction * speed * delta
		travel_distance += speed * delta
		
		if travel_distance >= trail_length:
			queue_free()
		else:
			queue_redraw()
	
	func _draw() -> void:
		var trail_size = min(travel_distance, 50)
		# Arrow head
		draw_circle(Vector2.ZERO, 4, trail_color)
		# Trail
		var trail_end = -direction * trail_size
		var color = trail_color
		color.a = 0.6
		draw_line(Vector2.ZERO, trail_end, color, 3)
		color.a = 0.3
		draw_line(Vector2.ZERO, trail_end * 0.6, color, 5)
