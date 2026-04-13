# 📋 MVP Implementation Plan — Steps & Tasks

**Projeto:** Project Guardians — MVP Adaptation Slice
**Data:** 12 de Abril de 2026
**Baseado em:** `MVP_GAP_ANALYSIS.md` + `MVP_PROGRESS.md`

---

## Como Usar

- Marque `[x]` quando uma task estiver completa
- Cada task é pequena o suficiente para ser feita em 15min–2h
- Tasks estão ordenadas por dependência — faça na ordem sempre que possível
- Blocos estão organizados por **Fase** com checkpoint ao final

---

## FASE 1 — Tornar o Reposicionamento Funcional

> **Objetivo:** Jogador pode mover estátuas durante shop E durante combate (1 charge/onda)
> **Tempo estimado:** 3-5 horas

### 1.1 Botão de Relocate no HUD

- [ ] **1.1.1** Adicionar `RelocateButton` node em `scenes/ui/hud.tscn`
  - Tipo: `Button`
  - Parent: `ActionButtons` (HBoxContainer junto com Inventory, Shop, Start Wave)
  - Text: `⚡ Relocate: 0/0`
  - `custom_minimum_size`: `Vector2(160, 50)`
  - `theme_override_font_sizes/font_size`: `16`

- [ ] **1.1.2** Adicionar `@onready var relocate_button: Button = $ActionButtons/RelocateButton` em `scripts/ui/hud_controller.gd`

- [ ] **1.1.3** Adicionar signal `signal relocate_button_pressed()` em `hud_controller.gd` (topo do arquivo, junto com os outros signals)

- [ ] **1.1.4** Conectar signal no `_ready()` do `hud_controller.gd`:
  ```gdscript
  if relocate_button:
      relocate_button.pressed.connect(_on_relocate_pressed)
  ```

- [ ] **1.1.5** Criar handler `_on_relocate_pressed()` em `hud_controller.gd`:
  ```gdscript
  func _on_relocate_pressed() -> void:
      if GameManager.current_state != GameManager.GameState.COMBAT:
          return
      if not GameManager.is_tangy_mvp_active():
          return
      if not GameManager.can_use_relocate():
          return
      relocate_button_pressed.emit()
  ```

- [ ] **1.1.6** Conectar signal no `main.gd` (`_ready()`):
  ```gdscript
  if hud:
      hud.relocate_button_pressed.connect(_on_hud_relocate_pressed)
  ```

- [ ] **1.1.7** Criar handler `_on_hud_relocate_pressed()` em `main.gd`:
  - Entrar em modo relocate: iterar `GameManager.placed_statues`, habilitar click selection
  - Esconder `statue_inventory_ui` e `equipment_shop_ui` se abertos
  - Chamar `arena.highlight_valid_cells()`
  - Setar flag `is_relocate_mode = true` no main

- [ ] **1.1.8** Adicionar `var is_relocate_mode: bool = false` no topo do `main.gd`

### 1.2 Input Handling para Relocate

- [ ] **1.2.1** No `_input()` do `main.gd`, adicionar branch para `is_relocate_mode`:
  ```gdscript
  # Handle relocate mode
  if is_relocate_mode and event is InputEventMouseButton:
      if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
          # Try to select a statue or confirm placement
          var clicked_statue = _get_statue_at_position(get_global_mouse_position())
          if clicked_statue:
              # First click: pick up statue
              if arena.begin_relocate_combat(clicked_statue):
                  is_relocate_mode = false  # Arena now owns the relocate state
                  print("[Main] Relocate mode — statue picked up")
              else:
                  print("[Main] Cannot relocate (no charges or invalid)")
          else:
              # Click on empty cell — only valid if a statue is being relocated
              if arena.relocating_statue:
                  var grid_pos = arena.world_to_grid(get_global_mouse_position())
                  if arena.confirm_relocate_combat(grid_pos):
                      is_relocate_mode = false
                      print("[Main] Relocate confirmed")
                  else:
                      print("[Main] Invalid cell for relocate")
      elif event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
          # Cancel
          if arena.relocating_statue:
              arena.cancel_relocate_combat()
          is_relocate_mode = false
          print("[Main] Relocate cancelled")
  ```

