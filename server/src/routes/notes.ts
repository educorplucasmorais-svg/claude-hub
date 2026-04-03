import { Router, Request, Response } from 'express'
import db from '../lib/db'
import { randomUUID } from 'crypto'

const router = Router()

router.get('/', (req: Request, res: Response) => {
  const source = req.query['source'] as string | undefined
  const rows = db.prepare(`
    SELECT * FROM notes
    ${source ? 'WHERE source = ?' : ''}
    ORDER BY updated_at DESC
  `).all(...(source ? [source] : []))
  return res.json({ items: rows, total: (rows as unknown[]).length })
})

router.post('/', (req: Request, res: Response) => {
  const { title, content, tags, source } = req.body as {
    title?: string; content?: string; tags?: string[]; source?: string
  }
  if (!title || !content) return res.status(400).json({ error: 'title and content required' })
  const id = randomUUID()
  db.prepare(`
    INSERT INTO notes (id, title, content, tags, source)
    VALUES (?, ?, ?, ?, ?)
  `).run(id, title, content, JSON.stringify(tags || []), source || 'manual')
  return res.status(201).json({ id, title })
})

router.put('/:id', (req: Request, res: Response) => {
  const id = req.params['id'] as string
  const { title, content, tags } = req.body as { title?: string; content?: string; tags?: string[] }
  const fields: string[] = []
  const vals: unknown[] = []
  if (title)   { fields.push('title = ?');   vals.push(title) }
  if (content) { fields.push('content = ?'); vals.push(content) }
  if (tags)    { fields.push('tags = ?');    vals.push(JSON.stringify(tags)) }
  fields.push('updated_at = datetime("now")')
  if (fields.length === 1) return res.status(400).json({ error: 'Nothing to update' })
  const r = db.prepare(`UPDATE notes SET ${fields.join(', ')} WHERE id = ?`).run(...vals, id)
  if (r.changes === 0) return res.status(404).json({ error: 'Not found' })
  return res.json(db.prepare('SELECT * FROM notes WHERE id = ?').get(id))
})

router.delete('/:id', (req: Request, res: Response) => {
  const id = req.params['id'] as string
  const r = db.prepare('DELETE FROM notes WHERE id = ?').run(id)
  if (r.changes === 0) return res.status(404).json({ error: 'Not found' })
  return res.json({ deleted: id })
})

export { router as notesRouter }
