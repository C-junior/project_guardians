# 🚀 Plano de Implementação do MVP - Project Guardians
**Data:** 11 de Abril de 2026  
**Engine:** Godot 4.4 (GL Compatibility)  
**Objetivo:** Implementar o MVP Adaptation Slice (Tangy-Style Tactical Defense)

---

## 📋 Resumo do Plano

Este plano detalha **COMO** implementar o MVP do Project Guardians em Godot, seguindo a documentação consolidada em `MVP_DOCUMENTATION.md`.

### Meta Final
Um loop de jogo completo e testável com:
- 8 ondas no mapa "The Sacred Grove"
- 5 estátuas com roles táticos
- Reposicionamento em shop + 1 relocate in-combat
- 6 runas/equipamentos vinculados a estátuas
- Soft aggro e focus indicators
- 1 boss com 2+ fases táticas

---

## 🎯 Fase 1: Reposicionamento (Shop + In-Combat)

### Visão Geral
Permitir ao jogador mover estátuas colocadas durante a shop phase e ter 1 relocate por onda durante combate.

### Tarefas Detalhadas

#### 1.1 Shop-Phase Reposition
**Arquivos:** `scripts/combat/arena.gd`, `scripts/main.gd`

**Implementação:**
```gdscript
# Em arena.gd
func _on_statue_selected_for_move(statue_node):
    # Highlight valid cells
    _highlight_valid_cells()
    # Store statue being moved
    _moving_statue = statue_node
    # Show move cursor
    _show_move_preview()

func _on_grid_cell_clicked(cell_position):
    if _moving_statue and _is_valid_cell(cell_position):
        # Move statue
        _moving_statue.global_position = cell_position
        _moving_statue.grid_position = cell_position
        # Keep all upgrades/equipment (already attached)
        _clear_highlights()
        _moving_statue = null
```

**Passos:**
1. Adicionar estado `is_shop_phase` ao Arena
2. Permitir click em estátua colocada durante shop
3. Implementar drag-to-move ou click-click move
4. Validar que célula destino está vazia
5. Highlight de células válidas (verde) e bloqueadas (vermelho)
6. Manter todos os dados da estátua (upgrades, equipment, evolution tier)

**Teste:**
- Colocar estátua
- Entrar em shop phase
- Selecionar estátua e mover
- Confirmar que upgrades permanecem

---

#### 1.2 In-Combat Relocate (1 charge/onda)
**Arquivos:** `autoload/GameManager.gd`, `scripts/combat/arena.gd`, `scenes/ui/hud.tscn`

**Implementação:**
```gdscript
# Em GameManager.gd
var relocate_charges: int = 1
var max_relocate_charges: int = 1

func use_relocate_charge() -> bool:
    if relocate_charges > 0:
        relocate_charges -= 1
        return true
    return false

func refill_relocate_charges():
    relocate_charges = max_relocate_charges

# Em arena.gd (no início de cada onda)
func _start_wave(wave_number):
    GameManager.refill_relocate_charges()
    # ... rest of wave start logic
```

**Passos:**
1. Adicionar `relocate_charges` ao GameManager
2. Refill no início de cada onda
3. Adicionar botão de relocate no HUD
4. Ao clicar no botão, entrar em "move mode"
5. Selecionar estátua → highlight células válidas
6. Click na célula destino → mover estátua
7. Decrementar charge
8. Se 0 charges, desabilitar botão até próxima onda
9. Adicionar lockout/cast time breve após relocate

**UI do HUD:**
```
[⚡ Relocate: 1/1]  (botão clicável)
```

**Teste:**
- Iniciar onda
- Usar relocate (deve funcionar)
- Tentar usar novamente (deve falhar - sem charges)
- Sobreviver à onda
- Nova onda: charge deve ser restaurado

---

#### 1.3 Feedback Visual de Move
**Arquivos:** `scripts/combat/arena.gd`, `scripts/combat/statue_base.gd`

**Implementação:**
```gdscript
# Efeito visual ao mover
func _on_statue_moved(statue_node):
    # Criar shockwave na posição antiga
    EffectsManager.create_shockwave(statue_node.global_position)
    # Criar materialize effect na posição nova
    EffectsManager.create_materialize(statue_node.global_position)
    # Breve scale animation
    var tween = create_tween()
    tween.tween_property(statue_node, "scale", Vector2(0.8, 0.8), 0.1)
    tween.tween_property(statue_node, "scale", Vector2(1.0, 1.0), 0.2)
```