### 1.3 Atualizar Visual do Botão de Relocate

- [ ] **1.3.1** Em `hud_controller.gd`, criar função `_update_relocate_button()`:
  ```gdscript
  func _update_relocate_button() -> void:
      if not relocate_button:
          return
      if GameManager.is_tangy_mvp_active() and GameManager.current_state == GameManager.GameState.COMBAT:
          relocate_button.visible = true
          relocate_button.text = "⚡ Relocate: %d/%d" % [GameManager.relocate_charges, GameManager.get_relocate_charges_per_wave()]
          relocate_button.disabled = not GameManager.can_use_relocate()
      else:
          relocate_button.visible = false
  ```

- [ ] **1.3.2** Chamar `_update_relocate_button()` no `_on_game_state_changed()` do HUD e no `_process()` ou timer

- [ ] **1.3.3** Conectar ao signal `GameManager.relocate_charges_changed` para atualizar botão:
  ```gdscript
  GameManager.relocate_charges_changed.connect(_update_relocate_button)
  ```

### 1.4 Shop-Phase Reposition

- [ ] **1.4.1** Em `main.gd`, no `_input()`, adicionar handler para shop-phase reposition:
  ```gdscript
  # Shop-phase statue reposition (right-click on placed statue during SHOP)
  if GameManager.current_state == GameManager.GameState.SHOP and not is_relocate_mode:
      if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
          var clicked_statue = _get_statue_at_position(get_global_mouse_position())
          if clicked_statue:
              _enter_shop_relocate(clicked_statue)
  ```

- [ ] **1.4.2** Criar função `_enter_shop_relocate(statue: Node)` em `main.gd`:
  ```gdscript
  func _enter_shop_relocate(statue: Node) -> void:
      if not arena:
          return
      arena.begin_relocate_shop(statue)
      is_relocate_mode = true
      print("[Main] Shop reposition — statue picked up")
  ```

- [ ] **1.4.3** No `_input()` do `main.gd`, quando `is_relocate_mode` e não é COMBAT:
  ```gdscript
  # Shop-phase relocate
  if is_relocate_mode and GameManager.current_state == GameManager.GameState.SHOP:
      if event is InputEventMouseButton and event.pressed:
          if event.button_index == MOUSE_BUTTON_LEFT:
              # Click on empty cell = confirm
              if arena.relocating_statue:
                  var grid_pos = arena.world_to_grid(get_global_mouse_position())
                  if arena.confirm_relocate_shop(grid_pos):
                      is_relocate_mode = false
                      print("[Main] Shop relocate confirmed")
              else:
                  # Click on another statue = switch pickup
                  var clicked = _get_statue_at_position(get_global_mouse_position())
                  if clicked:
                      arena.cancel_relocate_shop()
                      arena.begin_relocate_shop(clicked)
          elif event.button_index == MOUSE_BUTTON_RIGHT:
              # Cancel
              arena.cancel_relocate_shop()
              is_relocate_mode = false
              print("[Main] Shop relocate cancelled")
  ```

### 1.5 Integrar Relocate com Inventory UI

- [ ] **1.5.1** Quando relocate começa (shop ou combat), esconder `statue_inventory_ui` e `equipment_shop_ui`

- [ ] **1.5.2** Quando relocate termina (confirm ou cancel), mostrar `statue_inventory_ui` de volta (se SHOP phase)

### ✅ CHECKPOINT — Fase 1

> **Testar:** Iniciar run → colocar estátua → entrar em shop → right-click na estátua → mover → confirmar.
> Iniciar combate → clicar botão Relocate → clicar estátua → mover → confirmar. Verificar charges decrementam.
> Sobreviver onda → verificar charges resetam.

---

## FASE 2 — Finalizar Role Passives

> **Objetivo:** 4 passives funcionais (lone_hunt, sacred_line, sanctuary_aura, frost_zone) + storm_focus
> **Tempo estimado:** 2-3 horas

### 2.1 Configurar Valores nos Resources .tres

- [ ] **2.1.1** Em `sentinel.tres`, adicionar `passive_bonus_value = 0.15` (15% damage reduction)

