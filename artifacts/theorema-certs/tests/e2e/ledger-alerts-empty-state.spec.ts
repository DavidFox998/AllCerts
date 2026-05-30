import { test, expect, type Route } from "@playwright/test";

/**
 * Task #228: end-to-end coverage for the dedicated empty-state copy that
 * appears in the Recent ledger alerts panel when the All / Tamper / Monitor
 * kind filter (Task #178) hides *every* row.
 *
 * Task #202 already pins the kind filter when at least one row survives the
 * filter, but the "No {kind} alerts match the current filter." copy that the
 * panel shows when the active filter matches nothing was never exercised by a
 * test, so a regression could swap or drop that operator-facing wording with
 * nobody noticing.
 *
 * Selectors / copy under test
 * (`artifacts/theorema-certs/src/pages/dashboard.tsx`):
 *   - `[data-testid="text-ledger-alerts-empty"]` — the empty-state line; when a
 *     non-"all" filter hides every unacknowledged row it reads
 *     "No tamper alerts match the current filter." /
 *     "No monitor alerts match the current filter."
 *   - `[data-testid="text-ledger-alerts-count"]` — the count header, which
 *     still reflects the active filter (e.g. "0 entries (monitor only) ...")
 *   - `[data-testid="btn-ledger-alerts-kind-{tamper,monitor}"]` — the filter
 *     buttons
 *
 * Fixtures: two single-kind logs. The tamper-only fixture (2 tamper rows, no
 * monitor rows) drives the Monitor filter into its empty state; the
 * monitor-only fixture (a stalled + paired recovered row) drives the Tamper
 * filter into its empty state.
 */

const LEDGER_ALERTS_URL = "**/api/lean/ledger-alerts*";

function deliveryOk() {
  return {
    webhook: { status: "ok", error: null },
    email: { status: "ok", error: null },
  };
}

function tamperRow(
  id: string,
  failureMode: string,
  workflow: string,
  timestamp: string,
) {
  return {
    id,
    acknowledgedAt: null,
    timestamp,
    workflow,
    message: "Ledger checkpoint verification failed: sealed prefix mismatch",
    subject: `[MorningStar] Ledger integrity alert: ${workflow}`,
    failureMode,
    previousFailureMode: null,
    recovery: null,
    hitsPath: "data/hits.txt",
    checkpointPath: "data/hits.txt.checkpoint",
    expectedSize: 2048,
    actualSize: 1024,
    expectedSha: "1".repeat(64),
    source: "kernel._verify_checkpoint",
    delivery: deliveryOk(),
  };
}

function monitorRow(
  id: string,
  failureMode: string,
  previousFailureMode: string | null,
  message: string,
  subject: string,
  timestamp: string,
) {
  return {
    id,
    acknowledgedAt: null,
    timestamp,
    workflow: "api-server",
    message,
    subject,
    failureMode,
    previousFailureMode,
    recovery: null,
    hitsPath: "data/hits.txt",
    checkpointPath: "data/hits.txt.checkpoint",
    expectedSize: null,
    actualSize: null,
    expectedSha: null,
    source: "api-server.checkWatchdog",
    delivery: deliveryOk(),
  };
}

function envelope(alerts: unknown[]) {
  return {
    alerts,
    limit: 50,
    totalReturned: alerts.length,
    logPath: "data/ledger-alerts.jsonl",
    logExists: true,
    ackGcDropped: 0,
    rotation: 0,
    availableRotations: [],
  };
}

function buildTamperOnlyResponse() {
  return envelope([
    tamperRow(
      "tamper-row-a",
      "hits_rewritten_in_place",
      "zeta-burst-101-10000",
      "2026-05-28T01:30:00.000Z",
    ),
    tamperRow(
      "tamper-row-b",
      "hits_truncated",
      "psi-cascade-202-20000",
      "2026-05-28T01:00:00.000Z",
    ),
  ]);
}

