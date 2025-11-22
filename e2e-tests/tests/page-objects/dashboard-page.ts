import { Page } from "@playwright/test";
import { NavigationComponent } from "./components/navigation-component";
import { UserMenuComponent } from "./components/user-menu-component";
import { ChallengeWellComponent } from "./components/challenge-well-component";
import { UserConfirmationAlertComponent } from "./components/user-confirmation-alert-component";
import { LoginSuccessAlertComponent } from "./components/login-success-alert-component";

export class DashboardPage {
    public readonly navigation: NavigationComponent;
    public readonly userMenu: UserMenuComponent;
    public readonly challengeWell: ChallengeWellComponent;
    public readonly confirmationAlert: UserConfirmationAlertComponent;
    public readonly loginSuccessAlert: LoginSuccessAlertComponent;

    constructor(private readonly page: Page) {
        this.navigation = new NavigationComponent(page);
        this.userMenu = new UserMenuComponent(page);
        this.challengeWell = new ChallengeWellComponent(page);
        this.confirmationAlert = new UserConfirmationAlertComponent(page);
        this.loginSuccessAlert = new LoginSuccessAlertComponent(page);
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.challengeWell.assertIsDisplayed();
    }

    static async goto(page: Page): Promise<DashboardPage> {
        await page.goto("/dashboard");
        const dashboardPage = new DashboardPage(page);
        await dashboardPage.assertIsDisplayed();
        return dashboardPage;
    }
}
