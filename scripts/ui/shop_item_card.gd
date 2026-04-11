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
		"equipment":
			_setup_equipment(data.resource)
	
	# Show price with discount indicator if applicable
	if data.get("discounted", false) and data.has("original_cost"):
		cost_label.text = "🏷️ %d (was %d)" % [item_cost, data.original_cost]
		cost_label.modulate = Color(0.4, 1.0, 0.4)  # Green for discount
	else:
		cost_label.text = "💰 %d" % item_cost
	update_affordability(GameManager.gold)


func _setup_equipment(equipment: Resource) -> void:
	if not equipment:
		return
	
	if name_label:
		name_label.text = equipment.display_name
		
	# Placeholder icon if none provided (for now, runas don't have icons defined in EquipmentData, so we skip or use a generic one)
	if icon:
		icon.texture = null # Could generate a color block or something
	
	var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	var rarity = equipment.rarity if "rarity" in equipment else 0
	
	if type_label:
		var extra = " (Mergeable)" if getattr(equipment, "is_mergeable", false) else ""
		var tier = getattr(equipment, "item_tier", 0)
		var tier_str = "T" + str(tier+1) if tier > 0 else "Base"
		type_label.text = "Rune [%s] • %s%s" % [tier_str, rarity_names[rarity], extra]
		type_label.modulate = _get_rarity_color(rarity)
		
	# Build tooltip for stats
	var tt = equipment.display_name + "\n\n"
	if "description" in equipment and equipment.description:
		tt += equipment.description + "\n\n"
	
	var stats = []
	if getattr(equipment, "bonus_damage_flat", 0) > 0: stats.append("+%d DMG" % equipment.bonus_damage_flat)
	if getattr(equipment, "bonus_damage_percent", 0) > 0: stats.append("+%d%% DMG" % int(equipment.bonus_damage_percent * 100))
	if getattr(equipment, "bonus_attack_speed", 0) > 0: stats.append("+%d%% AS" % int(equipment.bonus_attack_speed * 100))
	if getattr(equipment, "bonus_range", 0) > 0: stats.append("+%d Range" % equipment.bonus_range)
	if getattr(equipment, "bonus_crit_chance", 0) > 0: stats.append("+%d%% Crit" % int(equipment.bonus_crit_chance * 100))
	if getattr(equipment, "bonus_threat", 0) > 0: stats.append("+%d Threat" % equipment.bonus_threat)
	
	if stats.size() > 0:
		tt += "Stats: " + ", ".join(stats)
	
	tooltip_text = tt
	
	var stylebox = StyleBoxFlat.new()
	stylebox.set_border_width_all(2)
	stylebox.border_color = _get_rarity_color(rarity)
	stylebox.bg_color = Color(0.1, 0.15, 0.2, 0.9)  # Dark blue-ish for runes
	stylebox.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", stylebox)

func getattr(obj: Object, prop: String, default: Variant) -> Variant:
	if prop in obj:
		return obj.get(prop)
	return default


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
