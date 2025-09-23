import express from "express";
import path from "path";
import { fileURLToPath } from "url";

const app = express();
const PORT = process.env.PORT || 3000;

// Resolve __dirname in ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Default route
app.get("/", (req, res) => {
  res.json({ message: "Hello from OpsFlow Backend v2!" });
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

// Serve static UI under /ui
const uiDir = path.join(__dirname, "..", "public-ui");
app.use("/ui", express.static(uiDir));
app.get("/ui", (req, res) => {
  res.sendFile(path.join(uiDir, "index.html"));
});

app.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
  console.log(`🖥️  UI available at http://localhost:${PORT}/ui`);
});
