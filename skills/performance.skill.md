---
name: performance
description: Análise e otimização de performance em frontend, backend, banco de dados e infraestrutura
version: 1.0.0
tags: [performance, optimization, caching, database, frontend]
---

# ⚡ Skill: Otimização de Performance

## Ativação
Use quando: "lento", "performance", "otimizar", "lag", "timeout", "N+1", "cache", "otimização"

## Frontend Performance

### Core Web Vitals (metas 2026)
| Métrica | Bom | Precisa Melhorar | Ruim |
|---------|-----|-----------------|------|
| LCP (maior conteúdo) | < 2.5s | 2.5-4s | > 4s |
| FID/INP (interatividade) | < 200ms | 200-500ms | > 500ms |
| CLS (estabilidade visual) | < 0.1 | 0.1-0.25 | > 0.25 |

### Técnicas React

#### Code Splitting & Lazy Loading
```typescript
// ❌ Importa tudo na bundle inicial
import { HeavyDashboard } from './HeavyDashboard'

// ✅ Carrega só quando necessário
const HeavyDashboard = lazy(() => import('./HeavyDashboard'))

function App() {
  return (
    <Suspense fallback={<Skeleton />}>
      <HeavyDashboard />
    </Suspense>
  )
}
```

#### Memoização Correta
```typescript
// ✅ memo para componentes com re-renders caros
const ProductCard = memo(({ product }: { product: Product }) => (
  <div>{product.name}</div>
), (prev, next) => prev.product.id === next.product.id)

// ✅ useMemo para cálculos pesados
const sortedProducts = useMemo(
  () => products.sort((a, b) => a.price - b.price),
  [products]
)

// ✅ useCallback para funções passadas como props
const handleClick = useCallback((id: string) => {
  onSelect(id)
}, [onSelect])
```

#### Virtualização de Listas
```typescript
// Para listas com 100+ itens
import { FixedSizeList } from 'react-window'

<FixedSizeList
  height={600}
  itemCount={products.length}
  itemSize={80}
>
  {({ index, style }) => (
    <ProductRow style={style} product={products[index]} />
  )}
</FixedSizeList>
```

### Bundle Optimization (Vite)
```typescript
// vite.config.ts
export default {
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          utils: ['lodash', 'date-fns'],
        }
      }
    }
  }
}
```

## Backend Performance

### N+1 Query Problem
```typescript
// ❌ N+1: 1 query para orders + N queries para cada user
const orders = await prisma.order.findMany()
for (const order of orders) {
  order.user = await prisma.user.findById(order.userId) // N queries!
}

// ✅ Include: 1 query com JOIN
const orders = await prisma.order.findMany({
  include: { user: true }
})

// ✅ Para casos complexos: DataLoader (batching)
```

### Caching Strategy
```typescript
// Redis para dados frequentes e caros
class UserService {
  async findById(id: string): Promise<User> {
    const cached = await redis.get(`user:${id}`)
    if (cached) return JSON.parse(cached)
    
    const user = await this.userRepo.findById(id)
    await redis.setex(`user:${id}`, 3600, JSON.stringify(user)) // TTL: 1h
    return user
  }

  async updateUser(id: string, data: UpdateUserDTO): Promise<User> {
    const user = await this.userRepo.update(id, data)
    await redis.del(`user:${id}`) // Invalidar cache
    return user
  }
}
```

### HTTP Response Optimization
```typescript
// ✅ Compressão
import compression from 'compression'
app.use(compression())

// ✅ Paginação sempre
app.get('/api/products', async (req, res) => {
  const { page = 1, limit = 20 } = req.query
  const products = await prisma.product.findMany({
    skip: (Number(page) - 1) * Number(limit),
    take: Number(limit)
  })
  res.json({ data: products, page, limit })
})
```

## Database Performance

### Índices Estratégicos
```sql
-- Para campos usados em WHERE frequentes
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);

-- Índice composto para queries compostas
CREATE INDEX idx_products_category_price 
ON products(category_id, price);

-- Verificar queries lentas
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 1;
```

### Query Optimization
```typescript
// ✅ Selecione apenas campos necessários
const users = await prisma.user.findMany({
  select: { id: true, name: true, email: true } // não traga senha, etc.
})

// ✅ Use count ao invés de findMany para contagem
const total = await prisma.order.count({ where: { status: 'pending' } })
```

## Ferramentas de Análise
```bash
# Lighthouse CI
npx lighthouse https://meusite.com --output json

# Bundle analyzer
npx vite-bundle-visualizer

# Node.js profiling
node --prof app.js
node --prof-process isolate-*.log

# DB slow query log (MySQL)
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 1;
```

### Regras desta Skill
- Meça ANTES de otimizar (profiling first)
- Otimização prematura é a raiz de todo mal
- Cache com invalidação correta vale mais que qualquer outra otimização
- Database: índices são a maior alavanca de performance
