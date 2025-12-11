extends CanvasLayer

## Inventory UI Controller
## Displays player's owned statues, artifacts, and consumables

signal item_selected(item: Resource, item_type: String)
signal place_statue_requested(statue_data: Resource)

@onready var items_grid: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/ItemsScroll/ItemsGrid
@onready var empty_label: Label = $Control/Panel/MarginContainer/VBoxContainer/EmptyLabel
@onready var statues_tab: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/TabsContainer/StatuesTab
@onready var artifacts_tab: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/TabsContainer/ArtifactsTab
@onready var consumables_tab: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/TabsContainer/ConsumablesTab
@onready var close_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/CloseButton

enum Tab { STATUES, ARTIFACTS, CONSUMABLES }
var current_tab: Tab = Tab.STATUES


func _ready() -> void:
	statues_tab.pressed.connect(_on_tab_pressed.bind(Tab.STATUES))
	artifacts_tab.pressed.connect(_on_tab_pressed.bind(Tab.ARTIFACTS))
	consumables_tab.pressed.connect(_on_tab_pressed.bind(Tab.CONSUMABLES))
	close_button.pressed.connect(_on_close_pressed)
	
	# Connect to inventory changes
	GameManager.inventory_changed.connect(_on_inventory_changed)
	
	_update_tab_styles()


func open() -> void:
	visible = true
	refresh()


func close() -> void:
	visible = false


func refresh() -> void:
	_clear_items()
	
	var items: Array = []
	var item_type_str: String = ""
	
	match current_tab:
		Tab.STATUES:
			items = GameManager.get_inventory_items("statues")
			item_type_str = "statues"
		Tab.ARTIFACTS:
			items = GameManager.get_inventory_items("artifacts")
			item_type_str = "artifacts"
		Tab.CONSUMABLES:
			items = GameManager.get_inventory_items("consumables")
			item_type_str = "consumables"
	
	empty_label.visible = items.is_empty()
	
	for entry in items:
		var item_data = entry["data"]
		var count = entry["count"]
		var card = _create_item_card(item_data, count, item_type_str)
		if card:
			items_grid.add_child(card)


func _create_item_card(item_data: Resource, count: int, item_type: String) -> Control:
	if not item_data:
		return null
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 100)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(inner_vbox)
	
	# Portrait/Icon
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(60, 50)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Check properties using get() instead of has()
	var portrait_tex = item_data.get("portrait_texture")
	var icon_tex = item_data.get("icon")
	if portrait_tex:
		portrait.texture = portrait_tex
	elif icon_tex:
		portrait.texture = icon_tex
	
	inner_vbox.add_child(portrait)
	
	# Name with count
	var name_label = Label.new()
	var display_name = item_data.get("display_name")
	if not display_name:
		display_name = str(item_data)
	if count > 1:
		name_label.text = "%s x%d" % [display_name, count]
	else:
		name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(name_label)
	
	# Action button for statues (place on grid)
	if item_type == "statues":
		var place_btn = Button.new()
		place_btn.text = "Place"
		place_btn.add_theme_font_size_override("font_size", 10)
		place_btn.pressed.connect(_on_place_statue.bind(item_data))
		inner_vbox.add_child(place_btn)
	
	return card


func _clear_items() -> void:
	for child in items_grid.get_children():
		child.queue_free()


func _update_tab_styles() -> void:
	# Reset all tabs
	statues_tab.modulate = Color(0.7, 0.7, 0.7, 1)
	artifacts_tab.modulate = Color(0.7, 0.7, 0.7, 1)
	consumables_tab.modulate = Color(0.7, 0.7, 0.7, 1)
	
	# Highlight current tab
	match current_tab:
		Tab.STATUES:
			statues_tab.modulate = Color(1, 1, 1, 1)
		Tab.ARTIFACTS:
			artifacts_tab.modulate = Color(1, 1, 1, 1)
		Tab.CONSUMABLES:
			consumables_tab.modulate = Color(1, 1, 1, 1)


func _on_tab_pressed(tab: Tab) -> void:
	current_tab = tab
	_update_tab_styles()
	refresh()


func _on_close_pressed() -> void:
	close()


func _on_place_statue(statue_data: Resource) -> void:
	place_statue_requested.emit(statue_data)


func _on_inventory_changed() -> void:
	if visible:
		refresh()
