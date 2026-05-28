import { test, expect, type Route, type Request } from "@playwright/test";

/**
 * Task #159: end-to-end coverage for the persistent checkpoint
 * re-roll audit trail (Task #141).
 *
 * The dashboard renders `panel-checkpoint-reroll-history` whenever
 * `GET /api/ledger/checkpoint/reroll/history` returns at least one
 * entry, and a successful re-roll click invalidates the history
 * query so the next poll picks up the new row. Server-side write
 * + read coverage lives in `routes/lean.integration.test.ts`
 * (Task #141 / #159); this spec closes the dashboard-side gap by:
 *
 *   1. Mocking the integrity endpoint so `checkpointStale: true`
 *      surfaces the "Re-roll checkpoint" button.
 *   2. Mocking the reroll history endpoint with a counter that
 *      returns `[]` on the first call and `[entry]` after the
 *      simulated re-roll fires.
 *   3. Mocking the SSE stream endpoint with a synthetic
 *      `event: result` payload so the button click resolves with
 *      `ok: true` and invalidates the history query.
 *   4. Seeding the rebuild token in localStorage so the button
 *      renders (gated on `cpStale && rebuildToken`).
 *
 * Assertion shape: after the click, `panel-checkpoint-reroll-history`
 * appears with `row-checkpoint-reroll-history-0` carrying the
 * referee label "alice".
 */

const INTEGRITY_URL = "**/api/ledger/integrity*";
const HISTORY_URL = "**/api/ledger/checkpoint/reroll/history*";
const STREAM_URL = "**/api/ledger/checkpoint/reroll/stream*";
// The dashboard's alerts panel polls `/api/lean/ledger-alerts` (the
// real endpoint mounted under the lean router), not `/api/ledger/
// alerts*`. Mocking the right path keeps the spec from leaking
// requests to whatever the managed api-server holds in real state.
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

function entryPayload(): Record<string, unknown> {
  return {
    capacity: 20,
    entries: [
      {
        timestamp: new Date("2026-05-28T01:00:00Z").toISOString(),
        durationMs: 1234,
        exitCode: 0,
        ok: true,
        error: null,
        refereeName: FIXTURE_REFEREE,
        ip: "203.0.113.7",
      },
    ],
  };
}

test.describe("dashboard: checkpoint reroll history panel (task #159)", () => {
  test("triggering a re-roll surfaces panel-checkpoint-reroll-history with the expected referee row", async ({
    page,
  }) => {
    let historyCalls = 0;
    let rerollFired = false;

    await page.route(INTEGRITY_URL, async (route: Route) => {
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify(integrityPayload()),
      });
    });

    // Alerts panel polls on the same interval — short-circuit it so
    // the dashboard does not stall waiting for a real endpoint.
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
      historyCalls += 1;
      const payload = rerollFired
        ? entryPayload()
        : { capacity: 20, entries: [] };
      await route.fulfill({
        status: 200,
        headers: { "content-type": "application/json" },
        body: JSON.stringify(payload),
      });
    });

    // SSE stream — emit a single `result` event so the dashboard's
    // streamReroll() resolves with `ok: true` and invalidates the
    // history query (which then sees `rerollFired = true`).
    await page.route(STREAM_URL, async (route: Route, request: Request) => {
      rerollFired = true;
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
        stdout: "OK: checkpoint re-rolled (before=100, after=200)\n",
        stderr: "",
        durationMs: 1234,
        error: null,
      };
      const sse =
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

    // Pre-click: panel should not render (history is empty).
    await expect(
      page.locator('[data-testid="panel-checkpoint-reroll-history"]'),
    ).toHaveCount(0);

    const rerollButton = page.locator(
      '[data-testid="button-reroll-checkpoint"]',
    );
    await expect(rerollButton).toBeVisible();
    await expect(rerollButton).toBeEnabled();
    await rerollButton.click();

    // After the click resolves and the history query is invalidated,
    // the panel + row-0 must appear with the expected referee label.
    const panel = page.locator(
      '[data-testid="panel-checkpoint-reroll-history"]',
    );
    await expect(panel).toBeVisible();
    const row0 = page.locator('[data-testid="row-checkpoint-reroll-history-0"]');
    await expect(row0).toBeVisible();
    await expect(row0).toHaveAttribute("data-reroll-ok", "true");
    await expect(row0).toContainText(FIXTURE_REFEREE);
    await expect(row0).toContainText("ok");
    await expect(row0).toContainText("1234ms");
    await expect(row0).toContainText("203.0.113.7");

    // The per-referee summary row should also be present and
    // labelled with the same referee.
    await expect(
      page.locator(
        `[data-testid="row-checkpoint-reroll-history-summary-${FIXTURE_REFEREE}"]`,
      ),
    ).toBeVisible();

    // Sanity: the history endpoint was polled at least twice (initial
    // load + post-reroll invalidation).
    expect(historyCalls).toBeGreaterThanOrEqual(2);
  });
});
