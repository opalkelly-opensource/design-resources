/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { IFrontPanel } from "@opalkelly/frontpanel-alloy-core";

import { SubEvent } from "sub-events/dist/src/event";

import FFTConfiguration, { BinNumber } from "./FFTConfiguration";

/**
 * Type representing a frequency bin defined by a bin number and an amplitude value.
 */
export type FrequencyBin = {
    number: BinNumber;
    amplitude: number;
};

/**
 * Enumeration representing the possible states of the FFT Signal Generator.
 */
export enum FFTSignalGeneratorState {
    Initial,
    InitializePending,
    InitializationComplete,
    InitializationFailed,
    ResetPending,
    ResetComplete,
    ResetFailed
}

/**
 * Event arguments for the FFT Signal Generator StateChanged event.
 */
export interface FFTSignalGeneratorStateChangeEventArgs {
    sender: FFTSignalGenerator;
    newState: FFTSignalGeneratorState;
    previousState: FFTSignalGeneratorState;
}

/**
 * Signal Generator
 */
export class FFTSignalGenerator {
    private readonly _FrontPanel: IFrontPanel;

    // Important: the IFFT bins are implemented as:
    // bin n real component = n * 2
    // bin n imaginary component = n * 2 + 1

    private readonly _FFTConfiguration: FFTConfiguration;

    private readonly _RetryCount: number;

    private _State: FFTSignalGeneratorState = FFTSignalGeneratorState.Initial;

    private readonly _StateChangedEvent: SubEvent<FFTSignalGeneratorStateChangeEventArgs> =
        new SubEvent<FFTSignalGeneratorStateChangeEventArgs>();

    /**
     * Get the configuration of the FFT.
     */
    public get FFTConfiguration() {
        return this._FFTConfiguration;
    }

    /**
     * Get the current state of the Signal Generator.
     */
    public get State() {
        return this._State;
    }

    /**
     * Get the StateChanged event used to monitor changes to the state of the Signal Generator.
     */
    public get StatechangedEvent() {
        return this._StateChangedEvent;
    }

    /**
     * Creates a new instance of the FFTSignalGenerator class.
     * @param frontpanel - Object that implements the IFrontPanel interface used to communicate with device.
     * @param fftConfiguration - Configuration of the FFT.
     * @param retryCount - Number of times to retry an operation.
     */
    constructor(frontpanel: IFrontPanel, fftConfiguration: FFTConfiguration, retryCount: number) {
        this._FrontPanel = frontpanel;
        this._FFTConfiguration = fftConfiguration;
        this._RetryCount = retryCount;
    }

    /**
     * Initializes the Signal Generator.
     * @returns Promise that resolves to true when the Signal Generator has been initialized, otherwise false.
     */
    public async Initialize(): Promise<boolean> {
        let retval: boolean;

        if (
            this._State === FFTSignalGeneratorState.Initial ||
            this._State === FFTSignalGeneratorState.InitializationFailed
        ) {
            console.log("FFTSignalGenerator::Initialization Pending...");

            this.UpdateState(FFTSignalGeneratorState.InitializePending);

            // Wait for Clocks to Lock
            await this._FrontPanel.updateWireOuts();

            let isLocked: boolean = ((await this._FrontPanel.getWireOutValue(0x20)) & 0x1) === 0x1;

            for (let retryIndex = 1; retryIndex < this._RetryCount && !isLocked; retryIndex++) {
                await this._FrontPanel.updateWireOuts();

                isLocked = ((await this._FrontPanel.getWireOutValue(0x20)) & 0x1) === 0x1;
            }

            if (isLocked) {
                this.UpdateState(FFTSignalGeneratorState.InitializationComplete);

                console.log("FFTSignalGenerator::Initialization Complete.");
            } else {
                this.UpdateState(FFTSignalGeneratorState.InitializationFailed);

                console.log("FFTSignalGenerator::Initialization Failed.");
            }

            retval = isLocked;
        } else {
            retval = false; // ERROR: Already Intialized
        }

        return retval;
    }

    /**
     * Resets the Signal Generator and clears all of the IFFT bins.
     * @returns Promise that resolves to true when the Signal Generator has been reset, otherwise false.
     */
    public async Reset(): Promise<boolean> {
        let retval: boolean;

        if (
            this._State === FFTSignalGeneratorState.InitializationComplete ||
            this._State === FFTSignalGeneratorState.ResetComplete ||
            this._State === FFTSignalGeneratorState.ResetFailed
        ) {
            console.log("FFTSignalGenerator::Reset Pending...");

            this.UpdateState(FFTSignalGeneratorState.ResetPending);

            // Reset IFFT
            await this.ClearAllBinRegisters();
            await this.SubmitBins();

            // Reset DAC
            await this._FrontPanel.setWireInValue(0x00, 0x00000002, 0xffffffff);
            await this._FrontPanel.updateWireIns();
            await this._FrontPanel.setWireInValue(0x00, 0x00000000, 0xffffffff);
            await this._FrontPanel.updateWireIns();

            // Wait for DAC to be ready
            await this._FrontPanel.updateWireOuts();

            let isDACReady: boolean =
                ((await this._FrontPanel.getWireOutValue(0x20)) & 0x00000002) === 0x00000002;

            for (let retryIndex = 0; retryIndex < this._RetryCount && !isDACReady; retryIndex++) {
                await this._FrontPanel.updateWireOuts();

                isDACReady =
                    ((await this._FrontPanel.getWireOutValue(0x20)) & 0x00000002) === 0x00000002;
            }

            if (isDACReady) {
                this.UpdateState(FFTSignalGeneratorState.ResetComplete);

                console.log("FFTSignalGenerator::Reset Complete.");
            } else {
                this.UpdateState(FFTSignalGeneratorState.ResetFailed);

                console.log("FFTSignalGenerator::Reset Failed.");
            }

            retval = isDACReady;
        } else {
            retval = false; // ERROR: Invalid State
        }

        return retval;
    }

