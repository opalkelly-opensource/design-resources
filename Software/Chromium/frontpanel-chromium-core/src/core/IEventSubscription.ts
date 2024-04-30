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
