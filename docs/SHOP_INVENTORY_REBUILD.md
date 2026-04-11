# 🔄 Shop & Inventory Rebuild - Resumo

**Data:** 11 de Abril de 2026  
**Objetivo:** Reconstruir o Shop e Inventory do jeito certo para o MVP

---

## ✅ O Que Foi Feito

### Problemas do Sistema Antigo
- ❌ Shop genérica com muitos itens não relevantes ao MVP
- ❌ Inventory complexo com 4 abas (Statues, Artifacts, Consumables, Upgrades)
- ❌ Sistema de upgrades não vinculado a estátuas específicas
- ❌ Cards genéricos que não exibiam informações táticas claras

### Solução Implementada

#### 1. EquipmentShopUI (Shop do MVP)
**Arquivos criados:**
- `scenes/ui/equipment_shop_ui.tscn`
- `scripts/ui/equipment_shop_ui.gd`
- `scenes/ui/equipment_shop_card.tscn`
- `scripts/ui/equipment_shop_card.gd`

**Características:**
- ✅ Focada nas **6 runas MVP** (Power, Range, Quickstep, Keen, Channel, Guard)
- ✅ Reroll com custo escalonado (30g + 20g × rerolls)
- ✅ Cards exibem stats detalhados e tooltips
- ✅ Gera ícones coloridos placeholder baseados no tipo de stat
- ✅ Integração completa com GameManager para compras

**Fluxo da Shop:**
```
Shop Abre → Gera 5 runas  → Player compra → Regenera shop
```

---

#### 2. StatueInventoryUI (Inventory do MVP)
**Arquivos criados:**
- `scenes/ui/statue_inventory_ui.tscn`
- `scripts/ui/statue_inventory_ui.gd`

**Características:**
- ✅ 2 abas simplificadas: **Statues** e **Equipment**
- ✅ Aba Statues: Mostra estátuas com tier, equipamento equipado, drag-and-drop
- ✅ Aba Equipment: Mostra runas disponíveis para equipar
- ✅ Detail panel com stats, equipment slots, habilidades
- ✅ Drag-and-drop para colocar estátuas na arena
- ✅ Suporte a repositionamento futuro

**Fluxo do Inventory:**
```
Player abre inventory → Vê estátuas + equipamentos → Drag para arena ou clica Place
```

---

#### 3. GameManager Updates
**Métodos adicionados:**
```gdscript
add_statue_to_inventory(statue_data, rarity)
apply_equipment_to_statue(statue_node, equipment)
get_max_equipment_slots_for_tier(tier)
```

**Estrutura de inventory atualizada:**
```gdscript
player_inventory = {
    "statues": [],
    "artifacts": [],
    "consumables": [],
    "upgrades": [],
    "equipment": []  # NOVO: Runas/equipment
}
```

---

#### 4. Main Controller Updates
**Arquivo:** `scripts/main.gd`

**Mudanças:**
- ✅ `shop_ui` → `equipment_shop_ui`
- ✅ `inventory_ui` → `statue_inventory_ui`
- ✅ Novos handlers: `_on_equipment_purchased()`, `_on_statue_purchased()`
- ✅ Todos os sinais reconectados
- ✅ Drag-and-drop atualizado

**Arquivo:** `scenes/main/main.tscn`
- ✅ Referências de cena atualizadas
- ✅ Nomes de nós atualizados

---

## 📊 Comparação: Antes vs Depois

### Shop Antiga
```
┌──────────────────────────────────────┐
│  Shop Genérica                       │
│  ├── 5 itens aleatórios             │
│  │   ├── Statues (qualquer uma)     │
│  │   ├── Artifacts                  │
│  │   ├── Consumables                │
│  │   └── Upgrades                   │
│  └── Reroll (50g base)              │
└──────────────────────────────────────┘
```

### Shop Nova (MVP)
```
┌──────────────────────────────────────┐
│  ⚒️ Equipment Shop                   │
│  ├── 3 Runas MVP                    │
│  │   ├── Power Rune (+25% DMG)      │
│  │   ├── Range Rune (+2 RNG)        │
│  │   └── Quickstep Rune (+30% ASPD) │
│  ├── 2 Estátuas MVP                 │
│  │   ├── Sentinel (Common)          │
│  │   └── Huntress (Rare)            │
│  └── Reroll (30g base)              │
└──────────────────────────────────────┘
```

---