**Passos:**
1. Shockwave na posição antiga
2. Materialize effect na posição nova
3. Breve animação de scale (bounce)
4. Hook para SFX futuro

---

### ✅ Critério de Conclusão - Fase 1
- [ ] Estátua pode ser movida na shop sem vender
- [ ] 1 relocate funciona mid-wave
- [ ] HUD mostra cargas restantes
- [ ] Células válidas são destacadas
- [ ] Upgrades permanecem após move
- [ ] Feedback visual de move é claro

---

## 🎯 Fase 2: Role Passives

### Visão Geral
Cada uma das 5 estátuas MVP recebe um role tag e uma passive que é ativada baseada em posicionamento.

### Tarefas Detalhadas

#### 2.1 Adicionar Role Tags
**Arquivos:** `scripts/data/statue_data.gd`, resources `.tres`

**Implementação:**
```gdscript
# Em statue_data.gd (Resource)
@export var role: RoleType

enum RoleType {
    FRONTLINE,
    PRECISION_DPS,
    SUPPORT,
    CONTROL_SUPPORT
}

# Nos resources .tres das 5 estátuas MVP:
# sentinel.tres: role = FRONTLINE
# huntress.tres: role = PRECISION_DPS
# divine_guardian.tres: role = SUPPORT
# frost_maiden.tres: role = CONTROL_SUPPORT
# arcane_weaver.tres: role = PRECISION_DPS
```

**Passos:**
1. Adicionar campo `role` ao StatueData
2. Atualizar 5 resources .tres do MVP
3. Adicionar visual indicator no HUD (ícone de role)

---

#### 2.2 Frontline Passive (Sentinel, Earthshaker)
**Arquivos:** `scripts/combat/statue_base.gd`

**Implementação:**
```gdscript
func _check_frontline_passive():
    if statue_data.role != RoleType.FRONTLINE:
        return
    
    # Check if exposed (closest to enemies or no allies in front)
    var is_exposed = _check_if_exposed()
    
    if is_exposed:
        # Apply mitigation bonus
        damage_reduction = 0.20  # -20% damage taken
        threat_multiplier = 1.5  # Enemies focus more
        passive_active = true
    else:
        damage_reduction = 0.0
        threat_multiplier = 1.0
        passive_active = false

func _check_if_exposed() -> bool:
    # Check if any allied statue is between this and enemy spawn
    for other_statue in arena.get_all_statues():
        if other_statue != self:
            if _is_statue_in_front_of_me(other_statue):
                return false
    return true
```

**Efeito:** -20% dano recebido quando exposta, +50% threat

---

#### 2.3 Precision DPS Passive (Huntress, Arcane Weaver, Shadow Dancer)
**Arquivos:** `scripts/combat/statue_base.gd`

**Implementação:**
```gdscript
func _check_precision_passive():
    if statue_data.role != RoleType.PRECISION_DPS:
        return
    
    # Check if isolated (no adjacent allies)
    var adjacent_allies = _count_adjacent_allies()
    
    if adjacent_allies == 0:
        # Lone Hunt bonus
        damage_multiplier = 1.20  # +20% damage
        passive_active = true
    else:
        damage_multiplier = 1.0
        passive_active = false

func _count_adjacent_allies() -> int:
    var count = 0
    var adjacent_cells = [
        grid_position + Vector2i(1, 0),
        grid_position + Vector2i(-1, 0),
        grid_position + Vector2i(0, 1),
        grid_position + Vector2i(0, -1),
        grid_position + Vector2i(1, 1),
        grid_position + Vector2i(-1, -1),
        grid_position + Vector2i(1, -1),
        grid_position + Vector2i(-1, 1),
    ]
    
    for other_statue in arena.get_all_statues():
        if other_statue != self and other_statue.grid_position in adjacent_cells:
            count += 1
    
    return count
```

**Efeito:** +20% dano quando sem aliados adjacentes (Lone Hunt)

---

#### 2.4 Support Passive (Divine Guardian, Frost Maiden)
**Arquivos:** `scripts/combat/statue_base.gd`

**Implementação:**
```gdscript
func _check_support_passive():
    if statue_data.role != RoleType.SUPPORT and statue_data.role != RoleType.CONTROL_SUPPORT:
        return
    
    # Check for allies in aura range
    var allies_in_range = _count_allies_in_range(aura_radius)
    
    if allies_in_range > 0:
        # Apply aura buffs to allies
        for ally in allies_in_range:
            ally.apply_aura_buff(heal_per_second, shield_amount, cooldown_reduction)
        passive_active = true
    else:
        passive_active = false

func _count_allies_in_range(radius: float) -> Array:
    var allies = []
    for other_statue in arena.get_all_statues():
        if other_statue != self:
            var distance = global_position.distance_to(other_statue.global_position)
            if distance <= radius:
                allies.append(other_statue)
    return allies
```