- [ ] **2.1.2** Em `huntress.tres`, adicionar `passive_bonus_value = 0.20` (+20% damage quando isolada)

- [ ] **2.1.3** Em `divine_guardian.tres`, adicionar `aura_radius = 150.0` (aura heal radius)

- [ ] **2.1.4** Em `frost_maiden.tres`, adicionar `aura_radius = 90.0` (range para check de frontline ally)

### 2.2 Implementar Storm Focus Passive (Arcane Weaver)

- [ ] **2.2.1** Adicionar `"storm_focus"` ao match em `evaluate_passive()` (`statue_base.gd:985`):
  ```gdscript
  "storm_focus":
      passive_active = _check_storm_focus()
  ```

- [ ] **2.2.2** Criar função `_check_storm_focus()` em `statue_base.gd`:
  ```gdscript
  ## storm_focus: Arcane Weaver gains +passive_bonus_value damage when not moving
  ## (i.e., when in a stable position with at least 1 ally within 120px).
  func _check_storm_focus() -> bool:
      var nearby = get_adjacent_allies(120.0)
      return not nearby.is_empty()
  ```

- [ ] **2.2.3** Adicionar ao `_apply_passive_bonus()` para `storm_focus`:
  ```gdscript
  "storm_focus":
      if is_now_active:
          _passive_dmg_bonus = statue_data.passive_bonus_value
          damage_modifier += _passive_dmg_bonus
      else:
          damage_modifier -= _passive_dmg_bonus
          _passive_dmg_bonus = 0.0
  ```

### 2.3 Verificar DR Aplicado em Take Damage

- [ ] **2.3.1** Encontrar função `take_damage()` em `statue_base.gd` (ou criar se não existir)

- [ ] **2.3.2** Adicionar cálculo de DR passivo:
  ```gdscript
  var dr = get_passive_dr()
  if dr > 0.0:
      amount *= (1.0 - dr)
  ```

### 2.4 Verificar Slow Multiplier Aplicado ao Enemy

- [ ] **2.4.1** Em `enemy_base.gd`, encontrar onde `apply_slow()` ou slow é aplicado

- [ ] **2.4.2** Verificar se consulta `statue.get_slow_multiplier()` e multiplicar duração do slow

### 2.5 Configurar passive_bonus_value e aura_radius Default

- [ ] **2.5.1** Verificar se `passive_bonus_value` default de 0.20 em `statue_data.gd` é razoável para todas as passives

- [ ] **2.5.2** Verificar se `aura_radius` default de 120.0 funciona para sanctuary_aura (talvez aumentar para 150)

### ✅ CHECKPOINT — Fase 2

> **Testar:** Colocar Sentinel na frente → verificar ring verde (passive ativa). Colocar Huntress isolada → verificar ring verde + dano aumentado. Colocar Divine Guardian → verificar heal pulse em aliados próximos. Colocar Frost Maiden atrás de Sentinel → verificar slow duration boost.

---

## FASE 3 — Soft Aggo Funcional

> **Objetivo:** Inimigos targeteiam estátuas baseado em threat
> **Tempo estimado:** 1-2 horas

### 3.1 Configurar statue_targeting_chance nos Enemies

- [ ] **3.1.1** Em `goblin.tres`, setar `statue_targeting_chance = 0.0` (sempre vai pro cristal)

- [ ] **3.1.2** Em `orc.tres`, setar `statue_targeting_chance = 0.15` (15% chance de focar estátua)

- [ ] **3.1.3** Em `slime.tres`, setar `statue_targeting_chance = 0.0`

- [ ] **3.1.4** Em `goblin_boss.tres`, setar `statue_targeting_chance = 1.0` na Phase 2 (já feito via `_on_phase_2_start`)

### 3.2 Enemy Movement com Statue Target

- [ ] **3.2.1** Em `enemy_base.gd` `_physics_process()`, verificar se quando `current_statue_target` existe e é válido, o inimigo se move em direção à estátua em vez de seguir o path:
  ```gdscript
  # If targeting a statue, move toward it instead of following path
  if current_statue_target and is_instance_valid(current_statue_target):
      var target_pos = current_statue_target.global_position
      var direction = (target_pos - position).normalized()
      position += direction * actual_speed * delta
      # Check if reached statue (close enough to attack)
      if position.distance_to(target_pos) < 30.0:
          _attack_statue(current_statue_target)
      return
  ```

