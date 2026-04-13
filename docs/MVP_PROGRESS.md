# 📊 Progresso Real do MVP — Project Guardians

**Data da Análise:** 12 de Abril de 2026
**Última Verificação:** 12 de Abril de 2026 — FASE 1 COMPLETA ✅

---

## 🔵 Legenda

| Símbolo | Significado |
|---------|-------------|
| ✅ | Implementado e funcional no código |
| ✅⚠️ | Implementado mas NÃO configurado/testado |
| ❌ | NÃO implementado |
| 🔄 | Parcialmente implementado |

---

## 1. Reposicionamento (Shop + In-Combat) — ✅ FASE 1 COMPLETA

| Componente | Status | Arquivo | Notas |
|------------|--------|---------|-------|
| `begin_relocate_shop()` | ✅ | `arena.gd:488` | Funcional — libera célula, ghost sprite, highlight células válidas |
| `confirm_relocate_shop()` | ✅ | `arena.gd:507` | Funcional — valida célula, reposiciona, animação pop-in + shockwave |
| `cancel_relocate_shop()` | ✅ | `arena.gd:519` | Funcional — retorna estátua à posição original |
| `begin_relocate_combat()` | ✅ | `arena.gd:528` | Funcional — consome 1 charge, pausa ataque da estátua |
| `confirm_relocate_combat()` | ✅ | `arena.gd:545` | Funcional — retoma ataque após move |
| `cancel_relocate_combat()` | ✅ | `arena.gd:553` | Funcional — retoma ataque, refund charge |
| `highlight_valid_cells()` | ✅ | `arena.gd:462` | Highlight verde-azul nas células vazias |
| `clear_cell_highlights()` | ✅ | `arena.gd:474` | Limpa highlights |
| `_finish_relocate()` | ✅ | `arena.gd:564` | Animação de pop-in + shockwave + re-eval passive |
| `relocate_charges` no GameManager | ✅ | `GameManager.gd:95-101` | Com signal `relocate_charges_changed` |
| `consume_relocate_charge()` | ✅ | `GameManager.gd:108` | Funcional |
| `reset_relocate_charges_for_wave()` | ✅ | `GameManager.gd:103` | Chamado no início de cada onda |
| `is_tangy_mvp_active()` | ✅ | `GameManager.gd:91` | Checa `current_map.tangy_mvp_enabled` |
| `is_relocating` flag na estátua | ✅ | `statue_base.gd:18` | Usado para pausar ataque durante relocate |
| `set_paused()` na estátua | ✅ | `statue_base.gd:1144` | Pausa attack timer + ghost sprite |
| **Trigger: shop-phase reposition** | ✅ | `main.gd:468` | Right-click em estátua durante SHOP → `_enter_shop_relocate()` |
| **Botão de relocate no HUD** | ✅ | `hud.tscn:84` | `RelocateButton` adicionado em `ActionButtons` — visível em SHOP/COMBAT |
| **Signal de relocate button** | ✅ | `hud_controller.gd:8` | `signal relocate_button_pressed()` conectado |
| **Input handler para relocate (COMBAT)** | ✅ | `main.gd:407-448` | Left-click pick/confirm, right-click cancel |
| **Input handler para relocate (SHOP)** | ✅ | `main.gd:480-492` | `_input_shop_relocate()` com confirm/cancel |
| **Integração com inventory UI** | ✅ | `main.gd:789-807` | Inventory/shop escondidos durante relocate, restaurados ao sair |
| **Right-click shortcut (COMBAT)** | ✅ | `main.gd:453-467` | Right-click em estátua durante combate entra direto em relocate |
| **`is_relocate_mode` flag** | ✅ | `main.gd:31` | Gerencia estado do relocate mode |
| **`_exit_relocate_mode()`** | ✅ | `main.gd:819-829` | Limpa highlights, cancela relocate, restaura UI |
| **Debug prints** | ✅ | `hud_controller.gd:77`, `main.gd:457,483` | Prints para diagnostic state |

---

## 2. Role Passives

