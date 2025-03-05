/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { ICameraEvent, CameraEventHandler, CameraEventAsyncHandler } from "./ICameraEvent";

import { IEventSubscription } from "@opalkelly/frontpanel-platform-api";

import EventSubscription from "./EventSubscription";

import { SubEvent, Subscription } from "sub-events";

import ICamera from "./ICamera";

/**
 * Class representing a Camera event.
 */
class CameraEvent implements ICameraEvent {
    private readonly _Target: SubEvent<ICamera> = new SubEvent();

    /**
     * Dispatches the event to all subscribed handlers.
     * @param sender - The sender of the event.
     * @returns {boolean} - Returns true after the event has been dispatched.
     */
    public dispatch(sender: ICamera): boolean {
        this._Target.emit(sender);
        return true;
    }

    /**
     * Subscribes a handler to the event.
     * @param handler - The handler function to subscribe to the event.
     * @returns {IEventSubscription} - The subscription object, which can be used to cancel the subscription.
     */
    public subscribe(handler: CameraEventHandler): IEventSubscription {
        const subscription: Subscription = this._Target.subscribe(handler);
        return new EventSubscription(subscription);
    }

    /**
     * Subscribes an asynchronous handler to the event.
     * @param handler - The asynchronous handler function to subscribe to the event.
     * @returns {IEventSubscription} - The subscription object, which can be used to cancel the subscription.
     */
    public subscribeAsync(handler: CameraEventAsyncHandler): IEventSubscription {
        const subscription: Subscription = this._Target.subscribe(handler);
        return new EventSubscription(subscription);
    }
}

export default CameraEvent;
