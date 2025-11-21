import { Locator, Page } from "@playwright/test";
import { DashboardPage } from "../dashboard-page";
import { waitForLiveViewConnected } from "../../utils";

export class EmailPasswordLoginFormComponent {
    private readonly emailInput: Locator;
    private readonly passwordInput: Locator;
    private readonly loginAndStayLoggedInButton: Locator;
    private readonly loginOnlyThisTimeButton: Locator;

    constructor(private readonly page: Page) {
        const form = page.locator('#login_form_password')
        this.emailInput = form.getByRole('textbox', { name: 'Email' });
        this.passwordInput = form.getByRole('textbox', { name: 'Password' });
        this.loginAndStayLoggedInButton = form.getByRole('button', { name: 'Log in and stay logged in' });
        this.loginOnlyThisTimeButton = form.getByRole('button', { name: 'Log in only this time' });
    }

    public async login(email: string, password: string, stayLoggedIn: boolean = true): Promise<DashboardPage> {
        await this.emailInput.clear();
        await this.emailInput.pressSequentially(email, { delay: 10 });

        await this.passwordInput.clear();
        await this.passwordInput.pressSequentially(password, { delay: 10 });

        if (stayLoggedIn) {
            await this.loginAndStayLoggedInButton.click();
        } else {
            await this.loginOnlyThisTimeButton.click();
        }

        const dashboardPage = new DashboardPage(this.page);
        await dashboardPage.assertIsDisplayed();
        return dashboardPage;
    }

    public async assertIsDisplayed(): Promise<void> {
        await this.loginAndStayLoggedInButton.waitFor({ state: 'visible' });
        await waitForLiveViewConnected(this.page);
    }
}
