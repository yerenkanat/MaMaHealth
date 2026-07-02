import { NextFunction, Request, Response } from 'express';

// Лёгкие метрики в формате Prometheus (без зависимостей).
let httpRequests = 0;
const byStatus: Record<number, number> = {};

export function metricsMiddleware(
  _req: Request,
  res: Response,
  next: NextFunction
) {
  res.on('finish', () => {
    httpRequests++;
    byStatus[res.statusCode] = (byStatus[res.statusCode] ?? 0) + 1;
  });
  next();
}

export function metricsHandler(_req: Request, res: Response) {
  const lines = [
    '# HELP mama_http_requests_total Total HTTP requests',
    '# TYPE mama_http_requests_total counter',
    `mama_http_requests_total ${httpRequests}`,
    '# HELP mama_http_responses_total HTTP responses by status',
    '# TYPE mama_http_responses_total counter',
    ...Object.entries(byStatus).map(
      ([s, n]) => `mama_http_responses_total{status="${s}"} ${n}`
    ),
    '# HELP mama_process_uptime_seconds Process uptime in seconds',
    '# TYPE mama_process_uptime_seconds gauge',
    `mama_process_uptime_seconds ${Math.round(process.uptime())}`,
  ];
  res.type('text/plain').send(lines.join('\n') + '\n');
}
