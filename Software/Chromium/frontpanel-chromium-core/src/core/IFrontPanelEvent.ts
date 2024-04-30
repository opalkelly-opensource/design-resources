import IFrontPanel from "./IFrontPanel";

import { IEventSubscription } from "./IEventSubscription";

/**
 * Type representing a FrontPanel event handler.
 * @param sender - The sender of the event.
 */
export type FrontPanelEventHandler = (sender: IFrontPanel) => void;

/**
 * Type representing an asynchronous FrontPanel event handler.
 * @param sender - The sender of the event.
 * @returns {Promise<void>} - A promise that resolves when the event handling is complete.
 */
export type FrontPanelEventAsyncHandler = (sender: IFrontPanel) => Promise<void>;

/**
 * Interface representing a FrontPanel event.
 */
export interface IFrontPanelEvent {
    /**
     * Subscribes a handler to the event.
     * @param handler - The handler function to subscribe to the event.
     * @returns {IEventSubscription} - The subscription object, which can be used to cancel the subscription.
     */
    Subscribe(handler: FrontPanelEventHandler): IEventSubscription;

    /**
     * Subscribes an asynchronous handler to the event.
     * @param handler - The asynchronous handler function to subscribe to the event.
     * @returns {IEventSubscription} - The subscription object, which can be used to cancel the subscription.
     */
    SubscribeAsync(handler: FrontPanelEventAsyncHandler): IEventSubscription;
}
