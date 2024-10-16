import { ICameraEvent, CameraEventHandler, CameraEventAsyncHandler } from "./ICameraEvent";

import { IEventSubscription } from "@opalkelly/frontpanel-alloy-core";

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
    public Dispatch(sender: ICamera): boolean {
        this._Target.emit(sender);
        return true;
    }

    /**
     * Subscribes a handler to the event.
     * @param handler - The handler function to subscribe to the event.
     * @returns {IEventSubscription} - The subscription object, which can be used to cancel the subscription.
     */
    public Subscribe(handler: CameraEventHandler): IEventSubscription {
        const subscription: Subscription = this._Target.subscribe(handler);
        return new EventSubscription(subscription);
    }

    /**
     * Subscribes an asynchronous handler to the event.
     * @param handler - The asynchronous handler function to subscribe to the event.
     * @returns {IEventSubscription} - The subscription object, which can be used to cancel the subscription.
     */
    public SubscribeAsync(handler: CameraEventAsyncHandler): IEventSubscription {
        const subscription: Subscription = this._Target.subscribe(handler);
        return new EventSubscription(subscription);
    }
}

export default CameraEvent;
