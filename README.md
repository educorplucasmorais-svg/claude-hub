# Claude Hub — Master Development Guide

> Guia mestre para construir qualquer aplicação: frontend, backend, fullstack e automações.  
> Este repositório é um hub de skills, agentes e templates prontos para uso com Claude Code.

---

## 📦 Stack Padrão (2026)

| Camada | Tecnologia | Versão |
|---|---|---|
| **Frontend** | React + TypeScript | 18+ |
| **Build** | Vite | 8+ |
| **Estilo** | TailwindCSS v4 | @tailwindcss/vite |
| **Ícones** | Lucide React | latest |
| **Backend** | Node.js + Express | 22+ |
| **ORM** | Prisma | 6+ |
| **Banco** | MySQL / PostgreSQL | — |
| **Auth** | JWT + bcrypt | — |
| **Pagamentos** | Stripe | latest |
| **Deploy Front** | Vercel | — |
| **Deploy Back** | Railway / Render / VPS | — |
| **AI** | Gemini 2.0 Flash | via REST API |

---

## 🚀 Scaffolding Rápido

### Frontend (React + Vite + TypeScript + Tailwind)

```bash
# 1. Criar projeto
npm create vite@latest meu-app -- --template react-ts
cd meu-app

# 2. Instalar Tailwind v4 (via plugin Vite)
npm install -D tailwindcss @tailwindcss/vite

# 3. Instalar dependências comuns
npm install lucide-react axios react-router-dom
npm install -D @types/node

# 4. Estrutura de pastas
src/
├── components/    # UI reutilizável (Button, Input, Modal...)
├── pages/         # Páginas/rotas
├── hooks/         # Custom hooks
├── services/      # Chamadas de API
├── stores/        # Estado global (Zustand ou Context)
├── types/         # TypeScript types/interfaces
├── utils/         # Helpers
└── lib/           # Config (axios instance, queryClient...)
```

**vite.config.ts:**
```ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: { port: 3000 },
})
```

**src/index.css:**
```css
@import "tailwindcss";
* { box-sizing: border-box; }
body { margin: 0; }
```

---

### Backend (Node.js + Express + Prisma)

```bash
# 1. Inicializar
mkdir server && cd server
npm init -y

# 2. Instalar dependências
npm install express cors dotenv bcryptjs jsonwebtoken
npm install @prisma/client stripe
npm install -D typescript ts-node-dev @types/express @types/node @types/cors @types/bcryptjs @types/jsonwebtoken prisma

# 3. TypeScript
npx tsc --init

# 4. Prisma
npx prisma init --datasource-provider mysql
```

**Estrutura de pastas:**
```
server/
├── src/
│   ├── controllers/   # Lógica das rotas
│   ├── routes/        # Definição das rotas
│   ├── middleware/     # Auth, validation, error handling
│   ├── services/      # Business logic
│   ├── utils/         # Helpers
│   └── app.ts         # Express setup
├── prisma/
│   └── schema.prisma
├── .env
└── package.json
```

---

## 🏗️ Templates de Código

### Rota Express padrão

```ts
// src/routes/users.ts
import { Router } from 'express'
import { getUsers, createUser } from '../controllers/users.controller'
import { authMiddleware } from '../middleware/auth'

const router = Router()

router.get('/',    authMiddleware, getUsers)
router.post('/',   createUser)

export default router
```

### Controller padrão

```ts
// src/controllers/users.controller.ts
import { Request, Response } from 'express'
import { prisma } from '../lib/prisma'

export async function getUsers(req: Request, res: Response) {
  try {
    const users = await prisma.user.findMany({
      select: { id: true, name: true, email: true, createdAt: true }
    })
    return res.json({ data: users })
  } catch (error) {
    return res.status(500).json({ error: 'Internal server error' })
  }
}

export async function createUser(req: Request, res: Response) {
  try {
    const { name, email, password } = req.body
    // validation, hash, create...
    return res.status(201).json({ data: user })
  } catch (error) {
    return res.status(400).json({ error: 'Bad request' })
  }
}
```

### Auth Middleware

