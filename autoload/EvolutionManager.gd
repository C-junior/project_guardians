extends Node

## EvolutionManager - Handles statue merging and evolution

signal evolution_started(statue1: Node, statue2: Node, result_tier: int)
signal evolution_completed(evolved_statue: Node)
signal evolution_cancelled()

# Evolution state
var is_evolving: bool = false
var selected_statue: Node = null
var potential_merge_target: Node = null

# Visual feedback
var merge_preview_active: bool = false


func _ready() -> void:
	pass



## Get total count of a specific statue type at specific tier (inventory + placed ONLY, shop doesn't count)
func get_total_statue_count(statue_id: String, tier: int = 0) -> Dictionary:
	var result = {"placed": 0, "inventory": 0, "total": 0}
	
	# Count placed statues on the field
	for statue in GameManager.placed_statues:
		if statue.statue_data and statue.statue_data.id == statue_id and statue.evolution_tier == tier:
			result["placed"] += 1
	
	# Count inventory statues (inventory stores base tier statues, usually tier 0)
	var inventory_statues = GameManager.get_inventory_items("statues")
	for entry in inventory_statues:
		var data = entry["data"]
		if data and data.get("id") == statue_id:
			# Each inventory entry could have count > 1
			result["inventory"] += entry["count"]
	
	result["total"] = result["placed"] + result["inventory"]
	return result


## Check if we have enough statues to merge (need 3+ of same type/tier = becomes 1 evolved)
func can_merge_statue_type(statue_id: String, tier: int = 0) -> bool:
	var counts = get_total_statue_count(statue_id, tier)
	return counts["total"] >= 3 and tier < 3  # Can't evolve past Divine (tier 3)


## Check if two statues can be merged (placed statues only)
func can_merge(statue1: Node, statue2: Node) -> bool:
	if not statue1 or not statue2:
		return false
	if statue1 == statue2:
		return false
	if not statue1.statue_data or not statue2.statue_data:
		return false
	
	# Must be same type
	if statue1.statue_data.id != statue2.statue_data.id:
		return false
	
	# Must be same tier
	if statue1.evolution_tier != statue2.evolution_tier:
		return false
	
	# Cannot evolve past Divine (tier 3)
	if statue1.evolution_tier >= 3:
		return false
	
	return true


## Perform the evolution/merge
func evolve_statues(statue1: Node, statue2: Node) -> Node:
	if not can_merge(statue1, statue2):
		print("[Evolution] Cannot merge these statues")
		return null
	
	var new_tier = statue1.evolution_tier + 1
	var statue_data = statue1.statue_data
	var arena = statue1.arena
	var grid_pos = statue1.grid_position
	
	evolution_started.emit(statue1, statue2, new_tier)
	
	# Remove both statues
	arena.free_cell(statue1.grid_position)
	arena.free_cell(statue2.grid_position)
	GameManager.unregister_statue(statue1)
	GameManager.unregister_statue(statue2)
	
	# Create evolution effect
	_play_evolution_effect(statue1.position, statue2.position)
	
	# Wait for effect
	await get_tree().create_timer(0.5).timeout
	
	statue1.queue_free()
	statue2.queue_free()
	
	# Create evolved statue at statue1's position
	var evolved = arena.place_statue(statue_data, grid_pos, new_tier)
	
	if evolved:
		evolution_completed.emit(evolved)
		print("[Evolution] Created %s Tier %d!" % [statue_data.display_name, new_tier])
	
	return evolved


## Perform evolution using statue(s) from inventory and/or field
## This consumes 3 statues of the same type and creates one evolved statue
func evolve_statue_type(statue_id: String, tier: int, arena: Node) -> Node:
	var counts = get_total_statue_count(statue_id, tier)
	
	if counts["total"] < 3:
		print("[Evolution] Not enough statues to evolve (need 3, have %d)" % counts["total"])
		return null
	
	if tier >= 3:
		print("[Evolution] Cannot evolve past Divine tier")
		return null
	
	var new_tier = tier + 1
	var statue_data = _get_statue_data_by_id(statue_id)
	if not statue_data:
		print("[Evolution] Could not find statue data for: " + statue_id)
		return null
	
	var statues_to_consume = 3  # Need 3 to merge into 1
	var consumed = 0
	var placed_to_remove: Array[Node] = []
	var first_placed_position = Vector2i(-1, -1)
	var first_placed_world_pos = Vector2.ZERO
	
	# First, try to consume from inventory
	if counts["inventory"] > 0:
		var can_consume_from_inv = mini(statues_to_consume - consumed, counts["inventory"])
		for i in range(can_consume_from_inv):
			GameManager.remove_from_inventory(statue_data, "statues")
			consumed += 1
	
	# Then consume from placed statues
	if consumed < statues_to_consume:
		for statue in GameManager.placed_statues:
			if consumed >= statues_to_consume:
				break
			if statue.statue_data and statue.statue_data.id == statue_id and statue.evolution_tier == tier:
				placed_to_remove.append(statue)
				if first_placed_position == Vector2i(-1, -1):
					first_placed_position = statue.grid_position
					first_placed_world_pos = statue.position
				consumed += 1
	
	if consumed < statues_to_consume:
		print("[Evolution] Failed to consume enough statues")
		return null
	
	# Remove placed statues
	for statue in placed_to_remove:
		_play_evolution_effect(first_placed_world_pos, statue.position)
		arena.free_cell(statue.grid_position)
		GameManager.unregister_statue(statue)
		statue.queue_free()
	
	# Wait for effect
	await get_tree().create_timer(0.5).timeout
	
	# Determine where to place the evolved statue
	var evolved: Node = null
	if first_placed_position != Vector2i(-1, -1):
		# Place on field at the first removed statue's position
		evolved = arena.place_statue(statue_data, first_placed_position, new_tier)
	else:
		# All were from inventory - add evolved to inventory
		# Since inventory doesn't track tiers, we need special handling
		# For now, add to inventory and let player place it
		GameManager.add_to_inventory(statue_data, "statues")
		print("[Evolution] Evolved %s Tier %d added to inventory!" % [statue_data.display_name, new_tier])
		# Note: Inventory currently doesn't track evolution tier for statues
		# This is a limitation - for full functionality, inventory should track tier
		GameManager.inventory_changed.emit()
		evolution_completed.emit(null)
		return null
	
	if evolved:
		evolution_completed.emit(evolved)
		print("[Evolution] Created %s Tier %d on field!" % [statue_data.display_name, new_tier])
	
	# Ensure inventory UI refreshes to show updated counts
	GameManager.inventory_changed.emit()
	
	return evolved


