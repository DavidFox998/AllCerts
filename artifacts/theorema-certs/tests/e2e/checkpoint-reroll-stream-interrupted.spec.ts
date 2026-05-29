import { test, expect, type Route, type Request } from "@playwright/test";
import http from "node:http";
import type { AddressInfo, Socket } from "node:net";

/**
 * Task #201: pin the live-log panel's behaviour against a *real broken
 * stream*.
 *
 * Task #160 (`checkpoint-reroll-live-log.spec.ts`) only ever serves a
 * complete, cleanly-closed SSE body that ends with a `result` frame, so
 * it can't catch the failure mode that actually matters in production:
 * if the SSE forwarder in `artifacts/api-server/src/routes/lean.ts`
 * swallows a mid-stream error (proxy drops the connection, the spawned
 * `reroll-checkpoint.py` is OOM-killed, the server crashes) the
 * connection is *forcibly terminated* mid-`PROGRESS:` with no `result`
 * frame. `reader.read()` then rejects instead of returning `done`.
 *
 * Before task #201, that rejection escaped `streamReroll()` entirely;
 * the button's onClick `finally` cleared the spinner and the live-log
 * panel froze on the last PROGRESS line with no error — the operator
 * never learned the re-roll had actually failed.
 *
 * Playwright's `route.fulfill` can only deliver a *complete* response
 * (the socket always closes cleanly), so it cannot reproduce a forcible
 * mid-stream termination. Instead we stand up a tiny real HTTP server
 * that writes a couple of SSE `line` frames and then destroys the
 * socket, and 307-redirect the dashboard's stream POST to it. The
 * browser follows the redirect, renders the progress lines, then sees
 * the connection drop — exactly the production failure mode.
 *
 * Asserts:
 *   1. `panel-reroll-live-log` becomes visible and shows the streamed
 *      PROGRESS line (so we know lines really were rendered first).
 *   2. After the socket is destroyed, `text-reroll-checkpoint-error`
 *      surfaces a visible "stream interrupted" state.
 *   3. The button leaves the "Re-rolling…" state (no frozen spinner).
 */

const INTEGRITY_URL = "**/api/ledger/integrity*";
const HISTORY_URL = "**/api/ledger/checkpoint/reroll/history*";
const STREAM_URL = "**/api/ledger/checkpoint/reroll/stream*";
const ALERTS_URL = "**/api/lean/ledger-alerts*";
const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";
const REBUILD_REFEREE_STORAGE_KEY = "lean-rebuild-referee-name";
const FIXTURE_TOKEN = "fixture-token";
const FIXTURE_REFEREE = "alice";

function integrityPayload(): Record<string, unknown> {
  return {
    ok: true,
    monitor: {
      running: true,
      intervalSeconds: 300,
      lastTickAt: new Date().toISOString(),
      lastTickAgeSeconds: 1,
      lastResult: "ok",
      lastErrorMessage: null,
      monitorStalled: false,
      stallAgeSeconds: 0,
      stallThresholdSeconds: 900,
    },
    sealedPrefix: { size: 100, sha: "a".repeat(64) },
    liveFile: { size: 200, sha: "b".repeat(64), prefixMatch: true },
    checkpointAge: { seconds: 99999999, stale: true },
    checkpointStale: true,
    checkpointStaleThresholdSeconds: 2592000,
    sidecar: {
      status: "ok",
      lastOkAt: new Date().toISOString(),
      lastCheckedAt: new Date().toISOString(),
      writableMode: null,
      acknowledgedAt: null,
      payloadSha: null,
    },
    sidecarSecretStrictMode: false,
  };
}

/**
 * Boot a real HTTP server that emits a couple of SSE `line` frames and
 * then holds the connection open until the test calls `cut()`, at which
 * point it forcibly destroys the socket mid-PROGRESS — never sending a
 * `result` frame nor the chunked terminator, so the browser's
 * `reader.read()` rejects with a network error.
 *
 * Driving the cut from the test (rather than a fixed server-side timer)
 * removes the race against a CI browser that may be slow to follow the
 * cross-origin 307 redirect and render the progress lines under
 * full-suite load: with a timer, if it fired before the browser read
 * the frames, the streamed PROGRESS line never rendered and the spec
 * flaked. CORS is wide open (and OPTIONS is handled) because the
 * dashboard reaches it via a cross-origin 307 redirect from the Vite
 * dev origin.
 */
