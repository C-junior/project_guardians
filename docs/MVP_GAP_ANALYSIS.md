# 🎯 MVP Gap Analysis — O Que Falta Para Iniciar

**Projeto:** Project Guardians — MVP Adaptation Slice (Tangy-Style Tactical Defense)
**Data da Análise:** 12 de Abril de 2026
**Engine:** Godot 4.4 (GL Compatibility)
**Status Geral:** ~75% implementado — **Loop principal NÃO fecha ainda**

---

## 📊 Resumo Executivo

| Categoria | Status | Notas |
|-----------|--------|-------|
| **Arquitetura Base** | ✅ 95% | GameManager, EvolutionManager, ComboManager sólidos |
| **Combate Core** | ✅ 90% | Arena, estátuas, inimigos, projectiles funcionais |
| **Shop/Inventory** | ✅ 85% | Rebuilt para MVP, drag-and-drop, equipment slots |
| **Role Passives** | ⚠️ 60% | Código EXISTE em statue_base.gd mas NÃO está totalmente integrado |
| **Reposicionamento** | ⚠️ 50% | Código EXISTE em arena.gd mas NÃO testado/integrado ao flow |
| **Relocate HUD** | ❌ 0% | Botão/indicador de relocate charges NÃO existe no HUD |
| **Boss Phases** | ⚠️ 40% | Phase transition EXISTE mas Phase 1 behavior não está scriptado |
| **Soft Aggro** | ⚠️ 30% | Threat EXISTE em statue_data.gd mas enemy targeting não implementado |
| **Balanceamento** | ❌ 0% | 8 ondas geradas proceduralmente, sem tuning fino |
| **Assets Visuais** | ⚠️ 30% | 5/16 sprites de inimigos, zero áudio |

**Veredito:** O projeto tem **muito mais código implementado do que a documentação sugere**, mas faltam peças de integração críticas para o loop ser jogável.

---

## 🔍 Análise Detalhada por Sistema

---

### 1. 🔴 Reposicionamento (Shop Phase + In-Combat Relocate)

#### O que JÁ existe (código encontrado):

| Arquivo | O que existe | Status |
|---------|-------------|--------|
| `arena.gd` | `begin_relocate_shop()`, `confirm_relocate_shop()`, `cancel_relocate_shop()` | ✅ Implementado |
| `arena.gd` | `begin_relocate_combat()`, `confirm_relocate_combat()`, `cancel_relocate_combat()` | ✅ Implementado |
| `arena.gd` | `highlight_valid_cells()`, `clear_cell_highlights()` | ✅ Implementado |
| `arena.gd` | `_finish_relocate()` com animação de pop-in + shockwave | ✅ Implementado |
| `GameManager.gd` | `relocate_charges`, `consume_relocate_charge()`, `reset_relocate_charges_for_wave()` | ✅ Implementado |
| `GameManager.gd` | `is_tangy_mvp_active()` check | ✅ Implementado |
| `statue_base.gd` | `is_relocating` flag | ✅ Implementado |

#### O que FALTA (bloqueante):

| # | Tarefa | Arquivo(s) | Detalhe | Prioridade |
|---|--------|-----------|---------|------------|
| 1.1 | **Trigger de shop-phase reposition** | `main.gd`, `statue_inventory_ui.gd` | Não há nenhum código que chame `arena.begin_relocate_shop()` quando o jogador clica numa estátua durante a shop phase. O `sell_mode` existe mas usa venda, não movimento. | 🔴 CRÍTICO |
| 1.2 | **Botão/UI de relocate in-combat** | `hud.tscn`, `hud_controller.gd` | O HUD NÃO tem botão de relocate. Não há indicador visual de charges restantes. | 🔴 CRÍTICO |
| 1.3 | **Handler de clique no HUD para relocate** | `hud_controller.gd`, `main.gd` | Sem botão → sem signal → sem fluxo. Precisa conectar clique do botão → `arena.begin_relocate_combat()`. | 🔴 CRÍTICO |
| 1.4 | **Input handling para destino do relocate** | `main.gd` `_input()` | O `_input()` do main.gd lida com placement e upgrade mas NÃO com confirmação/cancelamento de relocate. | 🔴 CRÍTICO |
| 1.5 | **Integração com inventory UI durante relocate** | `statue_inventory_ui.gd`, `main.gd` | Durante relocate, o inventory UI deve esconder e o grid highlight deve aparecer. | 🟡 MÉDIA |
| 1.6 | **Testar fluxo completo** | — | Colocar estátua → entrar shop → mover estátua → confirmar → verificar upgrades mantidos. | 🟡 MÉDIA |

