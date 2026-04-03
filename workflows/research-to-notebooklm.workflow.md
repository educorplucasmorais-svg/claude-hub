---
name: research-to-notebooklm
description: Workflow de pesquisa com Claude → estruturação → exportação para NotebookLM
version: 1.0.0
trigger: manual
tags: [research, notebooklm, obsidian, knowledge]
---

# 🔬 Workflow: Pesquisa → NotebookLM

## Quando Usar
- Pesquisar um tópico complexo
- Preparar material para estudo
- Criar base de conhecimento para projeto
- Gerar podcast de áudio com NotebookLM

## Passo a Passo

### Fase 1: Pesquisa com Claude (15-30 min)

#### Prompt Template
```
Pesquise sobre [TÓPICO] e estruture assim:

1. **Visão Geral**: O que é e por que importa?
2. **Conceitos Fundamentais**: Os 5-10 conceitos chave
3. **Como Funciona**: Explicação técnica/prática
4. **Casos de Uso**: Quando e como aplicar
5. **Exemplos Práticos**: Código/exemplos concretos  
6. **Trade-offs**: Vantagens e limitações
7. **Recursos**: Melhores referências para aprofundar
8. **FAQ**: 10 perguntas frequentes com respostas
```

### Fase 2: Revisar e Enriquecer

Após resposta Claude:
1. Adicione suas próprias notas e insights
2. Conecte com conhecimento existente
3. Marque pontos para aprofundar
4. Adicione exemplos do seu contexto

### Fase 3: Salvar no Obsidian

```powershell
.\scripts\obsidian\sync-to-vault.ps1 `
  -NoteTitle "[TÓPICO] - Research" `
  -NoteType "learning" `
  -NoteContent "[cole o conteúdo aqui]" `
  -Tags @("research", "area/dev")
```

### Fase 4: Exportar para NotebookLM

```powershell
# Exportar nota específica
.\scripts\notebooklm\export-to-notebooklm.ps1 `
  -InputPath "scripts\obsidian\local-vault\Inbox\[arquivo.md]" `
  -Title "[TÓPICO] para NotebookLM"
```

### Fase 5: Configurar NotebookLM

1. Acesse: https://notebooklm.google.com
2. Crie novo Notebook: "[TÓPICO] - [DATA]"
3. Upload o arquivo exportado
4. (Opcional) Adicione URLs de referência como fontes adicionais
5. Gere **Audio Overview** para podcast de revisão
6. Use **Chat** para Q&A aprofundado

### Fase 6: Capturar Insights do NotebookLM

Após explorar no NotebookLM:
```powershell
# Salvar insights de volta no Obsidian
.\scripts\obsidian\sync-to-vault.ps1 `
  -NoteTitle "[TÓPICO] - Insights NotebookLM" `
  -NoteType "learning" `
  -Tags @("notebooklm", "insights")
```

## Templates de Perguntas para NotebookLM

Após carregar fontes, pergunte:
```
- "Crie um briefing de 1 página sobre [tópico]"
- "Quais são os pontos mais controversos?"  
- "Como isso se aplica a [meu contexto específico]?"
- "Crie um FAQ de 20 perguntas e respostas"
- "Quais conceitos ainda não estão claros nas fontes?"
- "Gere um estudo de caso hipotético"
```
