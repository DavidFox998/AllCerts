import { test, expect } from "@playwright/test";
import { existsSync } from "node:fs";
import {
  bootStaleBindingFixture,
  cleanupStaleBindingTmpDir,
  createStaleBindingTmpDir,
  installStaleBindingForwarders,
  type FixtureServer,
} from "./helpers/stale-binding-fixture.js";

/**
 * Task #232: end-to-end coverage for the amber "stale checkpoint
 * binding" banner's Acknowledge button
 * (`button-ack-ledger-sidecar-stale-binding`) and its acknowledged
 * badge (`badge-ledger-sidecar-stale-binding-acknowledged`).
 *
 * Task #204 added the Acknowledge button + acknowledged badge to the
 * amber banner, mirroring the red forged-sidecar banner, and wired it
 * to `POST /ledger/sidecar-stale-binding-ack`. That flow was covered
 * by a checker-level integration test
 * (`ledger.integration.test.ts` "acknowledges a stale-checkpoint-
 * binding incident…") but had NO browser-level coverage driving the
 * real HTTP route through the rendered UI — so a dashboard refactor
 * could silently drop the attribution surface. The forged-sidecar
 * flow has analogous e2e coverage
 * (`ledger-sidecar-forged-ack*.spec.ts`); this spec is its
 * stale-binding twin.
 *
 * Strategy mirrors the forged fixture: an in-process express server
 * boots a real `createLedgerChecker` over a tmp dir whose sidecar is
 * HMAC-valid but bound to a checkpoint that is NOT on disk (the real
 * router classifies it `stale_checkpoint_binding` on boot), with a
 * broken live ledger so the sticky flag survives the first `/integrity`
 * poll. Playwright forwards `/api/ledger/integrity`, the ack POST, and
 * the history GET to that fixture, so the dashboard exercises the same
 * production code path as the integration test.
 */

const FIXTURE_REFEREE_NAME = "alice";
const FIXTURE_NAMED_TOKEN = "alice-stale-binding-token";
const REBUILD_TOKEN_STORAGE_KEY = "lean-rebuild-token";

const namedTokens = new Map<string, string | null>([
  [FIXTURE_NAMED_TOKEN, FIXTURE_REFEREE_NAME],
]);

