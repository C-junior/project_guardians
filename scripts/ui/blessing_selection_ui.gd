extends CanvasLayer

## Blessing Selection UI - Choose starting blessing at run start

signal blessing_selected(blessing: Resource)

var blessing_pool: Array = []
var current_choices: Array = []

@onready var panel: PanelContainer = $Control/Panel
@onready var choices_container: HBoxContainer = $Control/Panel/MarginContainer/VBoxContainer/ChoicesContainer
@onready var title_label: Label = $Control/Panel/MarginContainer/VBoxContainer/TitleLabel


func _ready() -> void:
	_load_blessings()
	visible = false


func _load_blessings() -> void:
	var dir = DirAccess.open("res://resources/blessings/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res = load("res://resources/blessings/" + file_name)
				if res:
					blessing_pool.append(res)
			file_name = dir.get_next()
	print("[BlessingUI] Loaded %d blessings" % blessing_pool.size())


func open() -> void:
	visible = true
	_generate_choices()


func close() -> void:
	visible = false


func _generate_choices() -> void:
	# Clear existing
	for child in choices_container.get_children():
		child.queue_free()
	
	current_choices.clear()
	
	# Pick 3 random blessings
	var available = blessing_pool.duplicate()
	available.shuffle()
	
	for i in range(mini(3, available.size())):
		var blessing = available[i]
		current_choices.append(blessing)
		_create_blessing_card(blessing)


func _create_blessing_card(blessing: Resource) -> void:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 250)
	
	# Style
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(0.15, 0.12, 0.2, 0.95)
	stylebox.set_border_width_all(3)
	stylebox.border_color = Color(0.6, 0.4, 0.8)  # Purple
	stylebox.set_corner_radius_all(12)
	card.add_theme_stylebox_override("panel", stylebox)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	card.add_child(vbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	vbox.add_child(margin)
	
	var inner_vbox = VBoxContainer.new()
	inner_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(inner_vbox)
	
	# Name
	var name_label = Label.new()
	name_label.text = blessing.display_name if blessing.display_name else "Blessing"
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	inner_vbox.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = blessing.description if blessing.description else ""
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.custom_minimum_size.y = 80
	inner_vbox.add_child(desc_label)
	
	# Select button
	var select_btn = Button.new()
	select_btn.text = "Choose"
	select_btn.add_theme_font_size_override("font_size", 14)
	select_btn.pressed.connect(_on_blessing_chosen.bind(blessing))
	inner_vbox.add_child(select_btn)
	
	choices_container.add_child(card)


func _on_blessing_chosen(blessing: Resource) -> void:
	GameManager.current_blessing = blessing
	
	# Apply blessing effects
	if blessing.has_method("apply_effects"):
		blessing.apply_effects()
	else:
		# Manual effect application
		if blessing.get("extra_starting_gold") and blessing.extra_starting_gold > 0:
			GameManager.gold += blessing.extra_starting_gold
			print("[Blessing] +%d starting gold" % blessing.extra_starting_gold)
		if blessing.get("crystal_health_bonus") and blessing.crystal_health_bonus > 0:
			var bonus = int(GameManager.crystal_max_health * blessing.crystal_health_bonus)
			GameManager.crystal_max_health += bonus
			GameManager.crystal_health += bonus
			print("[Blessing] Crystal HP +%d" % bonus)
	
	print("[BlessingUI] Chose: %s" % blessing.display_name)
	blessing_selected.emit(blessing)
	close()