- [ ] **3.2.2** Criar função `_attack_statue(statue: Node)` em `enemy_base.gd`:
  ```gdscript
  func _attack_statue(statue: Node) -> void:
      # Statue takes damage instead of crystal
      if statue.has_method("take_damage"):
          statue.take_damage(damage_to_crystal, self)
      # Brief attack cooldown to prevent instant multi-hit
      await get_tree().create_timer(1.0).timeout
  ```

### 3.3 Focus Icon Visible

- [ ] **3.3.1** Verificar que `_focus_icon` aparece quando `set_enemy_focused(true)` é chamado — já implementado em `statue_base.gd:1202`

- [ ] **3.3.2** Testar visualmente: quando inimigo foca estátua, "!" vermelho aparece

### ✅ CHECKPOINT — Fase 3

> **Testar:** Colocar Sentinel na frente com Guard Rune. Spawn orcs. Verificar se alguns orcs focam a Sentinel (focus icon "!"). Verificar que Sentinel não morre instantaneamente.

---

## FASE 4 — Boss Phases

> **Objetivo:** Goblin Boss com 2 fases distintas e mechanic de summon + lane sweep
> **Tempo estimado:** 3-4 horas

### 4.1 Boss Phase 1 — Summon Behavior

- [ ] **4.1.1** Verificar que `goblin_boss.tres` já tem `can_summon=true`, `summon_cooldown=6.0`, `summon_enemy_id="goblin"`, `summon_count=3` — ✅ já configurado

- [ ] **4.1.2** Verificar que `_on_summon_timer()` em `enemy_base.gd:394` funciona para o boss

- [ ] **4.1.3** **Adicionar SummonTimer node** em `scenes/entities/enemy.tscn` se não existir:
  - Node type: `Timer`
  - Name: `SummonTimer`
  - `wait_time`: 6.0
  - `one_shot`: false

### 4.2 Boss Phase 2 — Lane Sweep

- [ ] **4.2.1** Adicionar variáveis em `enemy_base.gd` (perto de `boss_phase`):
  ```gdscript
  var lane_sweep_timer: float = 0.0
  const LANE_SWEEP_INTERVAL: float = 4.0
  const LANE_SWEEP_DAMAGE: float = 15.0
  const LANE_SWEEP_LENGTH: float = 100.0
  const LANE_SWEEP_WIDTH: float = 50.0
  ```

- [ ] **4.2.2** Em `_on_phase_2_start()`, inicializar timer:
  ```gdscript
  lane_sweep_timer = LANE_SWEEP_INTERVAL
  ```

- [ ] **4.2.3** Em `_physics_process()`, quando `boss_phase == 2`:
  ```gdscript
  if boss_phase == 2:
      lane_sweep_timer -= delta
      if lane_sweep_timer <= 0.0:
          _perform_lane_sweep()
          lane_sweep_timer = LANE_SWEEP_INTERVAL
  ```

- [ ] **4.2.4** Criar função `_perform_lane_sweep()` em `enemy_base.gd`:
  ```gdscript
  func _perform_lane_sweep() -> void:
      if not arena:
          return
      # Damage all statues in a rectangle in front of boss
      var sweep_origin = global_position
      var sweep_dir = Vector2.RIGHT if sprite and not sprite.flip_h else Vector2.LEFT

      # Visual: shockwave line
      EffectsManager.create_shockwave(arena, sweep_origin, Color(1.0, 0.3, 0.2, 0.8), LANE_SWEEP_LENGTH, 0.3)

      # Check all statues
      for statue in GameManager.placed_statues:
          if not is_instance_valid(statue):
              continue
          var dist = global_position.distance_to(statue.global_position)
          if dist <= LANE_SWEEP_LENGTH:
              # Check if in front (dot product)
              var to_statue = (statue.global_position - global_position).normalized()
              if to_statue.dot(sweep_dir) > 0.5:  # Within ~60 degrees
                  if statue.has_method("take_damage"):
                      statue.take_damage(LANE_SWEEP_DAMAGE, self)
                      print("[Boss] Lane sweep hit %s for %d damage" % [statue.statue_data.display_name, LANE_SWEEP_DAMAGE])

      # Screen shake for impact
      _screen_shake(0.2, 6.0)
  ```