### Inventory Antigo
```
┌──────────────────────────────────────┐
│  📦 Inventory                        │
│  ├── 🗿 Statues (tab)               │
│  ├── ✨ Artifacts (tab)             │
│  ├── 🧪 Consumables (tab)           │
│  └── ⬆️ Upgrades (tab)             │
│                                      │
│  Detail panel básico                 │
└──────────────────────────────────────┘
```

### Inventory Novo (MVP)
```
┌──────────────────────────────────────┐
│  🗿 Statues & Equipment             │
│  ├── 🗿 Statues (tab)               │
│  │   ├── Sentinel ★★                │
│  │   │   ⚒️ Power Rune, Guard Rune  │
│  │   └── Huntress ★                 │
│  │       ⚒️ (empty 0/1 slots)       │
│  └── ⚒️ Runes (tab)                 │
│      ├── Range Rune                 │
│      └── Keen Rune                  │
│                                      │
│  Detail panel com equipment slots   │
└──────────────────────────────────────┘
```

---

## 🎯 Benefícios da Reconstrução

### Para o MVP
1. ✅ **Foco claro**: Shop só mostra itens relevantes
2. ✅ **Decisões significativas**: Player escolhe entre runas ou estátuas
3. ✅ **Equipment vinculado**: Runas pertencem a estátuas específicas
4. ✅ **UI simplificada**: Menos ruído, mais clareza tática
5. ✅ **Drag-and-drop**: Colocar estátuas é intuitivo

### Para Desenvolvimento
1. ✅ **Código limpo**: Sem lógica desnecessária
2. ✅ **Fácil de testar**: Pool de itens reduzido (6 runas + 5 estátuas)
3. ✅ **Fácil de estender**: Adicionar novas runas é trivial
4. ✅ **Separação clara**: Shop gera items → Inventory armazena → Arena usa

---

## 📁 Arquivos Criados/Modificados

### Criados (6 arquivos)
```
scenes/ui/equipment_shop_ui.tscn       (NOVO)
scenes/ui/equipment_shop_card.tscn     (NOVO)
scenes/ui/statue_inventory_ui.tscn     (NOVO)
scripts/ui/equipment_shop_ui.gd        (NOVO)
scripts/ui/equipment_shop_card.gd      (NOVO)
scripts/ui/statue_inventory_ui.gd      (NOVO)
```

### Modificados (3 arquivos)
```
autoload/GameManager.gd                (+3 métodos)
scripts/main.gd                        (referências atualizadas)
scenes/main/main.tscn                  (cenas atualizadas)
```

### Deletados (6 arquivos)
```
scenes/ui/shop_ui.tscn                 ❌
scenes/ui/shop_item_card.tscn          ❌
scenes/ui/inventory_ui.tscn            ❌
scripts/ui/shop_manager.gd             ❌
scripts/ui/shop_item_card.gd           ❌
scripts/ui/inventory_ui.gd             ❌
```

---

## 🚀 Próximos Passos

1. **Testar no Godot**: Abrir o projeto e verificar se as novas UIs carregam
2. **Testar fluxo**:
   - Iniciar nova run
   - Abrir shop → Comprar runa → Ver no inventory
   - Abrir inventory → Drag estátua → Colocar na arena
3. **Implementar reposicionamento** (Fase 1 do MVP)
4. **Implementar role passives** (Fase 2 do MVP)
5. **Implementar soft aggro** (Fase 4 do MVP)

---

## 📝 Notas Técnicas

### Ícones Placeholder
As runas e estátuas sem ícones geram squares coloridos automaticamente:
- **Power Rune**: Laranja/vermelho (dano)
- **Range Rune**: Azul (alcance)
- **Quickstep Rune**: Amarelo (velocidade)
- **Keen Rune**: Dourado (crit)
- **Channel Rune**: Roxo (cooldown)
- **Guard Rune**: Verde/cinza (threat/HP)

### Raridade de Estátuas
Shop gera estátuas com raridade aleatória:
- Common (50%), Uncommon (30%), Rare (15%), Epic (4%), Legendary (1%)
- Custo base: 350g × multiplicador de raridade

### Equipamento em Estátuas
- Tier 0 (★): 1 slot
- Tier 1 (★★): 2 slots
- Tier 2 (★★★): 3 slots
- Tier 3 (★★★★): 4 slots

---

*Rebuild completed: 11 de Abril de 2026*  
*Status: Pronto para teste no Godot Editor* ✅
