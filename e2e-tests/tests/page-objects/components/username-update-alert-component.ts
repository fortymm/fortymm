import { Page } from "@playwright/test";
import { BaseAlertComponent } from "./base-alert-component";

export class UsernameUpdateAlertComponent extends BaseAlertComponent {
    constructor(page: Page) {
        super(page, "Username updated successfully.");
    }
}
