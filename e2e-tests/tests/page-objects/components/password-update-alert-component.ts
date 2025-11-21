import { Page } from "@playwright/test";
import { BaseAlertComponent } from "./base-alert-component";

export class PasswordUpdateAlertComponent extends BaseAlertComponent {
    constructor(page: Page) {
        super(page, "Password updated successfully!");
    }
}
