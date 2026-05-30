import type { Page, Route, Request } from "@playwright/test";
import {
  mkdtempSync,
  writeFileSync,
  rmSync,
  unlinkSync,
  existsSync,
} from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { createHash, createHmac } from "node:crypto";
import http from "node:http";
import type { AddressInfo } from "node:net";
import express from "express";
import {
  createLedgerChecker,
  readStaleBindingAckHistory,
} from "../../../../api-server/src/routes/ledger.js";

/**
 * Shared Playwright fixture for the stale-checkpoint-binding e2e spec
 * (task #232). The amber "stale checkpoint binding" banner gained an
 * Acknowledge button + acknowledged badge in task #204, mirroring the
 * red forged-sidecar banner. The forged flow has end-to-end coverage
 * (`helpers/forged-sidecar-fixture.ts`); this helper is its
 * stale-binding twin so a future dashboard refactor that drops the
 * `POST /ledger/sidecar-stale-binding-ack` UI surface is caught.
 *
 *   - `seedStaleTmpLedger(tmpDir)`   — write a healthy sealed prefix +
 *                                      matching checkpoint + HMAC secret,
 *                                      then seal a sidecar whose MAC
 *                                      verifies but whose `boundCheckpoint*`
 *                                      fields point at a checkpoint that
 *                                      is NOT on disk (→ the real router
 *                                      classifies it
 *                                      `stale_checkpoint_binding` on boot),
 *                                      then break the live ledger so the
 *                                      first `/integrity` verify returns
 *                                      `mismatch` instead of healing the
 *                                      sticky stale-binding flag.
 *   - `seedHealthyTmpLedger(tmpDir)` — a healthy sealed prefix + matching
 *                                      checkpoint + secret with NO sidecar,
 *                                      so the boot read is `missing` and
 *                                      `acknowledgeStaleBinding()` returns
 *                                      `no_incident` (→ the route answers
 *                                      409). Used to drive the genuine
 *                                      409 path end-to-end.
 *   - `bootStaleBindingFixture({paths, namedTokens})` — boot an express
 *                                      server around a real
 *                                      `createLedgerChecker`, mount the
 *                                      integrity router, the ack POST
 *                                      (bearer-token resolution via
 *                                      `namedTokens`, mirroring the
 *                                      production `LEDGER_REBUILD_TOKENS`
 *                                      parser shape), and the history GET
 *                                      (delegating to the real
 *                                      `readStaleBindingAckHistory` so the
 *                                      fixture does not re-implement the
 *                                      read logic).
 *   - `installStaleBindingForwarders(page, target)` — forward the three
 *                                      dashboard endpoints to the active
 *                                      fixture(s). `target` is either a
 *                                      single getter (all three → one
 *                                      fixture) or a per-endpoint getter
 *                                      map (so the 409 case can point
 *                                      `/integrity` at a stale fixture
 *                                      while the ack POST hits a healthy,
 *                                      no-incident fixture).
 *
 * The `namedTokens` map carries the (token → refereeName) shape from
 * the production `LEDGER_REBUILD_TOKENS=alice:...,bob:...` parser. A
 * `null` value means "valid token, but no attribution".
 */

export const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";
export const LEDGER_STALE_BINDING_ACK_URL =
  "**/api/ledger/sidecar-stale-binding-ack";
export const LEDGER_STALE_BINDING_ACK_HISTORY_URL =
  "**/api/ledger/sidecar-stale-binding-ack/history*";

/**
 * Known HMAC secret pre-seeded so the router does NOT auto-generate
 * one on boot, and so the sealed sidecar's MAC verifies against the
 * same key the router loads.
 */
const SECRET_HEX = "cd".repeat(32);
/** Bogus bound checkpoint that does not match the on-disk one. */
const STALE_BOUND_SHA = "0".repeat(64);
const STALE_BOUND_SIZE = 999;

export function sha256(buf: Buffer | string): string {
  return createHash("sha256").update(buf).digest("hex");
}

/**
 * Mirrors the canonicalize() + HMAC scheme in
 * `artifacts/api-server/src/routes/ledger.ts` so we can seed a sidecar
 * the REAL router accepts as HMAC-valid but binding-stale.
 */
function sealSidecar(
  secretHex: string,
  payload: {
    lastOkAt: string | null;
    lastCheckedAt: string | null;
    boundCheckpointSize: number | null;
    boundCheckpointSha: string | null;
  },
): string {
  const canonical = JSON.stringify({
    lastOkAt: payload.lastOkAt,
    lastCheckedAt: payload.lastCheckedAt,
    boundCheckpointSize: payload.boundCheckpointSize,
    boundCheckpointSha: payload.boundCheckpointSha,
  });
  const mac = createHmac("sha256", Buffer.from(secretHex, "hex"))
    .update(canonical)
    .digest("hex");
  return JSON.stringify({ ...payload, mac }) + "\n";
}

