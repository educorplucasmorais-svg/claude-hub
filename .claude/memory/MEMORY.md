# 🧠 Memory Hub Claude

## Projeto: Claude Hub com Multiple Skills

### Status
- ✅ Estrutura base criada
- ✅ 12 Skills implementadas
- ✅ Integração Obsidian (sync, auto-save, templates)
- ✅ Integração NotebookLM (export, bundle, workflow)
- ✅ Hooks configurados (post-message, pre-command, post-command)
- ✅ 4 Workflows criados
- ✅ Settings.json atualizado

### Skills Disponíveis (12)
1. `code-review` — Revisão profunda de código
2. `debug` — Debug sistemático com RCA
3. `refactor` — Refatoração SOLID/Clean Code
4. `docs-generator` — JSDoc, README, ADR
5. `test-generator` — Jest, Vitest, Testing Library
6. `architect` — Design de sistemas e C4 Model
7. `security-audit` — OWASP Top 10, hardening
8. `performance` — Frontend, backend, DB optimization
9. `git-workflow` — Conventional Commits, branching
10. `api-design` — REST, DTOs, versionamento
11. `obsidian-sync` — Templates e sync com vault
12. `notebooklm-export` — Export para fontes NotebookLM

### Integrações
- **Obsidian**: `scripts/obsidian/` — configure vault em `config.json`
- **NotebookLM**: `scripts/notebooklm/` — exporta `.txt` otimizados

### Configurações Importantes
- Modelo: Claude Opus 4.6
- Memória: Ativada em `.claude/memory`
- Permissões: Read, Write, Edit, Glob, Grep, Bash, Agent
- Hooks: postMessage, preCommand, postCommand ativos

### Para Configurar Obsidian
1. Edite `scripts/obsidian/config.json`
2. Defina `vaultPath` para seu vault local
3. Execute: `.\scripts\obsidian\sync-to-vault.ps1 -NoteTitle "Teste"`

### Próximas Ações
1. Configurar `vaultPath` no config do Obsidian
2. Testar sync de uma nota
3. Fazer upload de bundle no NotebookLM
4. Adicionar skills específicas de projeto conforme necessidade

