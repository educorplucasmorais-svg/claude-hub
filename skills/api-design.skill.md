---
name: api-design
description: Design de APIs REST e GraphQL, contratos, versionamento, documentação e boas práticas
version: 1.0.0
tags: [api, rest, graphql, openapi, swagger, design]
---

# 🔌 Skill: Design de APIs

## Ativação
Use quando: "API", "endpoint", "REST", "GraphQL", "contrato", "rota", "request/response"

## REST API Design Principles

### 1. Nomenclatura de Rotas
```
# Regras:
# ✅ Substantivos (recursos), não verbos
# ✅ Plural para coleções
# ✅ kebab-case para múltiplas palavras
# ✅ Hierarquia de recursos

# ✅ Boas rotas
GET    /api/users              # lista usuários
GET    /api/users/:id          # busca usuário
POST   /api/users              # cria usuário
PUT    /api/users/:id          # atualiza completo
PATCH  /api/users/:id          # atualiza parcial
DELETE /api/users/:id          # deleta usuário

GET    /api/users/:id/orders   # pedidos de um usuário
GET    /api/orders/:id/items   # itens de um pedido

# ❌ Más rotas
POST /api/getUser
GET  /api/createOrder
POST /api/deleteProduct/:id
GET  /api/UsersList
```

### 2. HTTP Status Codes
```
200 OK              → GET/PUT/PATCH com sucesso
201 Created         → POST bem-sucedido
204 No Content      → DELETE bem-sucedido
400 Bad Request     → Input inválido (erro do cliente)
401 Unauthorized    → Não autenticado
403 Forbidden       → Autenticado mas sem permissão
404 Not Found       → Recurso não existe
409 Conflict        → Conflito (email duplicado, etc.)
422 Unprocessable   → Entidade inválida semanticamente
429 Too Many Req.   → Rate limit excedido
500 Internal Server → Erro do servidor
503 Unavailable     → Serviço temporariamente fora
```

### 3. Response Format Padrão
```typescript
// ✅ Sucesso com dados
{
  "data": { ... },
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 20,
    "totalPages": 5
  }
}

// ✅ Sucesso com lista
{
  "data": [...],
  "meta": { "total": 50, "page": 1, "limit": 20 }
}

// ✅ Erro padronizado
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Email já está em uso",
    "details": [
      { "field": "email", "message": "Email must be unique" }
    ]
  }
}
```

### 4. Implementação Express Tipada
```typescript
import { Router, Request, Response } from 'express'
import { z } from 'zod'
import { asyncHandler } from '../utils/asyncHandler'

const router = Router()

const createUserSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  password: z.string().min(8)
})

// POST /api/users
router.post('/', 
  authenticate,
  asyncHandler(async (req: Request, res: Response) => {
    const body = createUserSchema.parse(req.body) // throws ZodError se inválido
    
    const user = await userService.create(body)
    
    return res.status(201).json({
      data: toUserDTO(user) // nunca retorne entidade diretamente
    })
  })
)

// GET /api/users?page=1&limit=20&sort=createdAt
router.get('/',
  authenticate,
  authorize('admin'),
  asyncHandler(async (req: Request, res: Response) => {
    const { page = '1', limit = '20', sort = 'createdAt' } = req.query
    
    const { users, total } = await userService.findAll({
      page: Number(page),
      limit: Math.min(Number(limit), 100), // máximo 100
      sort: String(sort)
    })
    
    return res.json({
      data: users.map(toUserDTO),
      meta: {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / Number(limit))
      }
    })
  })
)
```

### 5. Versionamento de API
```
# URL versioning (mais simples, recomendado)
/api/v1/users
/api/v2/users

# Header versioning
Accept: application/vnd.myapi.v2+json

# Estratégia de deprecação:
# 1. Anunciar deprecação com 6 meses de antecedência
# 2. Header de aviso: Deprecation: true, Sunset: data
# 3. Manter versão antiga por pelo menos 1 ano
```

### 6. Rate Limiting
```typescript
import rateLimit from 'express-rate-limit'

// Global
app.use(rateLimit({ windowMs: 15*60*1000, max: 100 }))

// Endpoints sensíveis
const strictLimit = rateLimit({ windowMs: 60*1000, max: 5 })
app.use('/api/auth', strictLimit)
app.use('/api/payments', strictLimit)
```

### 7. DTO Pattern
```typescript
// Nunca exponha entidades diretamente
interface UserDTO {
  id: string
  name: string
  email: string
  createdAt: string
  // ❌ sem: password, refreshToken, etc.
}

function toUserDTO(user: User): UserDTO {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    createdAt: user.createdAt.toISOString()
  }
}
```

### Regras desta Skill
- Contratos imutáveis: não quebre clientes existentes
- Sempre versione antes de fazer breaking changes
- DTOs em todas as responses (nunca entidades brutas)
- Rate limit em endpoints de autenticação e pagamento
- OpenAPI/Swagger atualizado junto com o código