- [ ] **4.2.5** Adicionar função `_screen_shake()` em `enemy_base.gd` se não existir:
  ```gdscript
  func _screen_shake(duration: float = 0.2, intensity: float = 5.0) -> void:
      var camera = get_viewport().get_camera_2d()
      if camera:
          var original = camera.offset
          var t = create_tween()
          for i in range(int(duration * 20)):
              var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
              t.tween_property(camera, "offset", original + offset, 0.05)
          t.tween_property(camera, "offset", original, 0.05)
  ```

### 4.3 Boss Phase 1 — Movement Behavior

- [ ] **4.3.1** Em `_physics_process()`, quando `boss_phase == 1` e NÃO está summoning, boss deve se mover para o cristal normalmente (já funciona via path_follow)

- [ ] **4.3.2** O summon timer já spawna goblins automaticamente — verificar que funciona

### 4.4 HUD Boss Phase Notification

- [ ] **4.4.1** Em `hud_controller.gd`, criar função `show_boss_phase_notification(phase_text: String)`:
  ```gdscript
  func show_boss_phase_notification(text: String) -> void:
      var label = Label.new()
      label.text = text
      label.add_theme_font_size_override("font_size", 32)
      label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
      label.add_theme_color_override("font_outline_color", Color.BLACK)
      label.add_theme_constant_override("outline_size", 5)
      label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
      var vp_size = get_viewport().get_visible_rect().size
      label.position = Vector2(vp_size.x / 2 - 150, vp_size.y / 2 - 50)
      add_child(label)

      # Animate
      label.scale = Vector2.ZERO
      var t = create_tween()
      t.tween_property(label, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT)
      t.tween_property(label, "scale", Vector2.ONE, 0.1)
      t.tween_interval(2.0)
      t.tween_property(label, "modulate:a", 0.0, 0.3)
      t.tween_callback(label.queue_free)
  ```

- [ ] **4.4.2** Em `enemy_base.gd` `_on_phase_2_start()`, chamar notificação:
  ```gdscript
  var hud = get_node_or_null("/root/Main/HUD")
  if hud and hud.has_method("show_boss_phase_notification"):
      hud.show_boss_phase_notification("🔥 BOSS PHASE 2 — ENRAGED! 🔥")
  ```

### ✅ CHECKPOINT — Fase 4

> **Testar:** Iniciar wave 8. Boss spawna 3 goblins a cada 6s. Quando HP chega em 50%: boss fica vermelho, speed +25%, statue_targeting = 1.0, notification no HUD. Boss faz lane sweep a cada 4s com shockwave visual + screen shake.

---

## FASE 5 — Balanceamento

> **Objetivo:** 8 ondas com pacing justo, 3 builds viáveis
> **Tempo estimado:** 4-6 horas (inclui teste)

### 5.1 Enemy Stats

- [ ] **5.1.1** Ler `goblin.tres` — verificar HP, damage, speed. Ajustar se necessário para onda 1 ser fácil.

- [ ] **5.1.2** Ler `orc.tres` — verificar HP, damage, speed. Deve ser ~1.5x mais forte que goblin.

- [ ] **5.1.3** Ler `slime.tres` — verificar HP, damage. Deve ser fraco mas split em mini_slimes.

- [ ] **5.1.4** Ler `goblin_boss.tres` — HP=200, damage=30. Testar wave 8. Se boss morre em <30s → aumentar HP para 300-400.

### 5.2 Gold Economy

- [ ] **5.2.1** Fazer test run: iniciar jogo, contar ouro após onda 1. Verificar quantos itens pode comprar.

- [ ] **5.2.2** Se jogador pode comprar >3 itens na onda 1 → reduzir wave bonus para `60 + wave*12`

