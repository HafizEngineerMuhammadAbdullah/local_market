// src/routes/health.routes.js - ROUTE layer: only maps a URL to a controller.
import { Router } from 'express';
import { checkHealth } from '../controllers/health.controller.js';

const router = Router();

router.get('/', checkHealth); // GET /api/health

export default router;
