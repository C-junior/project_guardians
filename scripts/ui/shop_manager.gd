extends CanvasLayer

## ShopManager - Handles preparation phase shop logic and UI

signal item_purchased(item: Resource, item_type: String)
signal shop_closed()

# Shop state
var current_items: Array[Dictionary] = []  # {"resource": Resource, "type": String}
var base_item_count: int = 5

# References
@onready var items_container: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/ItemsContainer
@onready var gold_label: Label = $Control/Panel/MarginContainer/VBoxContainer/Header/GoldLabel
@onready var reroll_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/RerollButton
@onready var start_wave_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/StartWaveButton
@onready var wave_label: Label = $Control/Panel/MarginContainer/VBoxContainer/Header/WaveLabel

# Item card scene
var item_card_scene: PackedScene = preload("res://scenes/ui/shop_item_card.tscn")

# Resource pools
var statue_pool: Array[Resource] = []
var artifact_pool: Array[Resource] = []
var consumable_pool: Array[Resource] = []

# Close button reference
@onready var close_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/CloseButton


func _ready() -> void:
	reroll_button.pressed.connect(_on_reroll_pressed)
	start_wave_button.pressed.connect(_on_start_wave_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	GameManager.gold_changed.connect(_update_gold_display)
	
	_load_item_pools()
	visible = false


func _load_item_pools() -> void:
	# Load all statue resources
	var statue_dir = DirAccess.open("res://resources/statues/")
	if statue_dir:
		statue_dir.list_dir_begin()
		var file_name = statue_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res = load("res://resources/statues/" + file_name)
				if res:
					statue_pool.append(res)
			file_name = statue_dir.get_next()
	
	# Load all artifact resources
	var artifact_dir = DirAccess.open("res://resources/artifacts/")
	if artifact_dir:
		artifact_dir.list_dir_begin()
		var file_name = artifact_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res = load("res://resources/artifacts/" + file_name)
				if res:
					artifact_pool.append(res)
			file_name = artifact_dir.get_next()
	
	# Load all consumable resources
	var consumable_dir = DirAccess.open("res://resources/consumables/")
	if consumable_dir:
		consumable_dir.list_dir_begin()
		var file_name = consumable_dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res = load("res://resources/consumables/" + file_name)
				if res:
					consumable_pool.append(res)
			file_name = consumable_dir.get_next()
	
	print("[Shop] Loaded %d statues, %d artifacts, %d consumables" % [statue_pool.size(), artifact_pool.size(), consumable_pool.size()])


## Open shop for preparation phase
func open_shop() -> void:
	visible = true
	_update_gold_display(GameManager.gold)
	_update_wave_display()
	_update_reroll_button()
	_generate_shop_items()


## Close shop and return to combat
func close_shop() -> void:
	visible = false
	shop_closed.emit()


## Generate random shop items
func _generate_shop_items() -> void:
	# Clear existing items
	for child in items_container.get_children():
		child.queue_free()
	current_items.clear()
	
	var item_count = base_item_count
	# Add extra slots from artifacts
	for artifact in GameManager.active_artifacts:
		var extra = artifact.get("extra_shop_items")
		if extra:
			item_count += extra
	
	# Determine item distribution
	# 50% statues, 30% artifacts, 20% consumables (roughly)
	for i in range(item_count):
		var roll = randf()
		var item_data: Dictionary = {}
		
		if roll < 0.5 and statue_pool.size() > 0:
			# Statue
			var statue = statue_pool[randi() % statue_pool.size()]
			item_data = {"resource": statue, "type": "statue", "cost": statue.get_cost()}
		elif roll < 0.8 and artifact_pool.size() > 0:
			# Artifact
			var artifact = artifact_pool[randi() % artifact_pool.size()]
			# Don't offer already acquired artifacts
			var already_has = false
			for owned in GameManager.active_artifacts:
				if owned.id == artifact.id:
					already_has = true
					break
			if not already_has:
				item_data = {"resource": artifact, "type": "artifact", "cost": artifact.get_cost()}
			else:
				# Fallback to statue
				var statue = statue_pool[randi() % statue_pool.size()]
				item_data = {"resource": statue, "type": "statue", "cost": statue.get_cost()}
		else:
			# Consumable - use actual resource
			if consumable_pool.size() > 0:
				var consumable = consumable_pool[randi() % consumable_pool.size()]
				item_data = {"resource": consumable, "type": "consumable", "cost": consumable.base_cost}
			else:
				# Fallback to statue if no consumables
				var statue = statue_pool[randi() % statue_pool.size()]
				item_data = {"resource": statue, "type": "statue", "cost": statue.get_cost()}
		
		if item_data.size() > 0:
			current_items.append(item_data)
			_create_item_card(item_data)


func _generate_random_consumable() -> Dictionary:
	var consumables = [
		{"name": "Battle Horn", "desc": "Abilities start ready", "cost": 100, "effect": "abilities_ready"},
		{"name": "Gold Fever", "desc": "2x gold this wave", "cost": 150, "effect": "gold_boost"},
		{"name": "Stone Walls", "desc": "+30% crystal HP", "cost": 75, "effect": "crystal_hp"},
		{"name": "Slow Time", "desc": "Enemies 25% slower", "cost": 100, "effect": "slow_enemies"},
	]
	var chosen = consumables[randi() % consumables.size()]
	return {"resource": null, "type": "consumable", "data": chosen, "cost": chosen.cost}


func _create_item_card(item_data: Dictionary) -> void:
	var card = item_card_scene.instantiate()
	# IMPORTANT: Add to tree BEFORE setup so @onready vars are ready
	items_container.add_child(card)
	card.setup(item_data)
	card.purchased.connect(_on_item_purchased.bind(item_data))



func _on_item_purchased(item_data: Dictionary) -> void:
	if not GameManager.can_afford(item_data.cost):
		return
	
	GameManager.spend_gold(item_data.cost)
	
	match item_data.type:
		"statue":
			# Mark for placement (handled by main game)
			item_purchased.emit(item_data.resource, "statue")
		"artifact":
			GameManager.add_artifact(item_data.resource)
			item_purchased.emit(item_data.resource, "artifact")
		"consumable":
			# Only add to inventory - player will activate from inventory UI
			if item_data.resource:
				GameManager.add_to_inventory(item_data.resource, "consumables")
				print("[Shop] Consumable added to inventory: %s" % item_data.resource.display_name)
			item_purchased.emit(item_data.resource, "consumable")
	
	# Regenerate shop to remove purchased item
	_generate_shop_items()


func _on_reroll_pressed() -> void:
	if GameManager.reroll_shop():
		_generate_shop_items()
		_update_reroll_button()


func _on_start_wave_pressed() -> void:
	close_shop()
	GameManager.start_next_wave()


func _on_close_pressed() -> void:
	# Just close shop without starting wave
	visible = false
	shop_closed.emit()


func _update_gold_display(gold: int) -> void:
	if gold_label:
		gold_label.text = "💰 %d" % gold
	
	# Update item affordability
	for card in items_container.get_children():
		if card.has_method("update_affordability"):
			card.update_affordability(gold)


func _update_wave_display() -> void:
	if wave_label:
		wave_label.text = "Wave %d Complete!" % GameManager.current_wave


func _update_reroll_button() -> void:
	var cost = GameManager.get_reroll_cost()
	reroll_button.text = "🔄 Reroll (%dg)" % cost
	reroll_button.disabled = not GameManager.can_afford(cost)
