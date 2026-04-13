extends CanvasLayer

## StatueInventoryUI - Inventário simplificado para MVP
## Mostra estátuas com equipment slots e runas equipadas
## Suporta drag-and-drop para colocar estátuas na arena

signal place_statue_requested(statue_data: Resource, tier: int)
signal drag_started(statue_data: Resource, tier: int)
signal drag_ended()
signal drop_requested(statue_data: Resource, tier: int, mouse_pos: Vector2)
signal equipment_applied(statue_data: Resource, equipment: EquipmentData)

enum Tab { STATUES, EQUIPMENT }
var current_tab: Tab = Tab.STATUES

# Drag and drop state
var is_dragging: bool = false
var dragged_statue: Resource = null
var dragged_tier: int = 0
var drag_preview: Control = null

# UI references
@onready var items_grid: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/ItemsScroll/ItemsGrid
@onready var empty_label: Label = $Control/Panel/MarginContainer/VBoxContainer/EmptyLabel
@onready var statues_tab: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/TabsContainer/StatuesTab
@onready var equipment_tab: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/TabsContainer/EquipmentTab
@onready var close_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Header/CloseButton

# Detail panel
@onready var detail_panel: PanelContainer = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel
@onready var detail_portrait: TextureRect = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailPortrait
@onready var detail_name: Label = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailInfo/DetailName
@onready var detail_tier: Label = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailInfo/DetailTier
@onready var detail_stats: Label = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailInfo/DetailStats
@onready var detail_equipment: Label = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailInfo/DetailEquipment
@onready var detail_desc: Label = $Control/Panel/MarginContainer/VBoxContainer/DetailPanel/DetailMargin/DetailHBox/DetailInfo/DetailDesc

# Selected item for equipment tab
var selected_equipment: EquipmentData = null

# Equip mode state
var equip_mode: bool = false
var pending_equip_item: EquipmentData = null
var statue_picker_overlay: Control = null
var equip_status_label: Label = null


func _ready() -> void:
	statues_tab.pressed.connect(_on_tab_pressed.bind(Tab.STATUES))
	equipment_tab.pressed.connect(_on_tab_pressed.bind(Tab.EQUIPMENT))
	close_button.pressed.connect(_on_close_pressed)
	
	GameManager.inventory_changed.connect(_on_inventory_changed)
	
	_update_tab_styles()
	
	# Make detail panel a floating overlay
	if detail_panel:
		detail_panel.top_level = true
		detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		detail_panel.custom_minimum_size = Vector2(250, 0)
		detail_panel.z_index = 100

func open() -> void:
	visible = true
	refresh()


func close() -> void:
	visible = false
	_hide_detail_panel()


func refresh() -> void:
	_clear_items()
	_hide_detail_panel()
	
	match current_tab:
		Tab.STATUES:
			_refresh_statues()
		Tab.EQUIPMENT:
			_refresh_equipment()


func _refresh_statues() -> void:
	var unlocked_statues = GameManager.get_unlocked_statue_resources()
	
	empty_label.visible = unlocked_statues.is_empty()
	
	for statue_data in unlocked_statues:
		var owned_count = GameManager.get_inventory_count(statue_data, "statues")
		var tier = 0
		var equipped_items = []
		
		var cost = statue_data.get_cost(tier) if statue_data.has_method("get_cost") else 50
		var can_afford = owned_count > 0 or GameManager.can_afford(cost)

		var card = _create_statue_card(statue_data, tier, equipped_items, owned_count, cost, can_afford)
		if card:
			items_grid.add_child(card)


