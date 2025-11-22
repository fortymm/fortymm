import { Locator, Page } from "@playwright/test";
import { User } from "../factories/user-factory";
import { LoginPage } from "./login-page";

export class RegistrationPage {
    public readonly heading: Locator;
    private emailInput: Locator;
    private usernameInput: Locator;
    private registerButton: Locator;

    constructor(private readonly page: Page) {
        this.heading = page.getByRole('heading', { name: 'Register for an account' });
        this.emailInput = page.getByLabel('Email');
        this.usernameInput = page.getByLabel('Username');
        this.registerButton = page.getByRole('button', { name: 'Create an account' });
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.heading.waitFor({ state: 'visible' });
    }

    public async registerAs(user: User): Promise<LoginPage> {
        await this.emailInput.pressSequentially(user.email, { delay: 10 });
        await this.usernameInput.pressSequentially(user.username, { delay: 10 });

        // Wait for navigation to complete after clicking the register button
        await this.registerButton.click();

        const loginPage = new LoginPage(this.page);
        await loginPage.assertIsDisplayed();

        return loginPage;
    }
}