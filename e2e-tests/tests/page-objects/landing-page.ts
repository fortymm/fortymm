import { expect, Locator, Page } from "@playwright/test";
import { RegistrationPage } from "./registration-page";
import { LogoutAlertComponent } from "./components/logout-alert-component";
import { LoginPage } from "./login-page";

export class LandingPage {
    public readonly heading: Locator;
    public readonly logoutAlert: LogoutAlertComponent;
    private registrationLink: Locator;
    private loginLink: Locator;

    static async goTo(page: Page): Promise<LandingPage> {
        await page.goto('/');
        const landingPage = new LandingPage(page);

        await landingPage.assertIsDisplayed();

        return landingPage;
    }

    constructor(private readonly page: Page) {
        this.heading = page.getByText("Peace of mind from prototype to production.");
        this.registrationLink = page.getByRole('link', { name: 'Register' });
        this.loginLink = page.getByRole('link', { name: 'Log in' });
        this.logoutAlert = new LogoutAlertComponent(page);
    }

    async navigateToRegistration(): Promise<RegistrationPage> {
        await this.registrationLink.click();
        const registrationPage = new RegistrationPage(this.page);
        await registrationPage.assertIsDisplayed();
        return registrationPage;
    }

    async navigateToLogin(): Promise<LoginPage> {
        await this.loginLink.click();
        const loginPage = new LoginPage(this.page);
        await loginPage.assertIsDisplayed();
        return loginPage;
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.heading.waitFor({ state: "visible" });
    }
}