func _create_statue_card(statue_data: Resource, tier: int, equipped_items: Array, owned_count: int = 0, cost: int = 50, can_afford: bool = true) -> Control:
	if not statue_data:
		return null
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 200)
	
	# Store metadata
	card.set_meta("item_data", statue_data)
	card.set_meta("item_type", "statue")
	card.set_meta("tier", tier)
	card.set_meta("equipped_items", equipped_items)
	
	# Style with tier-colored border
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.15, 0.2, 0.95)
	stylebox.set_border_width_all(3)
	stylebox.set_corner_radius_all(10)
	
	# Get tier color from EvolutionManager
	var tier_colors = [
		Color.GRAY,      # ★ Base
		Color.GREEN,     # ★★ Enhanced
		Color.GOLD,      # ★★★ Awakened
		Color.ORANGE_RED # ★★★★ Divine
	]
	stylebox.border_color = tier_colors[clamp(tier, 0, 3)]
	
	card.add_theme_stylebox_override("panel", stylebox)
	
	# Hover for detail
	card.mouse_entered.connect(_on_card_hovered.bind(card, statue_data, tier, equipped_items))
	card.mouse_exited.connect(_on_card_unhovered)
	
	# Drag-and-drop for statues
	card.gui_input.connect(_on_card_gui_input.bind(card, statue_data, tier, can_afford))
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 8)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(inner_vbox)
	
	# Tier indicator
	var tier_label = Label.new()
	var stars = ""
	for i in range(tier + 1):
		stars += "★"
	var tier_names = ["Base", "Enhanced", "Awakened", "Divine"]
	tier_label.text = "%s %s" % [stars, tier_names[clamp(tier, 0, 3)]]
	tier_label.add_theme_font_size_override("font_size", 10)
	tier_label.add_theme_color_override("font_color", tier_colors[clamp(tier, 0, 3)])
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(tier_label)
	
	# Portrait/Icon
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(70, 60)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var portrait_tex = statue_data.get("portrait_texture") if "portrait_texture" in statue_data else null
	if portrait_tex:
		portrait.texture = portrait_tex
	
	inner_vbox.add_child(portrait)
	
	# Name
	var name_label = Label.new()
	var display_name = statue_data.get("display_name") if "display_name" in statue_data else "Unknown"
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_vbox.add_child(name_label)
	
	# Equipment slots display
	if equipped_items.size() > 0:
		var equip_label = Label.new()
		var equip_names = []
		for equip in equipped_items:
			if equip is EquipmentData:
				equip_names.append(equip.display_name)
		equip_label.text = "⚒️ " + ", ".join(equip_names)
		equip_label.add_theme_font_size_override("font_size", 9)
		equip_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7))
		equip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equip_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		equip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner_vbox.add_child(equip_label)
	
	# Buttons
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 5)
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_vbox.add_child(btn_hbox)
	
	# Place button replaced by click action
	var cost_label = Label.new()
	if owned_count > 0:
		cost_label.text = "📍 Click to place (Owned)"
		cost_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	else:
		cost_label.text = "📍 Click to buy (%dG)" % cost
		if can_afford:
			cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
		else:
			cost_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			
	cost_label.add_theme_font_size_override("font_size", 11)
	btn_hbox.add_child(cost_label)
	
	return card


func _refresh_equipment() -> void:
	var equipment = GameManager.get_inventory_items("equipment")
	
	empty_label.visible = equipment.is_empty()
	
	for entry in equipment:
		var equip_data = entry["data"]
		
		var card = _create_equipment_card(equip_data)
		if card:
			items_grid.add_child(card)


