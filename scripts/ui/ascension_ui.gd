extends CanvasLayer

## Ascension UI Controller
## Allows player to select 3 matching statues to upgrade them into one evolved statue
## Now supports selecting from BOTH inventory AND placed statues on the field

signal ascension_completed(evolved_statue: Resource, tier: int)
signal ascension_cancelled()

# References
@onready var panel: Panel = $Control/Panel
@onready var slots_container: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/SlotsContainer
@onready var slot1: PanelContainer = $Control/Panel/MarginContainer/VBoxContainer/SlotsContainer/Slot1
@onready var slot2: PanelContainer = $Control/Panel/MarginContainer/VBoxContainer/SlotsContainer/Slot2
@onready var slot3: PanelContainer = $Control/Panel/MarginContainer/VBoxContainer/SlotsContainer/Slot3
@onready var result_container: VBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/ResultContainer
@onready var result_icon: TextureRect = $Control/Panel/MarginContainer/VBoxContainer/ResultContainer/ResultIcon
@onready var result_label: Label = $Control/Panel/MarginContainer/VBoxContainer/ResultContainer/ResultLabel
@onready var ascend_button: Button = $Control/Panel/MarginContainer/VBoxContainer/ButtonsContainer/AscendButton
@onready var cancel_button: Button = $Control/Panel/MarginContainer/VBoxContainer/ButtonsContainer/CancelButton
@onready var status_label: Label = $Control/Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var inventory_scroll: ScrollContainer = $Control/Panel/MarginContainer/VBoxContainer/InventoryScroll
@onready var inventory_grid: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/InventoryScroll/InventoryGrid

# Slot data - now stores dictionaries with source info: {"data": Resource, "source": "inventory"|"field", "node": Node (if from field)}
var selected_statues: Array = [null, null, null]
var current_selecting_slot: int = -1

func _ready() -> void:
	ascend_button.pressed.connect(_on_ascend_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Connect slot buttons
	slot1.gui_input.connect(_on_slot_clicked.bind(0))
	slot2.gui_input.connect(_on_slot_clicked.bind(1))
	slot3.gui_input.connect(_on_slot_clicked.bind(2))
	
	visible = false
	_update_ui()


func open() -> void:
	visible = true
	_clear_slots()
	_populate_all_statues()
	_update_ui()


func close() -> void:
	visible = false
	_clear_slots()


func _clear_slots() -> void:
	selected_statues = [null, null, null]
	current_selecting_slot = -1
	_update_slot_visuals()


func _populate_all_statues() -> void:
	# Clear existing items
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Get statues from INVENTORY
	var inventory_statues = GameManager.get_inventory_items("statues")
	
	for entry in inventory_statues:
		var item_data = entry["data"]
		var count = entry["count"]
		
		if count > 0:
			var card = _create_inventory_card(item_data, count, "inventory")
			if card:
				inventory_grid.add_child(card)
	
	# Get statues from FIELD (placed statues)
	# Group by statue type and tier
	var placed_groups: Dictionary = {}  # key: "statue_id_tier" -> Array of nodes
	for statue in GameManager.placed_statues:
		if statue and statue.statue_data:
			var key = "%s_%d" % [statue.statue_data.id, statue.evolution_tier]
			if not placed_groups.has(key):
				placed_groups[key] = []
			placed_groups[key].append(statue)
	
	# Create cards for placed statues
	for key in placed_groups:
		var statues_arr = placed_groups[key]
		if statues_arr.size() > 0:
			var first_statue = statues_arr[0]
			var card = _create_placed_card(first_statue.statue_data, statues_arr.size(), statues_arr, first_statue.evolution_tier)
			if card:
				inventory_grid.add_child(card)


func _create_inventory_card(item_data: Resource, count: int, source: String) -> Control:
	if not item_data:
		return null
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(100, 120)
	
	# Style - different colors for inventory vs field
	var stylebox = StyleBoxFlat.new()
	if source == "inventory":
		stylebox.bg_color = Color(0.2, 0.25, 0.3, 0.9)  # Blue-ish for inventory
		stylebox.border_color = Color(0.4, 0.5, 0.6)
	else:
		stylebox.bg_color = Color(0.25, 0.3, 0.2, 0.9)  # Green-ish for field
		stylebox.border_color = Color(0.5, 0.6, 0.4)
	stylebox.set_border_width_all(2)
	stylebox.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", stylebox)
	
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
	
	# Source label
	var source_label = Label.new()
	source_label.text = "📦 Inventory" if source == "inventory" else "🏰 Field"
	source_label.add_theme_font_size_override("font_size", 8)
	source_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(source_label)
	
	# Portrait
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(50, 50)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var portrait_tex = item_data.get("portrait_texture")
	if portrait_tex:
		portrait.texture = portrait_tex
	inner_vbox.add_child(portrait)
	
	# Name with count
	var name_label = Label.new()
	var display_name = item_data.get("display_name")
	if not display_name:
		display_name = str(item_data)
	name_label.text = "%s x%d" % [display_name, count]
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(name_label)
	
	# Select button
	var select_btn = Button.new()
	select_btn.text = "Select"
	select_btn.add_theme_font_size_override("font_size", 10)
	select_btn.pressed.connect(_on_source_item_selected.bind(item_data, "inventory", null))
	inner_vbox.add_child(select_btn)
	
	return card


## Create a card for PLACED statues on the field
func _create_placed_card(item_data: Resource, count: int, statue_nodes: Array, tier: int) -> Control:
	if not item_data:
		return null
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(100, 120)
	
	# Style - green-ish for field
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.25, 0.3, 0.2, 0.9)
	stylebox.set_border_width_all(2)
	stylebox.border_color = Color(0.5, 0.6, 0.4)
	stylebox.set_corner_radius_all(8)
	card.add_theme_stylebox_override("panel", stylebox)
	
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
	
	# Source label with tier
	var source_label = Label.new()
	var tier_name = EvolutionManager.get_tier_name(tier) if tier > 0 else ""
	source_label.text = "🏰 Field" + (" ★" + str(tier + 1) if tier > 0 else "")
	source_label.add_theme_font_size_override("font_size", 8)
	source_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	source_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(source_label)
	
	# Portrait
	var portrait = TextureRect.new()
	portrait.custom_minimum_size = Vector2(50, 50)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	var portrait_tex = item_data.get("portrait_texture")
	if portrait_tex:
		portrait.texture = portrait_tex
	inner_vbox.add_child(portrait)
	
	# Name with count
	var name_label = Label.new()
	var display_name = item_data.get("display_name")
	if not display_name:
		display_name = str(item_data)
	name_label.text = "%s x%d" % [display_name, count]
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(name_label)
	
	# Select button
	var select_btn = Button.new()
	select_btn.text = "Select"
	select_btn.add_theme_font_size_override("font_size", 10)
	# Pass the array of statue nodes for field statues
	select_btn.pressed.connect(_on_source_item_selected.bind(item_data, "field", statue_nodes))
	inner_vbox.add_child(select_btn)
	
	return card


