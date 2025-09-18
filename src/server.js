import express from "express";

const app = express();
const PORT = process.env.PORT || 3000;

// Default route
app.get("/", (req, res) => {
  res.json({ message: "Hello from OpsFlow Backend!" });
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "OK", uptime: process.uptime() });
});

// Sample users endpoint
app.get("/users", (req, res) => {
  res.json([
    { id: 1, name: "Alice" },
    { id: 2, name: "Bob" }
  ]);
});

app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
});