func _create_equipment_card(equipment: EquipmentData) -> Control:
	if not equipment:
		return null
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 200)
	card.set_meta("item_data", equipment)
	card.set_meta("item_type", "equipment")
	
	# Style
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	stylebox.set_border_width_all(3)
	stylebox.border_color = equipment.get_rarity_color()
	stylebox.set_corner_radius_all(10)
	card.add_theme_stylebox_override("panel", stylebox)
	
	# Hover for detail
	card.mouse_entered.connect(_on_equipment_card_hovered.bind(card, equipment))
	card.mouse_exited.connect(_on_card_unhovered)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	card.add_child(vbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_all", 8)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 4)
	margin.add_child(inner_vbox)
	
	# Icon placeholder
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(60, 60)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if equipment.icon_texture:
		icon_rect.texture = equipment.icon_texture
	else:
		# Colored square based on stat
		var color = Color.WHITE
		if equipment.bonus_damage_percent > 0:
			color = Color(1.0, 0.5, 0.2)
		elif equipment.bonus_range > 0:
			color = Color(0.3, 0.7, 1.0)
		elif equipment.bonus_attack_speed > 0:
			color = Color(1.0, 1.0, 0.3)
		elif equipment.bonus_crit_chance > 0:
			color = Color(1.0, 0.8, 0.2)
		
		var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(color)
		for x in range(64):
			for y in range(64):
				if x < 4 or x > 59 or y < 4 or y > 59:
					img.set_pixel(x, y, Color.DARK_GRAY)
		icon_rect.texture = ImageTexture.create_from_image(img)
	
	inner_vbox.add_child(icon_rect)
	
	# Name
	var name_label = Label.new()
	name_label.text = equipment.display_name
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_vbox.add_child(name_label)
	
	# Rarity
	var rarity_label = Label.new()
	rarity_label.text = equipment.get_rarity_name()
	rarity_label.add_theme_font_size_override("font_size", 10)
	rarity_label.add_theme_color_override("font_color", equipment.get_rarity_color())
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(rarity_label)
	
	# Stats
	var stats_label = Label.new()
	stats_label.text = equipment.get_stat_summary()
	stats_label.add_theme_font_size_override("font_size", 9)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	inner_vbox.add_child(stats_label)
	
	# EQUIP BUTTON — click to assign this rune to a placed statue
	var equip_btn = Button.new()
	equip_btn.text = "⚒️ Equip"
	equip_btn.add_theme_font_size_override("font_size", 11)
	equip_btn.pressed.connect(_on_equip_rune_pressed.bind(equipment))
	inner_vbox.add_child(equip_btn)
	
	return card


## Detail panel handlers
func _on_card_hovered(card: Control, statue_data: Resource, tier: int, equipped_items: Array) -> void:
	_show_statue_detail(statue_data, tier, equipped_items)
	_position_detail_panel(card)


func _on_equipment_card_hovered(card: Control, equipment: EquipmentData) -> void:
	_show_equipment_detail(equipment)
	_position_detail_panel(card)


func _position_detail_panel(card: Control) -> void:
	if not detail_panel:
		return
	
	# Delay for 1 frame to ensure size is calculated
	await get_tree().process_frame
	
	if not is_instance_valid(card) or not is_instance_valid(detail_panel):
		return
		
	var card_pos = card.global_position
	var panel_size = detail_panel.size
	var screen_size = detail_panel.get_viewport_rect().size
	
	var target_x = card_pos.x + card.size.x + 10
	if target_x + panel_size.x > screen_size.x:
		target_x = card_pos.x - panel_size.x - 10
		
	var target_y = card_pos.y
	if target_y + panel_size.y > screen_size.y:
		target_y = screen_size.y - panel_size.y - 10
		
	if target_y < 10:
		target_y = 10
		
	detail_panel.global_position = Vector2(target_x, target_y)


func _on_card_unhovered() -> void:
	if not is_dragging:
		_hide_detail_panel()


func _show_statue_detail(statue_data: Resource, tier: int, equipped_items: Array) -> void:
	if not statue_data:
		return
	
	detail_panel.visible = true
	
	# Portrait
	var portrait_tex = statue_data.get("portrait_texture")
	if portrait_tex:
		detail_portrait.texture = portrait_tex
	
	# Name
	var display_name = statue_data.get("display_name") if "display_name" in statue_data else "Unknown"
	detail_name.text = display_name
	
	# Tier
	var stars = ""
	for i in range(tier + 1):
		stars += "★"
	var tier_names = ["Base", "Enhanced", "Awakened", "Divine"]
	detail_tier.text = "%s %s" % [stars, tier_names[clamp(tier, 0, 3)]]
	
	# Stats
	var base_dmg = statue_data.get("base_damage") if "base_damage" in statue_data else 0
	var base_spd = statue_data.get("attack_speed") if "attack_speed" in statue_data else 0
	var base_rng = statue_data.get("attack_range") if "attack_range" in statue_data else 0
	
	# Apply evolution multipliers
	var tier_mults = [1.0, 1.4, 1.8, 2.5]
	var mult = tier_mults[clamp(tier, 0, 3)]
	
	detail_stats.text = "DMG: %.0f | SPD: %.2f | RNG: %.0f" % [
		base_dmg * mult,
		base_spd,
		base_rng
	]
	
	# Equipment
	if equipped_items.size() > 0:
		var equip_names = []
		for equip in equipped_items:
			if equip is EquipmentData:
				equip_names.append(equip.display_name)
		detail_equipment.text = "⚒️ " + ", ".join(equip_names)
		detail_equipment.visible = true
	else:
		var max_slots = _get_max_equipment_slots(tier)
		detail_equipment.text = "⚒️ Empty (%d/%d slots)" % [0, max_slots]
		detail_equipment.visible = true
	
	# Description
	var desc = statue_data.get("description") if "description" in statue_data else ""
	var ability_name = statue_data.get("ability_name") if "ability_name" in statue_data else ""
	var ability_desc = statue_data.get("ability_description") if "ability_description" in statue_data else ""
	
	var parts = []
	if desc:
		parts.append(desc)
	if ability_name:
		parts.append("\n⚔️ %s" % ability_name)
		parts.append(ability_desc)
	
	if parts.size() > 0:
		detail_desc.text = "\n".join(parts)
		detail_desc.visible = true
	else:
		detail_desc.visible = false


func _show_equipment_detail(equipment: EquipmentData) -> void:
	if not equipment:
		return
	
	detail_panel.visible = true
	
	# Icon
	if equipment.icon_texture:
		detail_portrait.texture = equipment.icon_texture
	
	# Name
	detail_name.text = equipment.display_name
	
	# Rarity
	detail_tier.text = "%s • Rune" % equipment.get_rarity_name()
	detail_tier.add_theme_color_override("font_color", equipment.get_rarity_color())
	
	# Stats
	detail_stats.text = equipment.get_stat_summary()
	
	# Description
	detail_desc.text = equipment.description
	detail_desc.visible = true
	
	# Hide equipment line for runes
	detail_equipment.visible = false


func _hide_detail_panel() -> void:
	if detail_panel:
		detail_panel.visible = false


# ===========================================================================
# EQUIP MODE — select a placed statue to apply a rune
# ===========================================================================

func _on_equip_rune_pressed(equipment: EquipmentData) -> void:
	"""Player clicked 'Equip' on a rune card. Show statue picker."""
	if not equipment:
		return
	
	var placed = GameManager.placed_statues
	if placed.is_empty():
		_show_equip_feedback("⚠️ No statues placed! Place a statue first.")
		return
	
	pending_equip_item = equipment
	equip_mode = true
	_show_statue_picker(equipment, placed)


func _show_statue_picker(equipment: EquipmentData, placed_statues: Array) -> void:
	"""Build and display an overlay listing all placed statues."""
	_close_statue_picker()  # ensure no duplicate
	
	statue_picker_overlay = Control.new()
	statue_picker_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	statue_picker_overlay.z_index = 200
	
	# Dimmed background that cancels equip on click
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.55)
	bg.gui_input.connect(_on_picker_bg_input)
	statue_picker_overlay.add_child(bg)
	
	# Center panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(500, 340)
	panel.position = Vector2(-250, -170)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.14, 0.98)
	panel_style.set_border_width_all(3)
	panel_style.border_color = equipment.get_rarity_color()
	panel_style.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", panel_style)
	statue_picker_overlay.add_child(panel)
	
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 16)
	margin_c.add_theme_constant_override("margin_right", 16)
	margin_c.add_theme_constant_override("margin_top", 12)
	margin_c.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin_c)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin_c.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "⚒️ Equip: %s" % equipment.display_name
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", equipment.get_rarity_color())
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Select a placed statue to equip this rune"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)
	
	# Scrollable list of placed statues
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(scroll)
	
	var grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 10)
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	scroll.add_child(grid)
	
	for statue_node in placed_statues:
		if not is_instance_valid(statue_node) or not statue_node.statue_data:
			continue
		var btn_card = _create_statue_pick_card(statue_node, equipment)
		grid.add_child(btn_card)
	
	# Status label for feedback
	equip_status_label = Label.new()
	equip_status_label.text = ""
	equip_status_label.add_theme_font_size_override("font_size", 13)
	equip_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(equip_status_label)
	
	# Cancel button
	var cancel_btn = Button.new()
	cancel_btn.text = "✖ Cancel"
	cancel_btn.add_theme_font_size_override("font_size", 13)
	cancel_btn.pressed.connect(_cancel_equip_mode)
	cancel_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(cancel_btn)
	
	# Add overlay to this CanvasLayer's Control root
	var root_control = get_node_or_null("Control")
	if root_control:
		root_control.add_child(statue_picker_overlay)
	else:
		add_child(statue_picker_overlay)


