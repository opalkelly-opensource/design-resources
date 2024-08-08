/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import ICamera from "./ICamera";

import { IEventSubscription } from "@opalkelly/frontpanel-alloy-core";

/**
 * Type representing a Camera event handler.
 * @param sender - The sender of the event.
 */
export type CameraEventHandler = (sender: ICamera) => void;

/**
 * Type representing an asynchronous Camera event handler.
 * @param sender - The sender of the event.
 * @returns {Promise<void>} - A promise that resolves when the event handling is complete.
 */
export type CameraEventAsyncHandler = (sender: ICamera) => Promise<void>;

/**
 * Interface representing a Camera event.
 */
export interface ICameraEvent {
    /**
     * Subscribes a handler to the event.
     * @param handler - The handler function to subscribe to the event.
     * @returns {IEventSubscription} - The subscription object, which can be used to cancel the subscription.
     */
    Subscribe(handler: CameraEventHandler): IEventSubscription;

    /**
     * Subscribes an asynchronous handler to the event.
     * @param handler - The asynchronous handler function to subscribe to the event.
     * @returns {IEventSubscription} - The subscription object, which can be used to cancel the subscription.
     */
    SubscribeAsync(handler: CameraEventAsyncHandler): IEventSubscription;
}
