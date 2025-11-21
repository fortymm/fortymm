import { Page } from "@playwright/test";

/**
 * Waits for Phoenix LiveView to be fully connected before proceeding.
 *
 * Phoenix LiveView adds the `.phx-connected` class to the body element once
 * the WebSocket connection is established and the LiveView is ready for interactions.
 *
 * @param page - The Playwright page object
 * @param timeout - Maximum time to wait in milliseconds (default: 5000)
 *
 * @example
 * ```typescript
 * await waitForLiveViewConnected(page);
 * // Now safe to interact with LiveView elements
 * await page.getByLabel("Email").fill("user@example.com");
 * ```
 */
export async function waitForLiveViewConnected(page: Page, timeout: number = 5000): Promise<void> {
    await page.waitForSelector("[data-phx-main].phx-connected", { timeout }) // Ensure that the live-view is connected
}

/**
 * Waits for Phoenix LiveView to be connected using the LiveSocket JavaScript API.
 *
 * This is an alternative method that checks the LiveSocket connection status
 * using the window.liveSocket object exposed by Phoenix LiveView.
 *
 * @param page - The Playwright page object
 * @param timeout - Maximum time to wait in milliseconds (default: 5000)
 *
 * @example
 * ```typescript
 * await waitForLiveSocketConnected(page);
 * ```
 */
export async function waitForLiveSocketConnected(page: Page, timeout: number = 5000): Promise<void> {
    await page.waitForFunction(
        'window.liveSocket && window.liveSocket.isConnected()',
        { timeout }
    );
}

/**
 * Waits for all pending LiveView operations to complete.
 *
 * This waits for the page to be fully loaded and all LiveView updates to settle.
 * Useful after navigation or after triggering LiveView events.
 *
 * @param page - The Playwright page object
 * @param timeout - Maximum time to wait in milliseconds (default: 5000)
 *
 * @example
 * ```typescript
 * await page.getByRole("button", { name: "Submit" }).click();
 * await waitForLiveViewToSettle(page);
 * ```
 */
export async function waitForLiveViewToSettle(page: Page, timeout: number = 5000): Promise<void> {
    // Wait for LiveView to be connected
    await waitForLiveViewConnected(page, timeout);

    // Wait for network to be idle (no ongoing requests)
    await page.waitForLoadState('networkidle', { timeout });
}
