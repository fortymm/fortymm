import { Page } from "@playwright/test";
import { NavigationComponent } from "./components/navigation-component";
import { UserMenuComponent } from "./components/user-menu-component";
import { ChangeEmailFormComponent } from "./components/change-email-form-component";
import { ChangeUsernameFormComponent } from "./components/change-username-form-component";
import { ChangePasswordFormComponent } from "./components/change-password-form-component";
import { PasswordUpdateAlertComponent } from "./components/password-update-alert-component";
import { EmailChangeAlertComponent } from "./components/email-change-alert-component";
import { UsernameUpdateAlertComponent } from "./components/username-update-alert-component";
import { EmailChangeSuccessAlertComponent } from "./components/email-change-success-alert-component";
import { waitForLiveViewConnected } from "../utils";

export class AccountSettingsPage {
    public readonly navigation: NavigationComponent;
    public readonly userMenu: UserMenuComponent;
    public readonly changeEmailForm: ChangeEmailFormComponent;
    public readonly changeUsernameForm: ChangeUsernameFormComponent;
    public readonly changePasswordForm: ChangePasswordFormComponent;
    public readonly passwordUpdateAlert: PasswordUpdateAlertComponent;
    public readonly emailChangeAlert: EmailChangeAlertComponent;
    public readonly emailChangeSuccessAlert: EmailChangeSuccessAlertComponent;
    public readonly usernameUpdateAlert: UsernameUpdateAlertComponent;

    constructor(private readonly page: Page) {
        this.navigation = new NavigationComponent(page);
        this.userMenu = new UserMenuComponent(page);
        this.changeEmailForm = new ChangeEmailFormComponent(page);
        this.changeUsernameForm = new ChangeUsernameFormComponent(page);
        this.changePasswordForm = new ChangePasswordFormComponent(page);
        this.passwordUpdateAlert = new PasswordUpdateAlertComponent(page);
        this.emailChangeAlert = new EmailChangeAlertComponent(page);
        this.emailChangeSuccessAlert = new EmailChangeSuccessAlertComponent(page);
        this.usernameUpdateAlert = new UsernameUpdateAlertComponent(page);
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.changeEmailForm.assertIsDisplayed();
        await waitForLiveViewConnected(this.page);
    }

    static async goto(page: Page): Promise<AccountSettingsPage> {
        await page.goto("/users/settings");
        const accountSettingsPage = new AccountSettingsPage(page);
        await accountSettingsPage.assertIsDisplayed();
        return accountSettingsPage;
    }
}
