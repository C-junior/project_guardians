extends CanvasLayer

## Inventory UI Controller
## Displays player's owned statues, artifacts, and consumables
## Supports drag-and-drop for placing statues

signal item_selected(item: Resource, item_type: String)
signal place_statue_requested(statue_data: Resource, tier: int)
signal ascension_requested()
signal drag_started(statue_data: Resource, tier: int)
signal drag_ended()
signal drop_requested(statue_data: Resource, tier: int, mouse_pos: Vector2)

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

# Drag and drop state
var is_dragging: bool = false
var dragged_statue: Resource = null
var dragged_tier: int = 0
var drag_preview: Control = null


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
	
	# For consumables tab, show active ones first
	if current_tab == Tab.CONSUMABLES and GameManager.active_consumables.size() > 0:
		# Add label for active consumables
		var active_label = Label.new()
		active_label.text = "⚡ Queued for Next Wave:"
		active_label.add_theme_font_size_override("font_size", 12)
		active_label.add_theme_color_override("font_color", Color.YELLOW)
		items_grid.add_child(active_label)
		
		for consumable in GameManager.active_consumables:
			var card = _create_active_consumable_card(consumable)
			if card:
				items_grid.add_child(card)
	
	empty_label.visible = items.is_empty() and GameManager.active_consumables.is_empty()
	
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
	
	# Store data for drag-and-drop
	card.set_meta("item_data", item_data)
	card.set_meta("item_type", item_type)
	card.set_meta("tier", tier)
	
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
	
	# Connect hover signals for detail panel
	card.mouse_entered.connect(_on_card_hovered.bind(item_data, item_type, tier))
	card.mouse_exited.connect(_on_card_unhovered)
	
	# Enable drag-and-drop for statues
	if item_type == "statues":
		card.gui_input.connect(_on_card_gui_input.bind(card, item_data, tier))
	
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
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow mouse events to pass through
	
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
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_vbox.add_child(name_label)
	
	# Drag hint for statues
	if item_type == "statues":
		var drag_hint = Label.new()
		drag_hint.text = "🖱️ Drag to place"
		drag_hint.add_theme_font_size_override("font_size", 9)
		drag_hint.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6, 0.8))
		drag_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		drag_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner_vbox.add_child(drag_hint)
	
	# Action buttons container
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 5)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_child(btn_hbox)
	
	# Place button for statues (alternative to drag)
	if item_type == "statues":
		var place_btn = Button.new()
		place_btn.text = "📍 Place"
		place_btn.add_theme_font_size_override("font_size", 11)
		place_btn.pressed.connect(_on_place_statue.bind(item_data, tier))
		btn_hbox.add_child(place_btn)
	
	# Use button for consumables
	if item_type == "consumables":
		var use_btn = Button.new()
		use_btn.text = "Use"
		use_btn.add_theme_font_size_override("font_size", 11)
		use_btn.pressed.connect(_on_use_consumable.bind(item_data))
		btn_hbox.add_child(use_btn)
	
	return card


## Handle hover to show details
func _on_card_hovered(item_data: Resource, item_type: String, tier: int) -> void:
	_show_detail_panel(item_data, item_type, tier)


func _on_card_unhovered() -> void:
	# Only hide if not actively dragging
	if not is_dragging:
		_hide_detail_panel()


## Handle drag-and-drop for statue cards
func _on_card_gui_input(event: InputEvent, card: Control, statue_data: Resource, tier: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# Start dragging
			_start_drag(statue_data, tier, card)
		elif not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and is_dragging:
			# End drag (handled by main.gd)
			pass


func _start_drag(statue_data: Resource, tier: int, source_card: Control) -> void:
	is_dragging = true
	dragged_statue = statue_data
	dragged_tier = tier
	
	# Create drag preview
	drag_preview = _create_drag_preview(statue_data, tier)
	get_tree().root.add_child(drag_preview)
	drag_preview.global_position = get_viewport().get_mouse_position() - Vector2(40, 40)
	
	# Emit signal so main.gd knows we're dragging
	drag_started.emit(statue_data, tier)
	
	# Hide inventory during drag
	visible = false
	
	print("[Inventory] Started dragging: %s (Tier %d)" % [statue_data.display_name, tier])


func _create_drag_preview(statue_data: Resource, tier: int) -> Control:
	var preview = PanelContainer.new()
	preview.custom_minimum_size = Vector2(80, 80)
	preview.z_index = 100
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Semi-transparent style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style.set_border_width_all(2)
	style.border_color = EvolutionManager.get_tier_color(tier)
	style.set_corner_radius_all(8)
	preview.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(vbox)
	
	# Portrait
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(60, 60)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var portrait_tex = statue_data.get("portrait_texture")
	if portrait_tex:
		portrait.texture = portrait_tex
	
	vbox.add_child(portrait)
	
	# Name
	var name_lbl = Label.new()
	name_lbl.text = statue_data.display_name
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)
	
	return preview


