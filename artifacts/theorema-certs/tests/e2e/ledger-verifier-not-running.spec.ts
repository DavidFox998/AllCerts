import { test, expect, type Route } from "@playwright/test";

/**
 * Task #116: end-to-end coverage for the "VERIFIER NOT RUNNING" amber
 * badge added in task #99.
 *
 * Task #99 added a server-computed `checkedStale` flag on
 * `GET /api/ledger/integrity`. When true, the dashboard's Ledger
 * Integrity card surfaces an amber `text-ledger-last-checked` block
 * with a `badge-ledger-checked-stale` reading
 * "VERIFIER NOT RUNNING — no recent attempt". The flag itself is
 * covered by `artifacts/api-server/src/routes/ledger.integration.test.ts`
 * (the "task #99" cases), but the dashboard rendering path was only
 * covered by manual inspection until this spec landed.
 *
 * Strategy: drive the dashboard through the global proxy
 * (`baseURL = localhost:80`) and mock `/api/ledger/integrity` via
 * Playwright route interception so we can flip `checkedStale` on
 * demand. The real server only flips the flag when the sidecar's
 * `lastCheckedAt` is older than `LEDGER_CHECKED_STALE_THRESHOLD_SECONDS`
 * (default 600s) and the sidecar is HMAC-protected, so it cannot be
 * hand-seeded from outside the api-server. Mocking keeps the test
 * deterministic without touching real ledger state.
 *
 * Selectors / copy under test (see
 * `artifacts/theorema-certs/src/pages/dashboard.tsx` ~line 1788-1851):
 *   - `[data-testid="text-ledger-last-checked"]` carries
 *     `data-checked-stale="true"|"false"`
 *   - `[data-testid="badge-ledger-checked-stale"]` only renders when
 *     `checkedStale === true`; copy is "VERIFIER NOT RUNNING — no
 *     recent attempt"
 *   - `[data-testid="text-ledger-checked-threshold"]` always renders
 *     when a threshold is present
 */

const LEDGER_INTEGRITY_URL = "**/api/ledger/integrity*";

type CheckedStaleOverrides = {
  checkedStale: boolean;
  lastCheckedAgeSeconds: number | null;
  checkedStaleThresholdSeconds: number;
};

function buildLedgerIntegrityBody(overrides: CheckedStaleOverrides) {
  const nowIso = new Date().toISOString();
  const lastCheckedAt =
    overrides.lastCheckedAgeSeconds == null
      ? null
      : new Date(
          Date.now() - overrides.lastCheckedAgeSeconds * 1000,
        ).toISOString();
  return {
    status: "ok",
    failureMode: null,
    reason: null,
    checkpointSize: 1024,
    checkpointSha:
      "0000000000000000000000000000000000000000000000000000000000000000",
    liveSize: 1024,
    livePrefixSha:
      "0000000000000000000000000000000000000000000000000000000000000000",
    growthBytes: 0,
    checkedAt: nowIso,
    ledgerLastModified: nowIso,
    ledgerPath: "data/hits.txt",
    checkpointPath: "data/hits.txt.checkpoint",
    lastOkAt: nowIso,
    lastOkAgeSeconds: 5,
    lastCheckedAt,
    lastCheckedAgeSeconds: overrides.lastCheckedAgeSeconds,
    staleThresholdSeconds: 1800,
    stale: false,
    checkedStaleThresholdSeconds: overrides.checkedStaleThresholdSeconds,
    checkedStale: overrides.checkedStale,
    checkpointLastModified: nowIso,
    checkpointAgeSeconds: 100,
    checkpointCoverageRatio: 1,
    checkpointStaleThresholdSeconds: 2592000,
    checkpointStale: false,
    lastOkSidecarStatus: "ok",
  };
}

async function installLedgerIntegrityMock(
  page: import("@playwright/test").Page,
  overridesRef: { current: CheckedStaleOverrides },
) {
  await page.route(LEDGER_INTEGRITY_URL, async (route: Route) => {
    await route.fulfill({
      status: 200,
      contentType: "application/json",
      body: JSON.stringify(buildLedgerIntegrityBody(overridesRef.current)),
    });
  });
}

test.describe("dashboard: ledger integrity 'verifier not running' badge", () => {
  test("renders amber 'VERIFIER NOT RUNNING' badge when checkedStale=true and hides it on the healthy path", async ({
    page,
  }) => {
    const overridesRef: { current: CheckedStaleOverrides } = {
      current: {
        checkedStale: true,
        lastCheckedAgeSeconds: 600,
        checkedStaleThresholdSeconds: 60,
      },
    };

    await installLedgerIntegrityMock(page, overridesRef);

    // Stale path.
    await page.goto("/");

    const lastCheckedBlock = page.locator(
      '[data-testid="text-ledger-last-checked"]',
    );
    await expect(lastCheckedBlock).toBeVisible();
    await expect(lastCheckedBlock).toHaveAttribute(
      "data-checked-stale",
      "true",
    );

    const checkedStaleBadge = page.locator(
      '[data-testid="badge-ledger-checked-stale"]',
    );
    await expect(checkedStaleBadge).toBeVisible();
    // Exact-copy assertion (normalize whitespace) so suffix regressions
    // ("VERIFIER NOT RUNNING" without "— no recent attempt") are caught.
    await expect(checkedStaleBadge).toHaveText(
      "VERIFIER NOT RUNNING — no recent attempt",
    );

    const thresholdPill = page.locator(
      '[data-testid="text-ledger-checked-threshold"]',
    );
    await expect(thresholdPill).toBeVisible();
    await expect(thresholdPill).toContainText("stale >");

    // Healthy path: flip the mock and reload so the dashboard re-fetches.
    overridesRef.current = {
      checkedStale: false,
      lastCheckedAgeSeconds: 5,
      checkedStaleThresholdSeconds: 60,
    };
    await page.reload();

    await expect(lastCheckedBlock).toBeVisible();
    await expect(lastCheckedBlock).toHaveAttribute(
      "data-checked-stale",
      "false",
    );
    await expect(
      page.locator('[data-testid="badge-ledger-checked-stale"]'),
    ).toHaveCount(0);
  });
});