func _on_slot_clicked(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# If slot has something, clear it
		if selected_statues[slot_index] != null:
			selected_statues[slot_index] = null
			_update_slot_visuals()
			_update_ui()
		else:
			# Set this as the current selecting slot
			current_selecting_slot = slot_index
			_highlight_slot(slot_index)


## Unified selection handler for both inventory and field statues
func _on_source_item_selected(item_data: Resource, source: String, nodes: Variant) -> void:
	# Find an empty slot or use current_selecting_slot
	var target_slot = -1
	
	if current_selecting_slot >= 0 and selected_statues[current_selecting_slot] == null:
		target_slot = current_selecting_slot
	else:
		# Find first empty slot
		for i in range(3):
			if selected_statues[i] == null:
				target_slot = i
				break
	
	if target_slot < 0:
		status_label.text = "All slots are full! Click a slot to clear it."
		return
	
	# Count how many we have from this source
	var available_count = 0
	var node_to_use: Node = null
	
	if source == "inventory":
		available_count = GameManager.get_inventory_count(item_data, "statues")
	else:  # field
		if nodes is Array:
			available_count = nodes.size()
	
	# Count how many already selected from this same source
	var already_selected_from_source = 0
	var used_nodes: Array = []
	for s in selected_statues:
		if s != null and s.get("data") != null:
			if s.get("data").get("id") == item_data.get("id") and s.get("source") == source:
				already_selected_from_source += 1
				if s.get("node") != null:
					used_nodes.append(s.get("node"))
	
	if already_selected_from_source >= available_count:
		status_label.text = "Not enough statues from this source!"
		return
	
	# For field statues, pick the next unused node
	if source == "field" and nodes is Array:
		for n in nodes:
			if n not in used_nodes:
				node_to_use = n
				break
	
	# Add to slot with source info
	selected_statues[target_slot] = {
		"data": item_data,
		"source": source,
		"node": node_to_use  # Only non-null for field statues
	}
	current_selecting_slot = -1
	_update_slot_visuals()
	_update_ui()


func _update_slot_visuals() -> void:
	var slots = [slot1, slot2, slot3]
	
	for i in range(3):
		var slot = slots[i]
		var slot_entry = selected_statues[i]
		
		# Clear slot content
		for child in slot.get_children():
			child.queue_free()
		
		# Create new content
		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.add_theme_constant_override("separation", 2)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_child(vbox)
		
		if slot_entry and slot_entry.get("data"):
			var statue_data = slot_entry.get("data")
			var source = slot_entry.get("source", "inventory")
			
			# Source indicator
			var source_lbl = Label.new()
			source_lbl.text = "📦" if source == "inventory" else "🏰"
			source_lbl.add_theme_font_size_override("font_size", 8)
			source_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(source_lbl)
			
			# Show portrait
			var portrait = TextureRect.new()
			portrait.custom_minimum_size = Vector2(40, 40)
			portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var portrait_tex = statue_data.get("portrait_texture")
			if portrait_tex:
				portrait.texture = portrait_tex
			vbox.add_child(portrait)
			
			var name_lbl = Label.new()
			name_lbl.text = statue_data.get("display_name") if statue_data.get("display_name") else "?"
			name_lbl.add_theme_font_size_override("font_size", 8)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(name_lbl)
		else:
			var empty_label = Label.new()
			empty_label.text = "Empty\n(Click)"
			empty_label.add_theme_font_size_override("font_size", 12)
			empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox.add_child(empty_label)


func _highlight_slot(slot_index: int) -> void:
	var slots = [slot1, slot2, slot3]
	for i in range(3):
		var slot = slots[i]
		if i == slot_index:
			slot.modulate = Color(0.5, 1.0, 0.5)  # Green highlight
		else:
			slot.modulate = Color.WHITE


func _update_ui() -> void:
	# Check if all 3 slots have the same statue type
	var can_ascend = _check_can_ascend()
	ascend_button.disabled = not can_ascend
	
	# Reset slot highlights
	var slots = [slot1, slot2, slot3]
	for slot in slots:
		slot.modulate = Color.WHITE
	
	if can_ascend:
		result_container.visible = true
		var base_data = selected_statues[0].get("data")
		
		# Get the evolved version (handles special sprites like Huntress)
		var result_data = _get_evolved_statue_data(base_data)
		
		var portrait_tex = result_data.get("portrait_texture")
		if portrait_tex:
			result_icon.texture = portrait_tex
		var tier_name = EvolutionManager.get_tier_name(1)  # Evolving to tier 1 (Enhanced)
		result_label.text = "%s → %s" % [base_data.get("display_name"), tier_name]
		status_label.text = "✅ Ready to Ascend!"
		status_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		result_container.visible = false
		var filled_count = 0
		for s in selected_statues:
			if s != null:
				filled_count += 1
		
		if filled_count == 0:
			status_label.text = "Select 3 matching statues (inventory OR field)"
		elif filled_count < 3:
			status_label.text = "Select %d more statue(s)" % (3 - filled_count)
		else:
			status_label.text = "⚠️ Statues must all be the same type!"
		status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))


