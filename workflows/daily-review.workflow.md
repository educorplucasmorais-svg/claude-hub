---
name: daily-review
description: Revisão diária de progresso, planejamento e sync com Obsidian/NotebookLM
version: 1.0.0
trigger: manual | scheduled
tags: [daily, review, planning, obsidian, productivity]
---

# 📅 Workflow: Daily Review

## Quando Usar
- Todo dia de manhã para planejar
- No final do dia para revisar
- Semanalmente para retrospectiva

## Passo a Passo

### Manhã (15 min)

#### 1. Revisar Memória
```
Leia: .claude/memory/MEMORY.md
Pergunte: O que estava fazendo ontem?
```

#### 2. Definir Prioridades do Dia
```
Template:
## Daily - [DATA]

### 🎯 Top 3 do Dia
1. (tarefa crítica)
2. (tarefa importante)  
3. (tarefa desejável)

### 📋 Backlog do Dia
- 
- 

### 🚫 O que NÃO fazer hoje
- (evite scope creep)
```

#### 3. Criar Nota no Obsidian
```powershell
.\scripts\obsidian\sync-to-vault.ps1 `
  -NoteTitle "Daily $(Get-Date -Format 'yyyy-MM-dd')" `
  -NoteType "meeting" `
  -NoteContent "[conteúdo do daily]"
```

---

### Final do Dia (10 min)

#### 1. Registrar o que foi feito
```
## ✅ Completado Hoje
- 
- 

## 🔄 Em Progresso (continua amanhã)
- 

## 💡 Aprendizados
- 

## 🐛 Problemas Encontrados
- 
```

#### 2. Atualizar MEMORY.md
Atualize `.claude/memory/MEMORY.md` com:
- Status do projeto
- Decisões tomadas
- Contexto importante para amanhã

#### 3. Commit das mudanças
```bash
git add -A
git commit -m "chore: daily progress $(date +%Y-%m-%d)"
```

---

### Revisão Semanal (30 min — sexta ou segunda)

#### Template
```markdown
# Weekly Review - Semana [N] de [ANO]

## 📊 Métricas
- Features entregues: X
- Bugs corrigidos: X
- PRs mergeadas: X

## 🏆 Conquistas
- 

## 😤 Frustrações / Bloqueios
- 

## 📚 O que aprendi
- 

## 🎯 Foco da próxima semana
1. 
2. 
3.

## 🔄 Processos para melhorar
- 
```

#### Exportar para NotebookLM
```powershell
# Exportar semana inteira para análise
.\scripts\notebooklm\export-to-notebooklm.ps1 -Bundle -Title "Weekly Review Semana $(Get-Date -UFormat '%V')"
```
