const pw = require("playwright"),
  fs = require("node:fs"),
  assert = require("node:assert/strict");
const root = process.env.QA_OUTPUT_DIR || "test-results/live-production";
fs.mkdirSync(root, { recursive: true });
const a = JSON.parse(fs.readFileSync(process.env.QA_ACCOUNT_FILE));
assert.equal(a.createdByThisValidation, true);
assert.equal(a.project, "quiznetic-30734");
assert.match(a.email, /^m32-web-qa-[a-f0-9-]{36}@example\.test$/);
const out = {
  url: process.env.PLAYWRIGHT_BASE_URL || "https://quiznetic.eirenya.com",
  playwright: require("playwright/package.json").version,
  startedAt: new Date().toISOString(),
  nativeSafari: false,
  results: [],
};
(async () => {
  for (const engine of (
    process.env.QA_ENGINES || "chromium,webkit,firefox"
  ).split(",")) {
    const b = await pw[engine].launch({
      ...(process.env.HTTPS_PROXY
        ? {
            proxy: {
              server: process.env.HTTPS_PROXY,
              bypass: "127.0.0.1,localhost",
            },
          }
        : {}),
      ...(process.env["QA_" + engine.toUpperCase() + "_EXECUTABLE"]
        ? {
            executablePath:
              process.env["QA_" + engine.toUpperCase() + "_EXECUTABLE"],
          }
        : {}),
    });
    try {
      for (const [device, viewport] of Object.entries({
        desktop: { width: 1280, height: 900 },
        mobile: { width: 390, height: 844 },
        tablet: { width: 768, height: 1024 },
      })) {
        const result = {
          engine,
          version: b.version(),
          device,
          checks: [],
          errors: [],
        };
        const c = await b.newContext({ viewport, locale: "en-US" });
        const p = await c.newPage();
        if (process.env.QA_ROUTE_HTTPS === "true")
          await p.route("https://**/*", async (r) => {
            try {
              const response = await r.fetch({ timeout: 90000 });
              await r.fulfill({ response });
            } catch (e) {
              await r.abort();
            }
          });
        p.setDefaultTimeout(25000);
        p.on("pageerror", (e) => result.errors.push(e.message.split("?")[0]));
        try {
          const sem = async () => {
            await p.waitForFunction(() =>
              document.querySelector(
                "flt-semantics-placeholder,flt-semantics-host",
              ),
            );
            await p
              .locator("flt-semantics-placeholder")
              .evaluateAll((ns) => ns.forEach((n) => n.click()));
          };
          const open = async (loc) => {
            await p.goto(out.url + "/#" + loc);
            await sem();
          };
          await open("/leaderboard?category=capital&difficulty=expert");
          await p
            .getByRole("button", { name: "Refuse analytics", exact: true })
            .click();
          await p
            .getByRole("button", {
              name: "Sign In / Create Account",
              exact: true,
            })
            .click();
          await p.waitForURL(/#\/login\?next=/);
          await p.reload();
          await sem();
          assert.match(p.url(), /next=.*leaderboard/);
          for (const [loc, value] of [
            [p.getByRole("textbox", { name: "Email", exact: true }), a.email],
            [p.locator("input[type=password]").first(), a.password],
          ]) {
            await loc.click();
            await loc.pressSequentially(value);
            await loc.press("Tab");
          }
          await p.getByRole("button", { name: "Sign in", exact: true }).click();
          await p.getByText("Global Leaderboard", { exact: true }).waitFor();
          assert.equal(
            await p.evaluate(
              () => window.firebase_auth.getAuth().currentUser.uid,
            ),
            a.uid,
          );
          await p
            .getByRole("button", { name: "Capital Quiz", exact: true })
            .waitFor();
          await p
            .getByRole("button", { name: "Expert", exact: true })
            .waitFor();
          result.checks.push("email-login-restores-deep-link");
          await p.reload();
          await sem();
          await p.getByText("Global Leaderboard", { exact: true }).waitFor();
          await p
            .getByRole("button", { name: "Expert", exact: true })
            .waitFor();
          result.checks.push("leaderboard-filters-survive-refresh");
          await p.screenshot({
            path: root + "/" + engine + "-" + device + "-leaderboard.png",
          });
          await open("/home");
          await p.getByText("Choose Your Quiz", { exact: true }).waitFor();
          await p
            .getByRole("button", { name: "Leaderboard", exact: true })
            .click();
          await p.getByText("Global Leaderboard", { exact: true }).waitFor();
          await p.goBack();
          await p.getByText("Choose Your Quiz", { exact: true }).waitFor();
          await p.goForward();
          await p.getByText("Global Leaderboard", { exact: true }).waitFor();
          result.checks.push("browser-back-forward");
          for (const [route, label] of [
            ["/profile", "Your Profile"],
            ["/settings", "Settings"],
          ]) {
            await open(route);
            await p.getByText(label, { exact: true }).waitFor();
            await p.reload();
            await sem();
            await p.getByText(label, { exact: true }).waitFor();
          }
          result.checks.push("profile-settings-session-refresh");
          await open("/difficulty?category=capital");
          await p
            .getByRole("button", { name: "Easy (15 questions)", exact: true })
            .waitFor();
          await p.reload();
          await sem();
          await p
            .getByRole("button", { name: "Easy (15 questions)", exact: true })
            .waitFor();
          result.checks.push("difficulty-deep-link-refresh");
          await p.screenshot({
            path: root + "/" + engine + "-" + device + "-difficulty.png",
          });
          for (const route of [
            "/quiz",
            "/result?score=15&total=15",
            "/unknown",
          ]) {
            await open(route);
            await p
              .getByRole("button", { name: "Choose a Quiz", exact: true })
              .waitFor();
          }
          result.checks.push("invalid-session-safe-recovery");
          assert.ok(
            await p.evaluate(
              () => document.documentElement.scrollWidth <= innerWidth,
            ),
          );
          result.checks.push("no-document-horizontal-overflow");
          assert.deepEqual(result.errors, []);
          await open("/settings");
          await p.getByRole("button", { name: /^Sign Out/ }).click();
          await p
            .getByRole("button", { name: "Continue as Guest", exact: true })
            .waitFor();
          assert.equal(
            await p.evaluate(() => window.firebase_auth.getAuth().currentUser),
            null,
          );
          result.checks.push("permanent-account-signout");
          result.passed = true;
        } catch (e) {
          result.passed = false;
          result.failure = e.message
            .split(a.email)
            .join("[test email]")
            .split(a.password)
            .join("[password]")
            .split(a.uid)
            .join("[test uid]");
          await p
            .screenshot({
              path: root + "/" + engine + "-" + device + "-failure.png",
            })
            .catch(() => {});
          out.results.push(result);
          fs.writeFileSync(
            root + "/matrix-report.json",
            JSON.stringify(out, null, 2),
          );
          console.log(JSON.stringify(result));
          throw e;
        } finally {
          await c.close();
        }
        out.results.push(result);
        fs.writeFileSync(
          root + "/matrix-report.json",
          JSON.stringify(out, null, 2),
        );
        console.log(JSON.stringify(result));
      }
    } finally {
      await b.close();
    }
  }
})().catch((e) => {
  console.error(e.message);
  process.exitCode = 1;
});
