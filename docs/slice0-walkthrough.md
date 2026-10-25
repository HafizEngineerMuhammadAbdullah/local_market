# Slice 0 Walkthrough - understanding every file

You said you will not trust code you cannot explain. Good. This document explains
**every file and every statement** in Slice 0. Read it with the file open beside it.
If any line here is still unclear after reading, ask me about that exact line.

---

## 1. The journey of one request

When something calls `GET http://localhost:5000/api/health`, this is what happens:

```
Browser / Thunder Client
        |   HTTP request
        v
   server.js  ........ started the server and keeps listening on port 5000
        |
        v
   src/app.js  ....... middleware runs first (cors, express.json), then Express
        |               looks for a matching route
        v
   routes/health.routes.js ........ "GET /  ->  checkHealth"      (the MENU)
        |
        v
   controllers/health.controller.js  reads request, calls the model (the WAITER)
        |
        v
   models/health.model.js ......... runs the SQL                  (the KITCHEN)
        |
        v
   config/db.js (pool)  ->  MySQL
        |
        v   result travels back up the same path
   res.json({...})  ->  response reaches the browser
```

Every later feature (register, search ads, promote ad) follows this same path.
Only the names change.

---

## 2. Ideas you need first

| Term | Plain meaning |
|---|---|
| **Node.js** | Lets JavaScript run outside the browser, on your computer or a server. |
| **Express** | A library on top of Node that makes it easy to receive HTTP requests and send responses. |
| **npm / package.json** | npm downloads libraries. `package.json` lists which libraries the project needs and defines commands like `npm run dev`. |
| **Route** | A rule: "when a request arrives for this method and this URL, run this function". |
| **Request / response (`req`, `res`)** | `req` describes what the client sent. `res` is how you answer. |
| **Middleware** | A function that runs on every request before your route, and can change `req`/`res` or stop the request. |
| **JSON** | Text format for data (`{"status":"ok"}`). Frontend and backend exchange JSON. |
| **Environment variable** | A setting (like a password) kept outside the code, in the `.env` file. |
| **Connection pool** | A small set of already-open database connections that requests share, instead of opening a new one every time. |
| **async / await** | Database calls take time. `await` pauses *that function* until the result is ready, without freezing the whole server. |
| **CORS** | A browser safety rule: JavaScript from one address (`localhost:5173`) may not read answers from another (`localhost:5000`) unless the server says it is allowed. |
| **HTTP status code** | A number in every response: 200 OK, 201 created, 400 bad input, 401 not logged in, 404 not found, 500 server error. |

---

## 3. File by file

### 3.1 `backend/package.json`

```json
{
  "name": "localmarket-backend",
  "version": "1.0.0",
  "description": "REST API for LocalMarket (Express + MySQL)",
  "type": "module",
  "main": "server.js",
  "scripts": {
    "dev": "node --watch server.js",
    "start": "node server.js"
  },
  "dependencies": { "cors": "...", "dotenv": "...", "express": "...", "mysql2": "..." }
}
```

| Line | Meaning |
|---|---|
| `name`, `version`, `description` | Labels only. They do not change behaviour. |
| `"type": "module"` | **Important.** Lets us write `import ... from ...` and `export` in `.js` files (the same syntax you use in React). Without it, Node expects the older `require()` style and `import` would fail with "Cannot use import statement outside a module". |
| `"main": "server.js"` | Names the entry file. |
| `"dev": "node --watch server.js"` | `npm run dev` starts the server **and restarts it automatically** whenever you save a file. `--watch` is built into Node, so we need no extra tool like nodemon. |
| `"start": "node server.js"` | `npm start` runs it once, without auto-restart. |
| `cors` | Adds the headers that allow your React app to call this API. |
| `dotenv` | Reads the `.env` file into `process.env`. |
| `express` | The web framework. We use **version 5**. |
| `mysql2` | The MySQL driver: lets Node send SQL to MySQL and get rows back. |

