---
name: code-review-pr
description: Workflow de code review de Pull Requests com relatório estruturado
version: 1.0.0
trigger: manual
tags: [code-review, pr, github, quality]
---

# 🔍 Workflow: Code Review de PR

## Quando Usar
- Revisar PR antes de mergear
- Auditar código de terceiros
- Onboarding (entender código novo)

## Passo a Passo

### 1. Coletar Contexto
```bash
# Ver diff completo da PR
git fetch origin
git diff origin/develop...origin/feature/nome-da-feature

# Ver commits da PR
git log origin/develop..origin/feature/nome-da-feature --oneline

# Ver arquivos modificados
git diff --name-only origin/develop...origin/feature/nome-da-feature
```

### 2. Revisar com Skill `code-review`
Ative a skill e analise:
1. Cada arquivo modificado
2. Impacto nas dependências
3. Testes adicionados/modificados
4. Documentação atualizada?

### 3. Checar Automático
```bash
# Lint
npm run lint

# Tests
npm test -- --coverage

# Build
npm run build

# Security
npm audit
```

### 4. Preencher Template de Review

```markdown
## 📋 Code Review — PR #[NÚMERO]

**Revisor:** Claude Hub  
**Data:** [DATA]  
**Branch:** `feature/X` → `develop`

### ✅ Aprovado
- [ ] Funcionalidade implementada corretamente
- [ ] Testes adicionados/atualizados
- [ ] Sem vulnerabilidades de segurança
- [ ] Performance não degradada
- [ ] Código legível e documentado

### 🚨 Bloqueantes (devem ser resolvidos antes do merge)
[lista ou "Nenhum"]

### ⚠️ Importantes (recomendações)
[lista ou "Nenhum"]

### 💡 Sugestões Futuras
[lista ou "Nenhum"]

### 📊 Veredicto
- [ ] ✅ Aprovado
- [ ] 🔄 Aprovado com alterações menores
- [ ] ❌ Requer mudanças significativas
```

### 5. Salvar Review no Obsidian (Opcional)
```powershell
.\scripts\obsidian\sync-to-vault.ps1 `
  -NoteTitle "Code Review PR #[NUM] - [Feature]" `
  -NoteType "meeting" `
  -Tags @("code-review", "project/nome")
```
