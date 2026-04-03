---
name: debug
description: Debug autônomo e sistemático de bugs, erros e comportamentos inesperados
version: 1.0.0
tags: [debug, bug, error, troubleshoot]
---

# 🐛 Skill: Debug Sistemático

## Ativação
Use quando: "não funciona", "erro", "bug", "quebrado", "exception", "undefined", "debug"

## Protocolo de Debug (5-Why + Binary Search)

### Fase 1: Coleta de Evidências
Sempre pergunte/colete:
1. **Mensagem de erro exata** (stack trace completo)
2. **Comportamento esperado** vs **comportamento atual**
3. **Quando começou** (último commit? deploy? mudança de config?)
4. **Ambiente** (dev/staging/prod? OS? versão Node/Browser?)
5. **Reproduce steps** (passo a passo para reproduzir)

### Fase 2: Hipóteses (ordenadas por probabilidade)
```
🎯 Hipótese 1: [mais provável] — Evidência: X
🎯 Hipótese 2: [provável]     — Evidência: Y  
🎯 Hipótese 3: [possível]     — Evidência: Z
```

### Fase 3: Investigação Sistemática
```
search/codebase → localizar arquivo relevante
↓
Ler código → identificar fluxo de execução
↓
Adicionar logging estratégico (temporário)
↓
Isolar componente → reproduzir em isolamento
↓
Binary search: dividir código ao meio para localizar origem
```

### Fase 4: Root Cause Analysis (RCA)
- Qual é o problema REAL (não o sintoma)?
- Por que aconteceu?
- Por que não foi detectado antes?
- Como prevenir no futuro?

### Fase 5: Fix + Verificação
```typescript
// ❌ Código com bug (antes)
// [mostrar código original]

// ✅ Código corrigido (depois)
// [mostrar correção com explicação]
```

Após fix:
- [ ] Rode testes existentes
- [ ] Adicione teste para o bug específico
- [ ] Verifique se fix não introduz regressão

### Padrões de Bug Comuns

#### JavaScript/TypeScript
```
- TypeError: Cannot read property X of undefined
  → Null check faltando: obj?.prop ou if (obj && obj.prop)
  
- Promise rejected sem .catch()
  → Adicionar try/catch em async/await
  
- Stale closure em React hooks
  → Verificar array de dependências useEffect/useCallback
  
- Memory leak
  → Cleanup no return do useEffect
```

#### Node.js / Express
```
- ECONNREFUSED → serviço não está rodando / porta errada
- ETIMEDOUT → firewall, rede, ou timeout muito curto
- EADDRINUSE → porta já ocupada: lsof -i :PORT
```

### Comandos de Debug Úteis
```bash
# Ver logs em tempo real
tail -f logs/app.log

# Verificar porta em uso
netstat -ano | findstr :3000   # Windows
lsof -i :3000                  # Mac/Linux

# Verificar variáveis de ambiente
node -e "console.log(process.env)"

# TypeScript: verificar tipos
npx tsc --noEmit
```

### Regras desta Skill
- NUNCA assuma a causa sem evidências
- Sempre reproduza o bug antes de corrigir
- Fix minimal: mude o mínimo necessário
- Documente a causa raiz no comentário do commit