func _create_statue_pick_card(statue_node: Node, equipment: EquipmentData) -> Control:
	"""Create a clickable card for one placed statue in the picker overlay."""
	var data = statue_node.statue_data
	var tier = statue_node.evolution_tier
	var can_equip_flag = statue_node.has_empty_slot()
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(120, 160)
	
	var tier_colors = [Color.GRAY, Color.GREEN, Color.GOLD, Color.ORANGE_RED]
	var border_color = tier_colors[clamp(tier, 0, 3)] if can_equip_flag else Color(0.3, 0.3, 0.3)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.14, 0.22, 0.95) if can_equip_flag else Color(0.1, 0.1, 0.1, 0.7)
	style.set_border_width_all(2)
	style.border_color = border_color
	style.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(vbox)
	
	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 6)
	margin_c.add_theme_constant_override("margin_right", 6)
	margin_c.add_theme_constant_override("margin_top", 6)
	margin_c.add_theme_constant_override("margin_bottom", 6)
	margin_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(margin_c)
	
	var iv = VBoxContainer.new()
	iv.add_theme_constant_override("separation", 3)
	iv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin_c.add_child(iv)
	
	# Portrait
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(50, 50)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ptex = data.get("portrait_texture")
	if ptex:
		portrait.texture = ptex
	iv.add_child(portrait)
	
	# Name
	var nlbl = Label.new()
	nlbl.text = data.display_name if data else "?"
	nlbl.add_theme_font_size_override("font_size", 11)
	nlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nlbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	nlbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	iv.add_child(nlbl)
	
	# Slots info
	var slots_lbl = Label.new()
	var used = statue_node.equipped_items.size()
	var max_s = statue_node.get_max_slots()
	slots_lbl.text = "Slots: %d/%d" % [used, max_s]
	slots_lbl.add_theme_font_size_override("font_size", 9)
	slots_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.7) if can_equip_flag else Color(1.0, 0.4, 0.4))
	slots_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slots_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	iv.add_child(slots_lbl)
	
	# Full indicator
	if not can_equip_flag:
		var full_lbl = Label.new()
		full_lbl.text = "FULL"
		full_lbl.add_theme_font_size_override("font_size", 10)
		full_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		full_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		full_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		iv.add_child(full_lbl)
	
	# Click handler
	if can_equip_flag:
		card.gui_input.connect(_on_statue_pick_input.bind(statue_node))
		# Hover highlight
		card.mouse_entered.connect(func():
			style.border_color = Color.WHITE
		)
		card.mouse_exited.connect(func():
			style.border_color = border_color
		)
	
	return card