func _check_can_ascend() -> bool:
	# All 3 slots must be filled
	for s in selected_statues:
		if s == null or s.get("data") == null:
			return false
	
	# All 3 must be the same type
	var first_data = selected_statues[0].get("data")
	var first_id = first_data.get("id") if first_data else null
	if first_id == null:
		return false
	
	for i in range(1, 3):
		var entry_data = selected_statues[i].get("data")
		if entry_data == null or entry_data.get("id") != first_id:
			return false
	
	return true


## Helper to get evolved statue data (handling special overrides)
func _get_evolved_statue_data(base_data: Resource) -> Resource:
	if not base_data:
		return null
	
	var statue_id = base_data.get("id")
	
	# SPECIAL CASE: Huntress/Archer Awaken Sprite
	if statue_id == "huntress":
		# Duplicate the resource to modify it without affecting the original
		var items = GameManager.get_inventory_items("statues")
		# Check if we already have an "Awakened Huntress" resource in inventory to reuse?
		# For now, just create a new runtime one.
		
		var result = base_data.duplicate()
		# Update ID so it doesn't stack with base version
		result.id = statue_id + "_awaken"
		
		var awaken_tex = load("res://assets/classes/archer_awaken.png")
		if awaken_tex:
			result.portrait_texture = awaken_tex
			result.display_name = "Awakened " + base_data.get("display_name")
		return result
	
	# Default: return base data (statue becomes Tier 1 but uses same base resource)
	# Logic elsewhere handles the +stats from tier
	return base_data


func _on_ascend_pressed() -> void:
	if not _check_can_ascend():
		return
	
	var base_statue_data = selected_statues[0].get("data")
	
	# Remove statues from their respective sources
	var arena = null
	for i in range(3):
		var entry = selected_statues[i]
		var source = entry.get("source")
		var node = entry.get("node")
		
		if source == "inventory":
			# Remove from inventory
			GameManager.remove_from_inventory(base_statue_data, "statues")
		else:  # field
			# Remove placed statue from field
			if node and is_instance_valid(node):
				if not arena:
					arena = node.arena
				arena.free_cell(node.grid_position)
				GameManager.unregister_statue(node)
				node.queue_free()
	
	# Determine result data (handle awakened sprites)
	var evolved_data = _get_evolved_statue_data(base_statue_data)
	
	# Add 1 evolved statue to inventory with tier=1 (Enhanced)
	GameManager.add_to_inventory(evolved_data, "statues", 1)
	
	print("[Ascension] Upgraded 3x %s into 1x %s! (combined from inventory + field)" % [base_statue_data.get("display_name"), evolved_data.get("display_name")])
	
	# Emit signal
	ascension_completed.emit(evolved_data, 1)
	
	# Refresh and close
	GameManager.inventory_changed.emit()
	close()


func _on_cancel_pressed() -> void:
	ascension_cancelled.emit()
	close()
