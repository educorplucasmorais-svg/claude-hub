import { Router, Request, Response } from 'express'
import db from '../lib/db'
import { randomUUID } from 'crypto'

const router = Router()

router.post('/', (req: Request, res: Response) => {
  const { feature, model, prompt, response, tokens, duration } = req.body as {
    feature?: string; model?: string; prompt?: string
    response?: string; tokens?: number; duration?: number
  }
  if (!prompt) return res.status(400).json({ error: 'prompt required' })
  const id = randomUUID()
  db.prepare(`
    INSERT INTO prompt_logs (id, feature, model, prompt, response, tokens, duration)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `).run(id, feature || 'unknown', model || 'gpt-4o', prompt, response || '', tokens ?? null, duration ?? null)
  return res.status(201).json({ id })
})

router.get('/', (req: Request, res: Response) => {
  const feature = req.query['feature'] as string | undefined
  const limit = Math.min(parseInt(req.query['limit'] as string || '50', 10), 200)
  const rows = db.prepare(`
    SELECT id, feature, model, prompt, tokens, duration, created_at as createdAt
    FROM prompt_logs
    ${feature ? 'WHERE feature = ?' : ''}
    ORDER BY created_at DESC LIMIT ?
  `).all(...(feature ? [feature, limit] : [limit]))
  return res.json({ items: rows, total: (rows as unknown[]).length })
})

router.get('/stats', (_req: Request, res: Response) => {
  const total     = (db.prepare('SELECT COUNT(*) as c FROM prompt_logs').get() as {c:number}).c
  const sites     = (db.prepare('SELECT COUNT(*) as c FROM generated_sites').get() as {c:number}).c
  const notes     = (db.prepare('SELECT COUNT(*) as c FROM notes').get() as {c:number}).c
  const byFeature = db.prepare('SELECT feature, COUNT(*) as count FROM prompt_logs GROUP BY feature').all()
  return res.json({ prompts: total, sites, notes, byFeature, dbPath: 'data/hub.db' })
})

export { router as logsRouter }
