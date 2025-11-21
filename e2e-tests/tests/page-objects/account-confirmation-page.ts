import { Locator, Page } from "@playwright/test";
import { DashboardPage } from "./dashboard-page";
import { waitForLiveViewConnected } from "../utils";

export class AccountConfirmationPage {
    private readonly confirmAndStayLoggedInButton: Locator;
    private readonly confirmAndLogInOnlyThisTimeButton: Locator;

    constructor(private readonly page: Page) {
        this.confirmAndStayLoggedInButton = page.getByRole("button", { name: "Confirm and stay logged in" });
        this.confirmAndLogInOnlyThisTimeButton = page.getByRole("button", { name: "Confirm and log in only this time" });
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.confirmAndStayLoggedInButton.waitFor({ state: 'visible' });
        await waitForLiveViewConnected(this.page);
    }

    public async confirmAndStayLoggedIn(): Promise<DashboardPage> {
        const dashboard = new DashboardPage(this.page);
        await this.confirmAndStayLoggedInButton.click();
        await dashboard.assertIsDisplayed();
        return dashboard;
    }

    public async confirmAndLogInOnlyThisTime(): Promise<DashboardPage> {
        const dashboard = new DashboardPage(this.page);
        await this.confirmAndLogInOnlyThisTimeButton.click();
        await dashboard.assertIsDisplayed();
        return dashboard;
    }
}
