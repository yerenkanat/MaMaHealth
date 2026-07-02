import express from 'express';
import { patientsRouter } from './routes/patients.js';
import { birthRouter } from './routes/birth.js';
import { profilesRouter } from './routes/profiles.js';

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => res.json({ status: 'ok' }));
app.use('/profiles', profilesRouter);
app.use('/patients', patientsRouter);
app.use('/pregnancies', birthRouter);

const port = Number(process.env.API_PORT ?? 8080);
app.listen(port, () => console.log(`[api] listening on :${port}`));