#### Especificação técnica do que precisa ser criado:

**HUD — Botão de Relocate:**
```
[⚡ Relocate: 1/1]  ← Button no HUD, visível apenas em COMBAT quando Tangy MVP ativo
```
- Signal `relocate_button_pressed` → `main.gd` entra em modo relocate
- Clique em estátua colocada → `arena.begin_relocate_combat(statue)`
- Grid highlight verde nas células válidas
- Clique em célula válida → `arena.confirm_relocate_combat(target_cell)`
- Clique direito → `arena.cancel_relocate_combat()`
- HUD atualiza charges restantes após uso

**Shop Phase — Mover estátua:**
- Durante SHOP state, clique direito numa estátua colocada entra em modo "pick up"
- Ou: botão "Move" no detail panel do inventory UI
- `arena.begin_relocate_shop(statue)` → highlight células válidas
- Clique em célula → `arena.confirm_relocate_shop(target_cell)`
- Clique direito → `arena.cancel_relocate_shop()`

---

### 2. 🔴 Role Passives

#### O que JÁ existe:

| Arquivo | O que existe | Status |
|---------|-------------|--------|
| `statue_data.gd` | `tactical_role` (enum int 0-5), `passive_id`, `passive_name`, `passive_description`, `passive_bonus_value`, `aura_radius` | ✅ Campos existem |
| `statue_base.gd` | `evaluate_passive()` com match para `lone_hunt`, `sacred_line`, `sanctuary_aura`, `frost_zone` | ✅ Implementado |
| `statue_base.gd` | `_check_lone_hunt()`, `_check_sacred_line()`, `_check_frost_zone()` | ✅ Implementado |
| `statue_base.gd` | `_pulse_sanctuary_aura()` com heal + efeitos visuais | ✅ Implementado |
| `statue_base.gd` | `_apply_passive_bonus()`, `get_passive_dr()`, `get_slow_multiplier()` | ✅ Implementado |
| `statue_base.gd` | `_passive_indicator` (ring visual) + `_focus_icon` (red "!") | ✅ Implementado |
| `statue_base.gd` | `get_adjacent_allies(radius)` helper | ✅ Implementado |

#### O que FALTA:

| # | Tarefa | Arquivo(s) | Detalhe | Prioridade |
|---|--------|-----------|---------|------------|
| 2.1 | **Configurar passive_id nos 5 .tres do MVP** | `resources/statues/sentinel.tres`, `huntress.tres`, `divine_guardian.tres`, `frost_maiden.tres`, `arcane_weaver.tres` | Os resources NÃO têm `passive_id` setado. Precisam de: `sentinel` → `"sacred_line"`, `huntress` → `"lone_hunt"`, `divine_guardian` → `"sanctuary_aura"`, `frost_maiden` → `"frost_zone"`, `arcane_weaver` → `""` (flexible, sem passive ou custom) | 🔴 CRÍTICO |
| 2.2 | **Configurar tactical_role nos 5 .tres do MVP** | Mesmos resources acima | `sentinel` → `1` (Frontline), `huntress` → `2` (Precision DPS), `divine_guardian` → `3` (Support), `frost_maiden` → `4` (Control Support), `arcane_weaver` → `5` (Flexible) | 🔴 CRÍTICO |
| 2.3 | **Configurar passive_bonus_value e aura_radius** | Mesmos resources | Valores sugeridos: `sentinel` → `passive_bonus_value: 0.15` (15% DR), `huntress` → `0.20` (+20% dmg), `divine_guardian` → `aura_radius: 150`, `frost_maiden` → `aura_radius: 90` | 🟡 MÉDIA |
| 2.4 | **Implementar passive para Arcane Weaver** | `statue_base.gd`, `arcane_weaver.tres` | Arcane Weaver é "Flexible DPS/Control" — precisa de uma passive custom (ex: chain lightning bounce +1 target quando aliado adjacente) OU deixar sem passive. | 🟡 MÉDIA |
| 2.5 | **DR aplicado em take_damage** | `statue_base.gd` `take_damage()` | Verificar se `take_damage()` consulta `get_passive_dr()` para aplicar damage reduction do sacred_line. Se não, adicionar. | 🟡 MÉDIA |
| 2.6 | **Slow multiplier aplicado em enemy apply_slow** | `enemy_base.gd` | Verificar se `apply_slow()` consulta `get_slow_multiplier()` da estátua mais próxima para estender duração do frost_zone. | 🟡 MÉDIA |
| 2.7 | **Tooltip/UX da passive no inventory UI** | `statue_inventory_ui.gd` | O detail panel deve mostrar `passive_name`, `passive_description` e estado (ativo/inativo). | 🟢 BAIXA |

