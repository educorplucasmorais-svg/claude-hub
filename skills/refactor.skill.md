---
name: refactor
description: Refatoração sistemática aplicando SOLID, DRY, Clean Code e padrões de design
version: 1.0.0
tags: [refactor, clean-code, solid, architecture]
---

# ♻️ Skill: Refatoração Sistemática

## Ativação
Use quando: "refatorar", "melhorar código", "limpar código", "clean code", "reorganizar"

## Princípios Aplicados (Ordem de Prioridade)

### 1. Análise Antes de Refatorar
- [ ] O código tem testes? Se não → escreva antes de refatorar
- [ ] Qual é o comportamento atual (contratos)?
- [ ] Qual é o smell principal?
- [ ] Qual é o risco de quebrar algo?

### 2. Code Smells → Soluções

#### 🍝 Código Espaguete / Função longa
```typescript
// ❌ Antes: função com 50+ linhas fazendo tudo
async function processOrder(data: any) {
  // valida...
  // salva no DB...
  // envia email...
  // atualiza estoque...
  // notifica...
}

// ✅ Depois: cada responsabilidade isolada (SRP)
async function processOrder(data: CreateOrderDTO) {
  const order = await validateAndCreateOrder(data)
  await Promise.all([
    sendOrderConfirmationEmail(order),
    updateInventory(order.items),
    notifyWarehouse(order)
  ])
  return order
}
```

#### 🔁 Código Duplicado (DRY)
```typescript
// ❌ Antes
const userA = { ...rawUser, createdAt: new Date() }
const userB = { ...rawUser, createdAt: new Date() }

// ✅ Depois: extraia para função/helper
const withTimestamp = <T>(obj: T): T & { createdAt: Date } =>
  ({ ...obj, createdAt: new Date() })
```

#### 🔗 Acoplamento excessivo (DIP)
```typescript
// ❌ Antes: depende de implementação concreta
class OrderService {
  private db = new MySQLDatabase()
}

// ✅ Depois: depende de abstração
class OrderService {
  constructor(private db: IDatabase) {}
}
```

#### 💉 Magic numbers / strings
```typescript
// ❌ Antes
if (user.role === 2) { ... }
setTimeout(fn, 86400000)

// ✅ Depois
const UserRole = { ADMIN: 2, USER: 1 } as const
const ONE_DAY_MS = 24 * 60 * 60 * 1000
```

### 3. Checklist SOLID

| Princípio | Verificação |
|-----------|-------------|
| **S** - SRP | Cada classe/módulo tem UMA razão para mudar? |
| **O** - OCP | Extensível sem modificar código existente? |
| **L** - LSP | Subclasses substituem bases sem quebrar? |
| **I** - ISP | Interfaces pequenas e específicas? |
| **D** - DIP | Módulos de alto nível dependem de abstrações? |

### 4. Estratégia de Refatoração Segura
```
1. git checkout -b refactor/nome-do-que-vai-refatorar
2. Rode testes → confirme que estão passando
3. Refatore EM PEQUENOS PASSOS (1 smell por vez)
4. Rode testes após cada passo
5. Se testes quebrarem → git stash e reanalise
6. PR com descrição do que mudou e por quê
```

### 5. Padrões de Design Comuns

| Problema | Padrão |
|----------|--------|
| Muitos `if/else` de tipo | Strategy ou Polymorphism |
| Criação complexa de objetos | Builder ou Factory |
| Dependências globais | Dependency Injection |
| Operações em coleções | Pipeline / Fluent Interface |
| Estado compartilhado | Observer ou Event Emitter |

### Regras desta Skill
- NUNCA refatore sem testes
- Commits atômicos (1 mudança por commit)
- Preserve contratos públicos (não quebre APIs)
- Documente PORQUÊ, não O QUÊ
