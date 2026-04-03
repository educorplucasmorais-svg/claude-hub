import { Request, Response, NextFunction } from 'express'

/**
 * Single-user auth middleware.
 * Protects all /api routes except /api/health.
 * Token set via HUB_AUTH_TOKEN in .env
 */
export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  // Skip health check
  if (req.path === '/api/health') return next()

  const token = process.env.HUB_AUTH_TOKEN
  if (!token) {
    // No token configured = dev mode, allow all
    return next()
  }

  const authHeader = req.headers.authorization
  const provided = authHeader?.startsWith('Bearer ')
    ? authHeader.slice(7)
    : req.query['token'] as string | undefined

  if (!provided || provided !== token) {
    return res.status(401).json({
      error: 'Unauthorized',
      hint: 'Provide Authorization: Bearer <HUB_AUTH_TOKEN>',
    })
  }

  return next()
}