| Componente | Status | Arquivo | Notas |
|------------|--------|---------|-------|
| `tactical_role` field | ✅ | `statue_data.gd:43` | Enum int 0-5: None, Frontline, Precision DPS, Support, Control Support, Flexible |
| `passive_id` field | ✅ | `statue_data.gd:44` | String ID da passive |
| `passive_name` field | ✅ | `statue_data.gd:45` | Nome legível |
| `passive_description` field | ✅ | `statue_data.gd:46` | Descrição multiline |
| `passive_bonus_value` field | ✅ | `statue_data.gd:48` | Valor numérico (ex: 0.20 = +20%) |
| `aura_radius` field | ✅ | `statue_data.gd:49` | Radius em pixels |
| `base_threat` field | ✅ | `statue_data.gd:50` | Threat weight para soft aggro |
| **sentinel.tres: tactical_role=1, passive_id="sacred_line"** | ✅ | `resources/statues/sentinel.tres` | Configurado corretamente |
| **huntress.tres: tactical_role=2, passive_id="lone_hunt"** | ✅ | `resources/statues/huntress.tres` | Configurado corretamente |
| **divine_guardian.tres: tactical_role=3, passive_id="sanctuary_aura"** | ✅ | `resources/statues/divine_guardian.tres` | Configurado corretamente |
| **frost_maiden.tres: tactical_role=4, passive_id="frost_zone"** | ✅ | `resources/statues/frost_maiden.tres` | Configurado corretamente |
| **arcane_weaver.tres: tactical_role=5, passive_id="storm_focus"** | ✅⚠️ | `resources/statues/arcane_weaver.tres` | Configurado MAS `storm_focus` NÃO existe no `evaluate_passive()` |
| `evaluate_passive()` | ✅ | `statue_base.gd:979` | Match para lone_hunt, sacred_line, sanctuary_aura, frost_zone |
| `_check_lone_hunt()` | ✅ | `statue_base.gd:1006` | Check aliados dentro de 90px |
| `_check_sacred_line()` | ✅ | `statue_base.gd:1012` | Check se estátua mais próxima do spawn |
| `_check_frost_zone()` | ✅ | `statue_base.gd:1049` | Check se aliado frontline dentro de 90px |
| `_pulse_sanctuary_aura()` | ✅ | `statue_base.gd:1030` | Heal 5% max HP + heal particles + shockwave |
| `_apply_passive_bonus()` | ✅ | `statue_base.gd:1058` | Aplica/remove `damage_modifier` e `passive_dr` |
| `get_passive_dr()` | ✅ | `statue_base.gd:1082` | Retorna DR do sacred_line |
| `get_slow_multiplier()` | ✅ | `statue_base.gd:1087` | Retorna 1.4x se frost_zone ativo |
| `get_threat_value()` | ✅ | `statue_base.gd:1098` | base_threat + guard rune bonus |
| `get_adjacent_allies()` | ✅ | `statue_base.gd:1110` | Retorna aliados dentro de radius |
| `_passive_indicator` (ring visual) | ✅ | `statue_base.gd:1157-1172` | Ring desenhado via `_draw()` |
| `_update_passive_indicator()` | ✅ | `statue_base.gd:1178` | queue_redraw no ring |
| `passive_active` flag | ✅ | `statue_base.gd:33` | Usado em `_process()` para pulse |
| `evaluate_passive()` chamado em `_process()` | ✅ | `statue_base.gd:474` | Só quando `is_tangy_mvp_active()` |
| `passive_bonus_value` nos .tres | ✅⚠️ | sentinel.tres, huntress.tres | **NÃO setado explicitamente** — usa default 0.20 |
| `aura_radius` nos .tres | ✅⚠️ | divine_guardian.tres, frost_maiden.tres | **NÃO setado explicitamente** — usa default 120.0 |
| `storm_focus` implementada | ❌ | `statue_base.gd` | **Não existe no `evaluate_passive()` match** |
| DR aplicado em `take_damage()` | ❓ | `statue_base.gd` | **Precisa verificar se `take_damage()` consulta `get_passive_dr()`** |

---

## 3. Statue-Bound Equipment (Runas)

