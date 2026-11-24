// One-off setup against the internal Nowen Note instance (see railway-start.sh).
// Exit 0 = done, non-zero = the service must not start.
import fs from "node:fs";

const base = `http://127.0.0.1:${process.env.BOOT_PORT || "3999"}`;
const bootMark = process.env.BOOT_MARK;
const aiMark = process.env.AI_MARK;
const adminUser = "admin";
const adminPassword = process.env.ADMIN_PASSWORD || "";
const log = (m) => console.log(`[railway] ${m}`);

async function api(path, { method = "GET", token, body } = {}) {
  const headers = { "content-type": "application/json" };
  if (token) headers.authorization = `Bearer ${token}`;
  const res = await fetch(base + path, { method, headers, body: body ? JSON.stringify(body) : undefined });
  let json = null;
  try { json = await res.json(); } catch { /* not JSON */ }
  return { status: res.status, json };
}

async function waitHealthy() {
  const deadline = Date.now() + 240_000;
  while (Date.now() < deadline) {
    try {
      const r = await fetch(`${base}/api/health`);
      if (r.ok) return;
    } catch { /* not up yet */ }
    await new Promise((r) => setTimeout(r, 1000));
  }
  throw new Error("setup instance did not become healthy within 240 s");
}

async function login(password) {
  const r = await api("/api/auth/login", { method: "POST", body: { username: adminUser, password } });
  return r.status === 200 && r.json?.token ? r.json.token : null;
}

async function bootstrapAdmin() {
  // Fresh database: upstream seeds admin / admin123. A half-finished earlier
  // run may already have changed it, so also try ADMIN_PASSWORD.
  let token = await login("admin123");
  if (token) {
    const r = await api("/api/auth/change-password", {
      method: "POST", token,
      body: { currentPassword: "admin123", newPassword: adminPassword },
    });
    if (r.status !== 200 || !r.json?.token) throw new Error(`password change failed (HTTP ${r.status})`);
    token = r.json.token;
    log("default admin password replaced with ADMIN_PASSWORD");
  } else {
    token = await login(adminPassword);
    if (!token) throw new Error("cannot sign in as admin with admin123 or ADMIN_PASSWORD");
    log("admin already uses ADMIN_PASSWORD");
  }
  const reg = await api("/api/auth/register/config", { method: "PUT", token, body: { allowRegistration: false } });
  if (reg.status !== 200 || reg.json?.allowRegistration !== false) throw new Error(`closing sign-up failed (HTTP ${reg.status})`);
  log("open sign-up closed (the admin can invite users or reopen it in Settings)");
  // Proof: the default password no longer works.
  if (await login("admin123")) throw new Error("admin123 still works after the change");
  fs.writeFileSync(bootMark, new Date().toISOString() + "\n", { mode: 0o600 });
  return token;
}

async function seedAI(token) {
  const key = process.env.AI_API_KEY || "";
  if (!key) return;
  if (!token) token = await login(adminPassword);
  if (!token) { log("AI_API_KEY set, but the admin password was changed in the app; set the AI key in Settings > AI instead"); fs.writeFileSync(aiMark, "skipped\n"); return; }
  const url = (process.env.AI_BASE_URL || "https://api.openai.com/v1").replace(/\/+$/, "");
  const model = process.env.AI_MODEL || "gpt-4o-mini";
  const provider = /^https:\/\/api\.openai\.com\//.test(url + "/") ? "openai" : "custom";
  const r = await api("/api/ai/settings", {
    method: "PUT", token,
    body: { ai_provider: provider, ai_api_url: url, ai_api_key: key, ai_model: model },
  });
  if (r.status !== 200) { log(`AI settings not saved (HTTP ${r.status}); set them in Settings > AI`); return; }
  fs.writeFileSync(aiMark, new Date().toISOString() + "\n", { mode: 0o600 });
  log(`AI assistant configured for the admin (${provider}, ${url}, model ${model})`);
}

try {
  await waitHealthy();
  let token = null;
  if (!fs.existsSync(bootMark)) token = await bootstrapAdmin();
  try { await seedAI(token); } catch (e) { log(`AI settings skipped: ${e.message}`); }
  process.exit(0);
} catch (e) {
  console.error(`[railway] setup failed: ${e.message}`);
  process.exit(1);
}
