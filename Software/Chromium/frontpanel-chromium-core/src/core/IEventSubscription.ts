/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
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
