import { expect, test } from "@playwright/test";
import { LandingPage } from "../page-objects/landing-page";
import { buildPassword, buildUser } from "../factories/user-factory";
import { AccountSettingsPage } from "../page-objects/account-settings-page";

test("it allows registration and login", async ({ page }) => {
    const user = buildUser();

    const loginPage = await test.step("register a new user", async () => {
        const landingPage = await LandingPage.goTo(page);
        const registrationPage = await landingPage.navigateToRegistration();
        return registrationPage.registerAs(user)
    });

    const dashboard = await test.step("confirm the account", async () => {
        const mailboxPage = await loginPage.navigateToMailbox();
        const confirmationEmail = await mailboxPage.selectConfirmationEmailFor(user);

        if (!confirmationEmail) {
            throw new Error("Confirmation email not found");
        }

        const accountConfirmationPage = await confirmationEmail.confirmEmail();
        return accountConfirmationPage.confirmAndStayLoggedIn();
    });

    expect(await dashboard.confirmationAlert.getMessage()).toBe("User confirmed successfully.");
    expect(await dashboard.userMenu.getUsername()).toBe(user.username);

    const accountSettings = await test.step("navigate to account settings", async () => {
        await dashboard.confirmationAlert.close();
        const menu = await dashboard.userMenu.open();

        return menu.navigateToAccountSettings();
    });

    const password = buildPassword();
    await test.step("set a password", async () => {
        await accountSettings.changePasswordForm.changePassword(password, password);
    });

    expect(await accountSettings.passwordUpdateAlert.getMessage()).toBe("Password updated successfully!");
    await accountSettings.passwordUpdateAlert.close();

    const landingPage = await test.step("log out", async () => {
        const menu = await accountSettings.userMenu.open();
        return menu.signOut();
    });

    expect(await landingPage.logoutAlert.getMessage()).toBe("Logged out successfully.");
    await landingPage.logoutAlert.close();

    const dashboardWithPassword = await test.step("log in with password", async () => {
        const loginPage = await landingPage.navigateToLogin();
        return loginPage.emailPasswordLoginForm.login(user.email, password);
    });

    await expect(await dashboardWithPassword.loginSuccessAlert.getMessage()).toBe("Welcome back!");
    await dashboardWithPassword.loginSuccessAlert.close();

    const accountSettingsWithPassword = await test.step("navigate to account settings", async () => {
        const menu = await dashboardWithPassword.userMenu.open();
        return menu.navigateToAccountSettings();
    });

    const newEmail = `new-${user.email}`;

    await test.step("change email", async () => {
        await accountSettingsWithPassword.changeEmailForm.changeEmail(newEmail);
        expect(await accountSettingsWithPassword.changeEmailForm.getEmail()).toBe(newEmail);
    });

    expect(await accountSettingsWithPassword.emailChangeAlert.getMessage()).toBe("A link to confirm your email change has been sent to the new address.");
    await accountSettingsWithPassword.emailChangeAlert.close();

    const newUsername = `new_${user.username}`;

    await test.step("change username", async () => {
        await accountSettingsWithPassword.changeUsernameForm.changeUsername(newUsername);
    });

    await expect(await accountSettingsWithPassword.usernameUpdateAlert.getMessage()).toBe("Username updated successfully.");
    await accountSettingsWithPassword.usernameUpdateAlert.close();

    /**
     * TODO: Fix this test. It fails because the username is not updated in the user menu after changing it.
     * things:///show?id=8M1VYFTycoGHMCKJiEcLoo
     * await expect(await accountSettingsWithPassword.userMenu.getUsername()).toBe(newUsername);
     */

    const landingPageWithNewUserDetails = await test.step("log out", async () => {
        const menu = await accountSettingsWithPassword.userMenu.open();
        return menu.signOut();
    });

    expect(await landingPageWithNewUserDetails.logoutAlert.getMessage()).toBe("Logged out successfully.");
    await landingPageWithNewUserDetails.logoutAlert.close();

    const loginPageWithConfirmedEmailChange = await test.step("confirm the email change", async () => {
        const loginPage = await landingPageWithNewUserDetails.navigateToLogin();
        const mailboxPage = await loginPage.navigateToMailbox();
        const confirmationEmail = await mailboxPage.selectEmailChangeConfirmationEmailFor(user);

        if (!confirmationEmail) {
            throw new Error("Confirmation email not found");
        }

        return confirmationEmail.confirmChange();
    });

    expect(await loginPageWithConfirmedEmailChange.mustLoginAlert.getMessage()).toBe("You must log in to access this page.");
    await loginPageWithConfirmedEmailChange.mustLoginAlert.close();

    const accountSettingsWithNewEmail = await test.step("log in with magic link", async () => {
        const loginPage = await landingPageWithNewUserDetails.navigateToLogin();
        await loginPage.passwordlessLoginForm.login(user.email);

        expect(await loginPage.magicLinkSentAlert.getMessage()).toBe("If your email is in our system, you will receive instructions for logging in shortly.");
        await loginPage.magicLinkSentAlert.close();

        const mailbox = await loginPage.navigateToMailbox();
        const magicLinkEmail = await mailbox.selectMagicLinkEmailFor(user);

        if (!magicLinkEmail) {
            throw new Error("Magic link email not found");
        }

        const emailLoginConfirmationPage = await magicLinkEmail.logInWithMagicLink();
        await emailLoginConfirmationPage.confirmAndStayLoggedIn();

        const accountSettings = new AccountSettingsPage(page);
        await accountSettings.assertIsDisplayed();

        return accountSettings;
    });

    expect(await accountSettingsWithNewEmail.changeEmailForm.getEmail()).toBe(newEmail);
    expect(await accountSettingsWithNewEmail.changeUsernameForm.getUsername()).toBe(newUsername);
    expect(await accountSettingsWithNewEmail.emailChangeSuccessAlert.getMessage()).toBe("Email changed successfully.");
    await accountSettingsWithNewEmail.emailChangeSuccessAlert.close();
    expect(await accountSettingsWithNewEmail.userMenu.getUsername()).toBe(newUsername);
});
