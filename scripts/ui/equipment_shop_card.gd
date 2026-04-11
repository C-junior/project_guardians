extends PanelContainer

## EquipmentShopCard - Card para runas e estátuas na shop MVP
## Exibe informações do item e botão de compra

signal purchased()

var item_data: Dictionary = {}
var item_cost: int = 0

@onready var icon_rect: TextureRect = $VBoxContainer/IconContainer/IconRect
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var type_label: Label = $VBoxContainer/TypeLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var cost_label: Label = $VBoxContainer/CostLabel
@onready var buy_button: Button = $VBoxContainer/BuyButton


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)


func setup(data: Dictionary) -> void:
	item_data = data
	item_cost = data.get("cost", 0)
	
	if data.type == "equipment":
		_setup_equipment_card(data.resource)
	elif data.type == "statue":
		_setup_statue_card(data.resource, data.rarity)
	
	cost_label.text = "💰 %d" % item_cost
	update_affordability(GameManager.gold)


func _setup_equipment_card(equipment: EquipmentData) -> void:
	if not equipment:
		return
	
	# Name
	name_label.text = equipment.display_name
	
	# Type/Rarity
	type_label.text = "%s • %s" % [equipment.get_rarity_name(), "Rune"]
	type_label.modulate = equipment.get_rarity_color()
	
	# Stats
	stats_label.text = equipment.get_stat_summary()
	
	# Icon (placeholder - runas não têm ícones ainda)
	if equipment.icon_texture:
		icon_rect.texture = equipment.icon_texture
	else:
		# Generate colored square based on equipment type
		var placeholder = _generate_rune_icon(equipment)
		icon_rect.texture = placeholder
	
	# Border style
	var stylebox = StyleBoxFlat.new()
	stylebox.set_border_width_all(3)
	stylebox.border_color = equipment.get_rarity_color()
	stylebox.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	stylebox.set_corner_radius_all(10)
	add_theme_stylebox_override("panel", stylebox)
	
	# Tooltip
	var tooltip_text = "%s\n\n%s\n\n%s" % [
		equipment.display_name,
		equipment.description,
		equipment.get_stat_summary()
	]
	self.tooltip_text = tooltip_text
	
	# Buy button text
	buy_button.text = "⚒️ Buy Rune"


func _setup_statue_card(statue_data: Resource, rarity: int) -> void:
	if not statue_data:
		return
	
	var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	var rarity_colors = [
		Color.GRAY, Color.GREEN, Color.BLUE, Color.PURPLE, Color.ORANGE
	]
	var rarity_mults = [1.0, 1.15, 1.30, 1.50, 1.80]
	
	# Name
	var display_name = statue_data.get("display_name") if "display_name" in statue_data else "Unknown Statue"
	name_label.text = display_name
	
	# Type/Rarity
	type_label.text = "%s • Statue" % rarity_names[rarity]
	type_label.modulate = rarity_colors[rarity]
	
	# Stats
	var base_dmg = statue_data.get("base_damage") if "base_damage" in statue_data else 0
	var base_spd = statue_data.get("attack_speed") if "attack_speed" in statue_data else 0
	var base_rng = statue_data.get("attack_range") if "attack_range" in statue_data else 0
	var mult = rarity_mults[rarity]
	
	stats_label.text = "DMG: %.0f | SPD: %.2f | RNG: %.0f" % [
		base_dmg * mult,
		base_spd,
		base_rng
	]
	
	# Icon
	var portrait = statue_data.get("portrait_texture") if "portrait_texture" in statue_data else null
	var icon = statue_data.get("icon") if "icon" in statue_data else null
	if portrait:
		icon_rect.texture = portrait
	elif icon:
		icon_rect.texture = icon
	else:
		# Placeholder colored square
		icon_rect.texture = _generate_statue_icon(rarity)
	
	# Border style
	var stylebox = StyleBoxFlat.new()
	stylebox.set_border_width_all(3)
	stylebox.border_color = rarity_colors[rarity]
	stylebox.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	stylebox.set_corner_radius_all(10)
	add_theme_stylebox_override("panel", stylebox)
	
	# Tooltip
	var ability_name = statue_data.get("ability_name") if "ability_name" in statue_data else ""
	var ability_desc = statue_data.get("ability_description") if "ability_description" in statue_data else ""
	var desc = statue_data.get("description") if "description" in statue_data else ""
	
	var tooltip_parts = [display_name, ""]
	if ability_name:
		tooltip_parts.append("⚔️ %s" % ability_name)
		tooltip_parts.append(ability_desc)
		tooltip_parts.append("")
	if desc:
		tooltip_parts.append(desc)
	
	self.tooltip_text = "\n".join(tooltip_parts)
	
	# Buy button text
	buy_button.text = "🗿 Buy Statue"


func _generate_rune_icon(equipment: EquipmentData) -> ImageTexture:
	# Generate a colored square based on equipment stats
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	# Color based on primary stat
	var color = Color.WHITE
	if equipment.bonus_damage_percent > 0:
		color = Color(1.0, 0.5, 0.2)  # Orange/red for damage
	elif equipment.bonus_range > 0:
		color = Color(0.3, 0.7, 1.0)  # Blue for range
	elif equipment.bonus_attack_speed > 0:
		color = Color(1.0, 1.0, 0.3)  # Yellow for speed
	elif equipment.bonus_crit_chance > 0:
		color = Color(1.0, 0.8, 0.2)  # Gold for crit
	elif equipment.bonus_threat > 0:
		color = Color(0.8, 0.3, 0.3)  # Red for threat
	else:
		color = Color(0.5, 0.8, 1.0)  # Cyan for utility
	
	img.fill(color)
	
	# Add border
	for x in range(64):
		for y in range(64):
			if x < 4 or x > 59 or y < 4 or y > 59:
				img.set_pixel(x, y, Color.DARK_GRAY)
	
	return ImageTexture.create_from_image(img)


func _generate_statue_icon(rarity: int) -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	var rarity_colors = [
		Color.GRAY, Color.GREEN, Color.BLUE, Color.PURPLE, Color.ORANGE
	]
	
	img.fill(rarity_colors[rarity].darkened(0.5))
	
	# Border
	for x in range(64):
		for y in range(64):
			if x < 4 or x > 59 or y < 4 or y > 59:
				img.set_pixel(x, y, Color.WHITE)
	
	return ImageTexture.create_from_image(img)


func update_affordability(gold: int) -> void:
	var can_afford = gold >= item_cost
	buy_button.disabled = not can_afford
	
	if can_afford:
		modulate = Color.WHITE
		cost_label.modulate = Color.WHITE
	else:
		modulate = Color(0.6, 0.6, 0.6)
		cost_label.modulate = Color.RED


func _on_buy_pressed() -> void:
	if GameManager.can_afford(item_cost):
		purchased.emit()