The `^` you will see before version numbers (for example `^5.3.0`) means "this version or a newer compatible one".
When you run `npm install`, npm downloads all four libraries into a `node_modules/` folder and writes
`package-lock.json` (the exact versions installed). Never edit or commit `node_modules`; `npm install` recreates it.

### 3.2 `backend/.env.example` and `.env`

`.env.example` is a **template** that is safe to share. You copy it to `.env`, which holds your real secrets
and is excluded from Git by `.gitignore`.

| Variable | Meaning |
|---|---|
| `PORT=5000` | The port the API listens on. The address becomes `http://localhost:5000`. |
| `CLIENT_URL=http://localhost:5173` | Where the React app runs (Vite's default port). Used by CORS. |
| `DB_HOST=localhost` | The computer MySQL runs on (yours). |
| `DB_PORT=3306` | MySQL's default port. |
| `DB_USER`, `DB_PASSWORD` | The same login you use in MySQL Workbench. With XAMPP the user is usually `root` and the password is empty. |
| `DB_NAME=localmarket` | The database that `schema.sql` creates. |
| `JWT_SECRET`, `JWT_EXPIRES_IN` | Not used yet. Slice 1 uses them to sign login tokens. |

Why not write the password directly in the code? Code gets shared and committed; secrets must not.

### 3.3 `backend/server.js` - the entry point

```js
import 'dotenv/config';
```
Reads `.env` and puts every line into `process.env` (so `process.env.DB_USER` becomes your user name).
**It must be the first import.** Imports run in order, and `db.js` reads `process.env` the moment it loads.
Note: `dotenv` looks for `.env` in the folder where you ran the command, so always run `npm run dev` from inside `backend/`.

```js
import app from './src/app.js';
import pool from './src/config/db.js';
```
Loads the Express app and the connection pool from our own files. `default` exports (see the last line of each file)
are imported without braces and may be given any name.

```js
const PORT = process.env.PORT || 5000;
```
Use the `PORT` from `.env`, or 5000 if it is missing (`||` means "or").

```js
async function start() {
  try {
    const connection = await pool.getConnection();
    connection.release();
    console.log('MySQL connected');
```
`async` marks a function that may `await`. `pool.getConnection()` borrows one connection from the pool. If MySQL is
down or the password is wrong, this line **throws an error**, which jumps to `catch`. `release()` gives the connection
back (it does not close it). We only wanted to prove the database answers.

```js
    app.listen(PORT, () => {
      console.log(`API running on http://localhost:${PORT}`);
    });
```
Starts listening for HTTP requests on the port. The arrow function runs once the server is ready, and prints the
address. The backticks `` ` `` with `${PORT}` insert the variable into the text.

```js
  } catch (error) {
    console.error('Could not connect to MySQL:', error.message);
    process.exit(1);
  }
}
start();
```
If anything failed, print a clear message and stop the program. `exit(1)` means "ended with an error" (0 means success).
We deliberately refuse to start without a database, because every feature needs it. The last line calls the function.

### 3.4 `backend/src/config/db.js` - the connection pool

```js
import mysql from 'mysql2/promise';
```
`mysql2` has two styles. `/promise` is the one that works with `async/await`.

```js
const pool = mysql.createPool({ ... });
```
Creates the pool **once**. Every file that imports it shares the same pool.

| Option | Meaning |
|---|---|
| `host`, `port`, `user`, `password`, `database` | Taken from `.env`, so no secret is in the code. |
| `waitForConnections: true` | If all connections are busy, new queries wait in line instead of failing. |
| `connectionLimit: 10` | At most 10 connections open at the same time. Plenty for this project. |
| `decimalNumbers: true` | MySQL `DECIMAL` columns (like `price`) would otherwise arrive in JavaScript as **strings** (`"85000.00"`). This makes them real numbers (`85000`), as the API contract promises. |

```js
export default pool;
```
Makes the pool available to other files with `import pool from '../config/db.js'`.

