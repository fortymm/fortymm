import { Locator, Page } from "@playwright/test";

export class ChangeEmailFormComponent {
    private readonly emailInput: Locator;
    private readonly changeEmailButton: Locator;

    constructor(private readonly page: Page) {
        this.emailInput = page.getByRole('textbox', { name: 'Email' });
        this.changeEmailButton = page.getByRole('button', { name: 'Change Email' });
    }

    public async getEmail(): Promise<string> {
        return await this.emailInput.inputValue();
    }

    public async changeEmail(newEmail: string): Promise<void> {
        await this.emailInput.clear();
        await this.emailInput.pressSequentially(newEmail, { delay: 10 });
        await this.changeEmailButton.click();
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.emailInput.waitFor({ state: 'visible' });
    }
}