    /**
     * Updates the current state of the Signal Generator and dispatches the StateChanged event.
     * @param newState - The new state of the Signal Generator.
     */
    private UpdateState(newState: FFTSignalGeneratorState) {
        if (newState !== this._State) {
            const previousState: FFTSignalGeneratorState = this._State;
            this._State = newState;

            this._StateChangedEvent.emit({
                sender: this,
                newState: this._State,
                previousState: previousState
            });
        }
    }

    /**
     * Clears all of the IFFT bins.
     * @returns Promise that resolves to true when all the bins are cleared, otherwise false.
     */
    public async ClearAllBins(): Promise<boolean> {
        let retval: boolean;

        if (this._State === FFTSignalGeneratorState.ResetComplete) {
            await this.ClearAllBinRegisters();

            await this.SubmitBins(); // Submits the Bin data to the IFFT

            retval = true; //SUCCESS: Bins Cleared
        } else {
            retval = false; //ERROR: Invalid State
        }

        return retval;
    }

    /**
     * Sets the specified IFFT bins.
     * @param bins - Array of frequency bins to set.
     * @param scale - Scale factor to apply to the frequency bin amplitude values.
     * @returns Promise that resolves to true when all the specified bins are set, otherwise false.
     */
    public async SetBins(bins: FrequencyBin[], scale: number): Promise<boolean> {
        let retval: boolean;

        if (this._State === FFTSignalGeneratorState.ResetComplete) {
            await this.SetBinRegisters(bins, scale);

            await this.SubmitBins(); // Submits the Bin data to the IFFT

            retval = true; // SUCCESS: Bins Set
        } else {
            retval = false; // ERROR: Invalid State
        }

        return retval;
    }

    /**
     * Clears the specified IFFT bins.
     * @param clearBins - Array of frequency bin numbers of the bins to clear.
     * @returns Promise that resolves to true when all the specified bins are cleared, otherwise false.
     */
    public async ClearBins(clearBins: BinNumber[]): Promise<boolean> {
        let retval: boolean;

        if (this._State === FFTSignalGeneratorState.ResetComplete) {
            await this.ClearBinRegisters(clearBins);

            await this.SubmitBins(); // Submits the Bin data to the IFFT

            retval = true; // SUCCESS: Bins Set
        } else {
            retval = false; // ERROR: Invalid State
        }

        return retval;
    }

    /**
     * Clears register values for all of the bins.
     * @returns Promise that resolves to true when all the bins are cleared, otherwise false.
     */
    protected async ClearAllBinRegisters(): Promise<void> {
        // Reset the real and imaginary components of each frequency bin. (2 registers per bin)
        const registerCount: number = this._FFTConfiguration.FFTLength;

        const registerWriteOperations: Promise<void>[] = [];

        for (let registerIndex = 0; registerIndex < registerCount; registerIndex++) {
            const operation = this._FrontPanel.writeRegister(registerIndex, 0x00);

            registerWriteOperations.push(operation);
        }

        await Promise.all(registerWriteOperations);
    }

    /**
     * Clears register values for the specified bin numbers
     * @param binNumbers - Array of bin numbers to clear
     * @returns Promise that resolves when the registers for all of the specified bins have been cleared.
     */
    protected async ClearBinRegisters(binNumbers: BinNumber[]): Promise<void> {
        const registerWriteOperations: Promise<void>[] = [];

        for (let binIndex = 0; binIndex < binNumbers.length; binIndex++) {
            const address = binNumbers[binIndex] * 2;

            const operation = this._FrontPanel.writeRegister(address, 0x00);

            registerWriteOperations.push(operation);
        }

        await Promise.all(registerWriteOperations);
    }

    /**
     * Sets the register value for the each specified frequency bin using the bin number and the amplitude value multiplied by the scale factor.
     * @param bins - Array of frequency bins to set.
     * @param amplitudeScaleFactor - Scale factor to apply to the amplitude values.
     * @returns Promise that resolves when all of the bin registers have been set.
     */
    protected async SetBinRegisters(
        bins: FrequencyBin[],
        amplitudeScaleFactor: number
    ): Promise<void> {
        const registerWriteOperations: Promise<void>[] = [];

        for (let binIndex = 0; binIndex < bins.length; binIndex++) {
            const address = bins[binIndex].number * 2;
            const value = Math.floor(
                bins[binIndex].amplitude *
                    this._FFTConfiguration.MaximumAmplitudeValue *
                    amplitudeScaleFactor
            );

            const operation = this._FrontPanel.writeRegister(address, value);

            registerWriteOperations.push(operation);
        }

        await Promise.all(registerWriteOperations);
    }

    /**
     * Submits the frequency bin data to the IFFT.
     * @returns Promise that resolves when the bin data has been submitted.
     */
    protected SubmitBins(): Promise<void> {
        return this._FrontPanel.activateTriggerIn(0x40, 1); // Submits the Bin data to the IFFT
    }
}
