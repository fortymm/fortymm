import { Locator, Page } from "@playwright/test";

export class ChallengeWellComponent {
    private readonly challengeButton: Locator;

    constructor(private readonly page: Page) {
        this.challengeButton = page.getByRole("button", { name: "Challenge a Friend" });
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.challengeButton.waitFor({ state: 'visible' });
    }

    public async createChallenge(): Promise<void> {
        await this.challengeButton.click();
    }
}