```ts
// src/middleware/auth.ts
import { Request, Response, NextFunction } from 'express'
import jwt from 'jsonwebtoken'

export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.split(' ')[1]
  if (!token) return res.status(401).json({ error: 'Unauthorized' })

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET!)
    req.user = payload as any
    next()
  } catch {
    return res.status(401).json({ error: 'Token inválido' })
  }
}
```

### Prisma Schema base

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "mysql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int      @id @default(autoincrement())
  name      String
  email     String   @unique
  password  String
  role      Role     @default(USER)
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@map("users")
}

enum Role {
  USER
  ADMIN
}
```

### Axios Service (Frontend)

```ts
// src/lib/api.ts
import axios from 'axios'

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:3001',
})

api.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  res => res,
  err => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)
```

### React Query Hook padrão

```ts
// src/hooks/useUsers.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'

export function useUsers() {
  return useQuery({
    queryKey: ['users'],
    queryFn: () => api.get('/users').then(r => r.data),
  })
}

export function useCreateUser() {
  const qc = useQueryClient()
  return useMutation({
    mutationFn: (data: CreateUserDTO) => api.post('/users', data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['users'] }),
  })
}
```

---

## 🗃️ .env Templates

### Frontend (.env)
```env
VITE_API_URL=http://localhost:3001
VITE_STRIPE_PUBLIC_KEY=pk_test_...
VITE_GEMINI_API_KEY=AIza...
```

### Backend (.env)
```env
PORT=3001
NODE_ENV=development

# Database
DATABASE_URL="mysql://user:password@localhost:3306/mydb"

# Auth
JWT_SECRET=seu_segredo_muito_secreto_aqui
JWT_EXPIRES_IN=7d

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Gemini
GEMINI_API_KEY=AIza...

# CORS
ALLOWED_ORIGINS=http://localhost:3000,https://meusite.vercel.app
```

---

## 🔐 Padrão de Autenticação JWT

```ts
// Login flow completo
// 1. POST /auth/login → retorna { token, user }
// 2. Armazena token no localStorage
// 3. Interceptor axios envia header automaticamente
// 4. Middleware valida em cada rota protegida

// src/controllers/auth.controller.ts
import bcrypt from 'bcryptjs'
import jwt from 'jsonwebtoken'
import { prisma } from '../lib/prisma'

export async function login(req: Request, res: Response) {
  const { email, password } = req.body
  const user = await prisma.user.findUnique({ where: { email } })
  if (!user || !await bcrypt.compare(password, user.password))
    return res.status(401).json({ error: 'Credenciais inválidas' })

  const token = jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET!,
    { expiresIn: '7d' }
  )
  return res.json({ token, user: { id: user.id, name: user.name, email: user.email } })
}
```

---

## 💳 Stripe Integration

```ts
// Backend: criar payment intent
import Stripe from 'stripe'
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!)

export async function createPaymentIntent(req: Request, res: Response) {
  const { amount, currency = 'brl' } = req.body
  const intent = await stripe.paymentIntents.create({
    amount: amount * 100, // centavos
    currency,
    metadata: { userId: req.user.id }
  })
  return res.json({ clientSecret: intent.client_secret })
}

// Webhook para confirmar pagamento
export async function handleWebhook(req: Request, res: Response) {
  const sig = req.headers['stripe-signature']!
  const event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_WEBHOOK_SECRET!)
  
  if (event.type === 'payment_intent.succeeded') {
    const intent = event.data.object as Stripe.PaymentIntent
    // Atualizar status no banco
  }
  return res.json({ received: true })
}
```

---

## 🤖 Gemini AI Integration

```ts
// Frontend: chamar Gemini diretamente
async function askGemini(prompt: string): Promise<string> {
  const key = import.meta.env.VITE_GEMINI_API_KEY
  const r = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${key}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 4096, temperature: 0.7 }
      })
    }
  )
  const data = await r.json()
  return data.candidates[0].content.parts[0].text
}
```

```ts
// Backend: via SDK
import { GoogleGenAI } from '@google/genai'
const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY })

