import React, { useEffect, useState } from "react";
import "./App.css";

function App() {
  const [health, setHealth] = useState(null);
  const [users, setUsers] = useState([]);

  useEffect(() => {
    fetch("/health").then((res) => res.json()).then((data) => setHealth(data));
    fetch("/users").then((res) => res.json()).then((data) => setUsers(data));
  }, []);

  return (
    <div className="dashboard-shell">
      <h1 className="dashboard-title">🚀 OpsFlow Dashboard</h1>

      <section className="section">
        <h2 className="section-title">API Health</h2>
        {health ? (
          <p className="health-text">
            Status: <strong>{health.status}</strong> | Uptime: {Math.floor(health.uptime)}s
          </p>
        ) : (
          <p className="muted-text">Loading health…</p>
        )}
      </section>

      <section className="section">
        <h2 className="section-title">Users</h2>
        {users.length > 0 ? (
          <ul className="users-list-simple">
            {users.map((u) => (
              <li className="users-list-item" key={u.id}>{u.name}</li>
            ))}
          </ul>
        ) : (
          <p className="muted-text">No users found</p>
        )}
      </section>
    </div>
  );
}

export default App;
