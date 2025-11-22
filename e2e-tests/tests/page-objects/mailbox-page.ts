import { expect, Locator, Page } from "@playwright/test";
import { User } from "../factories/user-factory";
import { AccountConfirmationPage } from "./account-confirmation-page";
import { LoginPage } from "./login-page";
import { EmailLoginConfirmationPage } from "./email-login-confirmation-page";

export class EmailPage {
    public readonly isConfirmationEmail: boolean;
    public readonly isLogInEmail: boolean;
    public readonly isUpdateEmailInstructions: boolean;

    private readonly subject: Locator;
    private readonly sentTo: Locator;

    constructor(protected readonly page: Page) {
        this.subject = page.locator('#email-details__subject');
        this.sentTo = page.locator('#email-details__to');
        this.isConfirmationEmail = false;
        this.isLogInEmail = false;
        this.isUpdateEmailInstructions = false;
    }

    static async getCurrentlySelectedEmail(page: Page): Promise<EmailPage> {
        const undifferentiatedEmailPage = new EmailPage(page);
        const subject = await undifferentiatedEmailPage.subject.textContent();

        if (!subject) {
            throw new Error('No email selected');
        }

        const emailPagesBySubject: Record<string, EmailPage> = {
            'Subject Confirmation instructions': new ConfirmationEmailPage(page),
            'Subject Log in instructions': new LogInEmailPage(page),
            'Subject Update email instructions': new UpdateEmailInstructionsPage(page)
        };

        const emailPage = emailPagesBySubject[subject.replace(/\s+/g, ' ').trim()];

        if (!emailPage) {
            throw new Error(`Unknown email subject: ${subject}`);
        }

        return emailPage;
    }

    public async emailAddressOfRecipient(): Promise<string> {
        const sentToText = await this.sentTo.textContent();

        if (!sentToText) {
            throw new Error('Email does not have a "To" field');
        }

        return sentToText.trim();
    }

    public async wasSentTo(user: User): Promise<boolean> {
        const sentToText = await this.emailAddressOfRecipient();

        if (!sentToText) {
            throw new Error('Email does not have a "To" field');
        }

        return sentToText.includes(user.email);
    }
}

export class ConfirmationEmailPage extends EmailPage {
    public readonly isConfirmationEmail: boolean;
    private readonly confirmationLink: Locator;

    constructor(page: Page) {
        super(page);
        this.isConfirmationEmail = true;
        this.confirmationLink = page.getByRole('link', { name: 'http://localhost:4000/users/log-in/' });
    }

    public async confirmEmail(): Promise<AccountConfirmationPage> {
        await this.confirmationLink.click();

        const confirmationPage = new AccountConfirmationPage(this.page);
        await confirmationPage.assertIsDisplayed();

        return confirmationPage;
    }
}

export class LogInEmailPage extends EmailPage {
    public readonly isLogInEmail: boolean;
    private readonly magicLink: Locator;

    constructor(page: Page) {
        super(page);
        this.isLogInEmail = true;
        this.magicLink = page.getByRole('link', { name: 'http://localhost:4000/users/log-in/' });
    }

    public async logInWithMagicLink(): Promise<EmailLoginConfirmationPage> {
        await this.magicLink.click();
        const emailLoginConfirmationPage = new EmailLoginConfirmationPage(this.page);
        await emailLoginConfirmationPage.assertIsDisplayed();
        return emailLoginConfirmationPage;
    }
}

export class UpdateEmailInstructionsPage extends EmailPage {
    public readonly isUpdateEmailInstructions: boolean;
    private readonly updateEmailInstructionsLink: Locator;

    constructor(page: Page) {
        super(page);
        this.updateEmailInstructionsLink = page.getByRole('link', { name: 'http://localhost:4000/users/settings/confirm-email/' });
        this.isUpdateEmailInstructions = true;
    }

    async confirmChange(): Promise<LoginPage> {
        await this.updateEmailInstructionsLink.click();
        const loginPage = new LoginPage(this.page);
        await loginPage.assertIsDisplayed();
        return loginPage;
    }
}

export class MailboxPage {
    private readonly heading: Locator;
    private readonly confirmationEmailLinks: Locator;
    private readonly updateEmailInstructionsLinks: Locator;
    private readonly loginLinks: Locator;

