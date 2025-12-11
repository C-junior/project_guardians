extends CanvasLayer

## Statue Selection UI Controller
## Displays unlocked statues for player to choose their starting guardian

signal statue_selected(statue_data: Resource)
signal back_to_menu()

@onready var statues_grid: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/ScrollContainer/StatuesGrid
@onready var confirm_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/ConfirmButton
@onready var back_button: Button = $Control/Panel/MarginContainer/VBoxContainer/Footer/BackButton

var selected_statue: Resource = null
var statue_cards: Array[Control] = []

# Preload the shop item card scene for displaying statues
const STATUE_CARD_SCENE = preload("res://scenes/ui/shop_item_card.tscn")


func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)
	confirm_button.disabled = true


func open() -> void:
	visible = true
	selected_statue = null
	confirm_button.disabled = true
	_populate_statues()


func close() -> void:
	visible = false
	_clear_statues()


func _populate_statues() -> void:
	_clear_statues()
	
	var unlocked_statues = GameManager.get_unlocked_statue_resources()
	
	if unlocked_statues.is_empty():
		push_warning("[StatueSelection] No unlocked statues found!")
		return
	
	for statue_data in unlocked_statues:
		var card = _create_statue_card(statue_data)
		if card:
			statues_grid.add_child(card)
			statue_cards.append(card)


func _create_statue_card(statue_data: Resource) -> Control:
	if not statue_data:
		return null
	
	# Create a custom card for selection
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 300)
	card.name = "StatueCard_%s" % statue_data.id
	
	# Store reference to statue data
	card.set_meta("statue_data", statue_data)
	
	# Main container
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	card.add_child(vbox)
	
	# Margin
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 8)
	margin.add_child(inner_vbox)
	
	# Portrait
	var portrait_rect = TextureRect.new()
	portrait_rect.custom_minimum_size = Vector2(180, 140)
	portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if statue_data.portrait_texture:
		portrait_rect.texture = statue_data.portrait_texture
	inner_vbox.add_child(portrait_rect)
	
	# Name
	var name_label = Label.new()
	name_label.text = statue_data.display_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(name_label)
	
	# Rarity
	var rarity_label = Label.new()
	var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	rarity_label.text = rarity_names[statue_data.rarity]
	rarity_label.add_theme_font_size_override("font_size", 14)
	rarity_label.add_theme_color_override("font_color", statue_data.get_rarity_color())
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(rarity_label)
	
	# Stats preview
	var stats_label = Label.new()
	stats_label.text = "⚔️ %d  |  🎯 %.1f/s" % [int(statue_data.base_damage), statue_data.attack_speed]
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(stats_label)
	
	# Ability hint
	var ability_label = Label.new()
	ability_label.text = "🔮 " + statue_data.ability_name
	ability_label.add_theme_font_size_override("font_size", 11)
	ability_label.add_theme_color_override("font_color", Color(0.5, 0.7, 1, 1))
	ability_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner_vbox.add_child(ability_label)
	
	# Selection button
	var select_btn = Button.new()
	select_btn.text = "Select"
	select_btn.custom_minimum_size = Vector2(0, 40)
	select_btn.pressed.connect(_on_statue_card_selected.bind(card, statue_data))
	inner_vbox.add_child(select_btn)
	
	return card


func _clear_statues() -> void:
	for card in statue_cards:
		if is_instance_valid(card):
			card.queue_free()
	statue_cards.clear()


func _on_statue_card_selected(card: Control, statue_data: Resource) -> void:
	selected_statue = statue_data
	confirm_button.disabled = false
	
	# Update visual selection state
	for c in statue_cards:
		if c == card:
			# Highlight selected
			c.modulate = Color(1.2, 1.2, 0.8, 1)
		else:
			# Dim others
			c.modulate = Color(0.7, 0.7, 0.7, 1)
	
	print("[StatueSelection] Selected: %s" % statue_data.display_name)


func _on_confirm_pressed() -> void:
	if selected_statue:
		GameManager.selected_starting_statue = selected_statue
		statue_selected.emit(selected_statue)
		close()


func _on_back_pressed() -> void:
	back_to_menu.emit()
	close()
