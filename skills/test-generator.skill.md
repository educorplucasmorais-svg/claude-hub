---
name: test-generator
description: Geração de testes unitários, integração e E2E com Jest, Vitest e Testing Library
version: 1.0.0
tags: [test, jest, vitest, testing-library, tdd, coverage]
---

# 🧪 Skill: Gerador de Testes

## Ativação
Use quando: "criar testes", "testar", "TDD", "cobertura", "Jest", "Vitest", "spec"

## Filosofia de Testes

```
Unitário  → Testa uma função isolada (mock de dependências)
Integração → Testa módulos interagindo (DB real ou em memória)
E2E        → Testa fluxo completo do usuário (Playwright/Cypress)

Regra 70/20/10: 70% unit, 20% integration, 10% E2E
```

## Templates por Tipo

### 1. Teste Unitário (Jest/Vitest)
```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { UserService } from './user.service'
import { UserRepository } from './user.repository'

// Mock da dependência
vi.mock('./user.repository')

describe('UserService', () => {
  let userService: UserService
  let mockUserRepo: vi.Mocked<UserRepository>

  beforeEach(() => {
    mockUserRepo = new UserRepository() as vi.Mocked<UserRepository>
    userService = new UserService(mockUserRepo)
    vi.clearAllMocks()
  })

  describe('findById', () => {
    it('should return user when found', async () => {
      // Arrange
      const mockUser = { id: '1', name: 'João', email: 'joao@test.com' }
      mockUserRepo.findById.mockResolvedValue(mockUser)

      // Act
      const result = await userService.findById('1')

      // Assert
      expect(result).toEqual(mockUser)
      expect(mockUserRepo.findById).toHaveBeenCalledWith('1')
      expect(mockUserRepo.findById).toHaveBeenCalledTimes(1)
    })

    it('should throw UserNotFoundError when user does not exist', async () => {
      // Arrange
      mockUserRepo.findById.mockResolvedValue(null)

      // Act & Assert
      await expect(userService.findById('999'))
        .rejects
        .toThrow('User not found')
    })
  })
})
```

### 2. Teste de Componente React (Testing Library)
```typescript
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { LoginForm } from './LoginForm'

describe('LoginForm', () => {
  const mockOnSubmit = vi.fn()

  beforeEach(() => {
    mockOnSubmit.mockClear()
  })

  it('should render email and password fields', () => {
    render(<LoginForm onSubmit={mockOnSubmit} />)
    
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/senha/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /entrar/i })).toBeInTheDocument()
  })

  it('should call onSubmit with credentials when form is valid', async () => {
    const user = userEvent.setup()
    render(<LoginForm onSubmit={mockOnSubmit} />)

    await user.type(screen.getByLabelText(/email/i), 'user@test.com')
    await user.type(screen.getByLabelText(/senha/i), 'senha123')
    await user.click(screen.getByRole('button', { name: /entrar/i }))

    await waitFor(() => {
      expect(mockOnSubmit).toHaveBeenCalledWith({
        email: 'user@test.com',
        password: 'senha123'
      })
    })
  })

  it('should show validation error for invalid email', async () => {
    const user = userEvent.setup()
    render(<LoginForm onSubmit={mockOnSubmit} />)

    await user.type(screen.getByLabelText(/email/i), 'email-invalido')
    await user.click(screen.getByRole('button', { name: /entrar/i }))

    expect(screen.getByText(/email inválido/i)).toBeInTheDocument()
    expect(mockOnSubmit).not.toHaveBeenCalled()
  })
})
```

### 3. Teste de API/Integration (Supertest)
```typescript
import request from 'supertest'
import { app } from '../app'
import { prisma } from '../lib/prisma'

describe('POST /api/auth/login', () => {
  beforeEach(async () => {
    await prisma.user.create({
      data: { email: 'test@test.com', password: await hash('senha123') }
    })
  })

  afterEach(async () => {
    await prisma.user.deleteMany()
  })

  it('should return JWT token on valid credentials', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@test.com', password: 'senha123' })

    expect(response.status).toBe(200)
    expect(response.body).toHaveProperty('token')
    expect(response.body.token).toMatch(/^eyJ/)
  })

  it('should return 401 on invalid credentials', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@test.com', password: 'errada' })

    expect(response.status).toBe(401)
    expect(response.body.message).toBe('Credenciais inválidas')
  })
})
```

### 4. Checklist de Cobertura
- [ ] Happy path (fluxo normal)
- [ ] Edge cases (limites, zeros, strings vazias)
- [ ] Error cases (exceções, falhas de rede)
- [ ] Boundary values (min/max, limites de array)
- [ ] Null/undefined inputs

### Convenção de Nomenclatura
```
describe('NomeDoMódulo') {
  describe('nomeDoMétodo') {
    it('should [ação esperada] when [condição]')
    // Exemplo:
    it('should return null when user is not found')
    it('should throw error when email is invalid')
    it('should send email when order is confirmed')
  }
}
```

### Regras desta Skill
- AAA Pattern: Arrange → Act → Assert (sempre)
- 1 assertion por conceito (não 10 expects num teste)
- Testes independentes: não dependem de ordem de execução
- Nomes de teste como documentação viva
- Coverage meta: > 80% para código crítico de negócio
