import { Locator, Page } from "@playwright/test";

export abstract class BaseAlertComponent {
    protected readonly alert: Locator;
    protected readonly message: Locator;
    protected readonly closeButton: Locator;

    constructor(protected readonly page: Page, messageText: string) {
        this.alert = page.getByRole("alert");
        this.message = this.alert.getByText(messageText);
        this.closeButton = this.alert.getByRole("button", { name: "close" });
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.alert.waitFor({ state: 'visible' });
    }

    public async getMessage(): Promise<string> {
        const content = await this.message.textContent();
        if (content === null) {
            throw new Error("Alert message content is null");
        }
        return content;
    }

    public async close(): Promise<void> {
        await this.closeButton.click();
        await this.alert.waitFor({ state: 'hidden' });
    }

    public async assertIsHidden(): Promise<void> {
        await this.alert.waitFor({ state: 'hidden' });
    }
}
