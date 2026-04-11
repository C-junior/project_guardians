extends CanvasLayer

## ShopManager - Handles preparation phase shop logic and UI

signal item_purchased(item: Resource, item_type: String)
signal shop_closed()

# Shop state
var current_items: Array[Dictionary] = []  # {"resource": Resource, "type": String}
var base_item_count: int = 5
var first_purchase_made: bool = false  # Tracks if discount was used
var items_generated_for_wave: int = -1  # Track which wave items were generated for

# References
@onready var items_container: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/ItemsContainer
@onready var gold_label: Label = $Control/Panel/MarginContainer/VBoxContainer/Header/GoldLabel
@onready var reroll_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/RerollButton
@onready var start_wave_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/StartWaveButton
@onready var wave_label: Label = $Control/Panel/MarginContainer/VBoxContainer/Header/WaveLabel

# Item card scene
var item_card_scene: PackedScene = preload("res://scenes/ui/shop_item_card.tscn")

# Resource pools
var equipment_pool: Array[Resource] = []

# Close button reference
@onready var close_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/CloseButton


func _ready() -> void:
	reroll_button.pressed.connect(_on_reroll_pressed)
	start_wave_button.pressed.connect(_on_start_wave_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	GameManager.gold_changed.connect(_update_gold_display)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	
	_load_item_pools()
	visible = false


func _on_game_state_changed(new_state: GameManager.GameState) -> void:
	# Reset first purchase and shop items when starting a new run
	if new_state == GameManager.GameState.SETUP:
		first_purchase_made = false
		items_generated_for_wave = -1
		current_items.clear()


func _load_item_pools() -> void:
	# Load all equipment resources (runes)
	var dir = DirAccess.open("res://resources/equipment/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res = load("res://resources/equipment/" + file_name)
				if res:
					equipment_pool.append(res)
			file_name = dir.get_next()
	
	print("[Shop] Loaded %d equipment items" % equipment_pool.size())


## Open shop for preparation phase
func open_shop() -> void:
	visible = true
	_update_gold_display(GameManager.gold)
	_update_wave_display()
	_update_reroll_button()
	# Only generate new items if wave changed (prevents items from changing when closing/reopening shop)
	if items_generated_for_wave != GameManager.current_wave:
		_generate_shop_items()
		items_generated_for_wave = GameManager.current_wave


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
	
	if equipment_pool.is_empty():
		return
		
	var item_count = base_item_count
	
	# Generate N random equipment items (runes)
	for i in range(item_count):
		var equipment = equipment_pool[randi() % equipment_pool.size()]
		var cost = equipment.shop_cost if "shop_cost" in equipment else 100
		
		var item_data: Dictionary = {
			"resource": equipment, 
			"type": "equipment", 
			"cost": cost
		}
		
		# Apply first purchase discount from blessing
		if not first_purchase_made and GameManager.current_blessing:
			var discount = GameManager.current_blessing.get("first_purchase_discount")
			if discount and discount > 0:
				item_data["original_cost"] = item_data["cost"]
				item_data["cost"] = int(item_data["cost"] * (1.0 - discount))
				item_data["discounted"] = true
				
		current_items.append(item_data)
		_create_item_card(item_data)





func _create_item_card(item_data: Dictionary) -> void:
	var card = item_card_scene.instantiate()
	# IMPORTANT: Add to tree BEFORE setup so @onready vars are ready
	items_container.add_child(card)
	card.setup(item_data)
	card.purchased.connect(_on_item_purchased.bind(item_data))



func _on_item_purchased(item_data: Dictionary) -> void:
	if not GameManager.can_afford(item_data.cost):
		return
	
	# Track if this was a discounted first purchase
	if item_data.get("discounted", false) and not first_purchase_made:
		first_purchase_made = true
		print("[Shop] First purchase discount applied!")
	
	# JUICE: Purchase celebration!
	_purchase_celebration(item_data.cost)
	
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
		"upgrade":
			# Add upgrade to inventory - player will apply from inventory UI
			if item_data.resource:
				GameManager.add_to_inventory(item_data.resource, "upgrades")
				print("[Shop] Upgrade added to inventory: %s" % item_data.resource.display_name)
			item_purchased.emit(item_data.resource, "upgrade")
	
	# Regenerate shop to remove purchased item
	_generate_shop_items()


## JUICE: Purchase celebration effect
func _purchase_celebration(cost: int) -> void:
	# Gold label bounce and flash
	if gold_label:
		var original_color = gold_label.get_theme_color("font_color") if gold_label.has_theme_color("font_color") else Color.WHITE
		var gold_tween = create_tween()
		gold_tween.tween_property(gold_label, "scale", Vector2(1.3, 1.3), 0.08)
		gold_tween.parallel().tween_property(gold_label, "modulate", Color.GOLD, 0.08)
		gold_tween.tween_property(gold_label, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
		gold_tween.parallel().tween_property(gold_label, "modulate", Color.WHITE, 0.15)
	
	# Spawn coin particles flying from gold label
	for i in range(5):
		var coin = Label.new()
		coin.text = "💰"
		coin.add_theme_font_size_override("font_size", 16)
		if gold_label:
			coin.position = gold_label.global_position + Vector2(randf_range(-20, 20), 0)
		else:
			coin.position = Vector2(100, 50)
		add_child(coin)
		
		var direction = Vector2(randf_range(-100, 100), randf_range(-80, -40))
		var coin_tween = create_tween()
		coin_tween.tween_property(coin, "position", coin.position + direction, 0.4).set_ease(Tween.EASE_OUT)
		coin_tween.parallel().tween_property(coin, "modulate:a", 0.0, 0.4)
		coin_tween.tween_callback(coin.queue_free)
	
	# Flash the whole shop panel briefly
	var panel = $Control/Panel
	if panel:
		var panel_tween = create_tween()
		panel_tween.tween_property(panel, "modulate", Color(1.2, 1.2, 1.0), 0.05)
		panel_tween.tween_property(panel, "modulate", Color.WHITE, 0.1)


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