func _on_statue_pick_input(event: InputEvent, statue_node: Node) -> void:
	"""Player clicked a statue in the picker — apply the pending rune."""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not pending_equip_item:
			return
		_apply_equip(statue_node)


func _apply_equip(statue_node: Node) -> void:
	"""Actually equip pending_equip_item onto the given statue node."""
	if not pending_equip_item:
		return
	
	var success = GameManager.apply_equipment_to_statue(statue_node, pending_equip_item)
	if success:
		print("[Inventory] Equipped %s onto %s" % [pending_equip_item.display_name, statue_node.statue_data.display_name])
		equipment_applied.emit(statue_node.statue_data, pending_equip_item)
		_show_equip_feedback("✅ %s equipped on %s!" % [pending_equip_item.display_name, statue_node.statue_data.display_name], Color(0.3, 1.0, 0.5))
		# Close picker after brief delay so user sees the feedback
		await get_tree().create_timer(0.7).timeout
		_cancel_equip_mode()
		refresh()
	else:
		_show_equip_feedback("❌ Could not equip — slot full or item missing.", Color(1.0, 0.4, 0.4))


func _on_picker_bg_input(event: InputEvent) -> void:
	"""Clicking outside the picker panel cancels equip mode."""
	if event is InputEventMouseButton and event.pressed:
		_cancel_equip_mode()


