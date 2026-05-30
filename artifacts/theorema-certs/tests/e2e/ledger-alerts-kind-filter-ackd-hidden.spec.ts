import { test, expect, type Route } from "@playwright/test";

/**
 * Task #229: end-to-end coverage for the count header when the kind
 * filter (Task #178/#202) AND the "Show acknowledged" toggle
 * (Task #147) are both in play at once.
 *
 * The count header in `artifacts/theorema-certs/src/pages/dashboard.tsx`
 * composes its suffixes inside a single parenthesised, comma-joined
 * group (~lines 2068–2091):
 *   - "N hidden by filter" — rows dropped by the active kind filter
 *   - "N ack'd hidden"     — acknowledged rows hidden while the toggle
 *                            is off
 * Each suffix has its own spec (`ledger-alerts-kind-filter.spec.ts`,
 * `ledger-alerts-ackd-hidden.spec.ts`) but nothing pins the *combined*
 * form, where both fire together. That ordering / off-by-one in the
 * count summary is exactly where a silent operator-facing regression
 * could hide.
 *
 * Note on the two counts:
 *   - "hidden by filter" is computed AFTER ack-filtering, so it counts
 *     only the rows the kind filter drops from the currently-visible
 *     (ack-respecting) set.
 *   - "ack'd hidden" counts EVERY acknowledged alert in the response,
 *     regardless of kind, and only appears while the toggle is off.
 *
 * Selectors / copy under test:
 *   - `[data-testid="panel-ledger-alerts"]`
 *   - `[data-testid="btn-ledger-alerts-kind-{all,tamper}"]`
 *   - `[data-testid="checkbox-show-acknowledged-alerts"]`
 *   - `[data-testid="text-ledger-alerts-count"]`
 *   - `[data-testid^="row-ledger-alert-"]`
 *
 * The `/api/lean/ledger-alerts*` endpoint is mocked via Playwright
 * route interception so the test is deterministic.
 */

const LEDGER_ALERTS_URL = "**/api/lean/ledger-alerts*";

function deliveryOk() {
  return {
    webhook: { status: "ok", error: null, inflight: 0, cap: 8 },
    email: { status: "ok", error: null, inflight: 0, cap: 8 },
  };
}

type Kind = "tamper" | "monitor";

function makeAlert(
  id: string,
  kind: Kind,
  acknowledgedAt: string | null,
  timestamp: string,
) {
  const monitor = kind === "monitor";
  return {
    id,
    acknowledgedAt,
    timestamp,
    workflow: monitor ? "api-server" : "zeta-burst-101-10000",
    message: monitor
      ? "The auto-integrity check has stalled — push alerts on ledger tamper may not fire until the api-server is investigated"
      : "Ledger checkpoint verification failed: live prefix sha mismatch",
    subject: monitor
      ? "[MorningStar] Ledger MONITOR STALLED — push alerts may be silent: api-server"
      : "[MorningStar] Ledger integrity alert: zeta-burst-101-10000",
    failureMode: monitor ? "monitor_stalled" : "hits_rewritten_in_place",
    previousFailureMode: null,
    recovery: null,
    hitsPath: "data/hits.txt",
    checkpointPath: "data/hits.txt.checkpoint",
    expectedSize: monitor ? null : 1024,
    actualSize: monitor ? null : 1024,
    expectedSha: monitor ? null : "0".repeat(64),
    source: monitor ? "api-server.checkWatchdog" : "kernel._verify_checkpoint",
    delivery: deliveryOk(),
  };
}

function buildMixedAlertsResponse() {
  // 5-row mix (listed most-recent-first, matching render order):
  //   3 unacknowledged: 2 tamper + 1 monitor
  //   2 acknowledged:   1 tamper + 1 monitor
  return {
    alerts: [
      makeAlert("tamper-unack-a", "tamper", null, "2026-05-28T01:40:00.000Z"),
      makeAlert(
        "monitor-ack",
        "monitor",
        "2026-05-27T00:00:00.000Z",
        "2026-05-28T01:30:00.000Z",
      ),
      makeAlert(
        "monitor-unack",
        "monitor",
        null,
        "2026-05-28T01:20:00.000Z",
      ),
      makeAlert(
        "tamper-ack",
        "tamper",
        "2026-05-27T00:01:00.000Z",
        "2026-05-28T01:10:00.000Z",
      ),
      makeAlert("tamper-unack-b", "tamper", null, "2026-05-28T01:00:00.000Z"),
    ],
    limit: 50,
    totalReturned: 5,
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
      body: JSON.stringify(buildMixedAlertsResponse()),
    });
  });
}

test.describe("dashboard: kind filter + Show acknowledged combined (task #229)", () => {
  test("composes both 'hidden by filter' and 'ack'd hidden' suffixes, and the toggle updates rows + header", async ({
    page,
  }) => {
    await installMock(page);
    await page.goto("/");

    const panel = page.locator('[data-testid="panel-ledger-alerts"]');
    await expect(panel).toBeVisible();

    const allBtn = page.locator('[data-testid="btn-ledger-alerts-kind-all"]');
    const tamperBtn = page.locator(
      '[data-testid="btn-ledger-alerts-kind-tamper"]',
    );
    const toggle = page.locator(
      '[data-testid="checkbox-show-acknowledged-alerts"]',
    );
    const count = page.locator('[data-testid="text-ledger-alerts-count"]');
    const rows = page.locator('[data-testid^="row-ledger-alert-"]');

    // Baseline: default kind=all, toggle off. Only the 3 unacknowledged
    // rows show; both acknowledged rows are hidden → only the
    // "ack'd hidden" suffix appears (no kind filter active yet).
    await expect(allBtn).toHaveAttribute("data-active", "true");
    await expect(toggle).not.toBeChecked();
    await expect(rows).toHaveCount(3);
    await expect(count).toHaveText("3 entries (2 ack'd hidden)");

    // Apply the tamper kind filter while the toggle is still off. Now
    // BOTH suffixes must fire together, in order, inside one paren
    // group: the 1 unacknowledged monitor row is "hidden by filter",
    // and the 2 acknowledged rows (of any kind) are "ack'd hidden".
    await tamperBtn.click();
    await expect(tamperBtn).toHaveAttribute("data-active", "true");
    await expect(count).toHaveAttribute("data-kind-filter", "tamper");
    await expect(rows).toHaveCount(2);
    await expect(count).toHaveText(
      "2 entries (tamper only) (1 hidden by filter, 2 ack'd hidden)",
    );

    // Toggle "Show acknowledged" on with the tamper filter still
    // active. The acknowledged tamper row joins the visible set, so the
    // "ack'd hidden" suffix drops entirely and only "hidden by filter"
    // remains — now counting BOTH monitor rows (the acked one included).
    await toggle.check();
    await expect(toggle).toBeChecked();
    await expect(rows).toHaveCount(3);
    await expect(count).not.toContainText("ack'd hidden");
    await expect(count).toHaveText(
      "3 entries (tamper only) (2 hidden by filter)",
    );

    // Toggle back off — the combined form must return exactly.
    await toggle.uncheck();
    await expect(toggle).not.toBeChecked();
    await expect(rows).toHaveCount(2);
    await expect(count).toHaveText(
      "2 entries (tamper only) (1 hidden by filter, 2 ack'd hidden)",
    );
  });
});