**Efeitos:**
- **Divine Guardian:** Heal 2% HP/sec + 10% damage buff aura
- **Frost Maiden:** +1s freeze duration quando atrás de frontline

---

#### 2.5 Passive State Indicators
**Arquivos:** `scripts/combat/statue_base.gd`, `scenes/ui/hud.tscn`

**Implementação:**
```gdscript
# Visual indicator quando passive está ativa
func _update_passive_indicator():
    if passive_active:
        # Green glow / ring
        passive_sprite.visible = true
        passive_sprite.modulate = Color(0.5, 1.0, 0.5, 0.8)
        # Tooltip
        tooltip_text = passive_description + " ✅ ATIVO"
    else:
        # Red/gray tint
        passive_sprite.visible = true
        passive_sprite.modulate = Color(1.0, 0.5, 0.5, 0.5)
        tooltip_text = passive_description + " ❌ inativo"
```

**UI:**
- Adicionar ícone de role no HUD quando estátua é selecionada
- Mostrar estado da passive (ativo/inativo) com tooltip

---

### ✅ Critério de Conclusão - Fase 2
- [ ] 5 estátuas MVP têm role tags
- [ ] Frontline recebe mitigação quando exposta
- [ ] Precision DPS recebe bônus quando isolada
- [ ] Support gera aura para aliados próximos
- [ ] HUD mostra estado da passive
- [ ] Posicionamento afeta combate de forma visível

---

## 🎯 Fase 3: Statue-Bound Equipment

### Visão Geral
Transformar upgrades existentes em equipamentos vinculados a estátuas específicas.

### Tarefas Detalhadas

#### 3.1 Reframe Upgrades como Equipment
**Arquivos:** `scripts/data/equipment_data.gd`, resources `.tres`

**Implementação:**
```gdscript
# Em equipment_data.gd (Resource)
class_name EquipmentData
extends Resource

@export var equipment_name: String
@export var equipment_type: EquipmentType
@export var stat_bonus: String  # "damage", "range", "attack_speed", etc.
@export var bonus_value: float  # 0.25 = +25%
@export var icon: Texture2D
@export var description: String

enum EquipmentType {
    POWER_RUNE,
    RANGE_RUNE,
    QUICKSTEP_RUNE,
    KEEN_RUNE,
    CHANNEL_RUNE,
    GUARD_RUNE
}
```

**Criar 6 resources:**
- `power_rune.tres`: +25% damage
- `range_rune.tres`: +2 range
- `quickstep_rune.tres`: +30% attack speed
- `keen_rune.tres`: +20% crit chance
- `channel_rune.tres`: -30% cooldown
- `guard_rune.tres`: +50% HP, +threat

---

#### 3.2 Equipment Attachment System
**Arquivos:** `scripts/combat/statue_base.gd`

**Implementação:**
```gdscript
# Em statue_base.gd
@export var equipped_items: Array[EquipmentData] = []

func apply_equipment():
    var equipment = equipped_items
    for item in equipment:
        match item.equipment_type:
            EquipmentType.POWER_RUNE:
                damage_multiplier *= 1.25
            EquipmentType.RANGE_RUNE:
                attack_range += 2.0
            EquipmentType.QUICKSTEP_RUNE:
                attack_speed *= 1.30
            EquipmentType.KEEN_RUNE:
                crit_chance += 0.20
            EquipmentType.CHANNEL_RUNE:
                cooldown_multiplier *= 0.70
            EquipmentType.GUARD_RUNE:
                max_hp *= 1.50
                threat_multiplier *= 1.50

func can_equip(item: EquipmentData) -> bool:
    # Check slot availability
    var max_slots = get_max_equipment_slots()
    return equipped_items.size() < max_slots

func get_max_equipment_slots() -> int:
    # Based on evolution tier
    match evolution_tier:
        0: return 1
        1: return 2
        2: return 3
        3: return 4
    return 1
```

**Passos:**
1. Adicionar array `equipped_items` à estátua
2. Aplicar bônus no `_ready()` e ao equipar
3. Verificar slot limit baseado no tier
4. Mostrar equipment no tooltip da estátua