export type StaleBindingPaths = {
  hitsPath: string;
  checkpointPath: string;
  lastOkPath: string;
  secretPath: string;
};

export type FixtureServer = {
  baseUrl: string;
  close: () => Promise<void>;
};

export type BootStaleBindingFixtureOptions = {
  paths: StaleBindingPaths;
  /**
   * Bearer-token → referee-name map. A token with value `null` is
   * accepted but produces no attribution. Tokens not in the map are
   * rejected with 401.
   */
  namedTokens: Map<string, string | null>;
};

function ledgerPaths(tmpDir: string): StaleBindingPaths {
  return {
    hitsPath: path.join(tmpDir, "hits.txt"),
    checkpointPath: path.join(tmpDir, "hits.txt.checkpoint"),
    lastOkPath: path.join(tmpDir, "hits.txt.lastok"),
    secretPath: path.join(tmpDir, "hits.txt.lastok.key"),
  };
}

/**
 * Seed a tmp dir so the checker boots into a sticky
 * `stale_checkpoint_binding` incident: a valid-MAC sidecar bound to a
 * checkpoint that is NOT on disk, plus a broken live ledger so the
 * first `/integrity` verify returns `mismatch` (a successful `ok`
 * verify would re-seal the sidecar and clear the sticky flag).
 */
export function seedStaleTmpLedger(tmpDir: string): StaleBindingPaths {
  const paths = ledgerPaths(tmpDir);
  const sealed = "line1\nline2\nline3\n";
  const buf = Buffer.from(sealed, "utf-8");
  writeFileSync(paths.hitsPath, buf);
  writeFileSync(paths.checkpointPath, `${buf.length} ${sha256(buf)}\n`);
  writeFileSync(paths.secretPath, SECRET_HEX + "\n");

  const stalePast = new Date(Date.now() - 30_000).toISOString();
  writeFileSync(
    paths.lastOkPath,
    sealSidecar(SECRET_HEX, {
      lastOkAt: stalePast,
      lastCheckedAt: stalePast,
      boundCheckpointSize: STALE_BOUND_SIZE,
      boundCheckpointSha: STALE_BOUND_SHA,
    }),
  );

  // Break the live ledger so the first /integrity verify returns
  // `mismatch` and the sticky stale-binding flag survives long enough
  // to observe + acknowledge.
  writeFileSync(paths.hitsPath, "X");
  return paths;
}

/**
 * Seed a tmp dir with a healthy sealed prefix + matching checkpoint +
 * secret but NO sidecar, so the boot read is `missing` and there is no
 * stale-binding incident. `acknowledgeStaleBinding()` returns
 * `no_incident`, which the ack route maps to HTTP 409.
 */
export function seedHealthyTmpLedger(tmpDir: string): StaleBindingPaths {
  const paths = ledgerPaths(tmpDir);
  const sealed = "line1\nline2\nline3\n";
  const buf = Buffer.from(sealed, "utf-8");
  writeFileSync(paths.hitsPath, buf);
  writeFileSync(paths.checkpointPath, `${buf.length} ${sha256(buf)}\n`);
  writeFileSync(paths.secretPath, SECRET_HEX + "\n");
  return paths;
}

export async function bootStaleBindingFixture(
  opts: BootStaleBindingFixtureOptions,
): Promise<FixtureServer> {
  const { paths, namedTokens } = opts;
  const checker = createLedgerChecker({
    hitsPath: paths.hitsPath,
    checkpointPath: paths.checkpointPath,
    lastOkPath: paths.lastOkPath,
    secretPath: paths.secretPath,
  });

  const app = express();
  app.use(express.json());
  app.use("/api", checker.router);
  app.post("/api/ledger/sidecar-stale-binding-ack", (req, res) => {
    const auth = req.headers["authorization"] ?? "";
    const match = /^Bearer\s+(.+)$/i.exec(
      Array.isArray(auth) ? (auth[0] ?? "") : auth,
    );
    const provided = match ? match[1]?.trim() : "";
    if (!provided || !namedTokens.has(provided)) {
      res
        .status(401)
        .json({ ok: false, error: "Unauthorized: bad referee token." });
      return;
    }
    const refereeName = namedTokens.get(provided) ?? null;
    const result =
      refereeName === null
        ? checker.acknowledgeStaleBinding()
        : checker.acknowledgeStaleBinding(refereeName);
    if (!result.ok) {
      res.status(409).json({
        ok: false,
        error:
          "No stale-checkpoint-binding incident to acknowledge: the boot sidecar read came back ok / missing / forged.",
      });
      return;
    }
    res.json({
      ok: true,
      acknowledgedAt: result.acknowledgedAt,
      alreadyAcknowledged: result.alreadyAcknowledged,
      boundCheckpointSha: result.boundCheckpointSha,
      ackedBy: result.ackedBy,
    });
  });

  // Task #231's GET history endpoint is registered in production by
  // `routes/lean.ts` (mounted on /api), not by `checker.router`.
  // Delegate to the real `readStaleBindingAckHistory` so the fixture
  // does not re-implement the read/parse logic.
  const historyPath = `${paths.lastOkPath}.stale-binding-ack.log.jsonl`;
  app.get("/api/ledger/sidecar-stale-binding-ack/history", (req, res) => {
    const rawLimit = req.query["limit"];
    let limit = 20;
    if (typeof rawLimit === "string" && rawLimit.trim() !== "") {
      const parsed = Number(rawLimit);
      if (Number.isFinite(parsed) && parsed > 0) {
        limit = Math.floor(parsed);
      }
    }
    const { entries } = readStaleBindingAckHistory(historyPath, limit);
    res.json({ entries, capacity: 20, rotation: 0, rotations: [] });
  });

  const srv = http.createServer(app);
  await new Promise<void>((resolve) => srv.listen(0, "127.0.0.1", resolve));
  const port = (srv.address() as AddressInfo).port;

  return {
    baseUrl: `http://127.0.0.1:${port}`,
    close: async () => {
      await new Promise<void>((resolve, reject) =>
        srv.close((err) => (err ? reject(err) : resolve())),
      );
    },
  };
}