func _process(_delta: float) -> void:
	# Update drag preview position
	if is_dragging and drag_preview:
		drag_preview.global_position = get_viewport().get_mouse_position() - Vector2(40, 40)


## Global input handler for drag-drop (must catch release anywhere)
func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Mouse released - try to place via signal
			# The actual placement is handled by main.gd which has arena access
			_try_drop_statue()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Cancel drag
			cancel_drag()
			visible = true
			refresh()


func _try_drop_statue() -> void:
	# Emit signal with current mouse position for main.gd to handle placement
	if is_dragging and dragged_statue:
		var mouse_pos = get_viewport().get_mouse_position()
		drop_requested.emit(dragged_statue, dragged_tier, mouse_pos)
		print("[Inventory] Drop requested at position: %s" % mouse_pos)


func cancel_drag() -> void:
	if is_dragging:
		is_dragging = false
		dragged_statue = null
		dragged_tier = 0
		if drag_preview:
			drag_preview.queue_free()
			drag_preview = null
		drag_ended.emit()


func complete_drag() -> void:
	if is_dragging:
		is_dragging = false
		var statue = dragged_statue
		var tier = dragged_tier
		dragged_statue = null
		dragged_tier = 0
		if drag_preview:
			drag_preview.queue_free()
			drag_preview = null
		drag_ended.emit()
		print("[Inventory] Drag completed")


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


## Create a card for active (queued) consumables
func _create_active_consumable_card(consumable_data: Resource) -> Control:
	if not consumable_data:
		return null
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 80)
	
	# Yellow border for active
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.2, 0.2, 0.1, 0.95)
	stylebox.set_border_width_all(3)
	stylebox.border_color = Color.YELLOW
	stylebox.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", stylebox)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_theme_constant_override("margin_bottom", 5)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(inner_vbox)
	
	# Name
	var name_label = Label.new()
	name_label.text = consumable_data.display_name if consumable_data.display_name else "Consumable"
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(name_label)
	
	# Active indicator
	var active_label = Label.new()
	active_label.text = "⚡ ACTIVE"
	active_label.add_theme_font_size_override("font_size", 9)
	active_label.add_theme_color_override("font_color", Color.YELLOW)
	active_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(active_label)
	
	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 9)
	cancel_btn.pressed.connect(_on_cancel_consumable.bind(consumable_data))
	inner_vbox.add_child(cancel_btn)
	
	return card


func _on_cancel_consumable(consumable_data: Resource) -> void:
	# Remove from active and return to inventory
	for i in range(GameManager.active_consumables.size()):
		var active = GameManager.active_consumables[i]
		if active == consumable_data or (active.get("id") and consumable_data.get("id") and active.id == consumable_data.id):
			GameManager.active_consumables.remove_at(i)
			GameManager.add_to_inventory(consumable_data, "consumables")
			refresh()
			print("[Inventory] Consumable cancelled: %s" % consumable_data.display_name)
			return


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


func _on_use_consumable(consumable_data: Resource) -> void:
	if not consumable_data:
		return
	
	# Check if already activated this wave
	for active in GameManager.active_consumables:
		if active == consumable_data or (active.get("id") and consumable_data.get("id") and active.id == consumable_data.id):
			print("[Inventory] Consumable already active!")
			return
	
	# Activate for next wave
	GameManager.active_consumables.push_back(consumable_data)
	
	# Remove from inventory
	GameManager.remove_from_inventory(consumable_data, "consumables")
	
	# Visual feedback
	print("[Inventory] Consumable activated: %s" % consumable_data.display_name)
	
	# Refresh UI
	refresh()


func _on_inventory_changed() -> void:
	if visible:
		refresh()


func _on_ascension_pressed() -> void:
	ascension_requested.emit()
