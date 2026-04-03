---
name: docs-generator
description: Geração automática de documentação técnica, JSDoc, README, ADRs e diagramas
version: 1.0.0
tags: [docs, documentation, jsdoc, readme, adr]
---

# 📚 Skill: Gerador de Documentação

## Ativação
Use quando: "documentar", "gerar docs", "README", "JSDoc", "comentar código", "ADR"

## Tipos de Documentação

### 1. JSDoc / TSDoc (Código)
```typescript
/**
 * Processa o pagamento de um pedido via gateway externo.
 * 
 * @param orderId - ID único do pedido
 * @param paymentData - Dados do pagamento (cartão/PIX/boleto)
 * @param options - Opções adicionais de processamento
 * @returns Promise com resultado do pagamento e transactionId
 * @throws {PaymentError} Se o gateway rejeitar o pagamento
 * @throws {OrderNotFoundError} Se o pedido não existir
 * 
 * @example
 * ```typescript
 * const result = await processPayment('order-123', {
 *   method: 'credit_card',
 *   amount: 99.90,
 *   currency: 'BRL'
 * })
 * console.log(result.transactionId) // 'txn_abc123'
 * ```
 */
async function processPayment(
  orderId: string,
  paymentData: PaymentDTO,
  options?: PaymentOptions
): Promise<PaymentResult>
```

### 2. README.md Template
```markdown
# 🚀 Nome do Projeto

> Descrição em uma linha do que o projeto faz.

## ✨ Features
- Feature 1
- Feature 2

## 🛠️ Tech Stack
- **Frontend:** React 18, TypeScript, TailwindCSS
- **Backend:** Node.js, Express
- **DB:** MySQL + Prisma
- **Infra:** Vercel, Hostinger

## 📦 Instalação

\`\`\`bash
git clone https://github.com/user/projeto
cd projeto
npm install
cp .env.example .env
npm run dev
\`\`\`

## 🔧 Variáveis de Ambiente

| Variável | Descrição | Obrigatório |
|----------|-----------|-------------|
| DATABASE_URL | URL do banco MySQL | ✅ |
| JWT_SECRET | Secret para tokens | ✅ |
| STRIPE_KEY | Chave API Stripe | ✅ |

## 📋 Scripts

| Comando | Descrição |
|---------|-----------|
| `npm run dev` | Desenvolvimento |
| `npm run build` | Build produção |
| `npm test` | Rodar testes |
| `npm run lint` | Verificar código |

## 📁 Estrutura do Projeto
\`\`\`
src/
├── components/    # Componentes React
├── pages/         # Páginas/rotas
├── hooks/         # Custom hooks
├── services/      # Lógica de negócio
├── types/         # TypeScript types
└── utils/         # Utilitários
\`\`\`

## 🤝 Contribuindo
1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-feature`
3. Commit: `git commit -m 'feat: adiciona nova feature'`
4. Push: `git push origin feature/nova-feature`
5. Abra um Pull Request

## 📄 Licença
MIT
```

### 3. ADR (Architecture Decision Record)
```markdown
# ADR-001: Título da Decisão

**Data:** YYYY-MM-DD  
**Status:** Accepted | Proposed | Deprecated  
**Deciders:** Nome dos envolvidos

## Contexto
Por que esta decisão foi necessária?

## Opções Consideradas
1. Opção A — Prós/Contras
2. Opção B — Prós/Contras
3. **Opção C (Escolhida)** — Prós/Contras

## Decisão
Escolhemos X porque Y.

## Consequências
- ✅ Positivas: ...
- ⚠️ Trade-offs: ...
```

### 4. API Documentation (OpenAPI/Swagger)
```yaml
# Para cada endpoint, documente:
GET /api/users/{id}:
  summary: Busca usuário por ID
  parameters:
    - name: id (string, required)
  responses:
    200: UserDTO
    404: Not Found
    401: Unauthorized
```

### Regras desta Skill
- Exemplos sempre com código real (não pseudocódigo)
- Parâmetros obrigatórios x opcionais claramente marcados
- Erros possíveis sempre documentados
- README deve permitir que novo dev rode o projeto em < 5 min
