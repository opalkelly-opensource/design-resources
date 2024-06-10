/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

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
