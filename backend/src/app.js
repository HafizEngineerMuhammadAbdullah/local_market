// src/app.js - builds the Express app: middleware first, then routes.
import express from 'express';
import cors from 'cors';

import healthRoutes from './routes/health.routes.js';
import errorHandler from './middleware/errorHandler.js';

const app = express();

// --- Middleware (runs on every request, in this order) ---
app.use(cors({ origin: process.env.CLIENT_URL })); // allow the React app to call us
app.use(express.json());                           // turn JSON request bodies into req.body

// --- Routes ---
app.use('/api/health', healthRoutes);
// Later slices add lines like:  app.use('/api/auth', authRoutes);

// --- If no route matched above, answer 404 in JSON ---
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// --- Must be LAST: catches any error thrown by a route ---
app.use(errorHandler);

export default app;