---

#### 3.3 Equipment UI
**Arquivos:** `scripts/ui/inventory_ui.gd`, `scripts/ui/shop_item_card.gd`

**Implementação:**
```gdscript
# Em inventory_ui.gd
func _on_equipment_clicked(equipment_data):
    # Show equipment details
    tooltip.show_equipment_info(equipment_data)
    # If statue is selected, try to equip
    if selected_statue:
        _try_equip_item(equipment_data)

func _try_equip_item(equipment_data: EquipmentData):
    if selected_statue.can_equip(equipment_data):
        selected_statue.equipped_items.append(equipment_data)
        selected_statue.apply_equipment()
        # Update UI
        _update_equipment_display()
```

**UI:**
- Quando estátua é selecionada, mostrar slots de equipment
- Slots preenchidos mostram ícone da runa
- Slots vazios mostram "+"
- Click em equipamento do inventory → equipa na estátua selecionada

---

#### 3.4 Shop Generation Bias
**Arquivos:** `scripts/ui/shop_manager.gd`

**Implementação:**
```gdscript
# Priorizar equipamentos do MVP na shop
func _generate_shop_items():
    var items = []
    
    # 40% equipment
    var equipment_count = 2
    for i in equipment_count:
        items.append(_get_random_mvp_equipment())
    
    # 40% statues (MVP roster)
    var statue_count = 2
    for i in statue_count:
        items.append(_get_random_mvp_statue())
    
    # 20% artifacts/consumables
    items.append(_get_random_artifact_or_consumable())
    
    return items
```

**Passos:**
1. Ajustar geração para priorizar 6 runas MVP
2. Priorizar 5 estátuas do MVP
3. Reduzir ruído de itens fora do slice

---

### ✅ Critério de Conclusão - Fase 3
- [ ] 6 runas MVP existem como EquipmentData
- [ ] Equipamentos são vinculados a estátuas
- [ ] Slots limitados baseado no tier
- [ ] Equipment aparece no tooltip
- [ ] Shop prioriza itens do MVP
- [ ] Equipment pode ser movido/removido

---

## 🎯 Fase 4: Soft Aggro e Pressão Inimiga

### Visão Geral
Inimigos podem targetear estátuas antes do cristal, criando pressão tática.

### Tarefas Detalhadas

#### 4.1 Threat System
**Arquivos:** `scripts/combat/statue_base.gd`, `scripts/combat/enemy_base.gd`

**Implementação:**
```gdscript
# Em statue_base.gd
var threat_value: float = 1.0

func calculate_threat() -> float:
    var base_threat = 1.0
    
    # Frontline generates more threat
    if statue_data.role == RoleType.FRONTLINE:
        base_threat *= 1.5
    
    # Equipment modifiers
    for equip in equipped_items:
        if equip.equipment_type == EquipmentType.GUARD_RUNE:
            base_threat *= 1.5
    
    # Distance to enemy spawn (closer = more threat)
    var distance_factor = 1.0 + (1.0 / (global_position.distance_to(enemy_spawn) + 1.0))
    
    threat_value = base_threat * distance_factor
    return threat_value
```

---

#### 4.2 Enemy Target Selection
**Arquivos:** `scripts/combat/enemy_base.gd`

**Implementação:**
```gdscript
func select_target() -> Node2D:
    var statues = arena.get_all_statues()
    
    if can_target_statues and statues.size() > 0:
        # Find statue with highest threat in range
        var best_target: Node2D = null
        var highest_threat = 0.0
        
        for statue in statues:
            var distance = global_position.distance_to(statue.global_position)
            if distance <= attack_range:
                var threat = statue.calculate_threat()
                if threat > highest_threat:
                    highest_threat = threat
                    best_target = statue
        
        if best_target:
            return best_target
    
    # Default: go to crystal
    return arena.crystal
```

**Passos:**
1. Adicionar `can_target_statues` a alguns inimigos
2. Inimigos escolhem alvo baseado em threat + distância
3. Se sem estátuas em range, vai para o cristal
4. Bosses SEMPRE podem targetear estátuas

---

#### 4.3 Focus Indicators
**Arquivos:** `scripts/combat/enemy_base.gd`, `scenes/ui/hud.tscn`

**Implementação:**
```gdscript
# Mostrar qual estátua está sendo focada
func _update_focus_indicator():
    if current_target is Statue:
        # Red arrow/line above statue
        current_target.focus_indicator.visible = true
        current_target.focus_indicator.modulate = Color(1.0, 0.0, 0.0, 0.8)
        
        # Optional: draw line from enemy to statue
        if show_aggro_line:
            aggro_line.points = [global_position, current_target.global_position]
            aggro_line.visible = true
```

