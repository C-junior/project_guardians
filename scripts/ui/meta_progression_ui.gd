extends CanvasLayer

## Aether Sanctum - Meta-Progression UI
## Between-run screen for spending Aether Essence on permanent upgrades and unlocks

signal sanctum_closed()

@onready var essence_label: Label = $Panel/EssenceLabel
@onready var unlocks_container: VBoxContainer = $Panel/ScrollContainer/UnlocksContainer
@onready var upgrades_container: VBoxContainer = $Panel/UpgradesPanel/UpgradesContainer
@onready var close_button: Button = $Panel/CloseButton

# Permanent upgrade definitions
var permanent_upgrades = [
	{"id": "starting_gold", "name": "Starting Coffers", "desc": "+25 starting gold", "cost": 200, "max": 5, "value": 25},
	{"id": "crit_chance", "name": "Critical Eye", "desc": "+2% base crit chance", "cost": 250, "max": 3, "value": 0.02},
	{"id": "crystal_hp", "name": "Crystal Fortitude", "desc": "+15 crystal max HP", "cost": 300, "max": 4, "value": 15},
	{"id": "wave_gold", "name": "Prosperity", "desc": "+5 gold per wave", "cost": 350, "max": 3, "value": 5},
]

# Unlockable content (statues/artifacts/blessings not yet unlocked)
var statue_unlocks = [
	{"id": "divine_guardian", "name": "Divine Guardian", "cost": 500},
	{"id": "earthshaker", "name": "Earthshaker", "cost": 500},
	{"id": "shadow_dancer", "name": "Shadow Dancer", "cost": 600},
	{"id": "frost_maiden", "name": "Frost Maiden", "cost": 600},
]


func _ready() -> void:
	visible = false
	if close_button:
		close_button.pressed.connect(_on_close_pressed)


func open() -> void:
	visible = true
	_refresh_ui()


func _refresh_ui() -> void:
	# Update essence display
	if essence_label:
		essence_label.text = "⭐ Aether Essence: %d" % GameManager.aether_essence
	
	# Clear and rebuild unlock buttons
	_build_unlocks()
	_build_upgrades()


func _build_unlocks() -> void:
	if not unlocks_container:
		return
	
	# Clear existing
	for child in unlocks_container.get_children():
		child.queue_free()
	
	# Add statue unlocks
	for unlock in statue_unlocks:
		if unlock.id in GameManager.unlocked_statues:
			continue  # Already unlocked
		
		var btn = _create_unlock_button(unlock, "statue")
		unlocks_container.add_child(btn)
	
	# If all unlocked, show message
	if unlocks_container.get_child_count() == 0:
		var label = Label.new()
		label.text = "All content unlocked! 🎉"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		unlocks_container.add_child(label)


func _build_upgrades() -> void:
	if not upgrades_container:
		return
	
	# Clear existing
	for child in upgrades_container.get_children():
		child.queue_free()
	
	# Add permanent upgrades
	for upgrade in permanent_upgrades:
		var current_level = _get_upgrade_level(upgrade.id)
		var btn = _create_upgrade_button(upgrade, current_level)
		upgrades_container.add_child(btn)


func _create_unlock_button(unlock: Dictionary, type: String) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(280, 50)
	
	var can_afford = GameManager.aether_essence >= unlock.cost
	btn.text = "🔓 %s - %d AE" % [unlock.name, unlock.cost]
	btn.disabled = not can_afford
	
	if can_afford:
		btn.modulate = Color.WHITE
	else:
		btn.modulate = Color(0.6, 0.6, 0.6)
	
	btn.pressed.connect(_on_unlock_pressed.bind(unlock, type))
	return btn


func _create_upgrade_button(upgrade: Dictionary, current_level: int) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(280, 50)
	
	var is_maxed = current_level >= upgrade.max
	var cost = upgrade.cost * (current_level + 1)  # Scaling cost
	var can_afford = GameManager.aether_essence >= cost and not is_maxed
	
	if is_maxed:
		btn.text = "✅ %s (MAX)" % upgrade.name
		btn.disabled = true
		btn.modulate = Color(0.5, 0.8, 0.5)
	else:
		btn.text = "📈 %s [%d/%d] - %d AE" % [upgrade.name, current_level, upgrade.max, cost]
		btn.disabled = not can_afford
		if can_afford:
			btn.modulate = Color.WHITE
		else:
			btn.modulate = Color(0.6, 0.6, 0.6)
	
	btn.tooltip_text = upgrade.desc
	btn.pressed.connect(_on_upgrade_pressed.bind(upgrade))
	return btn


func _get_upgrade_level(upgrade_id: String) -> int:
	# This would read from GameManager's saved upgrade levels
	match upgrade_id:
		"starting_gold":
			return int(GameManager.permanent_gold_bonus / 25)
		"crystal_hp":
			return int((GameManager.crystal_max_health - 100) / 15)
	return 0


func _on_unlock_pressed(unlock: Dictionary, type: String) -> void:
	if GameManager.aether_essence < unlock.cost:
		return
	
	GameManager.aether_essence -= unlock.cost
	
	match type:
		"statue":
			if unlock.id not in GameManager.unlocked_statues:
				GameManager.unlocked_statues.append(unlock.id)
		"artifact":
			if unlock.id not in GameManager.unlocked_artifacts:
				GameManager.unlocked_artifacts.append(unlock.id)
		"blessing":
			if unlock.id not in GameManager.unlocked_blessings:
				GameManager.unlocked_blessings.append(unlock.id)
	
	GameManager.save_meta_progression()
	_refresh_ui()
	print("[Sanctum] Unlocked %s: %s" % [type, unlock.name])


func _on_upgrade_pressed(upgrade: Dictionary) -> void:
	var current_level = _get_upgrade_level(upgrade.id)
	if current_level >= upgrade.max:
		return
	
	var cost = upgrade.cost * (current_level + 1)
	if GameManager.aether_essence < cost:
		return
	
	GameManager.aether_essence -= cost
	
	# Apply upgrade
	match upgrade.id:
		"starting_gold":
			GameManager.permanent_gold_bonus += int(upgrade.value)
		"crystal_hp":
			GameManager.crystal_max_health += int(upgrade.value)
		"wave_gold":
			# Would need to add this to GameManager
			pass
		"crit_chance":
			# Would need to add base_crit_bonus to GameManager
			pass
	
	GameManager.save_meta_progression()
	_refresh_ui()
	print("[Sanctum] Upgraded %s to level %d" % [upgrade.name, current_level + 1])


func _on_close_pressed() -> void:
	visible = false
	sanctum_closed.emit()
