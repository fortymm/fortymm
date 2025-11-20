import { test, expect } from "@playwright/test";
import { LandingPage } from "./page-objects/landing-page";

test.describe("the landing page", () => {
    test("it shows the heading", async ({ page }) => {
        const landingPage = await LandingPage.goTo(page);
        await expect(landingPage.heading).toBeVisible();
    });
});
