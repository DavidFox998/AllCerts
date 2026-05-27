import { defineConfig, devices } from "@playwright/test";

/**
 * Playwright config for theorema-certs dashboard end-to-end tests.
 *
 * The tests assume the standard Replit workspace stack is already
 * running behind the global proxy (artifacts/api-server +
 * artifacts/theorema-certs both up). They drive the dashboard
 * through the same proxy port the user sees (`localhost:80`), and
 * mock the only API endpoint they care about (`/api/ledger/integrity`)
 * via `page.route` so they do not depend on real server state.
 *
 * Run with:
 *   pnpm --filter @workspace/theorema-certs exec playwright test
 */
export default defineConfig({
  testDir: "./tests/e2e",
  fullyParallel: false,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: "list",
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL ?? "http://localhost:80",
    trace: "retain-on-failure",
  },
  projects: [
    {
      name: "chromium",
      use: { ...devices["Desktop Chrome"] },
    },
  ],
});