func _cancel_equip_mode() -> void:
	equip_mode = false
	pending_equip_item = null
	_close_statue_picker()


func _close_statue_picker() -> void:
	if statue_picker_overlay and is_instance_valid(statue_picker_overlay):
		statue_picker_overlay.queue_free()
		statue_picker_overlay = null
	equip_status_label = null


func _show_equip_feedback(msg: String, color: Color = Color(1.0, 0.9, 0.4)) -> void:
	"""Shows a brief message, either on the picker overlay or as a print."""
	print("[Inventory] %s" % msg)
	if equip_status_label and is_instance_valid(equip_status_label):
		equip_status_label.text = msg
		equip_status_label.add_theme_color_override("font_color", color)


## Drag-and-drop handlers
func _on_card_gui_input(event: InputEvent, card: Control, statue_data: Resource, tier: int, can_afford: bool = true) -> void:
	if not can_afford:
		return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_place_statue(statue_data, tier)


func _start_drag(statue_data: Resource, tier: int, source_card: Control) -> void:
	is_dragging = true
	dragged_statue = statue_data
	dragged_tier = tier
	
	# Create drag preview
	drag_preview = _create_drag_preview(statue_data, tier)
	get_tree().root.add_child(drag_preview)
	drag_preview.global_position = get_viewport().get_mouse_position() - Vector2(40, 40)
	
	drag_started.emit(statue_data, tier)
	
	# Hide inventory during drag
	visible = false
	
	print("[Inventory] Started dragging: %s (Tier %d)" % [statue_data.get("display_name") if "display_name" in statue_data else "Unknown", tier])


func _create_drag_preview(statue_data: Resource, tier: int) -> Control:
	var preview = PanelContainer.new()
	preview.custom_minimum_size = Vector2(80, 80)
	preview.z_index = 100
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var tier_colors = [Color.GRAY, Color.GREEN, Color.GOLD, Color.ORANGE_RED]
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	style.set_border_width_all(2)
	style.border_color = tier_colors[clamp(tier, 0, 3)]
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
	name_lbl.text = statue_data.get("display_name") if "display_name" in statue_data else "Unknown"
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)
	
	return preview


func _process(_delta: float) -> void:
	if is_dragging and drag_preview:
		drag_preview.global_position = get_viewport().get_mouse_position() - Vector2(40, 40)


func _input(event: InputEvent) -> void:
	if not is_dragging:
		return
	
	if event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_drop_statue()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_drag()
			visible = true
			refresh()


func _try_drop_statue() -> void:
	if is_dragging and dragged_statue:
		var mouse_pos = get_viewport().get_mouse_position()
		drop_requested.emit(dragged_statue, dragged_tier, mouse_pos)
		print("[Inventory] Drop requested at: %s" % mouse_pos)


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
		dragged_statue = null
		dragged_tier = 0
		if drag_preview:
			drag_preview.queue_free()
			drag_preview = null
		drag_ended.emit()


## Button handlers
func _on_place_statue(statue_data: Resource, tier: int) -> void:
	place_statue_requested.emit(statue_data, tier)


func _on_tab_pressed(tab: Tab) -> void:
	current_tab = tab
	_update_tab_styles()
	refresh()


func _on_close_pressed() -> void:
	close()


func _clear_items() -> void:
	for child in items_grid.get_children():
		child.queue_free()


func _update_tab_styles() -> void:
	statues_tab.modulate = Color(0.7, 0.7, 0.7, 1)
	equipment_tab.modulate = Color(0.7, 0.7, 0.7, 1)
	
	match current_tab:
		Tab.STATUES:
			statues_tab.modulate = Color(1, 1, 1, 1)
		Tab.EQUIPMENT:
			equipment_tab.modulate = Color(1, 1, 1, 1)


func _on_inventory_changed() -> void:
	if visible:
		refresh()


func _get_max_equipment_slots(tier: int) -> int:
	match tier:
		0: return 1  # ★ Base
		1: return 2  # ★★ Enhanced
		2: return 3  # ★★★ Awakened
		3: return 4  # ★★★★ Divine
	return 1
