import React, { useEffect, useState } from "react";

function App() {
  const [health, setHealth] = useState(null);
  const [users, setUsers] = useState([]);

  useEffect(() => {
    // Call backend health API
    fetch("http://<YOUR-EC2-PUBLIC-IP>:3000/health")
      .then((res) => res.json())
      .then((data) => setHealth(data));

    // Call backend users API
    fetch("http://<YOUR-EC2-PUBLIC-IP>:3000/users")
      .then((res) => res.json())
      .then((data) => setUsers(data));
  }, []);

  return (
    <div style={{ padding: "20px", fontFamily: "Arial" }}>
      <h1>🚀 OpsFlow Dashboard</h1>

      <h2>API Health</h2>
      {health ? (
        <p>Status: {health.status} | Uptime: {Math.floor(health.uptime)}s</p>
      ) : (
        <p>Loading health...</p>
      )}

      <h2>Users</h2>
      {users.length > 0 ? (
        <ul>
          {users.map((u) => (
            <li key={u.id}>{u.name}</li>
          ))}
        </ul>
      ) : (
        <p>No users found</p>
      )}
    </div>
  );
}

export default App;