func _get_statue_data_by_id(statue_id: String) -> Resource:
	var path = "res://resources/statues/%s.tres" % statue_id
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _play_evolution_effect(pos1: Vector2, pos2: Vector2) -> void:
	# Simple visual effect - flash and particles would go here
	# For now, we'll create temporary visual feedback
	pass


## Start statue selection for evolution
func start_evolution_selection() -> void:
	is_evolving = true
	selected_statue = null
	_highlight_evolvable_statues()


## Cancel evolution mode
func cancel_evolution() -> void:
	is_evolving = false
	selected_statue = null
	potential_merge_target = null
	_clear_highlights()
	evolution_cancelled.emit()


## Select a statue for evolution
func select_statue(statue: Node) -> void:
	if not is_evolving:
		return
	
	if selected_statue == null:
		# First selection
		selected_statue = statue
		_highlight_compatible_statues(statue)
	else:
		# Second selection - try to merge
		if can_merge(selected_statue, statue):
			evolve_statues(selected_statue, statue)
			is_evolving = false
			_clear_highlights()
		else:
			# Invalid target - reset selection
			selected_statue = statue
			_highlight_compatible_statues(statue)


## Get list of statue types that can be merged (have 2+ total)
func get_mergeable_statue_types() -> Array:
	var mergeable: Array = []
	var checked_ids: Array = []
	
	# Check placed statues
	for statue in GameManager.placed_statues:
		if not statue.statue_data:
			continue
		var statue_id = statue.statue_data.id
		var tier = statue.evolution_tier
		var key = "%s_%d" % [statue_id, tier]
		if key in checked_ids:
			continue
		checked_ids.append(key)
		
		if can_merge_statue_type(statue_id, tier):
			mergeable.append({
				"id": statue_id,
				"tier": tier,
				"name": statue.statue_data.display_name,
				"counts": get_total_statue_count(statue_id, tier)
			})
	
	# Check inventory statues (always tier 0 in inventory)
	var inventory_statues = GameManager.get_inventory_items("statues")
	for entry in inventory_statues:
		var data = entry["data"]
		if not data:
			continue
		var statue_id = data.get("id")
		if not statue_id:
			continue
		var tier = 0  # Inventory statues are base tier
		var key = "%s_%d" % [statue_id, tier]
		if key in checked_ids:
			continue
		checked_ids.append(key)
		
		if can_merge_statue_type(statue_id, tier):
			var display_name = data.get("display_name")
			if not display_name:
				display_name = statue_id
			mergeable.append({
				"id": statue_id,
				"tier": tier,
				"name": display_name,
				"counts": get_total_statue_count(statue_id, tier)
			})
	
	return mergeable


func _highlight_evolvable_statues() -> void:
	for statue in GameManager.placed_statues:
		# Check if this statue type has enough total (inventory + placed) to merge
		if statue.statue_data:
			var can_evolve = can_merge_statue_type(statue.statue_data.id, statue.evolution_tier)
			if can_evolve:
				statue.modulate = Color(0.5, 1.0, 0.5)  # Green tint
			else:
				statue.modulate = Color(0.5, 0.5, 0.5)  # Gray out
		else:
			statue.modulate = Color(0.5, 0.5, 0.5)  # Gray out


func _highlight_compatible_statues(selected: Node) -> void:
	for statue in GameManager.placed_statues:
		if can_merge(selected, statue):
			statue.modulate = Color(0.5, 1.0, 0.5)  # Green - can merge
		elif statue == selected:
			statue.modulate = Color(0.3, 0.8, 1.0)  # Blue - selected
		else:
			statue.modulate = Color(0.5, 0.5, 0.5)  # Gray out


func _clear_highlights() -> void:
	for statue in GameManager.placed_statues:
		statue.modulate = Color.WHITE


## Get evolution tier name
static func get_tier_name(tier: int) -> String:
	var names = ["Base", "Enhanced", "Awakened", "Divine"]
	return names[clamp(tier, 0, 3)]


## Get evolution tier color
static func get_tier_color(tier: int) -> Color:
	var colors = [
		Color.WHITE,           # Base
		Color(0.4, 0.8, 0.4),  # Enhanced - green
		Color(0.4, 0.6, 1.0),  # Awakened - blue
		Color(1.0, 0.8, 0.2)   # Divine - gold
	]
	return colors[clamp(tier, 0, 3)]
