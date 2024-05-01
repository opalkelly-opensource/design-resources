import { IFrontPanel } from "@opalkellytech/frontpanel-chromium-core";

import { SubEvent } from "sub-events/dist/src/event";

export type FrequencyBinNumber = number;

export type dBFS = number;
export type hertz = number;

export type FrequencyBin = {
    number: FrequencyBinNumber;
    amplitude: number;
};

export enum FFTSignalGeneratorState {
    Initial,
    InitializePending,
    InitializationComplete,
    InitializationFailed,
    ResetPending,
    ResetComplete,
    ResetFailed
}

export interface FFTSignalGeneratorStateChangeEventArgs {
    sender: FFTSignalGenerator;
    newState: FFTSignalGeneratorState;
    previousState: FFTSignalGeneratorState;
}

export class FFTSignalGenerator {
    private readonly _FrontPanel: IFrontPanel;

    // Important: the IFFT bins are implemented as:
    // bin n real component = n * 2
    // bin n imaginary component = n * 2 + 1

    private readonly _FFTLength: number;
    private readonly _SampleRate: hertz;
    private readonly _MaximumAmplitudeValue: number;
    private readonly _RetryCount: number;

    private _State: FFTSignalGeneratorState = FFTSignalGeneratorState.Initial;

    private readonly _StateChangedEvent: SubEvent<FFTSignalGeneratorStateChangeEventArgs> =
        new SubEvent<FFTSignalGeneratorStateChangeEventArgs>();

    public get FFTLength() {
        return this._FFTLength;
    }

    public get SampleRate() {
        return this._SampleRate;
    }

    public get MaximumAmplitudeValue() {
        return this._MaximumAmplitudeValue;
    }

    public get State() {
        return this._State;
    }

    public get StatechangedEvent() {
        return this._StateChangedEvent;
    }

    constructor(
        frontpanel: IFrontPanel,
        fftLength: number,
        sampleRate: hertz,
        maximumAmplitudeValue: number,
        retryCount: number
    ) {
        this._FrontPanel = frontpanel;
        this._FFTLength = fftLength;
        this._SampleRate = sampleRate;
        this._MaximumAmplitudeValue = maximumAmplitudeValue;
        this._RetryCount = retryCount;
    }

    // Operations
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
            await this.ClearAllBins();

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

    public async ClearAllBins(): Promise<boolean> {
        let retval: boolean;

        if (this._State === FFTSignalGeneratorState.ResetComplete) {
            // Reset the real and imaginary components of each frequency bin. (2 registers per bin)
            const registerCount: number = this._FFTLength;

            for (let registerIndex = 0; registerIndex < registerCount; registerIndex++) {
                await this._FrontPanel.writeRegister(registerIndex, 0x00);
            }

            await this.SubmitBins(); // Submits the Bin data to the IFFT

            retval = true; //SUCCESS: Bins Cleared
        } else {
            retval = false; //ERROR: Invalid State
        }

        return retval;
    }

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

    public async UpdateBins(
        updateBins: FrequencyBin[],
        clearBins: FrequencyBinNumber[],
        scale: number
    ): Promise<boolean> {
        let retval: boolean;

        if (this._State === FFTSignalGeneratorState.ResetComplete) {
            await this.ClearBinRegisters(clearBins);

            await this.SetBinRegisters(updateBins, scale);

            await this.SubmitBins(); // Submits the Bin data to the IFFT

            retval = true; // SUCCESS: Bins Set
        } else {
            retval = false; // ERROR: Invalid State
        }

        return retval;
    }

    public async ClearBins(clearBins: FrequencyBinNumber[]): Promise<boolean> {
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

    public GetBinFrequency(binNumber: FrequencyBinNumber): hertz {
        return this._SampleRate * (binNumber / this._FFTLength);
    }

    //
    protected async ClearBinRegisters(binNumbers: FrequencyBinNumber[]): Promise<void> {
        for (let binIndex = 0; binIndex < binNumbers.length; binIndex++) {
            const address = binNumbers[binIndex] * 2;

            await this._FrontPanel.writeRegister(address, 0x00);
        }
    }

    protected async SetBinRegisters(
        bins: FrequencyBin[],
        amplitudeScaleFactor: number
    ): Promise<void> {
        for (let binIndex = 0; binIndex < bins.length; binIndex++) {
            const address = bins[binIndex].number * 2;
            const value = Math.floor(
                bins[binIndex].amplitude * this._MaximumAmplitudeValue * amplitudeScaleFactor
            );

            await this._FrontPanel.writeRegister(address, value);
        }
    }

    protected SubmitBins(): Promise<void> {
        return this._FrontPanel.activateTriggerIn(0x40, 1); // Submits the Bin data to the IFFT
    }

    //
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

    // Converts a dbfs value to an integer the IFFT can use.
    // IFFT uses a 20 bit signed ap_fixed value.
    // We ignore the sign bit here, so:
    // 20 log(2 ^ 19) = ~115 dB scale
    // Return scaled integer value based on the dynamic range of 120 dB
    protected DBfsConversion(value: dBFS, scaleFactor: number) {
        const maximumAmplitudeValue = this._MaximumAmplitudeValue * scaleFactor;

        if (value === 0) {
            return maximumAmplitudeValue;
        } else {
            return Math.floor(Math.pow(10, value / 20) * maximumAmplitudeValue);
        }
    }
}
