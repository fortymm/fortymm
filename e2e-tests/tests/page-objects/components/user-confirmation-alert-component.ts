import { Page } from "@playwright/test";
import { BaseAlertComponent } from "./base-alert-component";

export class UserConfirmationAlertComponent extends BaseAlertComponent {
    constructor(page: Page) {
        super(page, "User confirmed successfully.");
    }
}
