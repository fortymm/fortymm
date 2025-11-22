import { Page } from "@playwright/test";
import { BaseAlertComponent } from "./base-alert-component";

export class MagicLinkSentAlertComponent extends BaseAlertComponent {
    constructor(page: Page) {
        super(page, "If your email is in our system, you will receive instructions for logging in shortly.");
    }
}
