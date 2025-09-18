import express from "express";
import usersRoutes from "./routes/users.js";

const app = express();

// Middleware
app.use(express.json());

// Default route
app.get("/", (req, res) => {
  res.json({ message: "Hello from CI/CD Assignment API!" });
});

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "OK", uptime: process.uptime() });
});

// Users routes
app.use("/users", usersRoutes);

app.listen(3000, () => {
  console.log("Server is running on port 3000");
});
export default app;