---

### 3. 🟡 Equipment (Runas Vinculadas a Estátuas)

#### O que JÁ existe:

| Arquivo | O que existe | Status |
|---------|-------------|--------|
| `equipment_data.gd` | Resource com `bonus_damage_flat`, `bonus_damage_percent`, `bonus_attack_speed`, `bonus_range`, `bonus_threat`, `statue_tint`, `glow_color` | ✅ Campos existem |
| `statue_base.gd` | `equipped_items: Array[Resource]`, `equip_item()`, `unequip_item_at()`, `get_max_slots()` | ✅ Implementado |
| `statue_base.gd` | `_recalculate_all_equipment_bonuses()` | ✅ Implementado |
| `statue_base.gd` | `_refresh_equipment_visuals()` com glow rings coloridos | ✅ Implementado |
| `GameManager.gd` | `apply_equipment_to_statue()`, `unequip_from_statue()`, `get_max_equipment_slots_for_tier()` | ✅ Implementado |
| 15 .tres files | 6 runas base + 6 +1 versions + 3 items especiais (executioner_edge, ember_shard, swift_lens) | ✅ Existem |
| `equipment_shop_ui.gd` | Vende equipment e adiciona ao inventory | ✅ Implementado |

#### O que FALTA:

| # | Tarefa | Arquivo(s) | Detalhe | Prioridade |
|---|--------|-----------|---------|------------|
| 3.1 | **Equipment bonuses aplicados em combate** | `statue_base.gd` | `_recalculate_all_equipment_bonuses()` já aplica os bonuses. **VERIFICAR** se os valores nos .tres estão corretos (ex: power_rune.tres deve ter `bonus_damage_percent = 0.25`). | 🟡 VERIFICAR |
| 3.2 | **UI de equipment no detail panel** | `statue_inventory_ui.gd` | O detail panel da estátua deve mostrar slots de equipment com ícones das runas equipadas e slots vazios. | 🟡 MÉDIA |
| 3.3 | **Shop prioriza 6 runas MVP** | `equipment_shop_ui.gd` | O shop deve ter pesos maiores para as 6 runas MVP (power, range, quickstep, keen, channel, guard) e filtrar itens fora do MVP pool. | 🟡 MÉDIA |
| 3.4 | **Ícones visuais das runas** | `resources/equipment/*.tres` | Verificar se cada .tres tem `icon` texture setada. Se não, criar placeholders. | 🟢 BAIXA |
| 3.5 | **Tooltip de equipment** | `statue_inventory_ui.gd` | Hover em equipment mostra nome, descrição e stat bonus. | 🟢 BAIXA |

---

### 4. 🟡 Soft Aggro e Focus Indicators

#### O que JÁ existe:

