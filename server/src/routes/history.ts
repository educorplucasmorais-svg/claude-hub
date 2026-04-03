import { Router, Request, Response } from 'express'
import fs from 'fs'
import path from 'path'

const router = Router()
const HISTORY_FILE = path.join(__dirname, '../../data/history.json')

// ─── Helpers ─────────────────────────────────────────────
interface HistoryItem {
  id: string
  title: string
  prompt: string
  siteType: string
  html: string
  createdAt: string
  size: number
}

function readHistory(): HistoryItem[] {
  if (!fs.existsSync(HISTORY_FILE)) return []
  try {
    return JSON.parse(fs.readFileSync(HISTORY_FILE, 'utf-8'))
  } catch {
    return []
  }
}

function writeHistory(items: HistoryItem[]): void {
  fs.mkdirSync(path.dirname(HISTORY_FILE), { recursive: true })
  fs.writeFileSync(HISTORY_FILE, JSON.stringify(items, null, 2), 'utf-8')
}

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 6)
}

// ─── GET /api/history ─────────────────────────────────────
router.get('/', (_req: Request, res: Response) => {
  const history = readHistory()
  // Return without full HTML to keep response small
  const list = history.map(({ html: _html, ...rest }) => rest)
  return res.json({ items: list, total: list.length })
})

// ─── POST /api/history — save a generated site ────────────
router.post('/', (req: Request, res: Response) => {
  const { prompt, siteType, html } = req.body as {
    prompt?: string
    siteType?: string
    html?: string
  }

  if (!html?.trim()) {
    return res.status(400).json({ error: 'html is required' })
  }

  const history = readHistory()
  const item: HistoryItem = {
    id: generateId(),
    title: prompt?.slice(0, 60) || 'Site gerado',
    prompt: prompt || '',
    siteType: siteType || 'landing',
    html,
    createdAt: new Date().toISOString(),
    size: Buffer.byteLength(html, 'utf-8'),
  }

  history.unshift(item)

  // Keep last 50 sites
  const trimmed = history.slice(0, 50)
  writeHistory(trimmed)

  return res.status(201).json({ id: item.id, title: item.title })
})

// ─── GET /api/history/:id — full HTML ─────────────────────
router.get('/:id', (req: Request, res: Response) => {
  const history = readHistory()
  const item = history.find(h => h.id === req.params['id'])
  if (!item) return res.status(404).json({ error: 'Not found' })
  return res.json(item)
})

// ─── DELETE /api/history/:id ──────────────────────────────
router.delete('/:id', (req: Request, res: Response) => {
  const history = readHistory()
  const filtered = history.filter(h => h.id !== req.params['id'])
  if (filtered.length === history.length) {
    return res.status(404).json({ error: 'Not found' })
  }
  writeHistory(filtered)
  return res.json({ deleted: req.params['id'] })
})

// ─── DELETE /api/history — clear all ─────────────────────
router.delete('/', (_req: Request, res: Response) => {
  writeHistory([])
  return res.json({ cleared: true })
})

export { router as historyRouter }
