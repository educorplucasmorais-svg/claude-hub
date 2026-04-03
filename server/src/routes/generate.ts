import { Router, Request, Response } from 'express'

const router = Router()

// ─── Gemini system prompt ─────────────────────────────────
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

// ─── Gemini call ─────────────────────────────────────────
async function callGemini(prompt: string): Promise<string> {
  const apiKey = process.env.GEMINI_API_KEY
  if (!apiKey) throw new Error('GEMINI_API_KEY not configured on server')

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
