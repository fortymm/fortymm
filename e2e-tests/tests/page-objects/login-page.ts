import { Locator, Page } from "@playwright/test";
import { MailboxPage } from "./mailbox-page";
import { PasswordlessLoginFormComponent } from "./components/passwordless-login-form-component";
import { EmailPasswordLoginFormComponent } from "./components/email-password-login-form-component";
import { MustLoginAlertComponent } from "./components/must-login-alert-component";
import { MagicLinkSentAlertComponent } from "./components/magic-link-sent-alert-component";
import { waitForLiveViewConnected } from "../utils";

export class LoginPage {
    public readonly passwordlessLoginForm: PasswordlessLoginFormComponent;
    public readonly emailPasswordLoginForm: EmailPasswordLoginFormComponent;
    public readonly mustLoginAlert: MustLoginAlertComponent;
    public readonly magicLinkSentAlert: MagicLinkSentAlertComponent;
    private readonly logInWithEmailButton: Locator;
    private readonly mailboxLink: Locator;

    constructor(private readonly page: Page) {
        this.passwordlessLoginForm = new PasswordlessLoginFormComponent(page);
        this.emailPasswordLoginForm = new EmailPasswordLoginFormComponent(page);
        this.mustLoginAlert = new MustLoginAlertComponent(page);
        this.magicLinkSentAlert = new MagicLinkSentAlertComponent(page);
        this.logInWithEmailButton = page.getByRole("button", { name: "Log in with email" });
        this.mailboxLink = page.getByRole('link', { name: 'the mailbox page' });
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.logInWithEmailButton.waitFor({ state: 'visible' });
        await waitForLiveViewConnected(this.page);
    }

    public async navigateToMailbox(): Promise<MailboxPage> {
        await this.mailboxLink.click();
        const mailboxPage = new MailboxPage(this.page);
        await mailboxPage.assertIsDisplayed();
        return mailboxPage;
    }
}