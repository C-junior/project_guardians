# Documentação de Design e Especificação Técnica (Godot Engine)
**Projeto:** Project Guardians - Tower Defense Roguelike
**Engine:** Godot 4.4 (GL Compatibility)
**Status:** MVP Adaptation Slice (Tangy-Style Tactical Defense)

Este documento serve como guia de referência para o estado **atual** do projeto, documentando a arquitetura implementada, sistemas principais, estruturas de dados e **valores exatos de balanceamento** em vigor. Ele integra o design original com as adaptações do Tangy MVP já em progresso.

---

## 1. Visão Geral do Jogo
Um Tower Defense Roguelike onde o jogador comanda estátuas de heroínas para defender um Cristal Sagrado contra ondas de inimigos. Cada estátua é um campeão com identidade tática, habilidades especiais e equipamentos vinculados. O jogo combina:

- **Defesa tática** com formação e posicionamento
- **Evolução por fusão** (3 iguais = 1 evoluida)
- **Shop roguelike** com ofertas aleatórias entre ondas
- **Meta-progressão** via Árvore de Habilidades (Aether Sanctum)
- **Adaptação Tangy MVP**: reposicionamento, roles táticos, equipamento por estátua, pressão inimiga

---

## 2. Arquitetura Implementada na Godot

### 2.1. Autoloads (Singletons)
O projeto possui 4 autoloads ativos:

| Autoload | Responsabilidade |
|----------|-----------------|
| **`GameManager.gd`** | Estado global da run: ouro, vidas/HP do cristal, onda atual, inventário, save/load meta (`user://save_data.json`), relocate charges |
| **`EvolutionManager.gd`** | Fusão/evolução de estátuas (3-do-mesmo = 1 evoluída), efeitos visuais de ascensão |
| **`ComboManager.gd`** | Tracking de combo de kills com recompensas escalonadas de ouro e feedback visual |
| **`TutorialManager.gd`** | Prompts contextuais de tutorial com persistência |

### 2.2. Estrutura de Cenas (Scenes)

**Cenas Principais (15 `.tscn`):**

| Cena | Caminho | Função |
|------|---------|--------|
| **Main** | `scenes/main/main.tscn` | Entry point, controlador de fluxo de jogo |
| **MainMenu** | `scenes/main/main_menu.tscn` | Tela de menu principal |
| **Arena** | `scenes/combat/arena.tscn` | Arena de combate principal com grid |
| **ArenaCitadel** | `scenes/combat/arena_citadel.tscn` | Variante da arena (Citadel) |
| **Enemy** | `scenes/entities/enemy.tscn` | Prefab de inimigo |
| **Statue** | `scenes/entities/statue.tscn` | Prefab de estátua/torre |
| **HUD** | `scenes/ui/hud.tscn` | Overlay de HUD in-game |
| **ShopUI** | `scenes/ui/shop_ui.tscn` | Tela de shop na fase de preparação |
| **ShopItemCard** | `scenes/ui/shop_item_card.tscn` | Card individual de item na shop |
| **InventoryUI** | `scenes/ui/inventory_ui.tscn` | Inventário com drag-and-drop |
| **AscensionUI** | `scenes/ui/ascension_ui.tscn` | Tela de evolução/ascensão |
| **BlessingSelection** | `scenes/ui/blessing_selection_ui.tscn` | Escolha de bônus inicial |
| **StatueSelection** | `scenes/ui/statue_selection_ui.tscn` | Escolha de estátua inicial |
| **MetaProgressionUI** | `scenes/ui/meta_progression_ui.tscn` | Tela do Aether Sanctum |

### 2.3. Scripts de Combate

| Script | Caminho | Função |
|--------|---------|--------|
| **Arena** | `scripts/combat/arena.gd` | Controller de combate: grid, spawns, ondas, relocate, juice |
| **StatueBase** | `scripts/combat/statue_base.gd` | Lógica de estátua: targeting, ataques, habilidades, evolução, equipment, upgrades |
| **EnemyBase** | `scripts/combat/enemy_base.gd` | Lógica de inimigo: path, HP, status effects, elite modifiers, boss phases, soft aggro |
| **EffectsManager** | `scripts/combat/effects_manager.gd` | Efeitos visuais (projéteis, impactos, shockwaves) |

### 2.4. Scripts de Dados (Resources)

O projeto usa **9 arquivos `.tres` customizados** como resources:

| Resource | Caminho | Conteúdo |
|----------|---------|----------|
| **StatueData** | `scripts/data/statue_data.gd` | Stats, habilidades, targeting, passivas Tangy, equipment slots |
| **EnemyData** | `scripts/data/enemy_data.gd` | Definições de inimigos (HP, velocidade, dano, comportamento) |
| **ArtifactData** | `scripts/data/artifact_data.gd` | Efeitos passivos globais de run |
| **BlessingData** | `scripts/data/blessing_data.gd` | Bônus iniciais de run |
| **ConsumableData** | `scripts/data/consumable_data.gd` | Itens de uso único |
| **EquipmentData** | `scripts/data/equipment_data.gd` | Runas/equipamentos vinculados a estátua |
| **UpgradeData** | `scripts/data/upgrade_data.gd` | Upgrades de estátua |
| **WaveData** | `scripts/data/wave_data.gd` | Geração de ondas: procedural + hand-crafted (8-wave Tangy) |
| **MapData** | `scripts/data/map_data.gd` | Definições de mapas |
| **MetaUnlock** | `scripts/data/meta_unlock.gd` | Definições de desbloqueios de meta-progressão |

### 2.5. Scripts de UI

| Script | Caminho | Função |
|--------|---------|--------|
| **MainMenu** | `scripts/ui/main_menu.gd` | Controlador do menu |
| **HUDController** | `scripts/ui/hud_controller.gd` | Atualiza HUD com stats da run |
| **ShopManager** | `scripts/ui/shop_manager.gd` | Geração da shop, cards, reroll, compra |
| **ShopItemCard** | `scripts/ui/shop_item_card.gd` | Card individual de item |
| **InventoryUI** | `scripts/ui/inventory_ui.gd` | Display de inventário com drag-and-drop |
| **StatueSelectionUI** | `scripts/ui/statue_selection_ui.gd` | Escolha de estátua inicial |
| **AscensionUI** | `scripts/ui/ascension_ui.gd` | Tela de evolução/merge |
| **BlessingSelectionUI** | `scripts/ui/blessing_selection_ui.gd` | Escolha de bônus |
| **MetaProgressionUI** | `scripts/ui/meta_progression_ui.gd` | Tela do Aether Sanctum |

### 2.6. Fluxo Principal de Jogo

O controlador `scripts/main.gd` gerencia:
- Transições de estado (MENU → SETUP → COMBAT → SHOP → COMBAT → GAME OVER)
- Drag-and-drop de estátuas
- Placement/selling de estátuas
- Gerenciamento de cenas

---

## 3. Especificações e Balanceamento Exato

### 3.1. Status Base do Jogador (Início da Run)
| Stat | Valor |
|------|-------|
| **Ouro Inicial**: 200 |
| **HP do Cristal**: 100 (base, modificável por blessings) |
| **Estátuas Iniciais**: 1 (aleatória Comum) |
| **Blessing Inicial**: 1 escolha entre 3 |

### 3.2. Estátuas (7 Heroínas)

O projeto possui **7 estátuas** com evolução em **4 tiers**:

**Evolução Tiers:**
| Tier | Nome | Mult Stats | Slots Upgrade | Visual |
|------|------|------------|---------------|--------|
| 0 | ★ Base | 1.0× | 1 | Standard stone |
| 1 | ★★ Enhanced | 1.4× | 2 | Glowing runes |
| 2 | ★★★ Awakened | 1.8× | 3 | Golden accents |
| 3 | ★★★★ Divine | 2.5× | 4 | Full luminescence |

**Raridade na Shop (multiplicadores):**
| Raridade | Mult Stats | Mult Custo | Drop Weight | Cor |
|----------|------------|------------|-------------|-----|
| Common | 1.00× | 1.00× | 50% | Cinza |
| Uncommon | 1.15× | 1.25× | 30% | Verde |
| Rare | 1.30× | 1.70× | 15% | Azul |
| Epic | 1.50× | 2.30× | 4% | Roxo |
| Legendary | 1.80× | 2.85× | 1% | Laranja/Dourado |

**As 7 Heroínas:**
| Estátua | Role (Tangy MVP) | Ataque | Habilidade Especial |
|---------|------------------|--------|---------------------|
| **Sentinel** | Frontline | Melee | **Shield Bash** - Stun em área, damage reduction |
| **Arcane Weaver** | Precision DPS | Medium | **Chain Lightning** - Bounce para 3 inimigos |
| **Huntress** | Precision DPS | Long | **Piercing Arrow** - Atravessa linha de inimigos |
| **Divine Guardian** | Support | Medium | **Radiant Smite** - Dano massivo + heal aliados |
| **Earthshaker** | Frontline | Short | **Ground Slam** - AOE + 50% slow 3s |
| **Shadow Dancer** | Precision DPS | Medium | **Blade Storm** - 200% attack speed 5s |
| **Frost Maiden** | Control Support | Medium | **Frozen Prison** - Imobiliza área 4s |