**UI:**
- Seta vermelha sobre estátua sendo focada
- Opcional: linha de aggro do inimigo até estátua
- HUD mostra "ALVO: [Nome da Estátua]" quando selecionada

---

### ✅ Critério de Conclusão - Fase 4
- [ ] Frontline gera mais threat
- [ ] Inimigos targeteiam estátuas em range
- [ ] Foco é visível com indicadores
- [ ] Boss sempre pode focar estátuas
- [ ] Posicionamento errado é punível

---

## 🎯 Fase 5: Boss com 2+ Fases Táticas

### Visão Geral
Goblin Boss deve ter mínimo 2 fases que exigem reposicionamento.

### Tarefas Detalhadas

#### 5.1 Boss State Machine
**Arquivos:** `scripts/combat/enemy_base.gd`, `resources/enemies/goblin_boss.tres`

**Implementação:**
```gdscript
enum BossPhase {
    PHASE_1_CRYSTAL_RUSH,
    PHASE_2_STATUE_FOCUS
}

var current_phase: BossPhase = BossPhase.PHASE_1_CRYSTAL_RUSH
var phase_threshold: float = 0.5  # Muda em 50% HP

func _check_phase_transition():
    var hp_percent = current_hp / max_hp
    
    if hp_percent <= phase_threshold and current_phase == BossPhase.PHASE_1_CRYSTAL_RUSH:
        _transition_to_phase_2()

func _transition_to_phase_2():
    current_phase = BossPhase.PHASE_2_STATUE_FOCUS
    can_target_statues = true
    
    # Visual feedback
    _play_phase_transition_effect()
    
    # Summon adds immediately
    _summon_goblin_adds(3)
    
    # Increase speed
    speed *= 1.2
```

---

#### 5.2 Phase 1: Crystal Rush
**Comportamento:**
- Move diretamente para o cristal
- Summon 3 goblins a cada 6 segundos
- HP: 200 (MVP balanceado para 8 waves)

```gdscript
func _phase_1_behavior(delta):
    # Move toward crystal
    move_toward(crystal_position)
    
    # Summon timer
    summon_timer -= delta
    if summon_timer <= 0:
        _summon_goblin_adds(3)
        summon_timer = 6.0
```

---

#### 5.3 Phase 2: Statue Focus
**Comportamento:**
- Começa a targetear estátuas (soft aggro)
- Lane sweep: move em linha, dano em área
- Summon 3 goblins imediatamente

```gdscript
func _phase_2_behavior(delta):
    # Target highest threat statue
    var target = _find_highest_threat_statue()
    if target:
        move_toward(target.global_position)
        attack(target)
    
    # Lane sweep every 4 seconds
    lane_sweep_timer -= delta
    if lane_sweep_timer <= 0:
        _perform_lane_sweep()
        lane_sweep_timer = 4.0

func _perform_lane_sweep():
    # Damage all statues in a line in front of boss
    var sweep_area = Rect2(global_position, Vector2(100, 50))
    for statue in arena.get_all_statues():
        if sweep_area.has_point(statue.global_position):
            statue.take_damage(20)  # Flat damage
```

---

#### 5.4 Visual Feedback de Fases
**Implementação:**
```gdscript
func _play_phase_transition_effect():
    # Screen shake
    EffectsManager.screen_shake(0.3, 0.2)
    
    # Boss visual change
    sprite.modulate = Color(1.0, 0.3, 0.3, 1.0)  # Red tint
    scale = Vector2(1.2, 1.2)  # Grow slightly
    
    # Shockwave
    EffectsManager.create_shockwave(global_position, 150.0)
    
    # HUD notification
    GameManager.show_boss_phase_notification("PHASE 2 - ENRAGED!")
```

---

### ✅ Critério de Conclusão - Fase 5
- [ ] Boss tem 2 fases claras
- [ ] Phase transition em 50% HP
- [ ] Phase 2 exige reposicionamento
- [ ] Fases são visualmente distintas
- [ ] Lane sweep força movimento
- [ ] Adds summonados criam pressão extra

---

## 🎯 Fase 6: Balanceamento Final

### Visão Geral
Ajustar valores para que as 8 ondas do MVP sejam desafiadoras mas justas.

### Tarefas Detalhadas

