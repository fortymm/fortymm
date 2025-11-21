import { Locator, Page } from "@playwright/test";

export class ChangeUsernameFormComponent {
    private readonly usernameInput: Locator;
    private readonly changeUsernameButton: Locator;

    constructor(private readonly page: Page) {
        this.usernameInput = page.getByRole('textbox', { name: 'Username' });
        this.changeUsernameButton = page.getByRole('button', { name: 'Change Username' });
    }

    public async getUsername(): Promise<string> {
        return await this.usernameInput.inputValue();
    }

    public async changeUsername(newUsername: string): Promise<void> {
        await this.usernameInput.clear();
        await this.usernameInput.pressSequentially(newUsername, { delay: 10 });
        await this.changeUsernameButton.click();
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.usernameInput.waitFor({ state: 'visible' });
    }
}