**Estátuas no MVP Slice (5):**
Sentinel, Huntress, Divine Guardian, Frost Maiden, Arcane Weaver

### 3.3. Economia

| Fonte | Valor |
|-------|-------|
| **Ouro por Kill** | Varia por tipo de inimigo (5-25g) |
| **Wave Completion** | `75 + (Onda × 15)` Ouro |
| **Boss Kill** | 200g + guaranteed rare item |
| **Reroll Cost** | `30 + (20 × rerolls)` Ouro |
| **Aether Essence (Meta)** | 10 por onda sobrevivida |

**Preços de Estátuas na Shop (base Common):**
| Categoria | Faixa de Preço |
|-----------|----------------|
| Common | 300-400g |
| Uncommon | 450-550g |
| Rare | 600-700g |
| Epic | 750-850g |
| Legendary | 900-1000g |

### 3.4. Inimigos e Ondas

**16 Tipos de Inimigos implementados:**
| Inimigo | HP Base | Velocidade | Notas |
|---------|---------|------------|-------|
| **Goblin** | Baixo | Rápida | Spawn comum |
| **Orc** | Médio | Média | Spawn a partir onda 3 |
| **Slime** | Baixo | Lenta | Divide em 2 mini-slimes na morte |
| **Troll** | Alto | Lenta | Tank, resistente a CC |
| **Necromancer** | Médio | Média | Summona skeletons |
| **Shadow Imp** | Médio | Média | Teleporta a cada 3s (wave 6+) |
| **Shielded Knight** | Médio | Média | 75% redução frontal (wave 6+) |
| **Dragon Whelp** | Médio | Voa | Só hit por ranged/magic (wave 11+) |
| **Goblin Boss** | Alto | Média | Boss wave 5/8, summon adds |
| **Orc Boss** | Muito Alto | Média | Boss wave 10, war cry buff |
| **Necromancer Lord** | Alto | Lenta | Boss wave 15, resurrect enemies |
| **Ancient Dragon** | Extremo | Voa | Boss wave 20, fire breath |
| **Crystal Golem** | Alto | Lenta | High HP, tanky |
| **Frost Giant** | Alto | Lenta | Slow aura |
| **Frost Queen** | Alto | Média | Freeze abilities |
| **Mini Slime** | Mínimo | Lenta | Spawned by slime death |

**Elite Modifiers (Wave 8+):**
| Modifier | Efeito | Chance |
|----------|--------|--------|
| **Enraged** | +50% dano, +30% speed | 15% wave 8+, 30% wave 12+ |
| **Armored** | 40% redução dano | 15% wave 8+, 30% wave 12+ |
| **Swift** | +80% velocidade | 15% wave 8+, 30% wave 12+ |
| **Vampiric** | Heals 20% dano causado | 15% wave 8+, 30% wave 12+ |
| **Splitting** | Spawns 2 mini na morte | 15% wave 8+, 30% wave 12+ |

**Estrutura de Ondas (Tangy MVP - 8 ondas):**
| Onda | Composição | Notas |
|------|------------|-------|
| 1 | Goblins apenas | Tutorial |
| 2 | Goblins + Orcs | Introdução |
| 3-4 | Mix crescente | Pressão moderada |
| 5 | **Goblin Boss** | Boss wave (MVP) |
| 6-7 | Mix + elites | Introdução soft aggro |
| 8 | **Boss Final** | Fight com 2+ phases (MVP) |

### 3.5. Sistema de Equipamento (Runas)

O MVP possui **6 runas** vinculadas a estátuas:

| Runa | Upgrade Original | Efeito |
|------|------------------|--------|
| **Power Rune** | Damage Boost | +25% dano |
| **Range Rune** | Range Extension | +2 range |
| **Quickstep Rune** | Speed Enchant | +30% attack speed |
| **Keen Rune** | Critical Strike | +20% crit chance |
| **Channel Rune** | Ability Mastery | -30% ability cooldown |
| **Guard Rune** | Novo | +50% HP, +threat (frontline) |

**Slots de Equipment por Tier:**
| Tier | Slots |
|------|-------|
| Base ★ | 1 |
| Enhanced ★★ | 2 |
| Awakened ★★★ | 3 |
| Divine ★★★★ | 4 |

**Meta Bônus (Runic Mastery):**
| Upgrade | Efeito | Custo AE |
|---------|--------|----------|
| Runic Mastery I | +1 slot base | 500 AE |
| Runic Mastery II | +1 slot base | 1000 AE |

