// src/config/db.js - creates ONE shared pool of MySQL connections.
import mysql from 'mysql2/promise'; // the "/promise" version lets us use async/await

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true, // if all connections are busy, queue the request
  connectionLimit: 10,      // at most 10 connections open at once
  decimalNumbers: true,     // return DECIMAL columns (price) as numbers, not strings
});

export default pool;
