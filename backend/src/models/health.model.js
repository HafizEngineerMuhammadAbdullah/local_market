// src/models/health.model.js - MODEL layer: ALL SQL lives in this folder.
import pool from '../config/db.js';

export async function pingDatabase() {
  const sql = 'SELECT 1 + 1 AS result';
  const [rows] = await pool.query(sql); // rows = array of result rows
  return rows[0].result;                // -> 2
}
