import express from 'express'
import cors from 'cors'
import dotenv from 'dotenv'
import { generateRouter } from './routes/generate'
import { historyRouter } from './routes/history'

dotenv.config()

const app = express()
const PORT = process.env.PORT || 3001

// ─── Middleware ───────────────────────────────────────────
app.use(cors({
  origin: [
    'http://localhost:3000',
    'http://localhost:5173',
    'https://site-seven-snowy-17.vercel.app',
    process.env.FRONTEND_URL || '',
  ].filter(Boolean),
  credentials: true,
}))

app.use(express.json({ limit: '2mb' }))

// ─── Routes ──────────────────────────────────────────────
app.use('/api/generate', generateRouter)
app.use('/api/history',  historyRouter)

// Health check
app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    gemini: !!process.env.GEMINI_API_KEY,
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  })
})

// ─── Start ───────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`Claude Hub API running on http://localhost:${PORT}`)
  console.log(`Gemini key: ${process.env.GEMINI_API_KEY ? 'OK' : 'NOT SET — set GEMINI_API_KEY in .env'}`)
})

export default app
