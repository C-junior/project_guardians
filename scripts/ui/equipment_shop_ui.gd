extends CanvasLayer

## EquipmentShopUI - Rune-only rotating shop + persistent statue catalog
## - Top section: 5 random runes that can be rerolled
## - Bottom section: Full statue catalog, always visible, always purchasable

signal equipment_purchased(equipment: EquipmentData)
signal statue_purchased(statue_data: Resource, tier: int)
signal shop_closed()

# Shop state
var current_runes: Array[Dictionary] = []
var base_rune_count: int = 5  # 5 runes per refresh
var reroll_count: int = 0

# MVP Equipment pool (6 runas)
var mvp_equipment_pool: Array[EquipmentData] = []

# MVP Statue pool (all statues - persistent catalog)
var mvp_statue_pool: Array[Resource] = []

# References
@onready var items_container: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/ItemsContainer
@onready var statue_catalog_container: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/StatueCatalogContainer
@onready var gold_label: Label = $Control/Panel/MarginContainer/VBoxContainer/Header/GoldLabel
@onready var reroll_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/RerollButton
@onready var close_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/CloseButton

# Card scene
var equipment_card_scene: PackedScene = preload("res://scenes/ui/equipment_shop_card.tscn")


func _ready() -> void:
	reroll_button.pressed.connect(_on_reroll_pressed)
	close_button.pressed.connect(_on_close_pressed)
	
	GameManager.gold_changed.connect(_update_gold_display)
	
	_load_mvp_pools()
	visible = false


func _load_mvp_pools() -> void:
	# Load 6 MVP runes
	var mvp_rune_ids = [
		"power_rune",
		"range_rune",
		"quickstep_rune",
		"keen_rune",
		"channel_rune",
		"guard_rune"
	]
	
	for rune_id in mvp_rune_ids:
		var path = "res://resources/equipment/%s.tres" % rune_id
		var res = load(path) as EquipmentData
		if res:
			mvp_equipment_pool.append(res)
	
	print("[EquipmentShop] Loaded %d MVP runes" % mvp_equipment_pool.size())
	
	# Load ALL MVP statues for the persistent catalog
	var mvp_statue_paths = [
		"res://resources/statues/sentinel.tres",
		"res://resources/statues/huntress.tres",
		"res://resources/statues/divine_guardian.tres",
		"res://resources/statues/frost_maiden.tres",
		"res://resources/statues/arcane_weaver.tres",
		"res://resources/statues/shadow_dancer.tres",
		"res://resources/statues/earthshaker.tres"
	]
	
	for statue_path in mvp_statue_paths:
		var res = load(statue_path)
		if res:
			mvp_statue_pool.append(res)
	
	print("[EquipmentShop] Loaded %d MVP statues for catalog" % mvp_statue_pool.size())


## Open shop
func open_shop() -> void:
	visible = true
	reroll_count = 0
	_update_gold_display(GameManager.gold)
	_generate_rune_items()
	_generate_statue_catalog()


## Close shop
func close_shop() -> void:
	visible = false
	shop_closed.emit()


# ============================================================================
# RUNE SECTION (rotating, refreshable)
# ============================================================================

## Generate rune shop items (5 random runes)
func _generate_rune_items() -> void:
	# Clear existing rune cards
	for child in items_container.get_children():
		child.queue_free()
	current_runes.clear()
	
	# Generate 5 random runes
	for i in range(base_rune_count):
		var equipment = mvp_equipment_pool.pick_random()
		var item_data = {
			"type": "equipment",
			"resource": equipment,
			"cost": equipment.shop_cost
		}
		current_runes.append(item_data)
		_create_rune_card(item_data)
	
	_update_reroll_button()


func _create_rune_card(item_data: Dictionary) -> void:
	var card = equipment_card_scene.instantiate()
	items_container.add_child(card)
	card.setup(item_data)
	card.purchased.connect(_on_rune_purchased.bind(item_data))


func _on_rune_purchased(item_data: Dictionary) -> void:
	if not GameManager.can_afford(item_data.cost):
		return
	
	GameManager.spend_gold(item_data.cost)
	
	# Add equipment to inventory
	GameManager.add_to_inventory(item_data.resource, "equipment")
	equipment_purchased.emit(item_data.resource)
	print("[EquipmentShop] Purchased rune: %s for %dg" % [item_data.resource.display_name, item_data.cost])
	
	# Regenerate rune section (removes the bought card and replaces with fresh random)
	_generate_rune_items()
	# Re-check statue affordability too
	_update_statue_affordability()


# ============================================================================
# STATUE CATALOG SECTION (persistent, always visible)
# ============================================================================

## Generate the full statue catalog (all statues always available)
func _generate_statue_catalog() -> void:
	# Clear existing catalog cards
	for child in statue_catalog_container.get_children():
		child.queue_free()
	
	# Show ALL statues, always at base rarity (Common)
	for statue in mvp_statue_pool:
		var cost = statue.get("base_cost") if "base_cost" in statue else 350
		var item_data = {
			"type": "statue",
			"resource": statue,
			"rarity": 0,  # Always Common in catalog
			"cost": cost
		}
		_create_statue_catalog_card(item_data)


func _create_statue_catalog_card(item_data: Dictionary) -> void:
	var card = equipment_card_scene.instantiate()
	statue_catalog_container.add_child(card)
	card.setup(item_data)
	card.purchased.connect(_on_statue_purchased.bind(item_data))


func _on_statue_purchased(item_data: Dictionary) -> void:
	if not GameManager.can_afford(item_data.cost):
		return
	
	GameManager.spend_gold(item_data.cost)
	
	# Add statue to inventory
	GameManager.add_statue_to_inventory(item_data.resource, item_data.rarity)
	statue_purchased.emit(item_data.resource, 0)  # Tier 0 (base)
	print("[EquipmentShop] Purchased statue: %s for %dg" % [item_data.resource.display_name, item_data.cost])
	
	# Don't remove statue from catalog — it stays available!
	# Just update affordability
	_update_gold_display(GameManager.gold)


# ============================================================================
# SHARED UI HELPERS
# ============================================================================

func _on_reroll_pressed() -> void:
	var cost = _get_reroll_cost()
	if not GameManager.can_afford(cost):
		return
	
	GameManager.spend_gold(cost)
	reroll_count += 1
	_generate_rune_items()  # Only reroll runes, not statues
	print("[EquipmentShop] Rerolled runes (cost: %dg, total rerolls: %d)" % [cost, reroll_count])


func _get_reroll_cost() -> int:
	return 30 + (20 * reroll_count)


func _on_close_pressed() -> void:
	close_shop()


func _update_gold_display(gold: int) -> void:
	if gold_label:
		gold_label.text = "💰 %d" % gold
	
	# Update rune card affordability
	for card in items_container.get_children():
		if card.has_method("update_affordability"):
			card.update_affordability(gold)
	
	# Update statue catalog affordability
	_update_statue_affordability()


func _update_statue_affordability() -> void:
	for card in statue_catalog_container.get_children():
		if card.has_method("update_affordability"):
			card.update_affordability(GameManager.gold)


func _update_reroll_button() -> void:
	var cost = _get_reroll_cost()
	reroll_button.text = "🔄 Reroll Runes (%dg)" % cost
	reroll_button.disabled = not GameManager.can_afford(cost)
