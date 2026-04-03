---
name: git-workflow
description: Git workflow profissional com Conventional Commits, branching strategy e automação
version: 1.0.0
tags: [git, github, commits, branching, ci-cd]
---

# 🌿 Skill: Git Workflow Profissional

## Ativação
Use quando: "commit", "git", "branch", "PR", "merge", "release", "versionamento"

## Conventional Commits (Padrão Obrigatório)

### Formato
```
<tipo>(escopo opcional): descrição curta

[corpo opcional - o que e por quê]

[rodapé opcional - BREAKING CHANGE, referencias]
```

### Tipos
| Tipo | Quando usar | Versão |
|------|-------------|--------|
| `feat` | Nova funcionalidade | MINOR |
| `fix` | Correção de bug | PATCH |
| `docs` | Apenas documentação | - |
| `style` | Formatação, sem lógica | - |
| `refactor` | Refatoração sem feat/fix | - |
| `test` | Adicionar/corrigir testes | - |
| `chore` | Build, deps, configs | - |
| `perf` | Melhoria de performance | PATCH |
| `ci` | CI/CD | - |
| `revert` | Reverter commit | - |

### Exemplos
```bash
# ✅ Bons commits
git commit -m "feat(auth): adiciona autenticação com Google OAuth"
git commit -m "fix(payment): corrige cálculo de desconto para cupons vencidos"
git commit -m "perf(api): adiciona índice na coluna user_id da tabela orders"
git commit -m "docs(readme): atualiza guia de instalação com Docker"

# ❌ Commits ruins
git commit -m "fix bug"
git commit -m "update"
git commit -m "WIP"
git commit -m "changes"
```

## Branching Strategy (Git Flow Simplificado)

### Estrutura de Branches
```
main          ← produção (sempre estável)
├── develop   ← integração (branch base para dev)
│   ├── feature/nome-da-feature
│   ├── fix/nome-do-bug
│   └── refactor/nome-do-que-refatora
└── hotfix/nome-do-hotfix  ← direto da main
```

### Fluxo de Trabalho
```bash
# 1. Nova feature
git checkout develop
git pull origin develop
git checkout -b feature/user-profile-page

# 2. Desenvolvendo
git add -p  # staging interativo (revise o que está adicionando)
git commit -m "feat(profile): adiciona componente UserAvatar"
git commit -m "feat(profile): implementa upload de foto"

# 3. Atualizar com develop (rebase para histórico limpo)
git fetch origin
git rebase origin/develop

# 4. Push e PR
git push origin feature/user-profile-page
# Abrir PR no GitHub → develop
```

### Pull Request Template
```markdown
## 📋 Descrição
O que essa PR faz?

## 🎯 Tipo de Mudança
- [ ] Nova feature
- [ ] Bug fix
- [ ] Refatoração
- [ ] Documentação

## 🧪 Como Testar
1. Passo 1
2. Passo 2

## 📸 Screenshots (se UI)

## ✅ Checklist
- [ ] Testes passando: `npm test`
- [ ] Lint OK: `npm run lint`
- [ ] Build OK: `npm run build`
- [ ] Self-review feito
```

## Git Hooks com Husky

### Setup
```bash
npm install --save-dev husky lint-staged commitlint @commitlint/config-conventional

# Ativar husky
npx husky init
```

### Pre-commit Hook
```bash
# .husky/pre-commit
#!/bin/sh
npx lint-staged
```

### Commit-msg Hook
```bash
# .husky/commit-msg
#!/bin/sh
npx --no -- commitlint --edit $1
```

### lint-staged Config
```json
// package.json
{
  "lint-staged": {
    "*.{ts,tsx}": ["eslint --fix", "prettier --write"],
    "*.{md,json}": ["prettier --write"]
  }
}
```

## Comandos Úteis
```bash
# Ver log bonito
git log --oneline --graph --all

# Stash com nome
git stash push -m "WIP: feature X"
git stash list
git stash pop stash@{0}

# Amend (corrigir último commit)
git commit --amend --no-edit
git commit --amend -m "feat: nova mensagem"

# Squash últimos 3 commits
git rebase -i HEAD~3

# Cherry-pick commit específico
git cherry-pick <commit-hash>

# Desfazer último commit (manter mudanças)
git reset --soft HEAD~1

# Reverter commit público
git revert <commit-hash>
```

### Regras desta Skill
- NUNCA commit direto na main ou develop
- SEMPRE usar Conventional Commits
- PRs pequenas e focadas (uma responsabilidade)
- Code review obrigatório antes de merge
- Secrets NUNCA no git (use .env + .gitignore)