export type StaleBindingForwarderTargets = {
  integrity: () => FixtureServer;
  ack: () => FixtureServer;
  history: () => FixtureServer;
};

/**
 * Forward `/api/ledger/integrity`, `/api/ledger/sidecar-stale-binding-ack`,
 * and `/api/ledger/sidecar-stale-binding-ack/history` from the
 * dashboard to the active fixture(s). `target` is either a single
 * getter (all three → one fixture) or a per-endpoint getter map. Each
 * getter is read on every request so a mid-test fixture swap takes
 * effect on the next poll.
 */
export async function installStaleBindingForwarders(
  page: Page,
  target: (() => FixtureServer) | StaleBindingForwarderTargets,
): Promise<void> {
  const targets: StaleBindingForwarderTargets =
    typeof target === "function"
      ? { integrity: target, ack: target, history: target }
      : target;

  const forward = async (
    route: Route,
    request: Request,
    getActive: () => FixtureServer,
    suffix: string,
  ) => {
    const upstream = new URL(request.url());
    const forwarded = `${getActive().baseUrl}${suffix}${upstream.search}`;
    const postData = request.postData();
    const res = await fetch(forwarded, {
      method: request.method(),
      headers: request.headers(),
      body: postData ?? undefined,
    });
    const body = Buffer.from(await res.arrayBuffer());
    const headers: Record<string, string> = {};
    res.headers.forEach((v, k) => {
      const lk = k.toLowerCase();
      if (
        lk === "content-encoding" ||
        lk === "content-length" ||
        lk === "transfer-encoding"
      ) {
        return;
      }
      headers[k] = v;
    });
    await route.fulfill({ status: res.status, headers, body });
  };

  await page.route(LEDGER_INTEGRITY_URL, (route, request) =>
    forward(route, request, targets.integrity, "/api/ledger/integrity"),
  );
  await page.route(LEDGER_STALE_BINDING_ACK_URL, (route, request) =>
    forward(
      route,
      request,
      targets.ack,
      "/api/ledger/sidecar-stale-binding-ack",
    ),
  );
  await page.route(LEDGER_STALE_BINDING_ACK_HISTORY_URL, (route, request) =>
    forward(
      route,
      request,
      targets.history,
      "/api/ledger/sidecar-stale-binding-ack/history",
    ),
  );
}

/**
 * Convenience tmp-dir creator + cleanup pair so the spec doesn't
 * repeat the `mkdtempSync` / `rmSync(force)` boilerplate.
 */
export function createStaleBindingTmpDir(
  prefix: string,
  variant: "stale" | "healthy" = "stale",
): {
  tmpDir: string;
  paths: StaleBindingPaths;
} {
  const tmpDir = mkdtempSync(path.join(tmpdir(), prefix));
  const paths =
    variant === "stale"
      ? seedStaleTmpLedger(tmpDir)
      : seedHealthyTmpLedger(tmpDir);
  return { tmpDir, paths };
}

export function cleanupStaleBindingTmpDir(
  tmpDir: string,
  paths: StaleBindingPaths,
): void {
  for (const p of [
    paths.lastOkPath,
    paths.secretPath,
    `${paths.lastOkPath}.stale-binding-ack`,
    `${paths.lastOkPath}.stale-binding-ack.log.jsonl`,
    paths.hitsPath,
    paths.checkpointPath,
  ]) {
    try {
      if (existsSync(p)) unlinkSync(p);
    } catch {
      /* ignore */
    }
  }
  rmSync(tmpDir, { recursive: true, force: true });
}
