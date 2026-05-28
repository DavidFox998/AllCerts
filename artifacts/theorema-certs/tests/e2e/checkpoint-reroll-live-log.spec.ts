import { test, expect, type Route, type Request } from "@playwright/test";

/**
 * Task #160: end-to-end coverage for the streamed checkpoint
 * re-roll's live-log panel.
 *
 * Task #142 wired the dashboard "Re-roll checkpoint" button to
 * consume the SSE `line` / `result` events emitted by
 * `POST /api/ledger/checkpoint/reroll/stream`. The companion test
 * `checkpoint-reroll-history-panel.spec.ts` (Task #159) covers the
 * post-success history panel, but the live progress UI itself —
 * `panel-reroll-live-log`, `text-reroll-line-count`, and
 * `text-reroll-live-log` — has no e2e guard. A regression that
 * dropped the `line` events (or stopped wiring them into
 * `rerollLogLines`) would silently revert the UX to the frozen
 * spinner state Task #142 fixed.
 *
 * This spec serves a multi-chunk SSE response so the dashboard's
 * stream reader picks up `STEP:` lines incrementally, then asserts:
 *
 *   1. `panel-reroll-live-log` becomes visible after the click.
 *   2. `text-reroll-line-count` advances to "3 lines" once all
 *      three `line` frames are consumed.
 *   3. `text-reroll-live-log` contains each `STEP:` / `OK:` line.
 *   4. A `stderr` line is rendered with the `! ` prefix used by
 *      the live log to distinguish it from stdout.
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

test.describe("dashboard: checkpoint reroll live log panel (task #160)", () => {
  test("STEP / OK lines from the SSE stream flow into panel-reroll-live-log and text-reroll-line-count", async ({
    page,
  }) => {
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
      const result = {
        ok: true,
        exitCode: 0,
        stdout:
          "STEP: verifying existing checkpoint\nSTEP: writing new checkpoint\nOK: checkpoint re-rolled (before=100, after=200)\n",
        stderr: "PROGRESS: 50%\n",
        durationMs: 1234,
        error: null,
      };
      const sse =
        `event: line\ndata: ${JSON.stringify({
          stream: "stdout",
          line: "STEP: verifying existing checkpoint",
        })}\n\n` +
        `event: line\ndata: ${JSON.stringify({
          stream: "stderr",
          line: "PROGRESS: 50%",
        })}\n\n` +
        `event: line\ndata: ${JSON.stringify({
          stream: "stdout",
          line: "STEP: writing new checkpoint",
        })}\n\n` +
        `event: line\ndata: ${JSON.stringify({
          stream: "stdout",
          line: "OK: checkpoint re-rolled (before=100, after=200)",
        })}\n\n` +
        `event: result\ndata: ${JSON.stringify(result)}\n\n`;
      await route.fulfill({
        status: 200,
        headers: {
          "content-type": "text/event-stream",
          "cache-control": "no-cache",
        },
        body: sse,
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

    await page.goto("/");

    // Live log panel is hidden until the button is clicked (no
    // re-roll has emitted any lines yet).
    await expect(
      page.locator('[data-testid="panel-reroll-live-log"]'),
    ).toHaveCount(0);

    const rerollButton = page.locator(
      '[data-testid="button-reroll-checkpoint"]',
    );
    await expect(rerollButton).toBeVisible();
    await expect(rerollButton).toBeEnabled();
    await rerollButton.click();

    // Once the stream lands, the live-log panel is visible and the
    // counter reflects all four line frames.
    const livePanel = page.locator('[data-testid="panel-reroll-live-log"]');
    await expect(livePanel).toBeVisible();

    const lineCount = page.locator('[data-testid="text-reroll-line-count"]');
    await expect(lineCount).toHaveText(/4 lines/);

    const liveLog = page.locator('[data-testid="text-reroll-live-log"]');
    await expect(liveLog).toContainText("STEP: verifying existing checkpoint");
    await expect(liveLog).toContainText("STEP: writing new checkpoint");
    await expect(liveLog).toContainText(
      "OK: checkpoint re-rolled (before=100, after=200)",
    );
    // stderr lines are rendered with the "! " prefix so operators
    // can tell progress chatter from real output.
    await expect(liveLog).toContainText("! PROGRESS: 50%");
  });
});