| Arquivo | O que existe | Status |
|---------|-------------|--------|
| `statue_data.gd` | `base_threat: float = 1.0` | ✅ Campo existe |
| `statue_base.gd` | `_focus_icon: Label` (red "!") criado em `_build_focus_icon()` | ✅ Implementado |
| `statue_base.gd` | `set_enemy_focused(focused: bool)` | ✅ Implementado |
| `statue_base.gd` | `_is_enemy_targeted` flag | ✅ Implementado |
| `enemy_base.gd` | `current_statue_target: Node` | ✅ Campo existe |
| `enemy_base.gd` | `_set_statue_target(statue)`, `_clear_statue_target()` | ✅ Implementado |
| `enemy_base.gd` | `statue_targeting_chance: float` | ✅ Campo existe |

#### O que FALTA:

| # | Tarefa | Arquivo(s) | Detalhe | Prioridade |
|---|--------|-----------|---------|------------|
| 4.1 | **Enemy target selection logic** | `enemy_base.gd` | Inimigos precisam de uma função `_select_statue_target()` que: (a) verifica `statue_targeting_chance`, (b) se roll passar, encontra estátua com maior threat em range de ataque, (c) chama `_set_statue_target()`. | 🔴 CRÍTICO |
| 4.2 | **Inimigos com statue_targeting_chance > 0** | `resources/enemies/*.tres` | Configurar `statue_targeting_chance` nos enemies do MVP. Sugeridos: Goblin=0, Orc=0.15, Slime=0, Goblin Boss=1.0 (sempre). | 🔴 CRÍTICO |
| 4.3 | **Enemy attack target priority** | `enemy_base.gd` `_attack()` | Quando inimigo ataca, deve verificar se tem `current_statue_target`. Se sim, ataca estátua. Se não, vai para o cristal. | 🟡 MÉDIA |
| 4.4 | **Threat calculation dinâmica** | `statue_base.gd` | Adicionar `calculate_threat()` que considera: `base_threat` + distância ao spawn + equipment (Guard Rune). Inimigos usam isso para escolher alvo. | 🟡 MÉDIA |
| 4.5 | **Aggro line visual** | `enemy_base.gd` | Opcional: Line2D do inimigo até a estátua focada para clareza visual. | 🟢 BAIXA |

---

### 5. 🟡 Boss com Fases Táticas

#### O que JÁ existe:

| Arquivo | O que existe | Status |
|---------|-------------|--------|
| `enemy_base.gd` | `boss_phase: int = 1`, `_check_phase_transition()`, `_on_phase_2_start()` | ✅ Implementado |
| `enemy_base.gd` | Phase 2: `statue_targeting_chance = 1.0`, speed +25%, shed slows | ✅ Implementado |
| `enemy_base.gd` | Visual transition: flash red → normal | ✅ Implementado |
| `goblin_boss.tres` | Resource existe com `is_boss = true` | ✅ Existe |
| `wave_data.gd` | Onda 8 spawn `goblin_boss` com 6 goblins + 4 orcs | ✅ Configurado |

#### O que FALTA:

| # | Tarefa | Arquivo(s) | Detalhe | Prioridade |
|---|--------|-----------|---------|------------|
| 5.1 | **Boss Phase 1 behavior script** | `enemy_base.gd` `_process()` ou `_physics_process()` | Phase 1 precisa de behavior ativo: (a) move toward crystal, (b) summon timer para spawn adds (3 goblins a cada 6s). Atualmente não há código de behavior por fase — só a transição. | 🔴 CRÍTICO |
| 5.2 | **Boss summon adds mechanic** | `enemy_base.gd` | Função `_summon_goblin_adds(count)` que spawna goblins na posição do boss. Precisa de referência à arena. | 🔴 CRÍTICO |
| 5.3 | **Boss Phase 2 lane sweep** | `enemy_base.gd` | Lane sweep: AOE damage em linha à frente do boss a cada 4s. Deve afetar estátuas E cristal. | 🟡 MÉDIA |
| 5.4 | **Boss stats balanceados para 8 waves** | `goblin_boss.tres` | Verificar HP, damage, speed do boss. Para 8 waves MVP, sugerido: HP=300-500, damage=15-20 por hit. | 🟡 MÉDIA |
| 5.5 | **Boss visual distinction** | `enemy_base.gd`, `goblin_boss.tres` | Boss deve ser maior, com sprite diferenciado ou scale aumentado. Phase 2 já tem flash red — adicionar scale +1.2. | 🟢 BAIXA |
| 5.6 | **HUD boss phase notification** | `hud_controller.gd` | Mensagem "BOSS PHASE 2 — ENRAGED!" no HUD quando transição ocorrer. | 🟢 BAIXA |