| Componente | Status | Arquivo | Notas |
|------------|--------|---------|-------|
| `equipped_items: Array[Resource]` | ✅ | `statue_base.gd:41` | Array de equipment |
| `equip_item()` | ✅ | `statue_base.gd:174` | Adiciona ao próximo slot vazio |
| `equip_item_at()` | ✅ | `statue_base.gd:190` | Equipa em slot específico |
| `unequip_item_at()` | ✅ | `statue_base.gd:207` | Remove item de slot |
| `can_equip()` | ✅ | `statue_base.gd:169` | Alias para `has_empty_slot()` |
| `get_max_slots()` | ✅ | `statue_base.gd:164` | Retorna 2 (MVP fixo) |
| `_recalculate_all_equipment_bonuses()` | ✅ | `statue_base.gd:221` | Recalcula dmg, speed, range, threat de todos os slots |
| `_refresh_equipment_visuals()` | ✅ | `statue_base.gd:264` | Glow rings + blended sprite tint |
| `_EquipGlowRing` class | ✅ | `statue_base.gd:297` | Inline class para glow animado |
| `apply_equipment_to_statue()` | ✅ | `GameManager.gd:377` | Remove do inventory, equipa na estátua |
| `unequip_from_statue()` | ✅ | `GameManager.gd:403` | Remove da estátua, volta ao inventory |
| **6 runas MVP .tres** | ✅ | `resources/equipment/power_rune.tres`, `range_rune.tres`, `quickstep_rune.tres`, `keen_rune.tres`, `channel_rune.tres`, `guard_rune.tres` | Existem com variants +1 |
| Equipment bonuses aplicados | ✅ | `statue_base.gd:221-262` | `_recalculate_all_equipment_bonuses()` aplica tudo |
| **UI: equipment slots no detail panel** | ❓ | `statue_inventory_ui.gd` | **Precisa verificar se o detail panel mostra slots** |
| **Shop pool bias para 6 runas MVP** | ❓ | `equipment_shop_ui.gd` | **Precisa verificar se shop prioriza runas MVP** |
| Ícones de runas nos .tres | ❓ | `resources/equipment/*.tres` | **Precisa verificar se `icon` texture está setada** |

---

## 4. Soft Aggro e Focus Indicators

| Componente | Status | Arquivo | Notas |
|------------|--------|---------|-------|
| `statue_targeting_chance` field | ✅ | `enemy_base.gd:49` | 0.0 = nunca, 1.0 = sempre |
| `current_statue_target` field | ✅ | `enemy_base.gd:48` | Node de estátua sendo focada |
| `_evaluate_statue_targeting()` | ✅ | `enemy_base.gd:547` | Encontra estátua com maior threat em range |
| `_set_statue_target()` | ✅ | `enemy_base.gd:576` | Set target + notifica estátua |
| `_clear_statue_target()` | ✅ | `enemy_base.gd:586` | Clear target + notifica estátua |
| `_aggro_eval_timer` | ✅ | `enemy_base.gd:50` | Re-avalia a cada 1.5s |
| Chamado em `_physics_process()` | ✅ | `enemy_base.gd:186-189` | Só quando `is_tangy_mvp_active()` |
| `_focus_icon` (red "!") | ✅ | `statue_base.gd:1185-1198` | Label vermelha sobre estátua focada |
| `set_enemy_focused()` | ✅ | `statue_base.gd:1202` | Mostra/esconde focus icon |
| `get_threat_value()` | ✅ | `statue_base.gd:1098` | base_threat + guard rune |
| **`statue_targeting_chance` configurado nos .tres** | ❌ | `resources/enemies/*.tres` | **Precisa verificar/setar nos enemies do MVP** |
| **Enemy ataca estátua focada (não só cristal)** | ❓ | `enemy_base.gd` | **Precisa verificar se inimigo para no caminho da estátua** |
| Aggro line visual | ❌ | — | Não implementado (opcional) |

---

## 5. Boss com Fases Táticas