### 3.6. Sistema de Itens (Shop)

**Categorias de Itens:**
| Categoria | Faixa Preço | Exemplos |
|-----------|-------------|----------|
| **Novas Estátuas** | 300-1000g | Baseado na raridade |
| **Artefatos** | 150-500g | Bônus passivos globais de run |
| **Equipamentos/Runas** | 200-400g | Upgrades por estátua |
| **Consumíveis** | 25-75g | Efeitos de 1 onda |

**Artefatos Disponíveis (8):**
| Artefato | Efeito | Custo |
|----------|--------|-------|
| Golden Crown | +20% gold | 300g |
| Ancient Tome | -25% cooldowns | 350g |
| War Banner | +15% dano global | 400g |
| Healing Spring | 3% HP regen/sec | 450g |
| Mystic Lens | +1 range global | 350g |
| Merchant's Insurance | Proteção de gold | 250g |
| Executioner's Stone | Execute low HP enemies | 300g |
| Soul Gem | +1 gold por kill | 200g |

**Consumíveis Rebalanceados:**
| Consumível | Preço | Efeito |
|------------|-------|--------|
| Battle Horn | 50g | Todas habilidades ready |
| Gold Fever | 75g | 2x gold essa onda |
| Stone Walls | 40g | +30% HP cristal |
| Slow Time | 60g | Inimigos 25% mais lentos |
| Scout's Map | 25g | Preview próxima onda |
| Arcane Surge | 50g | +30% cooldown recovery |
| Lucky Coin | 45g | +15% bonus gold chance |

### 3.7. Blessings Iniciais (5)

| Blessing | Efeito |
|----------|--------|
| **Warrior's Resolve** | Começa com Sentinel grátis |
| **Merchant's Fortune** | +100% ouro inicial (400g) |
| **Ancient Power** | Primeira compra 50% off |
| **Quick Reflexes** | -25% cooldowns |
| **Crystal Heart** | +75% HP cristal |

---

## 4. Meta-Progressão (Aether Sanctum)

Aether Essence (AE) é ganho ao fim de cada run:
- **10 AE** por onda sobrevivida
- **Bônus de Boss**: +25 AE por boss derrotado

**Desbloqueios no Aether Sanctum:**

### Statue Slots (Sacred Ground)
| Nível | Max Estátuas | Custo AE | Cumulativo |
|-------|--------------|----------|------------|
| Base | 4 | Grátis | - |
| I | 5 | 400 AE | 400 AE |
| II | 6 | 600 AE | 1,000 AE |
| III | 7 | 1000 AE | 2,000 AE |
| IV | 8 | 1500 AE | 3,500 AE |

### Upgrade Slots (Runic Mastery)
| Upgrade | Efeito | Custo AE |
|---------|--------|----------|
| Runic Mastery I | +1 base slot | 500 AE |
| Runic Mastery II | +1 base slot | 1000 AE |

### Desbloqueios de Conteúdo
| Unlock | Custo AE | Efeito |
|--------|----------|--------|
| Nova Estátua | 500 AE | Adiciona ao pool da shop |
| Novo Artefato | 300 AE | Adiciona ao pool da shop |
| Nova Blessing | 400 AE | Adiciona às opções iniciais |
| Gold Per Wave +5 | 200 AE | Ouro permanente por onda |

**Save/Load:** `user://save_data.json` via `FileAccess`
**Dados salvos:** aether_essence, unlocked_statues/artifacts/blessings, permanent_gold_bonus, statue_slots_unlocked, rune_slots_unlocked, completed_tutorials

---

## 5. Sistemas Tangy MVP Implementados

### 5.1. Reposicionamento (Relocate)
- **1 charge por onda** para mover estátua em combate
- **Movimento livre** durante shop/prep phase
- Células válidas destacadas no grid
- Upgrades/equipamentos permanecem attached

### 5.2. Roles Táticos
| Role | Estátuas | Bônus |
|------|----------|-------|
| **Frontline** | Sentinel, Earthshaker | Mitigação quando exposta |
| **Precision DPS** | Huntress, Shadow Dancer, Arcane Weaver | Bônus dano isolada |
| **Support/Control** | Divine Guardian, Frost Maiden | Aura heal/shield/cooldown |

### 5.3. Soft Aggro
- Alguns inimigos targeting estátuas antes do cristal
- Frontline gera mais threat
- Indicadores visuais de foco

### 5.4. Boss com Fases Táticas
- Boss MVP: **Goblin Boss** (wave 8)
- Mínimo 2 phases táticas
- Exige reposicionamento durante fight

---

## 6. Fórmulas de Cálculo