#### 6.1 Wave Pacing
**Arquivos:** `scripts/data/wave_data.gd`, resources `.tres`

**Estrutura de Ondas:**
```
Onda 1: 6 Goblins (tutorial)
Onda 2: 8 Goblins + 2 Orcs
Onda 3: 6 Goblins + 4 Orcs
Onda 4: 8 Orcs (prep para boss)
Onda 5: Goblin Boss (Phase 1) + 6 Goblins
Onda 6: 4 Goblins + 4 Orcs + 2 Elites
Onda 7: 6 Orcs + 2 Goblins + 1 Slime
Onda 8: Goblin Boss (Phase 1→2) + 4 Orcs
```

**Ajustes:**
- Reduzir HP inicial se muito difícil
- Aumentar gold reward se muito lento
- Ajustar spawn rate para dar tempo de reagir

---

#### 6.2 Testar 3 Builds

**Build 1: Frontline-Heavy**
- 2x Sentinel
- 1x Divine Guardian
- 1x Huntress
- Focus: Guard Rune, HP upgrades

**Build 2: Huntress Isolation**
- 1x Sentinel
- 2x Huntress (isoladas)
- 1x Arcane Weaver
- Focus: Damage/Range Runes

**Build 3: Support/Control**
- 1x Sentinel
- 1x Frost Maiden
- 1x Divine Guardian
- 1x Huntress
- Focus: Cooldown reduction, aura range

**Teste:**
Cada build deve conseguir completar as 8 ondas com estratégia diferente.

---

#### 6.3 Economy Tuning
**Meta:** Jogador deve ter escolhas difíceis na shop.

**Ajustes:**
```
Se jogador sempre pode comprar tudo:
→ Aumentar preços em 10-15%
→ Reduzir wave completion gold em 10g

Se jogador nunca tem ouro suficiente:
→ Reduzir preços em 10%
→ Aumentar gold per kill em 2-3g
```

---

### ✅ Critério de Conclusão - Fase 6
- [ ] 8 ondas têm pacing bom
- [ ] 3 builds diferentes podem vencer
- [ ] Shop cria escolhas difíceis
- [ ] Boss fight é tensa mas justa
- [ ] Não há "build perfeita" óbvia

---

## 📊 Cronograma Sugerido

**Ordem de implementação:**

1. **Fase 1:** Reposicionamento (2-3 dias)
2. **Fase 2:** Role Passives (1-2 dias)
3. **Fase 3:** Equipment (2 dias)
4. **Fase 4:** Soft Aggro (1-2 dias)
5. **Fase 5:** Boss Phases (2 dias)
6. **Fase 6:** Balanceamento (1-2 dias)

**Total estimado:** 9-13 dias de desenvolvimento

---

## ✅ MVP Exit Checklist Final

O MVP está completo quando **TODOS** os itens abaixo estão marcados:

### Sistemas
- [ ] Shop-phase reposition funciona
- [ ] 1 in-combat relocate funciona por onda
- [ ] 3 role passives estão ativas e visíveis
- [ ] Equipment é statue-bound e legível
- [ ] Inimigos pressionam estátuas (não só crystal)
- [ ] Boss tem 2+ fases táticas
- [ ] Focus indicators funcionam

### Gameplay
- [ ] 8 ondas podem ser completadas
- [ ] 3 builds diferentes são viáveis
- [ ] Shop cria tradeoffs reais
- [ ] Boss exige reposicionamento
- [ ] Dificuldade é justa mas desafiadora

### Polish
- [ ] Feedback visual de relocate é claro
- [ ] Passive states são compreensíveis
- [ ] Equipment é fácil de entender
- [ ] Fases do boss são visíveis
- [ ] HUD mostra informações necessárias

### Bugs
- [ ] Zero crashes em test runs
- [ ] Upgrades não se perdem em relocate
- [ ] Equipment aplica corretamente
- [ ] Soft aggro não quebra pathfinding
- [ ] Boss phases transicionam suavemente

---

## 🚀 Próximos Passos Imediatos

1. **Revisar** este plano e a `MVP_DOCUMENTATION.md`
2. **Iniciar** Fase 1: Reposicionamento
3. **Implementar** shop-phase movement primeiro
4. **Testar** após cada tarefa
5. **Commit** frequente com mensagens claras

**Boa sorte! Vamos construir um MVP incrível! 🎮**

---

*Plano criado em: 11 de Abril de 2026*  
*Engine: Godot 4.4 GL Compatibility*  
*Status: Pronto para implementação*
