/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

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
    private _UpdatePeriodMilliseconds: number;

    /**
     * Flag indicating whether the timer loop is currently running.
     */
    private _IsRunning: boolean = false;

    /**
     * Flag indicating that the timer loop should exit on the next iteration.
     */
    private _IsStopPending: boolean = false;

    /**
     * Function that cancels the timeout used to wait for the next update period.
     */
    private _CancelTimeout?: () => void;

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
    public async Start(): Promise<boolean> {
        let retval: boolean;

        // Wait for the timer to stop if stop is pending
        if (this._IsStopPending) {
            await this._UpdateTimer;
        }

        // Start the timer loop if it is currently stopped
        if (!this._IsRunning) {
            this._UpdateTimer = this.UpdateTimerLoop();

            retval = this._IsRunning;
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

            if (this._CancelTimeout) {
                this._CancelTimeout();
            }

            if (this._UpdateTimer !== null) {
                await this._UpdateTimer;

                this._UpdateTimer = null;
            }

            this._IsStopPending = false;
        }
    }

    /**
     * The main loop for the update timer. It periodically updates WireOuts and TriggerOuts, and
     * dispatches the events.
     * @returns A promise that resolves when the timer loop has exited.
     */
    private async UpdateTimerLoop(): Promise<void> {
        this._IsRunning = true;

        while (!this._IsStopPending) {
            const start: number = performance.now();

            // Update WireOuts and TriggerOuts and dispatch events
            const wireOutUpdate = this.UpdateWireOuts();
            const triggerOutUpdate = this.UpdateTriggerOuts();

            await Promise.all([wireOutUpdate, triggerOutUpdate]);

            const elapsed: number = performance.now() - start;

            // NOTE: Stop pending can change while waiting for the update promises to
            // resolve so we check it again before waiting for the next update period.
            if (!this._IsStopPending) {
                // Wait until the update period has elapsed
                const delay: number = this._UpdatePeriodMilliseconds - elapsed;

                await new Promise<void>((resolve) => {
                    const timeoutId = setTimeout(resolve, delay);

                    this._CancelTimeout = () => {
                        clearTimeout(timeoutId);
                        resolve();
                    };
                });
            }
        }

        this._IsRunning = false;
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
