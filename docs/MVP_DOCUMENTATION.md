# 🎮 Project Guardians - MVP Documentation Consolidada
**Projeto:** Project Guardians - Tower Defense Roguelike  
**Engine:** Godot 4.4 (GL Compatibility)  
**Data:** 11 de Abril de 2026  
**Status:** MVP Adaptation Slice (Tangy-Style Tactical Defense)

---

## 📋 Índice

1. [Visão Geral do Jogo](#visão-geral-do-jogo)
2. [MVP Scope - O Que Estamos Construindo](#mvp-scope)
3. [Arquitetura do Projeto](#arquitetura-do-projeto)
4. [Sistemas Principais](#sistemas-principais)
5. [Balanceamento e Valores](#balanceamento-e-valores)
6. [Estrutura de Arquivos](#estrutura-de-arquivos)
7. [Plano de Implementação do MVP](#plano-de-implementação-do-mvp)

---

## Visão Geral do Jogo

### Conceito Principal
Um Tower Defense Roguelike onde o jogador comanda estátuas de heroínas para defender um **Cristal Sagrado** contra ondas de inimigos. Cada estátua é um campeão com identidade tática, habilidades especiais e equipamentos.

### Diferenciais Chave
- **Estátuas de Heroínas** em vez de torres genéricas - cada uma com personalidade e poder
- **Evolução por Fusão** - 3 estátuas iguais = 1 evoluída (4 tiers)
- **Shop Roguelike** - ofertas aleatórias entre ondas
- **Defesa Tática** - reposicionamento, roles táticos, pressão inimiga
- **Meta-progressão** - Árvore de Habilidades (Aether Sanctum)

### Gênero e Plataforma
- **Gênero:** Tower Defense Roguelike
- **Engine:** Godot 4.4 (GL Compatibility)
- **Plataforma:** PC (Windows)

---

## MVP Scope

### 🎯 Objetivo do MVP
Transformar Project Guardians de um "shop-heavy roguelite TD" em um "tactical heroine defense roguelite" onde o jogador vence por:

1. Construir uma formação com frontline, damage e support claros
2. Reposicionar estátuas quando a pressão inimiga muda
3. Equipar upgrades significativos vinculados a cada estátua
4. Usar espaçamento e bônus de formação intencionalmente
5. Ler o foco inimigo e reagir antes do cristal colapsar

### ✅ MVP Frozen Slice v1 (ESCOPO TRAVADO)

#### Mapa
- **The Sacred Grove** (mapa tutorial já existente)

#### Duração da Run
- **8 ondas** no total
- Onda 8 é o boss final

#### Boss
- **Goblin Boss** retunado como único boss do MVP
- Mínimo **2 fases táticas** legíveis

#### Roster de Estátuas (5)
| Estátua | Role | Função Tática |
|---------|------|---------------|
| **Sentinel** | Frontline | Tank/Stun, damage reduction |
| **Huntress** | Precision DPS | Dano isolado, longo alcance |
| **Divine Guardian** | Support | Aura heal/shield para aliados |
| **Frost Maiden** | Control Support | Freeze/slow em área |
| **Arcane Weaver** | Flexible DPS/Control | Chain lightning, bounce damage |

#### Pool de Equipamentos (6 Runas)
| Runa | Efeito |
|------|--------|
| **Power Rune** | +25% dano |
| **Range Rune** | +2 range |
| **Quickstep Rune** | +30% attack speed |
| **Keen Rune** | +20% crit chance |
| **Channel Rune** | -30% ability cooldown |
| **Guard Rune** | +50% HP, +threat (frontline) |

#### Sistemas Incluídos no MVP
- ✅ Reposicionamento na fase de shop
- ✅ 1 carga de relocate em combate por onda
- ✅ 3 role passives: frontline, precision DPS, support
- ✅ 3-4 positioning synergies
- ✅ Equipamento vinculado a estátua
- ✅ Soft aggro/focus indicators
- ✅ Boss com 2+ fases táticas

#### ❌ Explicitamente FORA do MVP
- Earthshaker e Shadow Dancer retune
- Múltiplos bosses
- Mapas adicionais
- Crafting/cauldron systems
- Endless mode rebalance
- Skill trees de 300 nodes
- Pool de 100+ itens
- Free real-time tower dragging sem limites

---

## Arquitetura do Projeto

### Autoloads (Singletons)
| Autoload | Responsabilidade |
|----------|-----------------|
| **GameManager.gd** | Estado global da run: ouro, vidas, onda atual, inventário, save/load, relocate charges |
| **EvolutionManager.gd** | Fusão/evolução de estátuas (3-do-mesmo = 1 evoluída) |
| **ComboManager.gd** | Tracking de combo de kills com recompensas de ouro |
| **TutorialManager.gd** | Prompts contextuais de tutorial |

### Cenas Principais
| Cena | Função |
|------|--------|
| **Main** | Entry point, controlador de fluxo |
| **MainMenu** | Tela de menu principal |
| **Arena** | Arena de combate principal com grid |
| **Enemy** | Prefab de inimigo |
| **Statue** | Prefab de estátua/torre |
| **HUD** | Overlay de HUD in-game |
| **ShopUI** | Tela de shop na fase de preparação |
| **InventoryUI** | Inventário com drag-and-drop |

### Scripts de Combate
| Script | Função |
|--------|--------|
| **arena.gd** | Controller de combate: grid, spawns, ondas, relocate |
| **statue_base.gd** | Lógica de estátua: targeting, ataques, habilidades, evolução, equipment |
| **enemy_base.gd** | Lógica de inimigo: path, HP, status effects, soft aggro |
| **effects_manager.gd** | Efeitos visuais (projéteis, impactos, shockwaves) |

### Resources (Data)
| Resource | Conteúdo |
|----------|----------|
| **StatueData** | Stats, habilidades, roles táticos, equipment slots |
| **EnemyData** | Definições de inimigos (HP, velocidade, dano, comportamento) |
| **EquipmentData** | Runas/equipamentos vinculados a estátua |
| **WaveData** | Geração de ondas: 8-wave MVP Tangy |
| **ArtifactData** | Efeitos passivos globais de run |
| **BlessingData** | Bônus iniciais de run |

---

## Sistemas Principais

### 1. Sistema de Estátuas

#### Evolution Tiers
| Tier | Nome | Mult Stats | Slots Upgrade |
|------|------|------------|---------------|
| 0 | ★ Base | 1.0× | 1 |
| 1 | ★★ Enhanced | 1.4× | 2 |
| 2 | ★★★ Awakened | 1.8× | 3 |
| 3 | ★★★★ Divine | 2.5× | 4 |

#### Raridade na Shop
| Raridade | Mult Stats | Drop Weight | Cor |
|----------|------------|-------------|-----|
| Common | 1.00× | 50% | Cinza |
| Uncommon | 1.15× | 30% | Verde |
| Rare | 1.30× | 15% | Azul |
| Epic | 1.50× | 4% | Roxo |
| Legendary | 1.80× | 1% | Laranja/Dourado |

#### As 7 Heroínas (5 no MVP)
| Estátua | Role | Ataque | Habilidade Especial |
|---------|------|--------|---------------------|
| **Sentinel** | Frontline | Melee | Shield Bash - Stun em área, damage reduction |
| **Huntress** | Precision DPS | Long | Piercing Arrow - Atravessa linha de inimigos |
| **Divine Guardian** | Support | Medium | Radiant Smite - Dano massivo + heal aliados |
| **Frost Maiden** | Control Support | Medium | Frozen Prison - Imobiliza área 4s |
| **Arcane Weaver** | Flexible DPS | Medium | Chain Lightning - Bounce para 3 inimigos |
| Earthshaker | Frontline | Short | Ground Slam - AOE + 50% slow 3s |
| Shadow Dancer | Precision DPS | Medium | Blade Storm - 200% attack speed 5s |

### 2. Sistema de Reposicionamento (Relocate)

**Regras do MVP:**
- **1 charge por onda** para mover estátua em combate
- **Movimento livre** durante shop/prep phase
- Células válidas destacadas no grid
- Upgrades/equipamentos permanecem attached
- Relocate tem curto cast time para evitar spam

### 3. Roles Táticos

| Role | Estátuas | Bônus Passivo |
|------|----------|---------------|
| **Frontline** | Sentinel, Earthshaker | Mitigação quando exposta, gera mais threat |
| **Precision DPS** | Huntress, Shadow Dancer, Arcane Weaver | Bônus dano quando isolada |
| **Support/Control** | Divine Guardian, Frost Maiden | Aura heal/shield/cooldown para aliados próximos |

### 4. Positioning Synergies (MVP)

| Sinergia | Estátua | Condição | Efeito |
|----------|---------|----------|--------|
| **Lone Hunt** | Huntress | Sem aliados adjacentes | +20% dano |
| **Sacred Line** | Sentinel | Na frente de todos os aliados | +mitigação |
| **Sanctuary Aura** | Divine Guardian | Aliados dentro do raio | Heal/shield periódico |
| **Frost Zone** | Frost Maiden | Atrás de frontline | +slow duration |

### 5. Sistema de Equipamento (Runas)

**Regras:**
- Equipamentos são **vinculados a uma estátua específica**
- Slots baseados no tier de evolução (1-4 slots)
- Equipamentos permanecem na estátua ao mover/vender

**Meta Bônus:**
| Upgrade | Efeito | Custo AE |
|---------|--------|----------|
| Runic Mastery I | +1 slot base | 500 AE |
| Runic Mastery II | +1 slot base | 1000 AE |

### 6. Soft Aggro e Pressão Inimiga

**Regras do MVP:**
- Alguns inimigos podem **targeting estátuas** antes do cristal
- Estátuas Frontline geram **mais threat**
- HUD mostra indicadores visuais de foco
- Isso torna o posicionamento da frontline crucial

### 7. Boss com Fases Táticas

**Goblin Boss (Onda 8 do MVP):**
| Fase | Comportamento | Mecânica |
|------|---------------|----------|
| **Phase 1** | Pressiona cristal diretamente | Summon adds (3 goblins a cada 6s) |
| **Phase 2** | Targeting estátuas | Lane sweep ou ataque focalizado |

O boss deve exigir **reposicionamento** durante a luta.

### 8. Economia

#### Status Iniciais
| Stat | Valor |
|------|-------|
| Ouro Inicial | 200 |
| HP do Cristal | 100 |
| Estátuas Iniciais | 1 (aleatória Comum) |
| Blessing Inicial | 1 escolha entre 3 |

#### Ganho de Ouro
| Fonte | Valor |
|-------|-------|
| **Wave Completion** | `75 + (Onda × 15)` Ouro |
| **Boss Kill** | 200g + guaranteed rare item |
| **Reroll Cost** | `30 + (20 × rerolls)` Ouro |

#### Preços de Estátuas (base Common)
| Categoria | Faixa de Preço |
|-----------|----------------|
| Common | 300-400g |
| Uncommon | 450-550g |
| Rare | 600-700g |
| Epic | 750-850g |
| Legendary | 900-1000g |

### 9. Sistema de Itens (Shop)

**Categorias:**
| Categoria | Faixa Preço | Exemplos |
|-----------|-------------|----------|
| Novas Estátuas | 300-1000g | Baseado na raridade |
| Artefatos | 150-500g | Bônus passivos globais |
| Equipamentos/Runas | 200-400g | Upgrades por estátua |
| Consumíveis | 25-75g | Efeitos de 1 onda |

**Blessings Iniciais (5):**
| Blessing | Efeito |
|----------|--------|
| **Warrior's Resolve** | Começa com Sentinel grátis |
| **Merchant's Fortune** | +100% ouro inicial (400g) |
| **Ancient Power** | Primeira compra 50% off |
| **Quick Reflexes** | -25% cooldowns |
| **Crystal Heart** | +75% HP cristal |

### 10. Meta-Progressão (Aether Sanctum)

**Ganho de Aether Essence:**
- **10 AE** por onda sobrevivida
- **Bônus de Boss**: +25 AE por boss derrotado

**Desbloqueios:**
| Unlock | Custo AE | Efeito |
|--------|----------|--------|
| Statue Slots +1 | 400-1500 AE | Aumenta máximo de estátuas (base 4) |
| Nova Estátua | 500 AE | Adiciona ao pool da shop |
| Novo Artefato | 300 AE | Adiciona ao pool da shop |
| Nova Blessing | 400 AE | Adiciona às opções iniciais |

**Save/Load:** `user://save_data.json`

---

## Balanceamento e Valores

### Fórmulas de Cálculo

#### Dano Final de Estátua
```gdscript
var base = statue_data.base_damage
var rarity_mult = RARITY_MULTIPLIERS[statue.rarity]  # 1.0 a 1.8
var tier_mult = TIER_MULTIPLIERS[statue.evolution_tier]  # 1.0 a 2.5

# Equipment bónus
var equip_bonus = 1.0
for equip in statue.equipment:
    if equip.type == EquipmentType.POWER_RUNE:
        equip_bonus += 0.25  # +25%

# Global artifact bónus
var artifact_bonus = 1.0 + (GameManager.artifact_damage_bonus or 0.0)

var final_damage = base * rarity_mult * tier_mult * equip_bonus * artifact_bonus
```

#### Evolução (Merge)
- Requer **3 estátuas iguais** (mesmo tipo e tier)
- Resultado: **1 estátua do próximo tier**
- Stats multiplicados conforme tier

#### Combo System
- Kills dentro de **2s** contam para combo
- x5 combo: +5g bônus
- x10 combo: +15g bônus
- x20 combo: +50g bônus
- Combo reseta após 2s sem kill

### Estrutura de Ondas (MVP - 8 ondas)

| Onda | Composição | Notas |
|------|------------|-------|
| 1 | Goblins apenas | Tutorial |
| 2 | Goblins + Orcs | Introdução |
| 3-4 | Mix crescente | Pressão moderada |
| 5 | **Goblin Boss** (Phase 1) | Boss wave |
| 6-7 | Mix + elites | Introdução soft aggro |
| 8 | **Goblin Boss** (Phase 2) | Boss Final com 2+ phases |

### Inimigos no MVP

| Inimigo | HP Base | Velocidade | Notas |
|---------|---------|------------|-------|
| **Goblin** | Baixo | Rápida | Spawn comum |
| **Orc** | Médio | Média | Spawn a partir onda 3 |
| **Mini Slime** | Mínimo | Lenta | Spawned by slime death |

**Nota:** Apenas inimigos necessários para as 8 ondas do MVP devem estar ativos. Outros tipos podem existir nos resources mas não spawnar no MVP.

---

## Estrutura de Arquivos

```
projectguardians/
├── autoload/
│   ├── GameManager.gd          # Estado global, save/load, relocate charges
│   ├── EvolutionManager.gd     # Fusão/evolução
│   ├── ComboManager.gd         # Combo tracking
│   └── TutorialManager.gd      # Tutorial prompts
├── scenes/
│   ├── main/                   # Main, menu
│   ├── combat/                 # Arena, statue, enemy
│   ├── entities/               # Enemy, statue prefabs
│   └── ui/                     # HUD, shop, inventory, etc.
├── scripts/
│   ├── combat/                 # Arena, statue, enemy logic
│   ├── data/                   # Resources definitions
│   └── ui/                     # UI controllers
├── resources/
│   ├── statues/                # 7 .tres files
│   ├── enemies/                # 16 .tres files
│   ├── artifacts/              # 8 .tres files
│   ├── blessings/              # 5 .tres files
│   ├── consumables/            # 7 .tres files
│   ├── equipment/              # 6 .tres files (runas MVP)
│   ├── upgrades/               # 5 .tres files
│   └── maps/                   # 3 .tres files
├── assets/
│   ├── classes/                # Portraits (10 images)
│   ├── artifacts/              # Icons
│   ├── enemies/                # Sprites (5 existentes)
│   ├── maps/                   # Backgrounds
│   └── runes/                  # Ability icons
└── docs/
    ├── MVP_DOCUMENTATION.md    # ESTE ARQUIVO - Doc consolidada do MVP
    └── usertodo.md             # TODO para assets e decisões criativas
```

---

## Plano de Implementação do MVP

### 📊 Estado Atual do Projeto

#### ✅ Implementado e Funcional
- 7 estátuas únicas com habilidades e targeting
- Sistema de evolução 4 tiers
- Shop com estátuas, artefatos, consumíveis, upgrades
- Inventário com drag-and-drop
- Sistema de blessings (5 opções)
- Combate: crits, damage numbers, efeitos visuais
- Combo system
- Meta-progressão UI + save/load
- Wave generation (8 ondas configuráveis)
- Efeitos de evolução

#### ⚠️ Implementado mas Precisa Refinamento para MVP
- Tutorial prompts
- Balanceamento de ondas/stats para 8-wave MVP
- Settings menu

#### ❌ Pendente (Prioridade MVP)
- **Reposicionamento em shop phase**
- **Relocate in-combat (1 charge/onda)**
- **Role passives** (frontline, precision DPS, support)
- **Positioning synergies** (3-4)
- **Equipamentos vinculados a estátua** (reframe upgrades)
- **Soft aggro/focus indicators**
- **Boss com 2+ fases táticas**

---

### 🎯 Ordem de Implementação Recomendada

**Sequência mais segura:**

1. Shop-phase reposition
2. Role passives
3. Passive feedback (UI indicators)
4. Statue-bound equipment
5. In-combat relocate
6. Soft aggro
7. Boss phases
8. Balance pass

Esta ordem mantém o projeto jogável em cada etapa e permite testar o loop de adaptação cedo.

---

### 📋 Fases de Implementação

#### Fase 1: Reposicionamento (Shop + In-Combat)

**Tarefas:**
- [ ] Permitir selecionar estátua colocada na fase de shop
- [ ] Permitir mover para célula vazia válida
- [ ] Manter upgrades/equipamentos attached
- [ ] Adicionar 1 carga de relocate por onda
- [ ] Implementar validação de células válidas
- [ ] Highlight de células válidas/bloqueadas
- [ ] Adicionar relocate charges ao HUD

**Arquivos Principais:**
- `scripts/combat/arena.gd`
- `scripts/main.gd`
- `autoload/GameManager.gd`
- `scenes/ui/hud.tscn`

**Critério de Conclusão:**
- ✅ Estátua pode ser movida na shop sem vender/recomprar
- ✅ 1 relocate funciona mid-wave
- ✅ HUD mostra cargas restantes

---

#### Fase 2: Role Passives

**Tarefas:**
- [ ] Adicionar role tags às 5 estátuas MVP
- [ ] Implementar passive de Frontline (mitigação/threat quando exposta)
- [ ] Implementar passive de Precision DPS (bônus quando isolada)
- [ ] Implementar passive de Support (aura para aliados próximos)
- [ ] Adicionar indicadores visuais de passive ativa

**Arquivos Principais:**
- `scripts/combat/statue_base.gd`
- `scripts/data/statue_data.gd`
- `scenes/ui/hud.tscn`

**Critério de Conclusão:**
- ✅ Cada estátua MVP tem role tag
- ✅ Posicionamento afeta output de combate
- ✅ Jogador pode ver quando passive está ativa

---

#### Fase 3: Statue-Bound Equipment

**Tarefas:**
- [ ] Reframe upgrades existentes como runas/equipamentos
- [ ] Vincular equipamentos a estátuas específicas
- [ ] Mostrar equipamentos no tooltip da estátua
- [ ] Implementar pool de 6 runas MVP
- [ ] Ajustar shop para priorizar equipamentos do MVP

**Arquivos Principais:**
- `scripts/combat/statue_base.gd`
- `scripts/ui/inventory_ui.gd`
- `scripts/data/equipment_data.gd`
- `scripts/ui/shop_manager.gd`

**Critério de Conclusão:**
- ✅ Equipamentos pertencem a estátua específica
- ✅ 6 runas MVP existem e funcionam
- ✅ Shop prioriza itens relevantes ao MVP

---

#### Fase 4: Soft Aggro e Pressão

**Tarefas:**
- [ ] Implementar sistema de threat (frontline gera mais)
- [ ] Permitir alguns inimigos targetarem estátuas
- [ ] Adicionar focus indicators (ícone/linha de aggro)
- [ ] Testar com ondas do MVP

**Arquivos Principais:**
- `scripts/combat/enemy_base.gd`
- `scripts/combat/arena.gd`

**Critério de Conclusão:**
- ✅ Backline mistakes são puníveis
- ✅ Frontline importa e é focada
- ✅ Jogador pode ver quem está sendo atacado

---

#### Fase 5: Boss Adaptation

**Tarefas:**
- [ ] Scriptar Goblin Boss com 2 fases
- [ ] Phase 1: Crystal rush + summon adds
- [ ] Phase 2: Statue-targeting ou lane sweep
- [ ] Adicionar battlefield disruption (zona de perigo)
- [ ] Testar que reposicionamento é necessário

**Arquivos Principais:**
- `scripts/combat/enemy_base.gd`
- `scripts/data/enemy_data.gd`
- `scripts/data/wave_data.gd`

**Critério de Conclusão:**
- ✅ Boss tem 2 fases legíveis
- ✅ Luta exige ajuste de formação
- ✅ Fases são visíveis e compreensíveis

---

#### Fase 6: Balanceamento Final

**Tarefas:**
- [ ] Ajustar pacing das 8 ondas
- [ ] Tunar economia para escolhas difíceis
- [ ] Testar 3 builds diferentes:
  - Frontline-heavy
  - Huntress isolation
  - Support/control
- [ ] Ajustar valores se necessário

**Critério de Conclusão:**
- ✅ Todas as 3 builds podem completar o MVP
- ✅ Ondas são táticas, não apenas stat-check
- ✅ Shop cria tradeoffs reais

---

### ✅ MVP Exit Checklist

O MVP está pronto para ship quando **TODOS** forem verdadeiros:

- [ ] Shop-phase reposition funciona
- [ ] 1 in-combat relocate funciona
- [ ] 3 role passives estão ativas e visíveis
- [ ] Equipment é statue-bound e legível
- [ ] Inimigos pressionam estátuas (não só crystal)
- [ ] Boss tem 2+ fases táticas
- [ ] 1 mapa (Sacred Grove) pode ser completado com novas regras
- [ ] 3 builds diferentes testadas e funcionais

---

## 📝 Notas Finais

### Direção de Design
Project Guardians **NÃO** deve se tornar "Tangy com estátuas". A melhor versão é **"Project Guardians com clareza tática de nível Tangy"**.

Isso significa:
- ✅ Manter a fantasia das estátuas
- ✅ Manter evolução como diferencial principal
- ✅ Adicionar jogo de formação tática como novo centro da run

### Prioridade de Assets
1. **Sprites de inimigos faltantes** (apenas 5/16 existem)
2. **Ícones de artefatos** (alguns sem textura)
3. **Sons** (zero assets implementados - FASE FINAL)

### Próximos Passos Imediatos
1. ✅ Revisar esta documentação consolidada
2. 🎯 Iniciar **Fase 1: Reposicionamento**
3. 🎯 Implementar shop-phase movement
4. 🎯 Implementar in-combat relocate

---

*Última Atualização: 11 de Abril de 2026*  
*Engine: Godot 4.4 GL Compatibility*  
*Status: MVP Adaptation Slice - Pronto para Implementação*
