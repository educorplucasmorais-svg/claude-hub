scripts\obsidian\config.json → "vaultPath": "C:\\caminho\\para\\seu\\vault"# Claude Hub - Configuração do Projeto

## 📌 Visão Geral
Hub centralizado com múltiplas skills automatizadas para Claude Code,
com integração nativa ao **Obsidian** (knowledge base) e **NotebookLM** (pesquisa IA).

## 🎯 Objetivos
- Automatizar workflows comuns
- Centralizar configurações e padrões
- Facilitar reutilização de código e processos
- Sincronizar conhecimento entre Claude ↔ Obsidian ↔ NotebookLM

## 📁 Estrutura do Projeto

```
claude-hub/
├── CLAUDE.md                    # Este arquivo - regras e configuração
├── settings.json                # Configuração do Claude Code
├── .claude/
│   └── memory/
│       └── MEMORY.md            # Memória persistente entre sessões
│
├── skills/                      # 12 Skills customizadas
│   ├── code-review.skill.md
│   ├── debug.skill.md
│   ├── refactor.skill.md
│   ├── docs-generator.skill.md
│   ├── test-generator.skill.md
│   ├── architect.skill.md
│   ├── security-audit.skill.md
│   ├── performance.skill.md
│   ├── git-workflow.skill.md
│   ├── api-design.skill.md
│   ├── obsidian-sync.skill.md   # 🗒️ Integração Obsidian
│   └── notebooklm-export.skill.md # 📚 Integração NotebookLM
│
├── hooks/                       # Scripts automatizados
│   ├── post-message.ps1         # Auto-save Obsidian, atualiza memória
│   ├── pre-command.ps1          # Bloqueia comandos perigosos
│   └── post-command.ps1         # Alerta sobre falhas de build/test
│
├── workflows/                   # Fluxos de trabalho
│   ├── daily-review.workflow.md
│   ├── research-to-notebooklm.workflow.md
│   ├── project-kickoff.workflow.md
│   └── code-review-pr.workflow.md
│
├── scripts/
│   ├── obsidian/
│   │   ├── config.json          # Configurar caminho do vault aqui
│   │   ├── sync-to-vault.ps1    # Script principal de sync
│   │   └── auto-save-hook.ps1   # Hook de auto-save
│   └── notebooklm/
│       ├── config.json
│       └── export-to-notebooklm.ps1
│
└── docs/                        # Documentação do hub
```

## 🔧 Skills Disponíveis (12)

| Skill | Ativação |
|-------|----------|
| `code-review` | "revisar código", "code review" |
| `debug` | "não funciona", "erro", "bug", "debug" |
| `refactor` | "refatorar", "clean code", "melhorar código" |
| `docs-generator` | "documentar", "README", "JSDoc" |
| `test-generator` | "criar testes", "TDD", "Jest" |
| `architect` | "arquitetura", "design do sistema" |
| `security-audit` | "segurança", "OWASP", "vulnerabilidade" |
| `performance` | "lento", "otimizar", "N+1", "cache" |
| `git-workflow` | "commit", "branch", "PR", "git" |
| `api-design` | "API", "endpoint", "REST" |
| `obsidian-sync` | "salvar no Obsidian", "criar nota" |
| `notebooklm-export` | "NotebookLM", "exportar" |

## 🗒️ Integração Obsidian

### Setup (uma vez)
1. Edite `scripts/obsidian/config.json`
2. Defina `vaultPath` para o caminho do seu vault
3. Pronto — as notas serão salvas automaticamente

### Uso
```powershell
# Criar nota
.\scripts\obsidian\sync-to-vault.ps1 -NoteTitle "Minha Nota" -NoteType concept

# Sincronizar docs/
.\scripts\obsidian\sync-to-vault.ps1 -SyncAll

# Listar notas
.\scripts\obsidian\sync-to-vault.ps1 -ListNotes
```

### Auto-save
Digite "salvar no Obsidian" em qualquer conversa para salvar automaticamente.

## 📚 Integração NotebookLM

### Uso
```powershell
# Exportar documento específico
.\scripts\notebooklm\export-to-notebooklm.ps1 -InputPath ".\docs\artigo.md"

# Exportar tudo como bundle (recomendado)
.\scripts\notebooklm\export-to-notebooklm.ps1 -Bundle -OpenOutputFolder
```

Depois carregue o arquivo exportado em: https://notebooklm.google.com

## 📝 Hooks Configurados

| Hook | Arquivo | Função |
|------|---------|--------|
| `postMessage` | `hooks/post-message.ps1` | Auto-save Obsidian, update memória |
| `preCommand` | `hooks/pre-command.ps1` | Bloqueia comandos destrutivos |
| `postCommand` | `hooks/post-command.ps1` | Alerta sobre falhas |

## 🔐 Permissões

Permissões ativadas globalmente:
- Read, Write, Edit, Glob, Grep, Bash, Agent, EnterPlanMode

## 🚀 Quick Start

```powershell
# 1. Configure o vault Obsidian
notepad scripts\obsidian\config.json

# 2. Teste a integração
.\scripts\obsidian\sync-to-vault.ps1 -NoteTitle "Teste" -NoteType concept

# 3. Exporte para NotebookLM
.\scripts\notebooklm\export-to-notebooklm.ps1 -Bundle
```

## 📚 Referências
- [Claude Code Docs](https://claude.com/claude-code)
- [Obsidian](https://obsidian.md)
- [NotebookLM](https://notebooklm.google.com)
- Guia de Workflow: Shift+Tab+Tab+Plan Mode

