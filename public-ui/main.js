(function () {
  const $ = (sel) => document.querySelector(sel);
  const $$ = (sel) => Array.from(document.querySelectorAll(sel));

  const statusBadge = $("#status-badge");
  const healthStatus = $("#health-status");
  const healthUptime = $("#health-uptime");
  const usersList = $("#users-list");
  const usersEmpty = $("#users-empty");
  const refreshBtn = $("#refresh-users");
  const year = $("#year");

  year.textContent = String(new Date().getFullYear());

  const setBadge = (kind, text) => {
    statusBadge.classList.remove("status-badge--ok", "status-badge--warn", "status-badge--err", "status-badge--loading");
    statusBadge.classList.add(kind);
    statusBadge.textContent = text;
  };

  async function fetchHealth() {
    try {
      const res = await fetch("/health", { headers: { "accept": "application/json" } });
      const data = await res.json();
      const ok = data && (data.status === "OK" || data.status === "Healthy" || data.ok === true);
      setBadge(ok ? "status-badge--ok" : "status-badge--warn", ok ? "OK" : (data?.status || "WARN"));
      healthStatus.textContent = data?.status ?? "Unknown";
      const up = Number(data?.uptime ?? 0);
      healthUptime.textContent = isFinite(up) ? formatUptime(up) : String(data?.uptime ?? "—");
      healthStatus.classList.remove("muted");
      healthUptime.classList.remove("muted");
    } catch (e) {
      setBadge("status-badge--err", "ERROR");
      healthStatus.textContent = "Unavailable";
      healthUptime.textContent = "—";
      console.error(e);
    }
  }

  function formatUptime(seconds) {
    const s = Math.floor(seconds % 60);
    const m = Math.floor((seconds / 60) % 60);
    const h = Math.floor(seconds / 3600);
    return `${h}h ${m}m ${s}s`;
  }

  async function fetchUsers() {
    try {
      const res = await fetch("/users", { headers: { "accept": "application/json" } });
      const data = await res.json();
      renderUsers(Array.isArray(data) ? data : []);
    } catch (e) {
      console.error(e);
      renderUsers([]);
    }
  }

  function renderUsers(users) {
    usersList.innerHTML = "";
    if (!users.length) {
      usersEmpty.classList.remove("hidden");
      return;
    }
    usersEmpty.classList.add("hidden");
    const frag = document.createDocumentFragment();
    users.forEach((u) => {
      const li = document.createElement("li");
      li.className = "user-item";
      const avatar = document.createElement("div");
      avatar.className = "user-avatar";
      const name = document.createElement("span");
      name.className = "user-name";
      name.textContent = u.name ?? `User #${u.id ?? "?"}`;
      li.appendChild(avatar);
      li.appendChild(name);
      frag.appendChild(li);
    });
    usersList.appendChild(frag);
  }

  refreshBtn.addEventListener("click", fetchUsers);

  // Initial load
  fetchHealth();
  fetchUsers();

  // Auto-refresh health every 10s
  setInterval(fetchHealth, 10000);
})();
