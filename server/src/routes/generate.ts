import { Router, Request, Response } from 'express'
import { execSync } from 'child_process'
import db from '../lib/db'
import { randomUUID } from 'crypto'

const router = Router()

const SYSTEM_PROMPT = `Voce e um expert em HTML/CSS/JS. Gere APENAS um documento HTML5 COMPLETO e funcional (sem explicacoes, sem markdown, sem texto extra - so o HTML).

Regras obrigatorias:
- Use Tailwind CSS via CDN: <script src="https://cdn.tailwindcss.com"></script>
- Use Alpine.js via CDN: <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
- Configure Tailwind: tailwind.config = { darkMode: 'class' }
- NAO use imagens externas - use gradientes CSS ou placeholders
- Use icones SVG inline ou emojis
- Mobile-first, responsivo, codigo limpo e semantico
- Micro-interacoes com Alpine.js, paleta coesa, Google Fonts (Inter)
- Resultado deve parecer um site REAL e profissional
- Retorne APENAS o HTML, nada mais`

function getGithubToken(): string {
  const envToken = process.env.GITHUB_TOKEN
  if (envToken) return envToken
  try {
    return execSync('gh auth token', { encoding: 'utf-8' }).trim()
  } catch {
    throw new Error('GitHub token not found. Run: gh auth login')
  }
}

async function callGitHubModels(prompt: string, model = 'gpt-4o'): Promise<string> {
  const token = getGithubToken()

  const res = await fetch('https://models.inference.ai.azure.com/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({
      model,
      messages: [
        { role: 'system', content: SYSTEM_PROMPT },
        { role: 'user',   content: prompt },
      ],
      max_tokens: 8192,
      temperature: 0.7,
    }),
  })

  const data = await res.json() as {
    choices?: Array<{ message?: { content?: string } }>
    error?: { message?: string }
  }

  if (!res.ok) {
    if (res.status === 429 && model !== 'gpt-4o-mini') {
      console.warn(`[generate] ${model} rate limited, falling back to gpt-4o-mini`)
      return callGitHubModels(prompt, 'gpt-4o-mini')
    }
    throw new Error(data.error?.message || `GitHub Models HTTP ${res.status}`)
  }

  const text = data.choices?.[0]?.message?.content || ''
  const match = text.match(/```html\n?([\s\S]*?)```/)
  return match ? match[1].trim() : text.trim()
}

// POST /api/generate
router.post('/', async (req: Request, res: Response) => {
  const { prompt, siteType, colorScheme, model } = req.body as {
    prompt?: string; siteType?: string; colorScheme?: string; model?: string
  }

  if (!prompt?.trim()) return res.status(400).json({ error: 'prompt is required' })

  const fullPrompt = [
    siteType    ? `Tipo de site: ${siteType}` : '',
    colorScheme ? `Esquema de cores: ${colorScheme}` : '',
    prompt,
  ].filter(Boolean).join('\n')

  const selectedModel = model || 'gpt-4o'
  const start = Date.now()

  try {
    console.log(`[generate] model=${selectedModel} type=${siteType} prompt="${prompt.slice(0, 60)}..."`)
    const html = await callGitHubModels(fullPrompt, selectedModel)
    const duration = Date.now() - start

    // Log to DB (fire and forget)
    try {
      db.prepare('INSERT INTO prompt_logs (id, feature, model, prompt, response, duration) VALUES (?, ?, ?, ?, ?, ?)')
        .run(randomUUID(), 'site-builder', selectedModel, fullPrompt, `[HTML ${html.length} chars]`, duration)
    } catch { /* ignore */ }

    return res.json({ html, model: selectedModel, engine: 'github-models', duration })
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'Generation failed'
    console.error('[generate] error:', msg)
    return res.status(500).json({ error: msg })
  }
})

// GET /api/generate/models
router.get('/models', (_req: Request, res: Response) => {
  return res.json({
    models: [
      { id: 'gpt-4o',      label: 'GPT-4o (Recomendado)',  provider: 'GitHub Copilot' },
      { id: 'gpt-4o-mini', label: 'GPT-4o Mini (Rapido)',  provider: 'GitHub Copilot' },
      { id: 'o1-mini',     label: 'o1-mini (Raciocinio)',   provider: 'GitHub Copilot' },
    ],
    engine: 'github-models',
    auth: 'GitHub Copilot token (sem API key)',
  })
})

export { router as generateRouter }