### 6.1. Dano Final de Estátua
```gdscript
# Exemplo de cálculo de Dano
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

### 6.2. Evolução (Merge)
```gdscript
# Requer 3 estátuas iguais (mesmo tipo e tier)
# Resultado: 1 estátua do próximo tier
# Stats multiplicados por TIER_MULTIPLIERS[next_tier]
# Slots de upgrade aumentam conforme tier
```

### 6.3. Combo System
```gdscript
# Kills dentro de 2s contam para combo
# x5 combo: +5g bônus
# x10 combo: +15g bônus
# x20 combo: +50g bônus
# Combo reseta após 2s sem kill
```

---

## 7. Recursos e Assets

### 7.1. Resources (56 `.tres`)
| Tipo | Quantidade | Caminho |
|------|------------|---------|
| Estátuas | 7 | `resources/statues/` |
| Inimigos | 16 | `resources/enemies/` |
| Artefatos | 8 | `resources/artifacts/` |
| Blessings | 5 | `resources/blessings/` |
| Consumíveis | 7 | `resources/consumables/` |
| Equipment | 4 | `resources/equipment/` |
| Upgrades | 5 | `resources/upgrades/` |
| Mapas | 3 | `resources/maps/` |

### 7.2. Assets Visuais
| Tipo | Quantidade | Caminho |
|------|------------|---------|
| Portraits (Heroínas) | 10 | `assets/classes/` |
| Ícones de Artefatos | 14 | `assets/artifacts/` |
| Sprites de Inimigos | 5 | `assets/enemies/` |
| Backgrounds | 2 | `assets/maps/` |
| Ícones de Habilidade | 4 | `assets/runes/` |

**Nota:** Apenas 5 sprites de inimigos existem para 16 tipos. Asset art adicional é necessário.

### 7.3. Audio
**Status:** Zero assets de áudio implementados.
- Efeitos sonoros pendentes
- Música pendente
- UI sounds pendentes

---

## 8. Estado Atual do Projeto

### ✅ Implementado e Funcional
- 7 estátuas únicas com habilidades e targeting
- Sistema de evolução 4 tiers
- Shop com estátuas, artefatos, consumíveis, upgrades
- Inventário com drag-and-drop e aplicação de upgrades
- Sistema de blessings (5 opções)
- Combate: crits, damage numbers, efeitos visuais
- Combo system com tracking de kills
- Meta-progressão UI + save/load
- Elite modifiers (5 tipos)
- 16 tipos de inimigos incluindo 4 bosses
- Efeitos de evolução espetaculares
- Wave celebrations
- Crystal tension effects
- Run statistics tracking

### ⚠️ Implementado mas Precisa Refinamento
- Tutorial prompts (sistema existe, precisa ajuste)
- Settings menu (preparado, sem áudio)
- Balanceamento final de ondas/stats

### ❌ Pendente
- Sound effects e música (zero assets)
- Sprites finais para todos inimigos (apenas 5/16)
- Sprites melhores para estátuas
- Tilesets de mapa
- Mais conteúdo de endgame

---

## 9. Estrutura de Arquivos do Projeto

```
projectguardians/
├── autoload/
│   ├── GameManager.gd          # Estado global, save/load
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
│   ├── equipment/              # 4 .tres files
│   ├── upgrades/               # 5 .tres files
│   └── maps/                   # 3 .tres files
├── assets/
│   ├── classes/                # Portraits
│   ├── artifacts/              # Icons
│   ├── enemies/                # Sprites
│   ├── maps/                   # Backgrounds
│   └── runes/                  # Ability icons
└── docs/
    ├── GDD.md                  # Game Design Document
    ├── mvp_propouse.md         # Este arquivo
    ├── TANGY_MVP_ADAPTATION.md # Adaptação Tangy
    ├── TANGY_MVP_ROADMAP.md    # Roadmap MVP
    ├── CORE_SYSTEMS_BALANCE.md # Balanceamento
    └── GAME_COMPLETION_ROADMAP.md # Roadmap completo
```

---

## 10. Próximos Passas (Prioridade)

1. **Finalizar Balanceamento MVP** - Ajustar valores das 5 estátuas MVP
2. **Implementar Soft Aggro Completo** - Inimigos targeting estátuas
3. **Boss Fases Táticas** - Goblin Boss com 2+ phases
4. **Audio Integration** - Preparar sistema para SFX
5. **Asset Art** - Sprites faltantes para inimigos
6. **Polish Final** - Feedback visual, juice, tuning fino

---

*Última Atualização: Abril 10, 2026*
*Engine: Godot 4.4 GL Compatibility*
*Status: MVP Adaptation Slice em Progresso*
