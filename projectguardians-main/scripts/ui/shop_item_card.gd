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
			_setup_consumable(data.get("data", {}))
	
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
	
	var stylebox = StyleBoxFlat.new()
	stylebox.set_border_width_all(2)
	stylebox.border_color = Color(0.6, 0.3, 0.8)  # Purple for artifacts
	stylebox.bg_color = Color(0.18, 0.12, 0.22, 0.9)
	stylebox.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", stylebox)


func _setup_consumable(data: Dictionary) -> void:
	# Consumables use inline data, no texture needed
	if name_label:
		name_label.text = data.get("name", "Consumable")
	if type_label:
		type_label.text = data.get("desc", "")
		type_label.modulate = Color(0.4, 0.8, 0.4)
	
	var stylebox = StyleBoxFlat.new()
	stylebox.set_border_width_all(2)
	stylebox.border_color = Color(0.4, 0.8, 0.4)  # Green for consumables
	stylebox.bg_color = Color(0.12, 0.18, 0.12, 0.9)
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
		if cost_label:
			cost_label.modulate = Color.WHITE
	else:
		modulate = Color(0.6, 0.6, 0.6)
		if cost_label:
			cost_label.modulate = Color.RED


func _on_buy_pressed() -> void:
	if GameManager.can_afford(item_cost):
		purchased.emit()
