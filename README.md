## Folder Structure
localmarket/
├── README.md
├── .gitignore                  # node_modules, .env
├── docs/                       # SRS, ERD/DFD, api-contract.md  <- the agreement between front and back
├── backend/
│   ├── package.json
│   ├── .env                    # DB password, JWT secret (never commit)
│   ├── .env.example
│   ├── server.js               # starts the server
│   ├── sql/
│   │   ├── schema.sql          # CREATE TABLE statements
│   │   ├── seed.sql            # categories, admin, sample ads
│   │   └── report-queries.sql  # your JOIN / aggregate / transaction for the report
│   └── src/
│       ├── app.js              # Express app: middleware + routes
│       ├── config/db.js        # MySQL connection pool
│       ├── routes/             # URL -> controller   (auth.routes.js, ads.routes.js ...)
│       ├── controllers/        # read request -> call model -> send response
│       ├── models/             # YOUR SQL lives only here
│       └── middleware/         # auth (JWT), role check, error handler
└── frontend/                   # Vite + React app, its own package.json
    └── src/
        ├── api/client.js       # the ONLY file that talks to the backend
        ├── pages/
        ├── components/
        └── context/            # logged-in user state



Yes, I can build the backend. Because you want to write the SQL yourself and you're short on time, the plan below splits the work so both happen, and it keeps frontend and backend from getting mixed up.

## Who writes what

| I write (so you move fast) | You write (your wish, and what your instructor grades) |
|---|---|
| Server setup, database connection, JWT login middleware, routes, controllers, error handling, `.env`, README | **Every SQL query**, each in its own function in one folder: `models/` |

For each query I'll give you a **spec**: the function name, its inputs, what rows it must return, which tables to use, and a hint. Every function starts as an empty stub, so the app runs from the first minute and you fill the stubs one at a time, testing each in Postman. If you get stuck on a query, ask and I'll give you a hint or the full answer. Since time is short, I'd rather you never stay stuck for long.

## Where to start: database, then backend, then frontend

1. **Database first.** Run the `schema.sql` from your SRS. Everything else depends on it.
2. **Backend in slices**, each tested in Postman before moving on.
3. **Frontend last, one slice behind the backend.** Never build a screen for an API that doesn't exist yet. Most "hotch potch" comes from a frontend written against guesses.

A **slice** is one feature built all the way through the backend:

| Slice | Feature | DBMS concept it shows |
|---|---|---|
| 0 | Project setup, DB connection | |
| 1 | Register / login | UNIQUE, password hashing |
| 2 | Post ad, search and filter ads | **JOIN** (your main query) |
| 3 | Promote ad | **Transaction** (COMMIT / ROLLBACK) |
| 4 | Report: ads per category, spend per business | **Aggregate / GROUP BY** |
| 5 | Favorites | M:N table |
| 6 | Admin approve / reject | UPDATE and status lifecycle |

Slices 1–4 are your "must have". They cover everything the course expects: a JOIN, an aggregate and a transaction. If time runs short, cut slices 5 and 6 first: seed the approved ads and one admin account by hand, and skip an admin screen.

## Folder structure

One folder, one Git repo, two completely separate apps inside it:

```
localmarket/
├── README.md
├── .gitignore                  # node_modules, .env
├── docs/                       # SRS, ERD/DFD, api-contract.md  <- the agreement between front and back
├── backend/
│   ├── package.json
│   ├── .env                    # DB password, JWT secret (never commit)
│   ├── .env.example
│   ├── server.js               # starts the server
│   ├── sql/
│   │   ├── schema.sql          # CREATE TABLE statements
│   │   ├── seed.sql            # categories, admin, sample ads
│   │   └── report-queries.sql  # your JOIN / aggregate / transaction for the report
│   └── src/
│       ├── app.js              # Express app: middleware + routes
│       ├── config/db.js        # MySQL connection pool
│       ├── routes/             # URL -> controller   (auth.routes.js, ads.routes.js ...)
│       ├── controllers/        # read request -> call model -> send response
│       ├── models/             # YOUR SQL lives only here
│       └── middleware/         # auth (JWT), role check, error handler
└── frontend/                   # Vite + React app, its own package.json
    └── src/
        ├── api/client.js       # the ONLY file that talks to the backend
        ├── pages/
        ├── components/
        └── context/            # logged-in user state
```

Think of a restaurant: **routes** are the menu, **controllers** are the waiter, and **models** are the kitchen where the SQL lives. The waiter never cooks, and the kitchen never talks to the customer. Whenever something breaks, you know which layer to look in.

## Rules that prevent the mess

1. **Frontend and backend never import each other.** They only talk over HTTP.
2. **I deliver the whole skeleton once, as a zip**, with the exact structure above. After that, every slice comes as files with exact paths ("add this file here, replace that one"), never as loose snippets.
3. **`docs/api-contract.md` comes first.** It lists every endpoint with its request and response shape, and I write the frontend against it.
4. **All frontend calls go through `api/client.js`**, so the backend address lives in one place.
5. **Images:** store image **URLs** at first and skip file uploads. It saves a day, and you can add uploads at the end if time allows.
6. **Git:** commit after every working slice, so you can always go back.

## Before we start

- Node.js 18 or newer is installed (`node -v` in a terminal).
- MySQL is running (XAMPP or MySQL Server), and you know the username and password.
- Postman or the Thunder Client extension in VS Code is installed.
- You've decided what to do with `PAYMENT.business_id`: keep it, or remove it for strict 3NF. It affects one query.

You don't need to study Express first. I'll comment every file I write and explain it as I hand it over. If you want a 20-minute warm-up, learn just these: what `req` and `res` are, what a route is, and what `async/await` does.

Tell me your MySQL setup (XAMPP or MySQL Server), how many days you have left, and which choice you made for `PAYMENT.business_id`, and I'll build Slice 0 right away: the skeleton zip, `schema.sql`, and `api-contract.md`.


Search for `health|api/health`

Read 
Completed with input: {
  "path": "C:\\Users\\A1\\Desktop\\Project Section\\DBMS_Project_Section\\local_market\\backend\\package.json"
}

Read 
Completed with input: {
  "path": "C:\\Users\\A1\\Desktop\\Project Section\\DBMS_Project_Section\\local_market\\backend\\src\\app.js"
}

Read 
Completed with input: {
  "path": "C:\\Users\\A1\\Desktop\\Project Section\\DBMS_Project_Section\\local_market\\backend\\src\\controllers\\health.controller.js"
}

Read 
Completed with input: {
  "path": "C:\\Users\\A1\\Desktop\\Project Section\\DBMS_Project_Section\\local_market\\backend\\src\\models\\health.model.js"
}

Read 
Completed with input: {
  "path": "C:\\Users\\A1\\Desktop\\Project Section\\DBMS_Project_Section\\local_market\\backend\\server.js"
}

You can verify it in Postman without changing any files.

1. Start the backend and keep its terminal running. It should log that MySQL connected and the API is running on port 5000.
2. In Postman, create a new **HTTP Request**.
3. Set the method to **GET** and enter:
   `http://localhost:5000/api/health`
4. Click **Send**.

The health route runs a database query (`SELECT 1 + 1`) and should return **200 OK** with a response like:

```json
{
  "status": "ok",
  "database": "connected",
  "result": 2
}
```

That confirms the API is responding and can query the database. If Postman reports a connection error, check that the backend is still running and listening on port 5000. If the response is an error or not `200 OK`, check the backend terminal for the related error.