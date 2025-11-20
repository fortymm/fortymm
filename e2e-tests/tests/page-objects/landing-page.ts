import { expect, Locator, Page } from "@playwright/test";

export class LandingPage {
    public readonly heading: Locator;

    static async goTo(page: Page): Promise<LandingPage> {
        await page.goto('/');
        const landingPage = new LandingPage(page);

        await landingPage.assertIsDisplayed();

        return landingPage;
    }

    constructor(private readonly page: Page) {
        this.heading = page.getByText("Peace of mind from prototype to production.");
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.heading.waitFor({ state: "visible" });
    }
}