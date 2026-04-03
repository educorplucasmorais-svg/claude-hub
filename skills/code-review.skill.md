---
name: code-review
description: Revisão de código profunda com foco em bugs, segurança, performance e boas práticas
version: 1.0.0
tags: [code, review, quality, security]
---

# 🔍 Skill: Code Review Senior

## Ativação
Use quando: "revisar código", "code review", "analisar código", "checar qualidade"

## Protocolo de Revisão

### 1. Análise Estrutural
- Leia TODO o código antes de comentar
- Mapeie dependências e fluxo de dados
- Identifique padrões e anti-padrões

### 2. Checklist de Revisão (OBRIGATÓRIO)

#### 🐛 Bugs & Lógica
- [ ] Race conditions ou problemas de concorrência?
- [ ] Null/undefined não tratados?
- [ ] Loops infinitos ou recursão sem base?
- [ ] Comparações incorretas (== vs ===)?
- [ ] Lógica de negócio correta?

#### 🔐 Segurança
- [ ] SQL Injection / XSS / CSRF vulnerável?
- [ ] Secrets hardcoded?
- [ ] Inputs validados e sanitizados?
- [ ] Autenticação/autorização correta?
- [ ] Dados sensíveis expostos em logs?

#### ⚡ Performance
- [ ] N+1 queries?
- [ ] Operações bloqueantes desnecessárias?
- [ ] Memória: leaks ou uso excessivo?
- [ ] Caching onde necessário?
- [ ] Algoritmos O(n²) onde O(n) é possível?

#### 🏗️ Arquitetura & Clean Code
- [ ] SRP: cada função/classe tem uma responsabilidade?
- [ ] DRY: código duplicado?
- [ ] Nomes descritivos (funções, variáveis, classes)?
- [ ] Funções com mais de 20 linhas (refatorar)?
- [ ] Comentários desnecessários (código auto-explicativo)?

#### 🧪 Testabilidade
- [ ] Funções puras vs side effects isolados?
- [ ] Dependências injetáveis (DI)?
- [ ] Casos extremos cobertos?

### 3. Formato de Saída

```
## 📋 Code Review Report

### ✅ Pontos Positivos
- ...

### 🚨 Críticos (devem ser corrigidos)
1. **[TIPO]** Arquivo:linha — Descrição + Fix sugerido

### ⚠️ Importantes (recomendam correção)
1. **[TIPO]** Arquivo:linha — Descrição + Fix sugerido

### 💡 Sugestões (melhorias opcionais)
1. ...

### 📊 Score: X/10
**Resumo:** ...
```

### 4. Regras desta Skill
- NUNCA seja vago: sempre diga ONDE e COMO corrigir
- Forneça snippets de código corrigido
- Priorize: Segurança > Bugs > Performance > Style
- Se o código for TypeScript, verifique tipos strict
