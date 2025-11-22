import { Page } from "@playwright/test";
import { BaseAlertComponent } from "./base-alert-component";

export class MustLoginAlertComponent extends BaseAlertComponent {
    constructor(page: Page) {
        super(page, "You must log in to access this page.");
    }
}
