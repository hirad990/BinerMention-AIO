import { defineConfig, devices } from "@playwright/test";

const appUrl = "http://127.0.0.1:3000/mention/";

export default defineConfig({
  testDir: "./e2e",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? "github" : "list",
  use: { baseURL: "http://127.0.0.1:3000", trace: "retain-on-failure" },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    command: "npm run dev",
    url: appUrl,
    reuseExistingServer: !process.env.CI,
    timeout: 120000,
  },
});
