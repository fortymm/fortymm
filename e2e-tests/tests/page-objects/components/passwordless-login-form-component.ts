import { Locator, Page } from "@playwright/test";

export class PasswordlessLoginFormComponent {
    private readonly emailInput: Locator;
    private readonly loginButton: Locator;

    constructor(private readonly page: Page) {
        const form = page.locator('#login_form_magic');
        this.emailInput = form.getByRole('textbox', { name: 'Email' });
        this.loginButton = form.getByRole('button', { name: 'Log in with email' });
    }

    public async login(email: string): Promise<void> {
        await this.emailInput.clear();
        await this.emailInput.pressSequentially(email, { delay: 10 });
        await this.loginButton.click();
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.loginButton.waitFor({ state: 'visible' });
    }
}