- [ ] **5.2.3** Se jogador pode comprar <1 item na onda 1 → aumentar wave bonus para `90 + wave*18`

### 5.3 Statue Costs vs Gold

- [ ] **5.3.1** Verificar custo das estátuas MVP: sentinel=350, huntress=400, divine_guardian=550, frost_maiden=480, arcane_weaver=450

- [ ] **5.3.2** Se costs estão muito altos para a economia → reduzir base_cost em 10-15%

### 5.4 Testar 3 Builds

- [ ] **5.4.1** **Build Frontline-Heavy:** 2x Sentinel + 1x Divine Guardian + 1x Huntress
  - Iniciar run, comprar itens necessários
  - Sobreviver 8 ondas? Se sim → ✅
  - Se morrer em qual onda? Ajustar dificuldade dessa onda.

- [ ] **5.4.2** **Build Huntress Isolation:** 1x Sentinel + 2x Huntress (separadas) + 1x Arcane Weaver
  - Verificar se lone_hunt passive funciona (Huntress isolada = +20% damage)
  - Sobreviver 8 ondas?

- [ ] **5.4.3** **Build Control:** 1x Sentinel + 1x Frost Maiden + 1x Divine Guardian + 1x Huntress
  - Verificar se frost_zone + sanctuary_aura funcionam
  - Sobreviver 8 ondas?

### ✅ CHECKPOINT — Fase 5

> **Todas as 3 builds sobrevivem 8 ondas com dificuldade moderada?** Se sim → MVP balanceado. Se não → ajustar stats da onda onde falha.

---

## FASE 6 — Cleanup & Polish (Pós-MVP Jogável)

> **Objetivo:** Código limpo, assets mínimos, pronto para teste externo
> **Tempo estimado:** 2-3 horas

### 6.1 Limpar Arquivos Antigos

- [ ] **6.1.1** Deletar pasta `projectguardians-main/` inteira (ou mover para `projectguardians-main-backup/`)

- [ ] **6.1.2** Deletar `autoload/GameManager_backup.gd` e `.uid`

### 6.2 Refatorar main.gd

- [ ] **6.2.1** Extrair handlers de relocate para `scripts/ui/relocate_handler.gd`

- [ ] **6.2.2** Extrair handlers de sell para `scripts/ui/sell_handler.gd`

- [ ] **6.2.3** Extrair handlers de placement para `scripts/ui/placement_handler.gd`

- [ ] **6.2.4** Reduzir `main.gd` para <400 linhas

### 6.3 Assets Mínimos

- [ ] **6.3.1** Verificar se goblin, orc, slime, goblin_boss têm sprites funcionais

- [ ] **6.3.2** Se faltando, criar placeholders coloridos (retângulos simples com cores distintas)

- [ ] **6.3.3** Criar ícones placeholder para 6 runas MVP (círculos coloridos com texto)

---

## 📊 Resumo de Dependências

```
FASE 1 (Reposicionamento)
  └── Nenhuma dependência externa — pode começar imediatamente

FASE 2 (Role Passives)
  └── Nenhuma dependência externa — pode começar imediatamente
  └── Depende de FASE 1 apenas para testar relocate com passive re-eval

FASE 3 (Soft Aggro)
  └── Nenhuma dependência externa — pode começar imediatamente

FASE 4 (Boss Phases)
  └── Depende de FASE 3 (boss precisa de statue targeting na Phase 2)

FASE 5 (Balanceamento)
  └── Depende de FASES 1-4 completas (precisa do loop inteiro funcionando)

FASE 6 (Cleanup)
  └── Depende de FASE 5 completa
```

---

## 🎯 Ordem Recomendada de Execução

1. **FASE 1** — Reposicionamento (torna o jogo interativo)
2. **FASE 2** — Role Passives (dá profundidade tática)
3. **FASE 3** — Soft Aggro (cria pressão real)
4. **FASE 4** — Boss Phases (fecha o loop de combate)
5. **FASE 5** — Balanceamento (valida tudo)
6. **FASE 6** — Cleanup (prepara para teste externo)

---

*Plano criado em: 12 de Abril de 2026*
*Total de tasks: ~55 | Estimativa total: 15-23 horas*