| Componente | Status | Arquivo | Notas |
|------------|--------|---------|-------|
| `boss_phase: int = 1` | ✅ | `enemy_base.gd:53` | 1 = normal, 2 = enraged |
| `_check_phase_transition()` | ✅ | `enemy_base.gd:595` | Transição em 50% HP |
| `_on_phase_2_start()` | ✅ | `enemy_base.gd:604` | `statue_targeting_chance = 1.0`, speed +25%, shed slows, flash red |
| `can_summon` field | ✅ | `enemy_base.gd:44` | Flag de summon |
| `summon_timer` | ✅ | `enemy_base.gd:62` | Timer de summon |
| `_on_summon_timer()` | ✅ | `enemy_base.gd:394` | Spawna minions na posição do boss |
| **goblin_boss.tres: can_summon=true** | ✅ | `resources/enemies/goblin_boss.tres` | summon_cooldown=6.0, summon_enemy_id="goblin", summon_count=3 |
| **goblin_boss.tres: is_boss=true** | ✅ | `resources/enemies/goblin_boss.tres` | HP=200, damage=30, scale=1.5 |
| **Boss wave 8 no wave_data** | ✅ | `wave_data.gd:183-188` | Spawn 6 goblins + 4 orcs + goblin_boss |
| **Boss Phase 1 behavior ativo** | ❌ | — | Boss não tem behavior específico de Phase 1 (só o summon timer genérico) |
| **Boss Phase 2 lane sweep** | ❌ | — | **NÃO implementado** |
| **Boss visual distinction** | ✅ | `goblin_boss.tres` | scale_factor=1.5, tint_color=gold |
| **HUD boss phase notification** | ❌ | — | **NÃO implementado** |

---

## 6. Balanceamento das 8 Ondas

| Componente | Status | Arquivo | Notas |
|------------|--------|---------|-------|
| `_fill_tangy_mvp_wave()` | ✅ | `wave_data.gd:160-188` | 8 ondas hand-crafted |
| Onda 1: 5 goblins | ✅ | `wave_data.gd:162` | Tutorial |
| Onda 2: 7+3 goblins | ✅ | `wave_data.gd:164-165` | |
| Onda 3: 6 goblins + 2 orcs | ✅ | `wave_data.gd:167-168` | |
| Onda 4: 5 goblins + 4 orcs | ✅ | `wave_data.gd:170-171` | |
| Onda 5: 5 orcs + 4 goblins + 2 slimes | ✅ | `wave_data.gd:173-176` | |
| Onda 6: 6 orcs + 3 slimes + 5 goblins | ✅ | `wave_data.gd:178-181` | |
| Onda 7: 8 goblins + 6 orcs + 3 slimes | ✅ | `wave_data.gd:183-186` | Pre-boss pressure |
| Onda 8: 6 goblins + 4 orcs + goblin_boss | ✅ | `wave_data.gd:188-192` | Boss wave |
| **Enemy stats tuned** | ❓ | `resources/enemies/*.tres` | **Precisa verificar HP/damage/speed de cada enemy** |
| **Gold economy tuning** | ❓ | `GameManager.gd` | Wave bonus = `75 + wave*15`, precisa test in-game |
| **3 builds testáveis** | ❌ | — | **Nunca testado** |
| **Boss fight timing** | ❓ | — | **Precisa testar duração da wave 8** |

---

## 7. Infrastructure / Cleanup

| Componente | Status | Notas |
|------------|--------|-------|
| Pasta `projectguardians-main/` com arquivos antigos | ❌ | Contém versões antigas de 15+ arquivos .gd — deve ser deletada ou movida |
| `main.gd` com ~1030 linhas | ⚠️ | Funcional mas cresceu com relocate handlers — refatorar na Fase 6 |
| GameManager_backup.gd | ⚠️ | Backup na pasta autoload — pode deletar |
| Sprites de inimigos | ⚠️ | ~5/16 com sprites. Para MVP: goblin, orc, slime, goblin_boss têm sprites? |
| Áudio (música, SFX) | ❌ | Zero áudio implementado |
| Ícones de runas | ❓ | Precisa verificar se cada .tres tem `icon` texture |

---

## 📈 Score Geral

| Área | Progresso |
|------|-----------|
| Reposicionamento | ████████████████████ 100% ✅ **FASE 1 COMPLETA** |
| Role Passives | ███████████████░░░░░ 75% (código completo, falta storm_focus + tuning) |
| Equipment | ████████████████░░░░ 80% (sistema completo, falta UI polish) |
| Soft Aggro | ██████████████░░░░░░ 70% (avaliação existe, falta targeting em action + config) |
| Boss Phases | ████████████░░░░░░░░ 60% (Phase 2 existe, falta lane sweep + behavior) |
| Balanceamento | ████░░░░░░░░░░░░░░░░ 20% (ondas configuradas, sem tuning) |
| Assets/Polish | ████░░░░░░░░░░░░░░░░ 20% (sprites parciais, zero áudio) |

**Overall: ~60% do MVP funcionalmente jogável** (subiu de ~55%)
