import { Page } from "@playwright/test";
import { BaseAlertComponent } from "./base-alert-component";

export class LoginSuccessAlertComponent extends BaseAlertComponent {
    constructor(page: Page) {
        super(page, "Welcome back!");
    }
}
