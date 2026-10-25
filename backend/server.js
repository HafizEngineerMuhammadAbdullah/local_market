// server.js - the ENTRY POINT. Running `node server.js` starts here.

// 1) Load the values from the ".env" file into process.env.
//    This import must stay FIRST, so the variables exist before the
//    other files (which read process.env) are loaded.
import 'dotenv/config';

import app from './src/app.js';        // the Express app (routes + middleware)
import pool from './src/config/db.js'; // the MySQL connection pool

const PORT = process.env.PORT || 5000;

async function start() {
  try {
    // 2) Prove the database is reachable BEFORE accepting requests.
    const connection = await pool.getConnection();
    connection.release(); // hand the connection back to the pool
    console.log('MySQL connected');

    // 3) Start listening for HTTP requests.
    app.listen(PORT, () => {
      console.log(`API running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Could not connect to MySQL:', error.message);
    process.exit(1); // stop the program: there is no point running without a DB
  }
}

start();