test.describe("dashboard: stale checkpoint binding banner Acknowledge button (task #232)", () => {
  test("named-referee Acknowledge persists the badge with operator name + timestamp", async ({
    page,
  }) => {
    const { tmpDir, paths } = createStaleBindingTmpDir(
      "ledger-stale-binding-ack-e2e-",
    );

    const active = await bootStaleBindingFixture({ paths, namedTokens });

    try {
      // Anchor the Playwright virtual clock so the dashboard's 1s
      // `setNowMs` interval doesn't wake the page under parallel-worker
      // CPU contention, keeping the test well under the 30s ceiling.
      await page.clock.install({ time: Date.now() });
      await installStaleBindingForwarders(page, () => active);

      // Seed the bearer token that the in-fixture named-token map
      // resolves to "alice". The dashboard reads this from
      // localStorage and sends it as Authorization: Bearer <token>,
      // which also gates the Acknowledge button's render.
      await page.addInitScript(
        ([key, token]) => {
          window.localStorage.setItem(key as string, token as string);
        },
        [REBUILD_TOKEN_STORAGE_KEY, FIXTURE_NAMED_TOKEN],
      );

      await page.goto("/");

      const panel = page.locator(
        '[data-testid="panel-ledger-sidecar-stale-binding"]',
      );
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "false");

      // Un-acknowledged at boot: no badge yet.
      await expect(
        page.locator(
          '[data-testid="badge-ledger-sidecar-stale-binding-acknowledged"]',
        ),
      ).toHaveCount(0);

      const ackButton = page.locator(
        '[data-testid="button-ack-ledger-sidecar-stale-binding"]',
      );
      await expect(ackButton).toBeVisible();
      await expect(ackButton).toBeEnabled();
      await expect(ackButton).toHaveText(/^Acknowledge$/);

      // --- Click Acknowledge ---
      await ackButton.click();

      // After the POST resolves + the integrity query is invalidated,
      // the panel flips to data-acknowledged="true", the badge renders
      // with the operator attribution, and the button reads
      // "Acknowledged" and is disabled.
      await expect(panel).toHaveAttribute("data-acknowledged", "true");

      const badge = page.locator(
        '[data-testid="badge-ledger-sidecar-stale-binding-acknowledged"]',
      );
      await expect(badge).toBeVisible();
      await expect(badge).toHaveText(/acknowledged/i);
      await expect(badge).toContainText(`· ${FIXTURE_REFEREE_NAME}`);
      await expect(badge).toHaveAttribute(
        "data-acked-by",
        FIXTURE_REFEREE_NAME,
      );

      // The title carries "Acknowledged by alice at <ISO>" — pull the
      // ISO and assert its shape so the test doesn't race the clock.
      const title = await badge.getAttribute("title");
      expect(title).not.toBeNull();
      const expectedPrefix = `Acknowledged by ${FIXTURE_REFEREE_NAME} at `;
      expect(title).toMatch(
        new RegExp(
          `^Acknowledged by ${FIXTURE_REFEREE_NAME} at \\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z$`,
        ),
      );
      const iso = title!.slice(expectedPrefix.length);
      expect(new Date(iso).toISOString()).toBe(iso);

      await expect(ackButton).toBeDisabled();
      await expect(ackButton).toHaveText(/^Acknowledged$/);

      // The ack file must have been persisted to disk — that's the
      // mechanism that survives a restart.
      const ackPath = `${paths.lastOkPath}.stale-binding-ack`;
      expect(existsSync(ackPath)).toBe(true);
    } finally {
      await active.close();
      cleanupStaleBindingTmpDir(tmpDir, paths);
    }
  });

  test("renders the no-token hint instead of the Acknowledge button when no rebuild token is set", async ({
    page,
  }) => {
    const { tmpDir, paths } = createStaleBindingTmpDir(
      "ledger-stale-binding-notoken-e2e-",
    );

    const active = await bootStaleBindingFixture({ paths, namedTokens });

    try {
      await page.clock.install({ time: Date.now() });
      await installStaleBindingForwarders(page, () => active);

      // Deliberately do NOT seed `lean-rebuild-token`.
      await page.goto("/");

      const panel = page.locator(
        '[data-testid="panel-ledger-sidecar-stale-binding"]',
      );
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "false");

      // No token → the Acknowledge button is replaced by the hint.
      await expect(
        page.locator(
          '[data-testid="button-ack-ledger-sidecar-stale-binding"]',
        ),
      ).toHaveCount(0);
      const hint = page.locator(
        '[data-testid="hint-ack-ledger-sidecar-stale-binding-no-token"]',
      );
      await expect(hint).toBeVisible();
      await expect(hint).toContainText(/rebuild token/i);
    } finally {
      await active.close();
      cleanupStaleBindingTmpDir(tmpDir, paths);
    }
  });

  test("surfaces the 409 error when the incident has cleared server-side before the click", async ({
    page,
  }) => {
    // Integrity is driven by a stale fixture (so the banner + button
    // render), but the ack POST is forwarded to a separate HEALTHY,
    // no-incident fixture whose real route answers 409. This models
    // the race where the server-side incident cleared (e.g. a
    // re-verify from another operator) between the dashboard's
    // integrity snapshot and the operator's click.
    const stale = createStaleBindingTmpDir("ledger-stale-binding-409-stale-");
    const healthy = createStaleBindingTmpDir(
      "ledger-stale-binding-409-healthy-",
      "healthy",
    );

    let staleFixture: FixtureServer | null = null;
    let healthyFixture: FixtureServer | null = null;

    try {
      staleFixture = await bootStaleBindingFixture({
        paths: stale.paths,
        namedTokens,
      });
      healthyFixture = await bootStaleBindingFixture({
        paths: healthy.paths,
        namedTokens,
      });

      await page.clock.install({ time: Date.now() });
      await installStaleBindingForwarders(page, {
        integrity: () => staleFixture!,
        ack: () => healthyFixture!,
        history: () => staleFixture!,
      });

      await page.addInitScript(
        ([key, token]) => {
          window.localStorage.setItem(key as string, token as string);
        },
        [REBUILD_TOKEN_STORAGE_KEY, FIXTURE_NAMED_TOKEN],
      );

      await page.goto("/");

      const panel = page.locator(
        '[data-testid="panel-ledger-sidecar-stale-binding"]',
      );
      await expect(panel).toBeVisible();
      await expect(panel).toHaveAttribute("data-acknowledged", "false");

      const ackButton = page.locator(
        '[data-testid="button-ack-ledger-sidecar-stale-binding"]',
      );
      await expect(ackButton).toBeEnabled();
      await ackButton.click();

      // The 409 surfaces as the inline ack error; the banner stays
      // un-acknowledged and no badge renders.
      const errorText = page.locator(
        '[data-testid="text-ack-ledger-sidecar-stale-binding-error"]',
      );
      await expect(errorText).toBeVisible();
      await expect(errorText).toContainText("409");
      await expect(panel).toHaveAttribute("data-acknowledged", "false");
      await expect(
        page.locator(
          '[data-testid="badge-ledger-sidecar-stale-binding-acknowledged"]',
        ),
      ).toHaveCount(0);
    } finally {
      if (staleFixture) await staleFixture.close();
      if (healthyFixture) await healthyFixture.close();
      cleanupStaleBindingTmpDir(stale.tmpDir, stale.paths);
      cleanupStaleBindingTmpDir(healthy.tmpDir, healthy.paths);
    }
  });
});
