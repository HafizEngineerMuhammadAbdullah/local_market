// src/controllers/health.controller.js - CONTROLLER layer:
// reads the request, calls the model, sends the response. No SQL here.
import { pingDatabase } from '../models/health.model.js';

export async function checkHealth(req, res) {
  const result = await pingDatabase();
  res.json({ status: 'ok', database: 'connected', result });
}
