import { Locator, Page } from "@playwright/test";
import { DashboardPage } from "./dashboard-page";
import { waitForLiveViewConnected } from "../utils";

export class EmailLoginConfirmationPage {
    private readonly heading: Locator;
    private readonly keepMeLoggedInButton: Locator;
    private readonly logMeInOnlyThisTimeButton: Locator;

    constructor(private readonly page: Page) {
        this.heading = page.getByRole('heading', { level: 1 });
        this.keepMeLoggedInButton = page.getByRole('button', { name: 'Keep me logged in on this device' });
        this.logMeInOnlyThisTimeButton = page.getByRole('button', { name: 'Log me in only this time' });
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.keepMeLoggedInButton.waitFor({ state: 'visible' });
        await waitForLiveViewConnected(this.page);
    }

    public async getWelcomeMessage(): Promise<string> {
        return await this.heading.textContent() || "";
    }

    public async confirmAndStayLoggedIn(): Promise<void> {
        await this.keepMeLoggedInButton.click();
    }

    public async confirmOnlyThisTime(): Promise<DashboardPage> {
        await this.logMeInOnlyThisTimeButton.click();
        const dashboardPage = new DashboardPage(this.page);
        await dashboardPage.assertIsDisplayed();
        return dashboardPage;
    }
}
