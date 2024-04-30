import IFrontPanelEventSource from "./IFrontPanelEventSource";

import IFrontPanel from "./IFrontPanel";

import { IFrontPanelEvent } from "./IFrontPanelEvent";

import FrontPanelEvent from "./FrontPanelEvent";

/**
 * Class representing a timer that periodically updates WireOuts and TriggerOuts and dispatches
 * events to notify subscribers of changes.
 */
class FrontPanelPeriodicUpdateTimer implements IFrontPanelEventSource {
    /**
     * Event that is dispatched when WireOut values change.
     */
    private readonly _Device: IFrontPanel;

    /**
     * Event that notifies subscribers when WireOut values change.
     */
    private readonly _WireOutValuesChangedEvent = new FrontPanelEvent();

    /**
     * Event that notifies subscribers when TriggerOut values change.
     */
    private readonly _TriggerOutValuesChangedEvent = new FrontPanelEvent();

    /**
     * Reference to the update timer loop used to identify when the timer
     * loop has started and when it has exited.
     */
    private _UpdateTimer: Promise<void> | null = null;

    /**
     * The period in milliseconds between updates.
     */
    private _UpdatePeriodMilliseconds;

    /**
     * Flag indicating that the timer loop should exit on the next iteration.
     */
    private _IsStopPending = false;

    /**
     * Event that notifies subscribers when WireOut values change.
     */
    public get WireOutValuesChangedEvent(): IFrontPanelEvent {
        return this._WireOutValuesChangedEvent;
    }

    /**
     * Event that notifies subscribers when TriggerOut values change.
     */
    public get TriggerOutValuesChangedEvent(): IFrontPanelEvent {
        return this._TriggerOutValuesChangedEvent;
    }

    /**
     * Creates a new instance of the FrontPanelPeriodicUpdateTimer.
     * @param device - The interface to the FrontPanel device that is the source of WireOuts and TriggerOuts.
     * @param periodMilliseconds - The period in milliseconds between updates.
     */
    constructor(device: IFrontPanel, periodMilliseconds: number) {
        this._Device = device;

        this._UpdatePeriodMilliseconds = periodMilliseconds;
    }

    /**
     * Starts the update timer loop if it is not already running.
     * @returns true if the timer loop was successfully started; false if the timer loop was already started.
     */
    public Start(): boolean {
        let retval: boolean;

        if (this._UpdateTimer === null) {
            this._UpdateTimer = this.UpdateTimerLoop();

            retval = true;
        } else {
            retval = false; //ERROR: Timer already started
        }

        return retval;
    }

    /**
     * Stops the update timer loop and returns a promise that resolves when the loop has exited.
     * @returns A promise that resolves when the timer loop has exited.
     */
    public async Stop(): Promise<void> {
        if (!this._IsStopPending) {
            this._IsStopPending = true;

            await this._UpdateTimer;

            this._IsStopPending = false;
            this._UpdateTimer = null;
        }
    }

    /**
     * The main loop for the update timer. It periodically updates WireOuts and TriggerOuts, and
     * dispatches the events.
     * @returns A promise that resolves when the timer loop has exited.
     */
    private async UpdateTimerLoop(): Promise<void> {
        while (!this._IsStopPending) {
            const start: number = performance.now();

            // Update WireOuts and TriggerOuts and dispatch events
            await this.UpdateWireOuts();
            await this.UpdateTriggerOuts();

            const elapsed: number = performance.now() - start;

            // Wait until the update period has elapsed
            const delay: number = this._UpdatePeriodMilliseconds - elapsed;

            await new Promise((resolve) => {
                setTimeout(resolve, delay);
            });
        }
    }

    /**
     * Updates the WireOuts and dispatches the WireOutValuesChangedEvent.
     */
    private async UpdateWireOuts(): Promise<void> {
        await this._Device.updateWireOuts();

        this._WireOutValuesChangedEvent.Dispatch(this._Device);
    }

    /**
     * Updates the TriggerOuts and dispatches the TriggerOutValuesChangedEvent.
     */
    private async UpdateTriggerOuts(): Promise<void> {
        await this._Device.updateTriggerOuts();

        this._TriggerOutValuesChangedEvent.Dispatch(this._Device);
    }
}

export default FrontPanelPeriodicUpdateTimer;
