const http = require("http");
const net = require("net");
const os = require("os");

const port = Number(process.env.PORT || 3006);
const postgresHost = process.env.POSTGRES_HOST || "postgres";
const postgresPort = Number(process.env.POSTGRES_PORT || 5432);
const redisHost = process.env.REDIS_HOST || "redis";
const redisPort = Number(process.env.REDIS_PORT || 6379);

function writeJson(res, statusCode, payload) {
  res.writeHead(statusCode, { "Content-Type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(payload));
}

function checkTcp(host, tcpPort, timeoutMs = 1200) {
  return new Promise((resolve) => {
    const socket = new net.Socket();
    let resolved = false;

    const finish = (ok, error = null) => {
      if (resolved) {
        return;
      }
      resolved = true;
      socket.destroy();
      resolve({ ok, error });
    };

    socket.setTimeout(timeoutMs);
    socket.once("connect", () => finish(true));
    socket.once("timeout", () => finish(false, "timeout"));
    socket.once("error", (err) => finish(false, err.code || err.message));
    socket.connect(tcpPort, host);
  });
}

async function readinessPayload() {
  const [postgresCheck, redisCheck] = await Promise.all([
    checkTcp(postgresHost, postgresPort),
    checkTcp(redisHost, redisPort),
  ]);

  const checks = {
    postgres: postgresCheck,
    redis: redisCheck,
  };

  const ok = Object.values(checks).every((check) => check.ok);

  return {
    ok,
    service: "node-demo",
    checks,
    timestamp: new Date().toISOString(),
  };
}

const server = http.createServer(async (req, res) => {
  const route = new URL(req.url, `http://${req.headers.host || "localhost"}`).pathname;

  if (route === "/health") {
    writeJson(res, 200, {
      service: "node-demo",
      status: "ok",
      uptimeSeconds: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
    });
    return;
  }

  if (route === "/ready") {
    const payload = await readinessPayload();
    writeJson(res, payload.ok ? 200 : 503, payload);
    return;
  }

  if (route === "/") {
    writeJson(res, 200, {
      service: "node-demo",
      message: "Node.js demo service behind Apache reverse proxy.",
      hostname: os.hostname(),
      timestamp: new Date().toISOString(),
    });
    return;
  }

  writeJson(res, 404, {
    service: "node-demo",
    error: "not_found",
    path: route,
  });
});

server.listen(port, "0.0.0.0", () => {
  console.log(`[node-demo] listening on ${port}`);
});
