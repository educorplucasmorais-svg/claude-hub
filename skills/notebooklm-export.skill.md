---
name: notebooklm-export
description: Prepara e exporta conteúdo Claude para uso como fonte no Google NotebookLM
version: 1.0.0
tags: [notebooklm, google, research, knowledge, export, ai]
---

# 📚 Skill: Integração NotebookLM

## Ativação
Use quando: "NotebookLM", "exportar para NotebookLM", "fonte de pesquisa", "notebook google"

## O que é NotebookLM
Google NotebookLM é uma ferramenta de pesquisa e notetaking com IA que:
- Cria podcasts de áudio a partir das suas fontes
- Faz Q&A sobre documentos específicos
- Gera resumos, briefings e FAQs
- Conecta múltiplas fontes num único notebook

## Como Funciona Esta Integração

### Formatos Aceitos pelo NotebookLM
| Formato | Suporte | Recomendação |
|---------|---------|--------------|
| `.txt` | ✅ Nativo | **Melhor para texto puro** |
| `.md` | ✅ Nativo | Bom para documentação |
| PDF | ✅ Nativo | Para documentos formatados |
| Google Doc | ✅ Nativo | Para colaboração |
| URLs | ✅ Nativo | Para páginas web |
| `.docx` | ✅ Nativo | Para documentos Word |

### Workflow de Exportação

#### Opção 1: Via Script (Recomendado)
```powershell
# Exportar documento específico
.\scripts\notebooklm\export-to-notebooklm.ps1 -InputPath ".\docs\meu-artigo.md"

# Exportar TUDO como bundle único (melhor para NotebookLM)
.\scripts\notebooklm\export-to-notebooklm.ps1 -Bundle

# Abrir pasta de exports automaticamente
.\scripts\notebooklm\export-to-notebooklm.ps1 -Bundle -OpenOutputFolder
```

#### Opção 2: Copiar/Colar
Para conteúdo de conversa Claude, formatar assim:
```
# [Título do Documento]
Data: DD/MM/YYYY
Fonte: Claude Hub

[Conteúdo aqui — bem estruturado, sem markdown complexo]

## Seção 1
[texto]

## Seção 2  
[texto]
```

## Tipos de Fontes para NotebookLM

### 1. Fonte de Pesquisa (Research Brief)
```
# Pesquisa: [Tema]

## Resumo Executivo
[2-3 parágrafos]

## Pontos Principais
1. ...
2. ...
3. ...

## Análise Detalhada
[texto]

## Conclusões
[texto]

## Perguntas para Aprofundar
- Como X impacta Y?
- Qual é a diferença entre A e B?
```

### 2. Base de Conhecimento Técnico
```
# Documentação Técnica: [Sistema/Tecnologia]

## Visão Geral
[o que é e para que serve]

## Arquitetura
[como funciona]

## Componentes Principais
[lista e descrição]

## Como Usar
[passo a passo]

## Casos de Uso Comuns
[exemplos práticos]

## Troubleshooting
[problemas comuns e soluções]
```

### 3. Atas e Decisões de Projeto
```
# Decisões do Projeto: [Nome do Projeto]

## Decisão 1: [Título]
Data: YYYY-MM-DD
Status: Aprovado | Em discussão

### Contexto
[por que precisávamos decidir]

### Opções Avaliadas
- Opção A: [pros/contras]
- Opção B: [pros/contras]

### Decisão Tomada
[o que foi decidido e por quê]

### Impacto
[consequências]
```

## Melhores Práticas para NotebookLM

### ✅ Faça
- Use texto limpo e bem estruturado com cabeçalhos
- Um tópico por documento (melhora Q&A)
- Inclua contexto sobre quando/por que foi criado
- Use linguagem clara, evite jargão excessivo
- Divida documentos grandes (> 50 páginas) em partes
- Inclua exemplos concretos

### ❌ Evite
- Markdown pesado com tabelas complexas (prefira texto)
- Código fonte bruto sem explicação
- Imagens (NotebookLM não processa imagens em PDFs)
- Metadados desnecessários no início
- Conteúdo confidencial (dados pessoais, senhas)

## Geração de Podcast com NotebookLM

Após carregar suas fontes:
1. Clique em "Audio Overview" 
2. Customize o prompt: *"Faça um podcast de 10 minutos explicando [tema] para desenvolvedores"*
3. Aguarde geração (2-5 minutos)
4. Use para revisão, onboarding ou estudo

## Integração com Obsidian

Para sync bidirecional:
```
Claude Hub → Export → NotebookLM Fontes
     ↓
NotebookLM Insights → Claude Hub docs/ → Obsidian Sync
```

### Regras desta Skill
- Sempre limpar markdown antes de exportar
- Bundle de múltiplos docs é melhor que muitos docs pequenos
- Incluir contexto temporal (data) em todas as fontes
- Nunca incluir dados sensíveis/pessoais nas fontes
