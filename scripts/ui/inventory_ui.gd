extends CanvasLayer

## Inventory UI Controller
## Displays player's owned statues, artifacts, and consumables

signal item_selected(item: Resource, item_type: String)
signal place_statue_requested(statue_data: Resource, tier: int)
signal ascension_requested()

@onready var items_grid: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/ItemsScroll/ItemsGrid
@onready var empty_label: Label = $Control/Panel/MarginContainer/VBoxContainer/EmptyLabel
@onready var statues_tab: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/TabsContainer/StatuesTab
@onready var artifacts_tab: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/TabsContainer/ArtifactsTab
@onready var consumables_tab: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/TabsContainer/ConsumablesTab
@onready var close_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/CloseButton
@onready var ascension_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/AscensionButton

# Detail panel references
@onready var detail_panel: PanelContainer = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel
@onready var detail_portrait: TextureRect = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailPortrait
@onready var detail_name: Label = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailInfo/DetailName
@onready var detail_tier: Label = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailInfo/DetailTier
@onready var detail_stats: Label = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailInfo/DetailStats
@onready var detail_ability: Label = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailInfo/DetailAbility
@onready var detail_desc: Label = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailInfo/DetailDesc

enum Tab { STATUES, ARTIFACTS, CONSUMABLES }
var current_tab: Tab = Tab.STATUES
var selected_item_data: Resource = null
var selected_item_tier: int = 0
var selected_item_type: String = ""


func _ready() -> void:
	statues_tab.pressed.connect(_on_tab_pressed.bind(Tab.STATUES))
	artifacts_tab.pressed.connect(_on_tab_pressed.bind(Tab.ARTIFACTS))
	consumables_tab.pressed.connect(_on_tab_pressed.bind(Tab.CONSUMABLES))
	close_button.pressed.connect(_on_close_pressed)
	
	if ascension_button:
		ascension_button.pressed.connect(_on_ascension_pressed)
	
	# Connect to inventory changes
	GameManager.inventory_changed.connect(_on_inventory_changed)
	
	_update_tab_styles()


func open() -> void:
	visible = true
	refresh()


func close() -> void:
	visible = false
	_hide_detail_panel()


func refresh() -> void:
	_clear_items()
	_hide_detail_panel()
	
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
		var tier = entry.get("tier", 0)
		var card = _create_item_card(item_data, count, item_type_str, tier)
		if card:
			items_grid.add_child(card)


func _create_item_card(item_data: Resource, count: int, item_type: String, tier: int = 0) -> Control:
	if not item_data:
		return null
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(140, 180)
	
	# Style with tier-colored border for statues
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	stylebox.set_border_width_all(3)
	stylebox.set_corner_radius_all(10)
	
	if item_type == "statues" and tier > 0:
		stylebox.border_color = EvolutionManager.get_tier_color(tier)
	else:
		stylebox.border_color = Color(0.3, 0.3, 0.4)
	
	card.add_theme_stylebox_override("panel", stylebox)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(inner_vbox)
	
	# Tier indicator for statues
	if item_type == "statues":
		var tier_label = Label.new()
		var stars = ""
		for i in range(tier + 1):
			stars += "★"
		tier_label.text = "%s %s" % [stars, EvolutionManager.get_tier_name(tier)]
		tier_label.add_theme_font_size_override("font_size", 10)
		tier_label.add_theme_color_override("font_color", EvolutionManager.get_tier_color(tier))
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inner_vbox.add_child(tier_label)
	
	# Portrait/Icon
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(80, 70)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
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
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	inner_vbox.add_child(name_label)
	
	# Action buttons container
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 5)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_child(btn_hbox)
	
	# Info button (shows details)
	var info_btn = Button.new()
	info_btn.text = "ℹ️"
	info_btn.add_theme_font_size_override("font_size", 12)
	info_btn.pressed.connect(_on_item_info_pressed.bind(item_data, item_type, tier))
	btn_hbox.add_child(info_btn)
	
	# Place button for statues
	if item_type == "statues":
		var place_btn = Button.new()
		place_btn.text = "Place"
		place_btn.add_theme_font_size_override("font_size", 11)
		place_btn.pressed.connect(_on_place_statue.bind(item_data, tier))
		btn_hbox.add_child(place_btn)
	
	return card