    constructor(private readonly page: Page) {
        this.heading = page.getByRole('heading', { name: 'Mailbox' });
        this.confirmationEmailLinks = page.getByRole('link', { name: 'Fortymm Confirmation' });
        this.updateEmailInstructionsLinks = page.getByRole('link', { name: 'Fortymm Update email instructions' });
        this.loginLinks = page.getByRole('link', { name: 'Fortymm Log in instructions' });
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.heading.waitFor({ state: 'visible' });
    }

    private async selectEmailLink(link: Locator): Promise<EmailPage> {
        const originallySelectedEmail = await EmailPage.getCurrentlySelectedEmail(this.page);
        const originallySelectedEmailIsConfirmationEmail = originallySelectedEmail instanceof ConfirmationEmailPage;
        const originallySelectedEmailRecipient = await originallySelectedEmail.emailAddressOfRecipient();

        await link.click();

        await expect(async () => {
            const currentlySelectedEmail = await EmailPage.getCurrentlySelectedEmail(this.page);
            const currentlySelectedEmailIsConfirmationEmail = currentlySelectedEmail instanceof ConfirmationEmailPage;
            const currentlySelectedEmailRecipient = await currentlySelectedEmail.emailAddressOfRecipient();

            // Verify that a different email is now selected (either different type or different recipient)
            const emailTypeChanged = currentlySelectedEmailIsConfirmationEmail !== originallySelectedEmailIsConfirmationEmail;
            const recipientChanged = currentlySelectedEmailRecipient !== originallySelectedEmailRecipient;
            expect(emailTypeChanged || recipientChanged);
        }).toPass();

        return await EmailPage.getCurrentlySelectedEmail(this.page);
    }

    private async findEmailFromLinks(links: Locator[], predicate: (email: EmailPage) => Promise<boolean>): Promise<EmailPage | null> {
        for (const link of links) {
            const selectedEmail = await this.selectEmailLink(link);
            const matchesPredicate = await predicate(selectedEmail);

            if (matchesPredicate) {
                return selectedEmail;
            }
        }

        return null;
    }

    private async findEmailForUser(links: Locator[], user: User): Promise<EmailPage | null> {
        return await this.findEmailFromLinks(links, async email => await email.wasSentTo(user));
    }

    public async selectConfirmationEmailFor(user: User): Promise<ConfirmationEmailPage | null> {
        const initiallySelectedEmail = await EmailPage.getCurrentlySelectedEmail(this.page);
        const initiallySelectedEmailIsForUser = await initiallySelectedEmail.wasSentTo(user);

        if (initiallySelectedEmailIsForUser && initiallySelectedEmail.isConfirmationEmail) {
            return initiallySelectedEmail as ConfirmationEmailPage;
        }

        const links = await this.confirmationEmailLinks.all();
        return await this.findEmailForUser(links, user) as ConfirmationEmailPage | null;
    }

    public async selectEmailChangeConfirmationEmailFor(user: User): Promise<UpdateEmailInstructionsPage | null> {
        const initiallySelectedEmail = await EmailPage.getCurrentlySelectedEmail(this.page);
        const initiallySelectedEmailIsForUser = await initiallySelectedEmail.wasSentTo(user);

        if (initiallySelectedEmailIsForUser && initiallySelectedEmail.isUpdateEmailInstructions) {
            return initiallySelectedEmail as UpdateEmailInstructionsPage;
        }

        const links = await this.updateEmailInstructionsLinks.all();
        return await this.findEmailForUser(links, user) as UpdateEmailInstructionsPage | null;
    }

    public async selectMagicLinkEmailFor(user: User): Promise<LogInEmailPage | null> {
        const initiallySelectedEmail = await EmailPage.getCurrentlySelectedEmail(this.page);
        const initiallySelectedEmailIsForUser = await initiallySelectedEmail.wasSentTo(user);

        if (initiallySelectedEmailIsForUser && initiallySelectedEmail.isLogInEmail) {
            return initiallySelectedEmail as LogInEmailPage;
        }

        const links = await this.loginLinks.all();
        return await this.findEmailForUser(links, user) as LogInEmailPage | null;
    }
}