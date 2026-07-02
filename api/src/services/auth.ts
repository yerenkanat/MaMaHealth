import { randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';
import jwt from 'jsonwebtoken';

/** Хеширование пароля через scrypt (встроенный crypto, без внешних зависимостей). */
export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString('hex');
  const hash = scryptSync(password, salt, 64).toString('hex');
  return `${salt}:${hash}`;
}

/** Проверка пароля в постоянное время (timingSafeEqual). */
export function verifyPassword(password: string, stored: string): boolean {
  const [salt, hash] = stored.split(':');
  if (!salt || !hash) return false;
  const expected = Buffer.from(hash, 'hex');
  const actual = scryptSync(password, salt, 64);
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}

/** Выпуск JWT (совместим с payload, который читает verifyJwt: sub + role). */
export function signToken(userId: string, role: string): string {
  return jwt.sign({ sub: userId, role }, process.env.JWT_SECRET as string, {
    expiresIn: '7d',
  });
}
