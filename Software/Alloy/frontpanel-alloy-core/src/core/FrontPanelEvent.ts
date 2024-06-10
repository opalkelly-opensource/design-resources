/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import {
    IFrontPanelEvent,
    FrontPanelEventHandler,
    FrontPanelEventAsyncHandler
} from "./IFrontPanelEvent";

import { IEventSubscription } from "./IEventSubscription";

import EventSubscription from "./EventSubscription";

import { SubEvent, Subscription } from "sub-events";

import IFrontPanel from "./IFrontPanel";

/**
 * Class representing a FrontPanel event.
 */
class FrontPanelEvent implements IFrontPanelEvent {
    private readonly _Target: SubEvent<IFrontPanel> = new SubEvent();

    /**
     * Creates a new instance of a FrontPanel event.
     */
    constructor() {}

    /**
     * Dispatches the event to all subscribed handlers.
     * @param sender - The sender of the event.
     * @returns {boolean} - Returns true after the event has been dispatched.
     */
    public Dispatch(sender: IFrontPanel): boolean {
        this._Target.emit(sender);
        return true;
    }

    /**
     * Subscribes a handler to the event.
     * @param handler - The handler function to subscribe to the event.
     * @returns {IEventSubscription} - The subscription object, which can be used to cancel the subscription.
     */
    public Subscribe(handler: FrontPanelEventHandler): IEventSubscription {
        const subscription: Subscription = this._Target.subscribe(handler);
        return new EventSubscription(subscription);
    }

    /**
     * Subscribes an asynchronous handler to the event.
     * @param handler - The asynchronous handler function to subscribe to the event.
     * @returns {IEventSubscription} - The subscription object, which can be used to cancel the subscription.
     */
    public SubscribeAsync(handler: FrontPanelEventAsyncHandler): IEventSubscription {
        const subscription: Subscription = this._Target.subscribe(handler);
        return new EventSubscription(subscription);
    }
}

export default FrontPanelEvent;
