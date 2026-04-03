---
name: obsidian-sync
description: Integração completa com Obsidian - cria, formata e sincroniza notas no vault
version: 1.0.0
tags: [obsidian, notes, knowledge-base, markdown, vault, sync]
---

# 🗒️ Skill: Integração Obsidian

## Ativação
Use quando: "salvar no Obsidian", "criar nota", "Obsidian", "vault", "nota de conhecimento", "knowledge base"

## Como Funciona
Esta skill formata qualquer conteúdo como nota Obsidian válida com:
- **Frontmatter YAML** (metadados, tags, links)
- **Wikilinks** [[como esses]] para conexões entre notas
- **Dataview queries** para dashboards dinâmicos
- **Templates** padronizados por tipo de nota

## Templates de Nota

### 1. Nota de Conhecimento (Evergreen Note)
```markdown
---
title: "Título da Nota"
created: {{date:YYYY-MM-DD}}
modified: {{date:YYYY-MM-DD}}
tags:
  - type/concept
  - topic/tecnologia
  - status/in-progress
aliases:
  - "Nome alternativo"
source: "URL ou referência"
---

# Título da Nota

> 💡 **Resumo em uma frase**

## O que é
...

## Por que importa
...

## Como usar
...

## Conexões
- Relacionado com: [[Outra Nota]]
- Parte de: [[Área de Conhecimento]]
- Contrasta com: [[Conceito Oposto]]

## Referências
- [Link 1](url)
```

### 2. Nota de Projeto
```markdown
---
title: "Nome do Projeto"
created: {{date:YYYY-MM-DD}}
status: active | on-hold | completed | cancelled
type: project
tags:
  - type/project
  - area/desenvolvimento
due: YYYY-MM-DD
---

# 🚀 Nome do Projeto

## Objetivo
O que este projeto vai alcançar?

## Por que agora?
Motivação e contexto.

## Critérios de Sucesso
- [ ] Critério 1
- [ ] Critério 2

## Tarefas
- [ ] Task 1 📅 YYYY-MM-DD
- [ ] Task 2

## Notas e Decisões
### YYYY-MM-DD
...

## Recursos
- [[Nota Relacionada]]
- [Documentação](url)
```

### 3. Nota de Reunião / Daily
```markdown
---
date: {{date:YYYY-MM-DD}}
type: meeting | daily
participants: []
tags:
  - type/meeting
  - project/nome
---

# 📅 Reunião - {{date:DD/MM/YYYY}}

**Participantes:** ...
**Objetivo:** ...

## Discussões
...

## Decisões Tomadas
1. ...

## Ações
- [ ] @pessoa — Ação até 📅 data

## Próxima Reunião
...
```

### 4. Nota de Código / Snippet
```markdown
---
title: "Nome do Snippet"
language: typescript | python | sql | bash
tags:
  - type/snippet
  - topic/react
  - topic/hooks
created: {{date:YYYY-MM-DD}}
---

# 💻 Nome do Snippet

## Contexto
Quando usar este código?

## Código
\`\`\`typescript
// código aqui
\`\`\`

## Como Funciona
Explicação...

## Variações
...

## Armadilhas
...

## Referências
- [[Documentação Relacionada]]
```

### 5. Nota de Pesquisa / Aprendizado
```markdown
---
title: "O que aprendi sobre X"
source: "URL, livro, curso"
created: {{date:YYYY-MM-DD}}
tags:
  - type/learning
  - topic/assunto
  - status/processed
---

# 📖 Título do Aprendizado

## Fonte
...

## Principais Insights
1. ...
2. ...

## Perguntas Geradas
- Como X se conecta com Y?
- Por que Z funciona assim?

## Aplicações Práticas
...

## Conexões com Notas Existentes
- [[Nota A]] — porque X
- [[Nota B]] — porque Y
```

## Estrutura Recomendada do Vault

```
Vault/
├── 📥 Inbox/           # Capturas brutas (processar depois)
├── 🗒️ Notes/
│   ├── Concepts/       # Notas evergreen de conceitos
│   ├── Projects/       # Notas de projeto
│   ├── Meetings/       # Atas e reuniões
│   └── Snippets/       # Código e exemplos
├── 📚 Resources/       # Referências e fontes
├── 🏗️ Areas/          # Áreas de responsabilidade
├── 📁 Archive/         # Itens completados/obsoletos
└── 🧰 Templates/       # Templates das notas acima
```

## Convenções de Tags
```
type/concept     → Conceito ou definição
type/project     → Projeto ativo
type/meeting     → Atas de reunião
type/snippet     → Código reutilizável
type/learning    → Aprendizado de fonte externa

status/raw       → Capturado, não processado
status/in-progress → Em desenvolvimento
status/processed → Processado e conectado

area/dev         → Desenvolvimento
area/design      → Design e UX
area/business    → Negócio e estratégia
```

## Script de Sincronização
> Veja: `scripts/obsidian/sync-to-vault.ps1`
> Para configurar o caminho do vault, edite `scripts/obsidian/config.json`

### Regras desta Skill
- Toda nota deve ter frontmatter completo
- Usar wikilinks [[]] para conectar notas relacionadas
- Tags seguem taxonomia definida acima
- Notas atômicas: um conceito por nota
- Títulos como afirmações (não perguntas)
