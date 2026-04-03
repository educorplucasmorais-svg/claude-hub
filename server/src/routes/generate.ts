import { Router, Request, Response } from 'express'
import { execSync } from 'child_process'

const router = Router()

// ─── System prompt ────────────────────────────────────────
const SYSTEM_PROMPT = `Você é um expert em HTML/CSS/JS. Gere APENAS um documento HTML5 COMPLETO e funcional (sem explicações, sem markdown, sem texto extra — só o HTML).

Regras obrigatórias:
- Use Tailwind CSS via CDN: <script src="https://cdn.tailwindcss.com"></script>
- Use Alpine.js via CDN para interatividade: <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
- Configure Tailwind darkMode via script: tailwind.config = { darkMode: 'class' }
- NÃO use imagens externas — use gradientes CSS ou placeholders com background-color + texto
- Use ícones SVG inline ou emojis
- Mobile-first, responsivo
- Código limpo e semântico
- Inclua micro-interações com Alpine.js (hover, toggle, etc.)
- Paleta de cores coesa e moderna
- Tipografia com Google Fonts (Inter ou Geist via @import no <style>)
- O resultado deve parecer um site REAL e profissional
- Retorne APENAS o HTML, nada mais`

// ─── Get GitHub token (Copilot auth) ─────────────────────
function getGithubToken(): string {
  const envToken = process.env.GITHUB_TOKEN
  if (envToken) return envToken
  try {
    return execSync('gh auth token', { encoding: 'utf-8' }).trim()
  } catch {
    throw new Error('GitHub token not found. Run: gh auth login')
  }
}

// ─── GitHub Models API call (GPT-4o via Copilot) ─────────
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
    // Fallback to smaller model on quota/rate error
    if (res.status === 429 && model !== 'gpt-4o-mini') {
      console.warn(`[generate] ${model} rate limited, falling back to gpt-4o-mini`)
      return callGitHubModels(prompt, 'gpt-4o-mini')
    }
    throw new Error(data.error?.message || `GitHub Models HTTP ${res.status}`)
  }

  const text = data.choices?.[0]?.message?.content || ''
  // Strip markdown code block if present
  const match = text.match(/```html\n?([\s\S]*?)```/)
  return match ? match[1].trim() : text.trim()
}

// ─── POST /api/generate ───────────────────────────────────
router.post('/', async (req: Request, res: Response) => {
  const { prompt, siteType, colorScheme, model } = req.body as {
    prompt?: string
    siteType?: string
    colorScheme?: string
    model?: string
  }

  if (!prompt?.trim()) {
    return res.status(400).json({ error: 'prompt is required' })
  }

  const fullPrompt = [
    siteType    ? `Tipo de site: ${siteType}` : '',
    colorScheme ? `Esquema de cores: ${colorScheme}` : '',
    prompt,
  ].filter(Boolean).join('\n')

  try {
    const selectedModel = model || 'gpt-4o'
    console.log(`[generate] model=${selectedModel} type=${siteType} prompt="${prompt.slice(0, 60)}..."`)
    const html = await callGitHubModels(fullPrompt, selectedModel)
    return res.json({ html, model: selectedModel, engine: 'github-models' })
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'Generation failed'
    console.error('[generate] error:', msg)
    return res.status(500).json({ error: msg })
  }
})

// ─── GET /api/generate/models — list available ────────────
router.get('/models', (_req: Request, res: Response) => {
  return res.json({
    models: [
      { id: 'gpt-4o',          label: 'GPT-4o (Recomendado)',  provider: 'GitHub Copilot' },
      { id: 'gpt-4o-mini',     label: 'GPT-4o Mini (Rápido)',  provider: 'GitHub Copilot' },
      { id: 'o1-mini',         label: 'o1-mini (Raciocínio)',  provider: 'GitHub Copilot' },
    ],
    engine: 'github-models',
    auth: 'GitHub Copilot token (nenhuma API key necessária)',
  })
})

export { router as generateRouter }


  const models = ['gemini-2.0-flash', 'gemini-2.0-flash-lite', 'gemini-1.5-flash']
  let lastError = ''

  for (const model of models) {
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`
        const body = {
          contents: [{
            role: 'user',
            parts: [{ text: `${SYSTEM_PROMPT}\n\n---\n\n${prompt}` }],
          }],
          generationConfig: {
            maxOutputTokens: 8192,
            temperature: 0.7,
          },
        }

        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body),
        })

        if (res.status === 429) {
          const wait = attempt * 10000
          console.log(`Rate limited on ${model}, waiting ${wait}ms...`)
          await new Promise(r => setTimeout(r, wait))
          continue
        }

        if (!res.ok) {
          const err = await res.json() as { error?: { message?: string } }
          lastError = err?.error?.message || `HTTP ${res.status}`
          break // try next model
        }

        const data = await res.json() as {
          candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>
        }
        const text = data.candidates?.[0]?.content?.parts?.[0]?.text || ''
        const match = text.match(/```html\n?([\s\S]*?)```/)
        return match ? match[1].trim() : text.trim()

      } catch (e) {
        lastError = e instanceof Error ? e.message : 'Unknown error'
      }
    }
  }

  throw new Error(`All models failed: ${lastError}`)
}

// ─── POST /api/generate ───────────────────────────────────
router.post('/', async (req: Request, res: Response) => {
  const { prompt, siteType, colorScheme } = req.body as {
    prompt?: string
    siteType?: string
    colorScheme?: string
  }

  if (!prompt?.trim()) {
    return res.status(400).json({ error: 'prompt is required' })
  }

  const fullPrompt = [
    siteType    ? `Tipo de site: ${siteType}` : '',
    colorScheme ? `Esquema de cores: ${colorScheme}` : '',
    prompt,
  ].filter(Boolean).join('\n')

  try {
    console.log(`[generate] type=${siteType} scheme=${colorScheme} prompt="${prompt.slice(0, 60)}..."`)
    const html = await callGemini(fullPrompt)
    return res.json({ html, model: 'gemini-2.0-flash' })
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'Generation failed'
    console.error('[generate] error:', msg)
    return res.status(500).json({ error: msg })
  }
})

export { router as generateRouter }
