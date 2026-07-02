import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

// Расширяем Request проверенным контекстом аутентификации.
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      auth?: { userId: string; role: 'parent' | 'doctor' | 'admin' };
    }
  }
}

export function verifyJwt(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'unauthorized' });
  }
  try {
    const payload = jwt.verify(header.slice(7), process.env.JWT_SECRET!) as {
      sub: string;
      role: 'parent' | 'doctor' | 'admin';
    };
    req.auth = { userId: payload.sub, role: payload.role };
    next();
  } catch {
    return res.status(401).json({ error: 'invalid_token' });
  }
}
