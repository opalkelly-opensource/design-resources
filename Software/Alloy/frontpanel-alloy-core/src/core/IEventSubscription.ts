/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

/**
 * Interface representing an event subscription.
 */
export interface IEventSubscription {
    /**
     * Cancels the event subscription.
     * @returns {boolean} - Returns true if the cancellation was successful, false otherwise.
     */
    Cancel(): boolean;
}