---

### 6. 🔴 Balanceamento das 8 Ondas

#### O que JÁ existe:

| Arquivo | O que existe | Status |
|---------|-------------|--------|
| `wave_data.gd` | `_fill_tangy_mvp_wave()` com 8 ondas hand-crafted | ✅ Implementado |
| `wave_data.gd` | Composição de cada onda configurada | ✅ Implementado |

#### O que FALTA:

| # | Tarefa | Arquivo(s) | Detalhe | Prioridade |
|---|--------|-----------|---------|------------|
| 6.1 | **Enemy stats tuned para MVP** | `resources/enemies/*.tres` | Verificar HP/damage/speed de goblin, orc, slime, goblin_boss. Ondas 1-2 devem ser fáceis, 3-5 moderadas, 6-7 difíceis, 8 boss. | 🟡 MÉDIA |
| 6.2 | **Gold economy tuning** | `GameManager.gd`, `wave_data.gd` | Testar: jogador consegue comprar ~2-3 itens entre ondas 1-4? Se não, ajustar wave bonus (`75 + wave*15`) ou preços. | 🟡 MÉDIA |
| 6.3 | **3 builds testáveis** | — | Testar manualmente: (a) Frontline-heavy (2 sentinel + support), (b) Huntress isolation (2 huntress separadas), (c) Control (frost + divine). Todas devem sobreviver 8 ondas. | 🟡 MÉDIA |
| 6.4 | **Boss fight timing** | `goblin_boss.tres`, `wave_data.gd` | Boss wave (8) deve durar 60-120 segundos. Se muito curto → aumentar HP. Se muito longo → reduzir. | 🟡 MÉDIA |

---

### 7. 🟢 Assets e Polish (Pós-MVP Jogável)

| # | Tarefa | Detalhe | Prioridade |
|---|--------|---------|------------|
| 7.1 | **Sprites de inimigos faltantes** | Apenas 5/16 têm sprites. Para MVP: goblin, orc, slime, goblin_boss são essenciais. | 🟡 MÉDIA |
| 7.2 | **Ícones de runas** | 6 runas MVP precisam de ícones visuais (podem ser placeholders coloridos). | 🟢 BAIXA |
| 7.3 | **Limpar pasta `projectguardians-main/`** | Contém versões antigas de scripts. Deletar ou mover para backup. | 🟢 BAIXA |
| 7.4 | **Refatorar `main.gd`** | 862 linhas — extrair handlers de UI, placement, sell para módulos separados. | 🟢 BAIXA |
| 7.5 | **Zero áudio** | Sem música, sem SFX. Pode ser adicionado pós-MVP. | ⚪ PÓS-MVP |

---

## 🏗️ Ordem de Implementação Recomendada

Baseado nas dependências entre sistemas:

```
FASE 1 — Tornar o Loop Jogável (CRÍTICO)
═════════════════════════════════════════
  1.1  Configurar passives nos 5 .tres do MVP    ← 30min
  1.2  Integrar shop-phase reposition            ← 2h
  1.3  Criar botão de relocate no HUD            ← 2h
  1.4  Input handling para relocate              ← 1h
  1.5  Enemy target selection (soft aggro)       ← 2h
  1.6  Boss Phase 1 behavior + summon            ← 3h

  ✅ CHECKPOINT: Loop 8-wave jogável (mesmo que desbalanceado)

FASE 2 — Refinamento do Loop (MÉDIA)
═════════════════════════════════════
  2.1  Boss Phase 2 lane sweep                   ← 2h
  2.2  Configurar statue_targeting_chance        ← 30min
  2.3  DR em take_damage (sacred_line)           ← 30min
  2.4  Slow multiplier (frost_zone)              ← 30min
  2.5  UI: equipment slots no detail panel       ← 2h
  2.6  Shop prioriza 6 runas MVP                 ← 1h

  ✅ CHECKPOINT: Loop jogável COM sistemas táticos funcionando

FASE 3 — Balanceamento (MÉDIA)
═══════════════════════════════
  3.1  Tune enemy stats                          ← 2h
  3.2  Tune gold economy                         ← 1h
  3.3  Test 3 builds                             ← 3h
  3.4  Adjust wave pacing                        ← 2h

  ✅ CHECKPOINT: MVP balanceado e testável

FASE 4 — Polish (BAIXA — Pós-MVP)
══════════════════════════════════
  4.1  Sprites faltantes                         ← TBD
  4.2  Ícones de runas                           ← TBD
  4.3  Limpar projectguardians-main/             ← 30min
  4.4  Refatorar main.gd                         ← 3h
  4.5  Áudio                                     ← TBD
```

