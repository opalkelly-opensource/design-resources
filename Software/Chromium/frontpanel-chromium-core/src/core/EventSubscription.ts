import { IEventSubscription } from "./IEventSubscription";

import { Subscription } from "sub-events";

/**
 * Represents a subscription to an event.
 */
class EventSubscription implements IEventSubscription {
    private _Target: Subscription;

    constructor(subscription: Subscription) {
        this._Target = subscription;
    }

    public Cancel(): boolean {
        return this._Target.cancel();
    }
}

export default EventSubscription;
