extends PanelContainer

## Shop Item Card - Individual item display in shop

signal purchased()

var item_data: Dictionary = {}
var item_cost: int = 0
var _pending_data: Dictionary = {}

@onready var icon: TextureRect = $VBox/Icon
@onready var name_label: Label = $VBox/NameLabel
@onready var type_label: Label = $VBox/TypeLabel
@onready var cost_label: Label = $VBox/CostLabel
@onready var buy_button: Button = $VBox/BuyButton


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	# Apply pending data if setup was called before ready
	if _pending_data.size() > 0:
		_apply_setup(_pending_data)


func setup(data: Dictionary) -> void:
	item_data = data
	item_cost = data.get("cost", 0)
	
	# If not ready yet, defer the visual setup
	if not is_node_ready():
		_pending_data = data
		return
	
	_apply_setup(data)


func _apply_setup(data: Dictionary) -> void:
	# Safety check
	if not icon or not name_label or not type_label or not cost_label:
		return
	
	match data.type:
		"statue":
			_setup_statue(data.resource)
		"artifact":
			_setup_artifact(data.resource)
		"consumable":
			# Pass resource if available, otherwise fall back to data dict
			if data.resource:
				_setup_consumable(data.resource)
			else:
				_setup_consumable(data.get("data", {}))
		"upgrade":
			_setup_upgrade(data.resource)
	
	# Show price with discount indicator if applicable
	if data.get("discounted", false) and data.has("original_cost"):
		cost_label.text = "🏷️ %d (was %d)" % [item_cost, data.original_cost]
		cost_label.modulate = Color(0.4, 1.0, 0.4)  # Green for discount
	else:
		cost_label.text = "💰 %d" % item_cost
	update_affordability(GameManager.gold)


func _setup_statue(statue: Resource) -> void:
	if not statue:
		return
	# TODO: Replace with actual statue portrait textures
	# For now, just show the name
	if icon and statue.portrait_texture:
		icon.texture = statue.portrait_texture
	if name_label:
		name_label.text = statue.display_name
	
	# Show rarity
	var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	if type_label:
		type_label.text = "Statue • %s" % rarity_names[statue.rarity]
		type_label.modulate = _get_rarity_color(statue.rarity)
	
	# Add tooltip with stats
	tooltip_text = "%s\n\nDMG: %.0f | SPD: %.2f | RNG: %.0f\n%s" % [
		statue.display_name,
		statue.base_damage,
		statue.attack_speed,
		statue.attack_range,
		statue.ability_name if statue.ability_name else ""
	]
	
	# Rarity border color
	var stylebox = StyleBoxFlat.new()
	stylebox.set_border_width_all(2)
	stylebox.border_color = _get_rarity_color(statue.rarity)
	stylebox.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	stylebox.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", stylebox)


func _setup_artifact(artifact: Resource) -> void:
	if not artifact:
		return
	# TODO: Replace with actual artifact icon textures
	if icon and artifact.icon_texture:
		icon.texture = artifact.icon_texture
	if name_label:
		name_label.text = artifact.display_name
	
	var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	if type_label:
		type_label.text = "Artifact • %s" % rarity_names[artifact.rarity]
		type_label.modulate = _get_rarity_color(artifact.rarity)
	
	# Add tooltip with effect description
	tooltip_text = "%s\n\n%s" % [artifact.display_name, artifact.description]
	
	var stylebox = StyleBoxFlat.new()
	stylebox.set_border_width_all(2)
	stylebox.border_color = Color(0.6, 0.3, 0.8)  # Purple for artifacts
	stylebox.bg_color = Color(0.18, 0.12, 0.22, 0.9)
	stylebox.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", stylebox)


func _setup_consumable(data: Variant) -> void:
	# Handle both Dictionary (old) and Resource (new) data
	var item_name: String = ""
	var item_desc: String = ""
	
	if data is Resource:
		item_name = data.display_name if data.display_name else "Consumable"
		item_desc = data.description if data.description else ""
	else:
		item_name = data.get("name", "Consumable")
		item_desc = data.get("desc", "")
	
	if name_label:
		name_label.text = item_name
	if type_label:
		type_label.text = "Single Use"
		type_label.modulate = Color(0.4, 0.8, 0.4)
	
	# Add tooltip
	tooltip_text = "%s\n\n%s" % [item_name, item_desc]
	
	var stylebox = StyleBoxFlat.new()
	stylebox.set_border_width_all(2)
	stylebox.border_color = Color(0.4, 0.8, 0.4)  # Green for consumables
	stylebox.bg_color = Color(0.12, 0.18, 0.12, 0.9)
	stylebox.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", stylebox)


func _setup_upgrade(upgrade: Resource) -> void:
	if not upgrade:
		return
	
	if name_label:
		name_label.text = upgrade.display_name if upgrade.display_name else "Upgrade"
	
	if type_label:
		type_label.text = "⬆️ Statue Upgrade"
		type_label.modulate = Color(1.0, 0.6, 0.2)  # Orange
	
	# Add tooltip with effect
	var effect_desc = upgrade.get_effect_description() if upgrade.has_method("get_effect_description") else upgrade.description
	tooltip_text = "%s\n\n%s" % [upgrade.display_name, effect_desc]
	
	var stylebox = StyleBoxFlat.new()
	stylebox.set_border_width_all(2)
	stylebox.border_color = Color(1.0, 0.6, 0.2)  # Orange for upgrades
	stylebox.bg_color = Color(0.22, 0.16, 0.10, 0.9)
	stylebox.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", stylebox)


func _get_rarity_color(rarity: int) -> Color:
	var colors = [
		Color.GRAY,      # Common
		Color.GREEN,     # Uncommon
		Color.BLUE,      # Rare
		Color.PURPLE,    # Epic
		Color.ORANGE     # Legendary
	]
	return colors[clamp(rarity, 0, 4)]


func update_affordability(gold: int) -> void:
	var can_afford = gold >= item_cost
	if buy_button:
		buy_button.disabled = not can_afford
	
	if can_afford:
		modulate = Color.WHITE
		# Don't override discount green color
		if cost_label and item_data.get("discounted", false):
			cost_label.modulate = Color(0.4, 1.0, 0.4)  # Keep green for discount
		elif cost_label:
			cost_label.modulate = Color.WHITE
	else:
		modulate = Color(0.6, 0.6, 0.6)
		if cost_label:
			cost_label.modulate = Color.RED


func _on_buy_pressed() -> void:
	if GameManager.can_afford(item_cost):
		purchased.emit()