**Estimativa total para MVP jogável (Fases 1-2): 16-20 horas**
**Estimativa total para MVP balanceado (Fases 1-3): 24-30 horas**

---

## ✅ Checklist Consolidado

### Sistemas Críticos (bloqueiam jogo jogável)

- [ ] **1.1** Configurar `passive_id` + `tactical_role` nos 5 .tres do MVP
- [ ] **1.2** Integrar shop-phase reposition (trigger → begin_relocate_shop → confirm/cancel)
- [ ] **1.3** Criar botão de relocate no HUD com indicator de charges
- [ ] **1.4** Input handling no main.gd para relocate (confirm/cancel com clique)
- [ ] **1.5** Enemy target selection logic (soft aggro com threat)
- [ ] **1.6** Boss Phase 1 behavior (move to crystal + summon adds timer)

### Sistemas de Refinamento (melhoram experiência)

- [ ] **2.1** Boss Phase 2 lane sweep mechanic
- [ ] **2.2** Configurar `statue_targeting_chance` nos enemies do MVP
- [ ] **2.3** Verificar/aplicar DR do sacred_line em `take_damage()`
- [ ] **2.4** Verificar/aplicar slow multiplier do frost_zone em `enemy.apply_slow()`
- [ ] **2.5** Equipment slots visíveis no detail panel do inventory UI
- [ ] **2.6** Shop pool bias para 6 runas MVP

### Balanceamento (validação)

- [ ] **3.1** Enemy stats (HP/damage/speed) tuned para curva de 8 ondas
- [ ] **3.2** Gold economy: jogador faz 2-3 compras por wave早期, 1-2 tarde
- [ ] **3.3** 3 builds testáveis completam 8 ondas
- [ ] **3.4** Boss fight dura 60-120s

### Cleanup (não bloqueia)

- [ ] **4.1** Limpar pasta `projectguardians-main/`
- [ ] **4.2** Refatorar `main.gd` (extrair módulos)
- [ ] **4.3** Adicionar sprites mínimos (goblin, orc, slime, boss)
- [ ] **4.4** Ícones placeholder para runas

---

## 📝 Notas Técnicas Importantes

### Código Duplicado
A pasta `projectguardians-main/` contém versões antigas dos mesmos arquivos que existem na raiz. Isso causa confusão:
```
GameManager.gd (root)         ← ATUAL, em uso
projectguardians-main/GameManager.gd  ← ANTIGO, deletar
```
**Recomendação:** Deletar `projectguardians-main/` após confirmar que tudo está migrado.

### Estados do Game Flow
O fluxo atual é:
```
MENU → SETUP (blessing + statue selection) → COMBAT → SHOP → COMBAT → ... → GAME OVER
```
Durante SHOP phase:
- `main.gd` abre `equipment_shop_ui`
- `statue_inventory_ui` pode ser toggled com botão do HUD
- **Falta:** ability de clicar numa estátua colocada e movê-la (reposition)

### Tangy MVP Flag
O sistema usa `GameManager.is_tangy_mvp_active()` que checa `current_map.tangy_mvp_enabled`. O mapa `grove.tres` deve ter essa flag ativada. **Verificar.**

---

*Documento criado em: 12 de Abril de 2026*
*Baseado na análise de 46 arquivos .gd, 24 arquivos .tscn, 39 arquivos .tres*