func _on_item_info_pressed(item_data: Resource, item_type: String, tier: int) -> void:
	_show_detail_panel(item_data, item_type, tier)


func _show_detail_panel(item_data: Resource, item_type: String, tier: int) -> void:
	if not item_data:
		return
	
	selected_item_data = item_data
	selected_item_tier = tier
	selected_item_type = item_type
	
	detail_panel.visible = true
	
	# Portrait
	var portrait_tex = item_data.get("portrait_texture")
	var icon_tex = item_data.get("icon")
	if portrait_tex:
		detail_portrait.texture = portrait_tex
	elif icon_tex:
		detail_portrait.texture = icon_tex
	
	# Name
	var display_name = item_data.get("display_name")
	if not display_name:
		display_name = str(item_data)
	detail_name.text = display_name
	
	# Tier (for statues)
	if item_type == "statues":
		var stars = ""
		for i in range(tier + 1):
			stars += "★"
		detail_tier.text = "%s %s" % [stars, EvolutionManager.get_tier_name(tier)]
		detail_tier.add_theme_color_override("font_color", EvolutionManager.get_tier_color(tier))
		detail_tier.visible = true
		
		# Stats
		var stats = item_data.get_stats_for_tier(tier) if item_data.has_method("get_stats_for_tier") else {}
		if stats:
			detail_stats.text = "DMG: %.0f | SPD: %.2f | RNG: %.0f | HP: %.0f" % [
				stats.get("damage", 0),
				stats.get("attack_speed", 0),
				stats.get("range", 0),
				stats.get("health", 0)
			]
		else:
			detail_stats.text = "DMG: %.0f | SPD: %.2f | RNG: %.0f" % [
				item_data.get("base_damage") if item_data.get("base_damage") else 0,
				item_data.get("attack_speed") if item_data.get("attack_speed") else 0,
				item_data.get("attack_range") if item_data.get("attack_range") else 0
			]
		detail_stats.visible = true
		
		# Ability
		var ability_name = item_data.get("ability_name")
		var ability_desc = item_data.get("ability_description")
		if ability_name:
			detail_ability.text = "⚔️ %s" % ability_name
			detail_ability.visible = true
		else:
			detail_ability.visible = false
		
		# Description
		var desc = item_data.get("description")
		if desc:
			detail_desc.text = desc
			detail_desc.visible = true
		elif ability_desc:
			detail_desc.text = ability_desc
			detail_desc.visible = true
		else:
			detail_desc.visible = false
	
	elif item_type == "artifacts":
		detail_tier.text = "✨ Artifact"
		detail_tier.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
		detail_tier.visible = true
		detail_stats.visible = false
		detail_ability.visible = false
		
		var desc = item_data.get("description")
		if desc:
			detail_desc.text = desc
			detail_desc.visible = true
		else:
			detail_desc.visible = false
	
	elif item_type == "consumables":
		detail_tier.text = "🧪 Consumable"
		detail_tier.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
		detail_tier.visible = true
		detail_stats.visible = false
		detail_ability.visible = false
		
		var desc = item_data.get("description")
		if desc:
			detail_desc.text = desc
			detail_desc.visible = true
		else:
			detail_desc.visible = false


func _hide_detail_panel() -> void:
	if detail_panel:
		detail_panel.visible = false
	selected_item_data = null


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


func _on_place_statue(statue_data: Resource, tier: int = 0) -> void:
	place_statue_requested.emit(statue_data, tier)


func _on_inventory_changed() -> void:
	if visible:
		refresh()


func _on_ascension_pressed() -> void:
	ascension_requested.emit()
