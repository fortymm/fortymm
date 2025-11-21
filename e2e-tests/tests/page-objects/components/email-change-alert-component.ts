import { Page } from "@playwright/test";
import { BaseAlertComponent } from "./base-alert-component";

export class EmailChangeAlertComponent extends BaseAlertComponent {
    constructor(page: Page) {
        super(page, "A link to confirm your email change has been sent to the new address.");
    }
}