function buildMonitorOnlyResponse() {
  return envelope([
    monitorRow(
      "monitor-recovered-row",
      "recovered",
      "monitor_stalled",
      "The auto-integrity check has resumed — push alerts on ledger tamper are firing again",
      "[MorningStar] Ledger monitor RECOVERED: api-server",
      "2026-05-28T01:20:00.000Z",
    ),
    monitorRow(
      "monitor-stalled-row",
      "monitor_stalled",
      null,
      "The auto-integrity check has stalled — push alerts on ledger tamper may not fire until the api-server is investigated",
      "[MorningStar] Ledger MONITOR STALLED — push alerts may be silent: api-server",
      "2026-05-28T01:10:00.000Z",
    ),
  ]);
}

async function installLedgerAlertsMock(
  page: import("@playwright/test").Page,
  body: unknown,
) {
  await page.route(LEDGER_ALERTS_URL, async (route: Route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(body),
    });
  });
}

test.describe("dashboard: ledger alerts kind-filter empty state (task #228)", () => {
  test("Monitor filter over a tamper-only log shows the monitor empty-state copy and a monitor-only count header", async ({
    page,
  }) => {
    await installLedgerAlertsMock(page, buildTamperOnlyResponse());

    await page.goto("/");

    const panel = page.locator('[data-testid="panel-ledger-alerts"]');
    await expect(panel).toBeVisible();

    const monitorBtn = page.locator(
      '[data-testid="btn-ledger-alerts-kind-monitor"]',
    );
    const count = page.locator('[data-testid="text-ledger-alerts-count"]');
    const rows = page.locator('[data-testid^="row-ledger-alert-"]');
    const empty = page.locator('[data-testid="text-ledger-alerts-empty"]');

    // Sanity: both tamper rows render under the default "all" filter.
    await expect(rows).toHaveCount(2);
    await expect(empty).toHaveCount(0);
    await expect(count).toHaveText("2 entries");

    // Selecting Monitor hides every (tamper) row → empty state.
    await monitorBtn.click();
    await expect(monitorBtn).toHaveAttribute("data-active", "true");
    await expect(rows).toHaveCount(0);
    await expect(empty).toBeVisible();
    await expect(empty).toHaveText(
      "No monitor alerts match the current filter.",
    );

    // The count header still reflects the active filter.
    await expect(count).toHaveAttribute("data-kind-filter", "monitor");
    await expect(count).toHaveText(
      "0 entries (monitor only) (2 hidden by filter)",
    );
  });

  test("Tamper filter over a monitor-only log shows the tamper empty-state copy and a tamper-only count header", async ({
    page,
  }) => {
    await installLedgerAlertsMock(page, buildMonitorOnlyResponse());

    await page.goto("/");

    const panel = page.locator('[data-testid="panel-ledger-alerts"]');
    await expect(panel).toBeVisible();

    const tamperBtn = page.locator(
      '[data-testid="btn-ledger-alerts-kind-tamper"]',
    );
    const count = page.locator('[data-testid="text-ledger-alerts-count"]');
    const rows = page.locator('[data-testid^="row-ledger-alert-"]');
    const empty = page.locator('[data-testid="text-ledger-alerts-empty"]');

    // Sanity: both monitor rows render under the default "all" filter.
    await expect(rows).toHaveCount(2);
    await expect(empty).toHaveCount(0);
    await expect(count).toHaveText("2 entries");

    // Selecting Tamper hides every (monitor) row → empty state.
    await tamperBtn.click();
    await expect(tamperBtn).toHaveAttribute("data-active", "true");
    await expect(rows).toHaveCount(0);
    await expect(empty).toBeVisible();
    await expect(empty).toHaveText(
      "No tamper alerts match the current filter.",
    );

    // The count header still reflects the active filter.
    await expect(count).toHaveAttribute("data-kind-filter", "tamper");
    await expect(count).toHaveText(
      "0 entries (tamper only) (2 hidden by filter)",
    );
  });
});