### 3.5 `backend/src/app.js` - the Express app

```js
import express from 'express';
import cors from 'cors';
import healthRoutes from './routes/health.routes.js';
import errorHandler from './middleware/errorHandler.js';
```
Libraries and our own pieces. Note the `.js` ending: when using `import` in Node, file paths must include the extension.

```js
const app = express();
```
Creates the application object. Everything below configures it.

```js
app.use(cors({ origin: process.env.CLIENT_URL }));
```
`app.use` registers **middleware**. This one adds the header `Access-Control-Allow-Origin: http://localhost:5173`
to every answer, which tells the browser "that address may read my responses". Thunder Client and Postman are not
browsers and ignore CORS, but your React app needs it.

```js
app.use(express.json());
```
When a request carries a JSON body (a register form, say), this converts it into a JavaScript object at `req.body`.
We do not use `req.body` yet; Slice 1 does.

```js
app.use('/api/health', healthRoutes);
```
**Mounts** the health router at `/api/health`. The router's own path is `/`, so together they handle `GET /api/health`.
Every later feature adds one line like this (`/api/auth`, `/api/ads`, ...).

```js
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});
```
A function with no path matches **every** request that reached this point, meaning no earlier route handled it.
That is exactly what "unknown URL" means, so we answer `404` with JSON.

```js
app.use(errorHandler);
export default app;
```
Registers the error handler last and exports the app.

**Order matters.** Express goes through `app.use` / routes from top to bottom, and the first one that sends a response
ends the request. That is why middleware comes first, routes next, 404 after them, and the error handler at the very end.

### 3.6 `backend/src/middleware/errorHandler.js`

```js
export default function errorHandler(err, req, res, next) {
```
Express treats a function with **four** parameters as an error handler. Any error thrown in a route arrives here as `err`.
All four parameters must be written even though `next` is unused, or Express will not recognise it.

```js
  console.error(err);
```
Print the full error in your terminal, where you can read it. Clients never see this.

```js
  const status = err.status || 500;
  const message = status === 500 ? 'Internal server error' : err.message;
  res.status(status).json({ error: message });
}
```
Use the error's own status if it has one (later we will throw errors with 400, 403, ...), otherwise 500.
For 500 errors we send a **generic** message, because raw database error text can reveal table names and
help an attacker. Everything else sends its own message, which the contract says is `{ "error": "..." }`.

### 3.7 The health trio: route, controller, model

Three tiny files demonstrate the pattern you will repeat for every feature.

**`routes/health.routes.js`** (the menu)
```js
import { Router } from 'express';
import { checkHealth } from '../controllers/health.controller.js';
const router = Router();
router.get('/', checkHealth);
export default router;
```
`Router()` makes a mini-app that holds a group of routes. `router.get('/', checkHealth)` reads: "for a GET request to `/`,
run `checkHealth`". `{ checkHealth }` with braces is a **named** import (it must match the name exported).
This file never touches data.

**`controllers/health.controller.js`** (the waiter)
```js
import { pingDatabase } from '../models/health.model.js';

export async function checkHealth(req, res) {
  const result = await pingDatabase();
  res.json({ status: 'ok', database: 'connected', result });
}
```
It receives `req` and `res`, asks the model for data, and answers. `await` waits for the model. `res.json(...)` sends the object
as JSON with status 200. `{ ..., result }` is shorthand for `result: result`.
There is **no try/catch**: in Express 5, if an `async` function fails, Express automatically passes the error to
`errorHandler`. (In Express 4 you had to write `try/catch` and call `next(err)` yourself. If a tutorial shows that, it is
the older style.) I tested this: a broken SQL statement produced a clean `500` JSON answer and the server stayed alive.

