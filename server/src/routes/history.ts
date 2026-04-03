import { Router, Request, Response } from 'express'
import db from '../lib/db'
import { randomUUID } from 'crypto'

const router = Router()

router.get('/', (_req: Request, res: Response) => {
  const sites = db.prepare(`
    SELECT id, title, prompt, site_type as siteType, color_scheme as colorScheme,
           model, html_size as htmlSize, created_at as createdAt,
           deployed, deploy_url as deployUrl
    FROM generated_sites ORDER BY created_at DESC
  `).all()
  return res.json({ items: sites, total: (sites as unknown[]).length })
})

router.get('/:id', (req: Request, res: Response) => {
  const id = req.params['id'] as string
  const site = db.prepare('SELECT * FROM generated_sites WHERE id = ?').get(id)
  if (!site) return res.status(404).json({ error: 'Not found' })
  db.prepare('UPDATE generated_sites SET opened_at = datetime("now") WHERE id = ?').run(id)
  return res.json(site)
})

router.post('/', (req: Request, res: Response) => {
  const { prompt, siteType, colorScheme, model, html } = req.body as {
    prompt?: string; siteType?: string; colorScheme?: string; model?: string; html?: string
  }
  if (!html?.trim()) return res.status(400).json({ error: 'html is required' })
  const id = randomUUID()
  db.prepare(`
    INSERT INTO generated_sites (id, title, prompt, site_type, color_scheme, model, html, html_size)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
  `).run(
    id,
    (prompt || 'Site gerado').slice(0, 80),
    prompt || '',
    siteType || 'landing',
    colorScheme || 'dark',
    model || 'gpt-4o',
    html,
    Buffer.byteLength(html, 'utf-8'),
  )
  return res.status(201).json({ id, title: (prompt || 'Site gerado').slice(0, 80) })
})

router.delete('/:id', (req: Request, res: Response) => {
  const id = req.params['id'] as string
  const r = db.prepare('DELETE FROM generated_sites WHERE id = ?').run(id)
  if (r.changes === 0) return res.status(404).json({ error: 'Not found' })
  return res.json({ deleted: id })
})

export { router as historyRouter }
