// src/middleware/errorHandler.js - one place that turns errors into JSON.
// Express recognises an error handler by its FOUR parameters.
export default function errorHandler(err, req, res, next) {
  console.error(err); // full details stay in the server terminal

  const status = err.status || 500;
  const message = status === 500 ? 'Internal server error' : err.message;

  res.status(status).json({ error: message });
}
