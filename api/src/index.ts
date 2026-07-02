import './env.js';
import { createServer } from 'node:http';
import express from 'express';
import { assistantRouter } from './routes/assistant.js';
import { authRouter } from './routes/auth.js';
import { geoRouter } from './routes/geo.js';
import { patientsRouter } from './routes/patients.js';
import { birthRouter } from './routes/birth.js';
import { profilesRouter } from './routes/profiles.js';
import { attachSignaling } from './signaling.js';
import { metricsHandler, metricsMiddleware } from './metrics.js';

const app = express();
app.use(express.json());
app.use(metricsMiddleware);

app.get('/health', (_req, res) => res.json({ status: 'ok' }));
app.get('/metrics', metricsHandler);
app.use('/auth', authRouter);
app.use('/assistant', assistantRouter);
app.use('/profiles', profilesRouter);
app.use('/patients', geoRouter); // /patients/me/geo (до :patientId)
app.use('/patients', patientsRouter);
app.use('/pregnancies', birthRouter);

const port = Number(process.env.API_PORT ?? 8080);
const server = createServer(app);
attachSignaling(server);
server.listen(port, () => console.log(`[api] listening on :${port}`));
