---
name: project-kickoff
description: Workflow completo para iniciar novo projeto com toda documentação, ADRs e estrutura
version: 1.0.0
trigger: manual
tags: [project, kickoff, setup, architecture, documentation]
---

# 🚀 Workflow: Project Kickoff

## Quando Usar
- Iniciar qualquer novo projeto
- Onboarding de projeto existente
- Reorganização de projeto legado

## Checklist Completo

### 1. Definição (Antes de Codar)

- [ ] **Problema**: O que resolve? Para quem?
- [ ] **Escopo**: O que está IN/OUT do MVP?
- [ ] **Métricas de Sucesso**: Como sabemos que funcionou?
- [ ] **Stack**: Confirmado com CLAUDE.md do projeto?
- [ ] **Prazo**: Quando precisa estar pronto?

#### Documento de Visão
```markdown
# Visão do Projeto: [Nome]

## Problema
[1 parágrafo claro sobre o problema]

## Solução Proposta
[1 parágrafo sobre a abordagem]

## Usuários
- Primário: [quem usa mais]
- Secundário: [quem usa às vezes]

## MVP (Mínimo Viável)
Features OBRIGATÓRIAS para lançar:
1. 
2. 
3. 

## Fora do Escopo (v1)
- 
- 

## Critérios de Sucesso
- Métrica 1: [valor alvo]
- Métrica 2: [valor alvo]
```

### 2. Arquitetura (Skills: architect)

- [ ] Desenhar C4 Level 1 (System Context)
- [ ] Definir componentes principais
- [ ] Modelar banco de dados
- [ ] Documentar ADR-001 (stack choices)
- [ ] Revisar com skill `architect`

### 3. Setup do Repositório

```bash
# Estrutura base
mkdir src tests docs
git init
git checkout -b develop

# Configurar Git hooks
npm install --save-dev husky lint-staged
npx husky init

# .gitignore essencial
echo "node_modules/\n.env\n.env.local\ndist/\n.DS_Store" > .gitignore

# Commit inicial
git add .
git commit -m "chore: project kickoff - initial structure"
```

### 4. Documentação Inicial

- [ ] `README.md` (usar skill `docs-generator`)
- [ ] `.env.example` (todas as variáveis sem valores)
- [ ] `CONTRIBUTING.md` (usando skill `git-workflow`)
- [ ] `docs/architecture/` (ADRs)

### 5. Segurança Baseline (Skill: security-audit)

- [ ] `.env` no `.gitignore`
- [ ] Helmet instalado
- [ ] Rate limiting configurado
- [ ] Validação de inputs (Zod)
- [ ] HTTPS em produção

### 6. CI/CD Básico

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npm run lint
      - run: npm test
      - run: npm run build
```

### 7. Salvar no Obsidian + NotebookLM

```powershell
# Criar nota do projeto no Obsidian
.\scripts\obsidian\sync-to-vault.ps1 `
  -NoteTitle "[Nome do Projeto] - Kickoff" `
  -NoteType "project" `
  -Tags @("project/novo")

# Exportar docs iniciais para NotebookLM
.\scripts\notebooklm\export-to-notebooklm.ps1 -Bundle `
  -Title "[Projeto] - Documentação Inicial"
```

## Estimativa de Tempo por Fase
| Fase | Tempo |
|------|-------|
| Definição | 2-4 horas |
| Arquitetura | 2-8 horas |
| Setup repositório | 1-2 horas |
| Documentação | 2-4 horas |
| Segurança baseline | 1-2 horas |
| CI/CD | 1-2 horas |
| **Total** | **1-3 dias** |
