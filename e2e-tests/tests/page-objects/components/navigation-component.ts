import { Locator, Page } from "@playwright/test";

export class NavigationComponent {
    private readonly dashboardLink: Locator;
    private readonly matchesLink: Locator;

    constructor(private readonly page: Page) {
        this.dashboardLink = page.getByRole("link", { name: "Dashboard" });
        this.matchesLink = page.getByRole("link", { name: "Matches" });
    }

    public async navigateToDashboard(): Promise<void> {
        await this.dashboardLink.click();
        await this.page.waitForURL("/dashboard");
    }

    public async navigateToMatches(): Promise<void> {
        await this.matchesLink.click();
        await this.page.waitForURL("/matches");
    }
}