function bootBrokenStreamServer(): Promise<{
  url: string;
  cut: () => void;
  close: () => Promise<void>;
}> {
  let activeSocket: Socket | null = null;
  const srv = http.createServer((req, res) => {
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Headers", "*");
    res.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
    if (req.method === "OPTIONS") {
      res.writeHead(204);
      res.end();
      return;
    }
    res.writeHead(200, {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache, no-transform",
      Connection: "keep-alive",
    });
    const send = (event: string, data: unknown) => {
      res.write(`event: ${event}\n`);
      res.write(`data: ${JSON.stringify(data)}\n\n`);
    };
    send("line", {
      stream: "stdout",
      line: "STEP: verifying existing checkpoint",
    });
    send("line", { stream: "stderr", line: "PROGRESS: 50%" });
    // Hold the socket open. The test calls `cut()` only after it has
    // confirmed the browser rendered the PROGRESS line, so the
    // mid-stream termination is deterministic rather than timer-raced.
    activeSocket = res.socket ?? null;
  });
  return new Promise((resolve) => {
    srv.listen(0, "127.0.0.1", () => {
      const port = (srv.address() as AddressInfo).port;
      resolve({
        url: `http://127.0.0.1:${port}/broken-stream`,
        cut: () => {
          activeSocket?.destroy();
        },
        close: () =>
          new Promise<void>((r) => {
            // Destroy any still-open stream socket too, so `srv.close()`
            // resolves even if the test bailed before calling `cut()`.
            activeSocket?.destroy();
            srv.close(() => r());
          }),
      });
    });
  });
}

test.describe("dashboard: checkpoint reroll live log against a broken stream (task #201)", () => {
  test("a stream forcibly terminated mid-PROGRESS surfaces an interrupted error instead of freezing", async ({
    page,
  }) => {
    const broken = await bootBrokenStreamServer();

    await page.route(INTEGRITY_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify(integrityPayload()),
      });
    });
    await page.route(ALERTS_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          alerts: [],
          fileExists: false,
          totalLines: 0,
          truncated: false,
          rotation: 0,
          availableRotations: [],
          ackGcDropped: 0,
        }),
      });
    });
    await page.route(HISTORY_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ capacity: 20, entries: [] }),
      });
    });

    // Redirect the dashboard's stream POST to the real broken-stream
    // server. 307 preserves the POST method; the browser follows it
    // cross-origin and reads the partial SSE body until the socket dies.
    await page.route(STREAM_URL, async (route: Route, request: Request) => {
      const auth = request.headers()["authorization"] ?? "";
      if (!/^Bearer\s+fixture-token$/i.test(auth)) {
        await route.fulfill({
          status: 401,
          headers: { "content-type": "application/json" },
          body: JSON.stringify({ error: "unauthorized" }),
        });
        return;
      }
      await route.fulfill({
        status: 307,
        headers: { location: broken.url },
        body: "",
      });
    });

    await page.addInitScript(
      ([tokenKey, token, refKey, referee]) => {
        window.localStorage.setItem(tokenKey as string, token as string);
        window.localStorage.setItem(refKey as string, referee as string);
      },
      [
        REBUILD_TOKEN_STORAGE_KEY,
        FIXTURE_TOKEN,
        REBUILD_REFEREE_STORAGE_KEY,
        FIXTURE_REFEREE,
      ],
    );

    try {
      await page.goto("/");

      const rerollButton = page.locator(
        '[data-testid="button-reroll-checkpoint"]',
      );
      await expect(rerollButton).toBeVisible();
      await expect(rerollButton).toBeEnabled();
      await rerollButton.click();

      // The progress lines really render before the break, so this is a
      // genuine mid-stream interruption, not a connection that never
      // produced output.
      const livePanel = page.locator('[data-testid="panel-reroll-live-log"]');
      await expect(livePanel).toBeVisible();
      const liveLog = page.locator('[data-testid="text-reroll-live-log"]');
      await expect(liveLog).toContainText("! PROGRESS: 50%");

      // Now that the progress line has really rendered, force the
      // mid-stream termination. Driving it from the test (rather than a
      // server-side timer) guarantees the frames were read first, so the
      // assertion below isn't racing a slow CI browser.
      broken.cut();

      // The interruption is surfaced as a visible error instead of the
      // panel freezing on the last PROGRESS line.
      const error = page.locator('[data-testid="text-reroll-checkpoint-error"]');
      await expect(error).toBeVisible();
      await expect(error).toContainText(/interrupted/i);

      // The button is no longer stuck in the "Re-rolling…" spinner state.
      await expect(rerollButton).not.toHaveText(/Re-rolling/);
      await expect(rerollButton).toBeEnabled();
    } finally {
      await broken.close();
    }
  });
});
