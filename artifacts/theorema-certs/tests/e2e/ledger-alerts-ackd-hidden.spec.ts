import { test, expect, type Route } from "@playwright/test";

/**
 * Task #147: end-to-end coverage for the "N ack'd hidden" suffix added to
 * the Recent ledger alerts panel header counter
 * (`artifacts/theorema-certs/src/pages/dashboard.tsx` ~1546–1559).
 *
 * The suffix is the operator's only visual cue that acknowledged alerts
 * are waiting behind the "Show acknowledged" toggle. Unlike the
 * sink-wedged and stale-dismissals suffixes, it previously had no
 * Playwright coverage — a regression dropping or mislabeling it would
 * silently strand dismissed entries.
 *
 * Selectors / copy under test:
 *   - `[data-testid="panel-ledger-alerts"]`
 *   - `[data-testid="text-ledger-alerts-count"]` should:
 *       * include "N ack'd hidden" when "Show acknowledged" is OFF and
 *         at least one alert in the response has a non-null acknowledgedAt
 *       * NOT include "ack'd hidden" when the checkbox is toggled ON
 *   - `[data-testid="checkbox-show-acknowledged-alerts"]` (the toggle)
 *   - `[data-testid="row-ledger-alert-*"]` (hidden rows become visible
 *     once acknowledged alerts are shown)
 *
 * The `/api/lean/ledger-alerts*` endpoint is mocked via Playwright route
 * interception so the test is deterministic and does not depend on
 * driving real acknowledgements through the api-server.
 */

const LEDGER_ALERTS_URL = "**/api/lean/ledger-alerts*";

function makeAlert(id: string, acknowledgedAt: string | null) {
  return {
    id,
    acknowledgedAt,
    timestamp: new Date().toISOString(),
    workflow: "zeta-burst-101-10000",
    message:
      "Ledger checkpoint verification failed: live prefix sha mismatch",
    failureMode: "live_prefix_sha_mismatch",
    recovery: null,
    hitsPath: "data/hits.txt",
    checkpointPath: "data/hits.txt.checkpoint",
    expectedSize: 1024,
    actualSize: 1024,
    expectedSha:
      "0000000000000000000000000000000000000000000000000000000000000000",
    source: "kernel._verify_checkpoint",
    delivery: {
      webhook: { status: "ok", error: null, inflight: 0, cap: 8 },
      email: { status: "ok", error: null, inflight: 0, cap: 8 },
    },
  };
}

function buildAlertsResponse() {
  return {
    alerts: [
      makeAlert("unack-1", null),
      makeAlert("ack-1", "2026-05-27T00:00:00.000Z"),
      makeAlert("ack-2", "2026-05-27T00:01:00.000Z"),
    ],
    limit: 50,
    totalReturned: 3,
    logPath: "data/ledger-alerts.jsonl",
    logExists: true,
    ackGcDropped: 0,
    rotation: 0,
    availableRotations: [],
  };
}

async function installMock(page: import("@playwright/test").Page) {
  await page.route(LEDGER_ALERTS_URL, async (route: Route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(buildAlertsResponse()),
    });
  });
}

test.describe("dashboard: ledger alerts 'N ack'd hidden' suffix", () => {
  test("shows ack'd hidden suffix when toggle off, disappears once toggled on", async ({
    page,
  }) => {
    await installMock(page);
    await page.goto("/");

    const panel = page.locator('[data-testid="panel-ledger-alerts"]');
    await expect(panel).toBeVisible();

    const toggle = page.locator(
      '[data-testid="checkbox-show-acknowledged-alerts"]',
    );
    await expect(toggle).toBeVisible();
    await expect(toggle).not.toBeChecked();

    const counter = page.locator('[data-testid="text-ledger-alerts-count"]');
    await expect(counter).toBeVisible();
    // With the toggle off, only the 1 unacknowledged row is visible and the
    // 2 acknowledged ones are hidden — the suffix must say so.
    await expect(counter).toContainText("1 entry");
    await expect(counter).toContainText("2 ack'd hidden");

    // Only the unacknowledged row is rendered while hidden.
    await expect(
      page.locator('[data-testid^="row-ledger-alert-"]'),
    ).toHaveCount(1);

    // Toggling "Show acknowledged" on must drop the suffix and reveal the
    // hidden rows.
    await toggle.check();
    await expect(toggle).toBeChecked();
    await expect(counter).toContainText("3 entries");
    await expect(counter).not.toContainText("ack'd hidden");
    await expect(
      page.locator('[data-testid^="row-ledger-alert-"]'),
    ).toHaveCount(3);
  });
});