export async function generateWithAI(prompt: string) {
  const response = await ai.models.generateContent({
    model: 'gemini-2.0-flash',
    contents: prompt,
  })
  return response.text
}
```

---

## 🚀 Deploy

### Vercel (Frontend)

```bash
# Login e deploy
npx vercel login
npx vercel deploy --prod

# Variáveis de ambiente
npx vercel env add VITE_API_URL production

# vercel.json (SPA com React Router)
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

### Railway (Backend)

```bash
# Instalar CLI
npm install -g @railway/cli
railway login
railway init
railway up

# Variáveis
railway variables set DATABASE_URL=...
railway variables set JWT_SECRET=...
```

### Docker (Backend)

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
EXPOSE 3001
CMD ["node", "dist/app.js"]
```

---

## 🗂️ Checklist de Projeto Novo

### Kickoff (5 min)
- [ ] `npm create vite@latest` → react-ts
- [ ] Instalar Tailwind v4 + lucide-react
- [ ] Configurar `.env` e `.env.example`
- [ ] Criar estrutura de pastas (components, pages, hooks, services)
- [ ] Configurar `axios` instance com interceptors

### Backend (15 min)
- [ ] Express + cors + dotenv
- [ ] Prisma init + schema base (User, Role)
- [ ] `prisma migrate dev`
- [ ] Rotas: `/auth/login`, `/auth/register`, `/users`
- [ ] Auth middleware JWT
- [ ] Error handler global

### Features padrão
- [ ] Login / Register / Logout
- [ ] CRUD básico da entidade principal
- [ ] Proteção de rotas (authMiddleware)
- [ ] Paginação nas listagens
- [ ] Validação de input (zod ou express-validator)
- [ ] Upload de arquivos (multer + S3/Cloudflare R2)

### Produção
- [ ] `.env.production` com chaves reais
- [ ] `vercel.json` com rewrites
- [ ] CORS configurado com domínio de produção
- [ ] `DATABASE_URL` apontando para Hostinger/PlanetScale
- [ ] HTTPS no backend
- [ ] Rate limiting (express-rate-limit)

---

## 🛠️ Claude Hub — Skills Disponíveis

Use estas skills com Claude Code digitando o nome no chat:

| Skill | Quando usar |
|---|---|
| `code-review` | Antes de fazer PR — detecta bugs e vulnerabilidades |
| `debug` | Quando tem erro que não consegue achar |
| `refactor` | Código funcionando mas feio/repetido |
| `docs-generator` | Gerar JSDoc, README, ADR |
| `test-generator` | Criar testes Jest/Vitest |
| `architect` | Planejar novo módulo ou sistema |
| `security-audit` | Antes de ir pra produção |
| `performance` | App lento — diagnóstico e otimização |
| `git-workflow` | Commit messages, branching, PR |
| `api-design` | Design de endpoints REST |
| `obsidian-sync` | Salvar notas da sessão no Obsidian |
| `notebooklm-export` | Exportar para NotebookLM |

---

## 🤖 Agentes Autônomos

```powershell
# Terminal interativo (hub.ps1)
pwsh -File hub.ps1

# Comandos disponíveis
bom dia              # Briefing diário
analisar codigo      # Code Guardian
processar inbox      # Organizar Obsidian
pesquisar [topico]   # Fila de pesquisa

# NotebookLM (Gemini)
resumir              # Resumo executivo das notas
guia de estudos      # Flashcards + questões
mapa mental          # Mapa hierárquico
insights             # Pontos-chave
perguntar            # Q&A interativo
audio overview       # Roteiro de podcast

# Design (Stitch via Gemini)
design [descricao]   # Gerar componente React
html [descricao]     # Gerar HTML completo
```

---

## 📚 Referências

- [Vite Docs](https://vitejs.dev)
- [Tailwind v4](https://tailwindcss.com/docs/v4-beta)
- [Prisma Docs](https://www.prisma.io/docs)
- [Gemini API](https://ai.google.dev/gemini-api/docs)
- [Stripe Docs](https://stripe.com/docs)
- [React Query](https://tanstack.com/query)
- [Vercel Deploy](https://vercel.com/docs)

---

*Gerado automaticamente pelo Claude Hub · vault: Kaia · modelo: claude-sonnet-4-6*
