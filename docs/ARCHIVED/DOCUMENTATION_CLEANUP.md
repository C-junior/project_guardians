# 📋 Limpeza de Documentação - Resumo

## ✅ Documentos Criados

Foram criados **2 documentos consolidados** que substituem toda a documentação anterior:

1. **`MVP_DOCUMENTATION.md`** - Documentação completa e consolidada do MVP
   - Visão geral do jogo
   - Scope travado do MVP
   - Arquitetura do projeto
   - Todos os sistemas e valores
   - Plano de implementação (alto nível)

2. **`MVP_IMPLEMENTATION_PLAN.md`** - Plano de implementação técnico detalhado
   - 6 fases de implementação
   - Código de exemplo para cada sistema
   - Critérios de conclusão por fase
   - Checklist final do MVP

---

## 🗑️ Documentos que Podem Ser Removidos/Arquivados

Estes documentos contêm informações **duplicadas, desatualizadas ou fora do scope do MVP**:

### Alta Prioridade para Remover
| Arquivo | Motivo |
|---------|--------|
| `GDD.md` | Design original muito amplo, não reflete o MVP atual |
| `TANGY_MVP_ADAPTATION.md` | Informações já condensadas no MVP_DOCUMENTATION.md |
| `TANGY_MVP_ROADMAP.md` | Roadmap já incorporado no MVP_IMPLEMENTATION_PLAN.md |
| `TANGY_TD_REFERENCE.md` | Referência do Tangy já sintetizada nos novos docs |
| `GAME_COMPLETION_ROADMAP.md` | Roadmap completo (pós-MVP), pode confundir |
| `CORE_SYSTEMS_BALANCE.md` | Valores já estão no MVP_DOCUMENTATION.md |

### Média Prioridade para Remover
| Arquivo | Motivo |
|---------|--------|
| `JUICE_ENHANCEMENT_PLAN.md` | Plano de juice (muitos itens já implementados) |
| `MAP_1_BALANCE.md` | Balanceamento de 20 ondas (MVP é apenas 8) |
| `mvp_propouse.md` | Proposta original já condensada no MVP_DOCUMENTATION.md |

### Manter (Ativo)
| Arquivo | Motivo |
|---------|--------|
| `usertodo.md` | TODO ativo para assets e decisões criativas |
| `MVP_DOCUMENTATION.md` | **NOVO** - Doc principal do MVP |
| `MVP_IMPLEMENTATION_PLAN.md` | **NOVO** - Plano de implementação |

---

## 📁 Estrutura Recomendada de `docs/`

```
docs/
├── MVP_DOCUMENTATION.md           ← Documentação principal do MVP
├── MVP_IMPLEMENTATION_PLAN.md     ← Plano de implementação técnico
├── usertodo.md                    ← TODO para assets/decisões
└── ARCHIVED/                      ← Mover docs antigos para cá
    ├── GDD.md
    ├── TANGY_MVP_ADAPTATION.md
    ├── TANGY_MVP_ROADMAP.md
    ├── TANGY_TD_REFERENCE.md
    ├── GAME_COMPLETION_ROADMAP.md
    ├── CORE_SYSTEMS_BALANCE.md
    ├── JUICE_ENHANCEMENT_PLAN.md
    ├── MAP_1_BALANCE.md
    └── mvp_propouse.md
```

---

## 🎯 Benefícios da Consolidação

### Antes (10 documentos)
- ❌ Informações duplicadas em múltiplos arquivos
- ❌ Valores conflitantes entre documentos
- ❌ Scope pouco claro (20 ondas vs 8 ondas)
- ❌ Difícil para LLM de código saber qual doc seguir
- ❌ Risco de implementar features fora do MVP

### Depois (2 documentos principais)
- ✅ Single source of truth para o MVP
- ✅ Scope travado e claro (8 ondas, 5 estátuas, 6 runas)
- ✅ Valores de balanceamento consolidados
- ✅ Plano de implementação passo-a-passo
- ✅ Fácil para LLM entender o que construir

---

## 🚀 Próximos Passos Recomendados

1. **Revisar** os novos documentos `MVP_DOCUMENTATION.md` e `MVP_IMPLEMENTATION_PLAN.md`
2. **Mover** documentos antigos para pasta `docs/ARCHIVED/` (ou deletar se não precisar)
3. **Usar** `MVP_DOCUMENTATION.md` como referência principal para o projeto
4. **Seguir** `MVP_IMPLEMENTATION_PLAN.md` para implementação em Godot
5. **Iniciar** pela Fase 1: Reposicionamento

---

## 📝 Resumo do MVP

**O que estamos construindo:**
- Tower Defense Roguelike tático com 5 heroínas
- 8 ondas no mapa "The Sacred Grove"
- Reposicionamento tático (shop + 1 relocate/onda)
- 3 roles: Frontline, Precision DPS, Support
- 6 runas/equipamentos vinculados a estátuas
- Soft aggro: inimigos focam estátuas
- 1 boss com 2 fases táticas (Goblin Boss)

**O que NÃO estamos construindo (no MVP):**
- 20+ ondas
- 7 estátuas (apenas 5 no MVP)
- Múltiplos bosses
- Crafting systems
- Endless mode
- Skill trees de 300 nodes
- 100+ itens

---

*Documento criado em: 11 de Abril de 2026*
