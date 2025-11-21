import { Page } from "@playwright/test";
import { BaseAlertComponent } from "./base-alert-component";

export class LogoutAlertComponent extends BaseAlertComponent {
    constructor(page: Page) {
        super(page, "Logged out successfully.");
    }
}
