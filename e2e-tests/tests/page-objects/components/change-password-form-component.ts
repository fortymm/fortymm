import { Locator, Page } from "@playwright/test";

export class ChangePasswordFormComponent {
    private readonly newPasswordInput: Locator;
    private readonly confirmPasswordInput: Locator;
    private readonly savePasswordButton: Locator;

    constructor(private readonly page: Page) {
        this.newPasswordInput = page.locator('#user_password');
        this.confirmPasswordInput = page.locator('#user_password_confirmation');
        this.savePasswordButton = page.getByRole('button', { name: 'Save Password' });
    }

    public async changePassword(newPassword: string, confirmPassword: string): Promise<void> {
        await this.newPasswordInput.clear();
        await this.newPasswordInput.pressSequentially(newPassword, { delay: 10 });
        await this.confirmPasswordInput.clear();
        await this.confirmPasswordInput.pressSequentially(confirmPassword, { delay: 10 });
        await this.savePasswordButton.click();
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.newPasswordInput.waitFor({ state: 'visible' });
    }
}