**`models/health.model.js`** (the kitchen)
```js
import pool from '../config/db.js';

export async function pingDatabase() {
  const sql = 'SELECT 1 + 1 AS result';
  const [rows] = await pool.query(sql);
  return rows[0].result;
}
```
This is the only place with SQL, and **later it is where your handwritten queries go**.
`SELECT 1 + 1 AS result` asks MySQL to calculate 2 and name the column `result`. `pool.query(sql)` returns a pair:
`[rows, fields]`. `const [rows] = ...` is array destructuring that keeps only the first item. `rows` is an array of row
objects, here `[ { result: 2 } ]`, so `rows[0].result` is `2`.

**Why three files for something this small?** Each one has a single job. When a query is wrong, you open `models/`.
When the URL is wrong, you open `routes/`. When the response shape is wrong, you open `controllers/`.

### 3.8 `backend/sql/schema.sql`

| Statement | Meaning |
|---|---|
| `CREATE DATABASE IF NOT EXISTS localmarket CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;` | Creates the database only if missing. `utf8mb4` stores **any** character, including emojis. (MySQL's older `utf8` cannot store 4-byte characters such as emojis; Urdu text works in both.) The collation decides sorting and comparison rules. |
| `USE localmarket;` | Makes every following statement apply to this database. |
| `DROP TABLE IF EXISTS ...` (7 lines) | Deletes old tables so you can re-run the file. The order is **reverse** of creation: a table with a foreign key (`PAYMENT`) must go before the table it points to (`AD`). **It erases your data.** |
| `ENGINE=InnoDB` | The storage engine that supports foreign keys and transactions. It is the default in modern MySQL; writing it makes that explicit. |

The column rules, explained once and used in every table:

| Piece | Meaning |
|---|---|
| `INT AUTO_INCREMENT PRIMARY KEY` | An integer id that MySQL numbers 1, 2, 3... by itself; the primary key uniquely identifies each row. |
| `VARCHAR(100)` | Text up to 100 characters. |
| `NOT NULL` | The column must have a value. |
| `UNIQUE` | No two rows may share this value (used on `email`, category `name`, `slug`, and `BUSINESS.user_id`). The last one is what enforces **one business per user**. |
| `ENUM('a','b')` | Only the listed values are allowed (`role`, ad `status`, payment `status`). |
| `DEFAULT x` | The value used when you do not provide one (`role` defaults to `'user'`, ad `status` to `'pending'`). |
| `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | MySQL fills in the current date and time automatically. |
| `BOOLEAN` | True/false, stored as 0 or 1. |
| `DECIMAL(10,2)` | An exact number with 10 digits in total and 2 after the point (up to 99,999,999.99). Used for money because, unlike floating-point numbers, it never rounds strangely. |
| `TEXT` | Long text (ad description). |
| `FOREIGN KEY (x) REFERENCES T(y)` | `x` must match an existing `y` in table `T`. MySQL rejects an ad whose `business_id` does not exist. |
| `ON DELETE CASCADE` | When the parent row is deleted, its children are deleted automatically (delete a business, and its ads go). With no `ON DELETE` rule the default is to **block** deleting a parent that still has children (we use that for `CATEGORY` and for `PAYMENT`, to protect history). |
| `INDEX idx_city (city)` | A lookup structure that makes searches by `city` fast. |
| `UNIQUE KEY uq_user_ad (user_id, ad_id)` | The **pair** must be unique, so a user cannot favorite the same ad twice. |

Table order is from "no dependencies" to "depends on others": `USER`, `BUSINESS`, `CATEGORY`, `AD`, `AD_IMAGE`,
`FAVORITE`, `PAYMENT`. A table can only reference a table that already exists.

Note on the name `USER`: it is a keyword in SQL but is allowed as a table name in MySQL. If Workbench or MySQL ever
complains near `USER`, write it with backticks (`` `USER` ``).

### 3.9 `backend/sql/seed.sql`

`INSERT INTO CATEGORY (name, slug) VALUES (...), (...);` adds seven starting categories in one statement.
`slug` is the URL-friendly version of the name. Running it twice fails because of the `UNIQUE` constraints, which
shows the constraints working. Users and ads are not seeded yet because a user row needs a **hashed** password
created by the API (Slice 1).

---

## 4. Run it and verify it yourself

1. **Create the database.** In MySQL Workbench: `File > Open SQL Script...`, pick `backend/sql/schema.sql`,
   click the lightning-bolt button (runs the whole script). Then repeat with `seed.sql`.
   In the left **SCHEMAS** panel click the refresh arrows, expand `localmarket > Tables`: you should see 7 tables.
   Run `SELECT * FROM CATEGORY;` and confirm 7 rows.
2. **Install and configure.** In a terminal, **inside the `backend` folder**:
   ```
   npm install
   copy .env.example .env          (Mac/Linux: cp .env.example .env)
   ```
   Open `.env`, set `DB_USER` and `DB_PASSWORD` to your Workbench login.
3. **Start.** `npm run dev`. Expected output:
   ```
   MySQL connected
   API running on http://localhost:5000
   ```
4. **Test in the browser.** Open `http://localhost:5000/api/health`. Expected:
   `{"status":"ok","database":"connected","result":2}`.
   Open `http://localhost:5000/api/anything`. Expected: `{"error":"Route not found"}`.
5. **Test in Thunder Client** (practice now, you will need it from Slice 1): create a new request, method `GET`,
   URL `http://localhost:5000/api/health`, press Send. Read the **status code** (200) and the JSON.
6. **Break it on purpose** to understand what each piece does. Stop MySQL, then restart the server: you should see
   `Could not connect to MySQL: ...` and the program should exit. Put a wrong password in `.env`: same result.

## 5. Troubleshooting

| Message | Likely cause | Fix |
|---|---|---|
| `ECONNREFUSED ... 3306` | MySQL is not running, or wrong port | Start MySQL; check `DB_PORT` |
| `ER_ACCESS_DENIED_ERROR` | Wrong user or password | Fix `DB_USER` / `DB_PASSWORD` in `.env` |
| `ER_BAD_DB_ERROR: Unknown database` | `schema.sql` was not run | Run it in Workbench |
| `EADDRINUSE ... :5000` | Another program uses port 5000 (on a Mac, AirPlay does) | Change `PORT` in `.env` (the frontend will then call the new port) |
| `Cannot find package 'express'` | `npm install` not run, or wrong folder | `cd backend`, then `npm install` |
| `Cannot use import statement outside a module` | `"type": "module"` missing, or running from another folder | Check `package.json`; run from `backend/` |
| Variables are `undefined` | `.env` missing, or not in `backend/` | Copy `.env.example` to `backend/.env` |

## 6. What I tested, and what I could not

**Tested** (Node 22, and MariaDB 10.11 as the database): `schema.sql` and `seed.sql` run without errors;
`/api/health` returns the expected JSON; an unknown URL returns the JSON 404; a deliberately broken SQL statement
returned a clean 500 and the server stayed alive; a wrong password prints a clear message and exits with code 1;
`decimalNumbers` returns real numbers.

**Could not test:** your own machine. You have Node 24 and MySQL (not MariaDB). MariaDB is MySQL-compatible and
everything here is standard, so I expect no difference, but if anything fails, paste me the **exact** error text.

## 7. Check yourself (these are also viva-style questions)

1. Why must `import 'dotenv/config'` be the first line of `server.js`?
2. Which folder is the only place SQL may be written?
3. What would go wrong if `app.use(errorHandler)` were placed *before* the routes?
4. Why does the server refuse to start when MySQL is unreachable?
5. Which line produces the `{"error":"Route not found"}` answer?

<details><summary>Answers</summary>

1. Other files read `process.env` when they load, so the variables must already exist.
2. `backend/src/models/`.
3. Express hands errors only to error handlers registered *after* the code that failed, so route errors would never reach it.
4. Every feature needs the database; failing early with a clear message is better than half-working requests.
5. The `app.use((req, res) => { res.status(404)... })` block in `app.js`.

</details>
