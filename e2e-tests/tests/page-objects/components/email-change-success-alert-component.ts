import { Page } from "@playwright/test";
import { BaseAlertComponent } from "./base-alert-component";

export class EmailChangeSuccessAlertComponent extends BaseAlertComponent {
    constructor(page: Page) {
        super(page, "Email changed successfully.");
    }
}
