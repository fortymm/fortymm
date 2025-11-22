import { Locator, Page } from "@playwright/test";
import { AccountSettingsPage } from "../account-settings-page";
import { LandingPage } from "../landing-page";

class OpenUserMenu {
    private readonly accountSettingsLink: Locator;
    private readonly appearanceLink: Locator;
    private readonly signOutLink: Locator;

    constructor(private readonly page: Page) {
        // The dropdown menu items - scoped to the user-menu container
        const userMenuDropdown = page.locator('#user-menu');
        this.accountSettingsLink = userMenuDropdown.getByRole('link', { name: 'Account Settings' });
        this.appearanceLink = userMenuDropdown.getByRole('link', { name: 'Appearance' });
        this.signOutLink = userMenuDropdown.getByRole('link', { name: 'Sign Out' });
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.accountSettingsLink.waitFor({ state: 'visible' });
    }

    public async navigateToAccountSettings(): Promise<AccountSettingsPage> {
        await this.accountSettingsLink.click();
        const accountSettingsPage = new AccountSettingsPage(this.page);
        await accountSettingsPage.assertIsDisplayed();
        return accountSettingsPage;
    }

    public async navigateToAppearance(): Promise<void> {
        await this.appearanceLink.click();
    }

    public async signOut(): Promise<LandingPage> {
        await this.signOutLink.click();
        const landingPage = new LandingPage(this.page);
        await landingPage.assertIsDisplayed();
        return landingPage;
    }
}

export class UserMenuComponent {
    private readonly userMenuButton: Locator;

    constructor(private readonly page: Page) {
        // Use the accessible button with proper ARIA label
        // The user menu is now a <button> with aria-label="User menu"
        this.userMenuButton = page.getByRole('button', { name: 'User menu' });
    }

    public async getUsername(): Promise<string> {
        // The username is the alt text of the user avatar image
        const userImage = this.userMenuButton.getByRole('img');
        const username = await userImage.getAttribute('alt');
        if (!username) {
            throw new Error("Username not found in user menu avatar");
        }
        return username;
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.userMenuButton.waitFor({ state: 'visible' });
    }

    public async open(): Promise<OpenUserMenu> {
        await this.userMenuButton.click();
        const openMenu = new OpenUserMenu(this.page);
        await openMenu.assertIsDisplayed();
        return openMenu;
    }
}
