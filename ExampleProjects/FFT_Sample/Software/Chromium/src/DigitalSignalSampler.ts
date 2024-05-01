import { IFrontPanel, ByteCount } from "@opalkellytech/frontpanel-chromium-core";

import { SubEvent } from "sub-events";

export enum DigitalSignalSamplerState {
    Initial,
    InitializePending,
    InitializationComplete,
    InitializationFailed,
    ResetPending,
    ResetComplete,
    ResetFailed
}

export interface DigitalSignalSamplerStateChangeEventArgs {
    sender: DigitalSignalSampler;
    newState: DigitalSignalSamplerState;
    previousState: DigitalSignalSamplerState;
}

export class DigitalSignalSampler {
    private readonly _FrontPanel: IFrontPanel;
    private readonly _SampleSize: ByteCount;
    private readonly _SampleCount: number;

    private _State: DigitalSignalSamplerState = DigitalSignalSamplerState.Initial;

    private readonly _StateChangedEvent: SubEvent<DigitalSignalSamplerStateChangeEventArgs> =
        new SubEvent<DigitalSignalSamplerStateChangeEventArgs>();

    public get SampleSize() {
        return this._SampleSize;
    }

    public get SampleCount() {
        return this._SampleCount;
    }

    public get State() {
        return this._State;
    }

    public get StateChangedEvent() {
        return this._StateChangedEvent;
    }

    constructor(frontpanel: IFrontPanel, sampleSize: ByteCount, sampleCount: number) {
        this._FrontPanel = frontpanel;
        this._SampleSize = sampleSize;
        this._SampleCount = sampleCount;

        this._State = DigitalSignalSamplerState.InitializationComplete;
    }

    public async Reset(): Promise<boolean> {
        let retval: boolean;

        if (
            this._State === DigitalSignalSamplerState.InitializationComplete ||
            this._State === DigitalSignalSamplerState.ResetComplete ||
            this._State === DigitalSignalSamplerState.ResetFailed
        ) {
            console.log("DigitalSignalSampler::Reset Pending...");

            this.UpdateState(DigitalSignalSamplerState.ResetPending);

            // Wait for Clocks to Lock
            await this._FrontPanel.updateWireOuts();

            let isLocked: boolean = ((await this._FrontPanel.getWireOutValue(0x20)) & 0x1) === 0x1;

            for (let retryIndex = 1; retryIndex < 100 && !isLocked; retryIndex++) {
                await this._FrontPanel.updateWireOuts();

                isLocked = ((await this._FrontPanel.getWireOutValue(0x20)) & 0x1) === 0x1;
            }

            if (isLocked) {
                await this._FrontPanel.setWireInValue(0x01, 0x00000001, 0xffffffff);
                await this._FrontPanel.updateWireIns();
                await this._FrontPanel.setWireInValue(0x01, 0x00000000, 0xffffffff);
                await this._FrontPanel.updateWireIns();

                this.UpdateState(DigitalSignalSamplerState.ResetComplete);

                console.log("DigitalSignalSampler::Reset Complete.");
            } else {
                this.UpdateState(DigitalSignalSamplerState.ResetFailed);

                console.log("DigitalSignalSampler::Reset Failed.");
            }

            retval = isLocked;
        } else {
            retval = false; // ERROR: Invalid State
        }

        return retval;
    }

    public async ReadSamples(channels: Int16Array[]): Promise<boolean> {
        let retval: boolean;

        if (this._State === DigitalSignalSamplerState.ResetComplete) {
            await this._FrontPanel.activateTriggerIn(0x42, 0); // Fill the ADC FIFO

            // Wait for FIFO to fill.
            await this._FrontPanel.updateWireOuts();

            let isFull: boolean =
                ((await this._FrontPanel.getWireOutValue(0x20)) & 0x00000004) === 0x00000004;

            while (!isFull) {
                await this._FrontPanel.updateWireOuts();

                isFull =
                    ((await this._FrontPanel.getWireOutValue(0x20)) & 0x00000004) === 0x00000004;
            }

            //  Read Data
            const sampleData: ArrayBuffer = await this._FrontPanel.readFromPipeOut(
                0xa0,
                this._SampleSize * this._SampleCount
            );

            const samples: DataView = new DataView(sampleData);

            for (let sampleIndex = 0; sampleIndex < this._SampleCount; sampleIndex++) {
                const byteOffset: ByteCount = sampleIndex * this._SampleSize;

                channels[0][sampleIndex] = (samples.getUint16(byteOffset, false) >> 2) - 0x2000;
                channels[1][sampleIndex] = (samples.getUint16(byteOffset + 2, false) >> 2) - 0x2000;
            }

            retval = true; // SUCCESS:
        } else {
            retval = false; // ERROR: Invalid State
        }

        return retval;
    }

    //
    private UpdateState(newState: DigitalSignalSamplerState) {
        if (newState !== this._State) {
            const previousState: DigitalSignalSamplerState = this._State;
            this._State = newState;

            this._StateChangedEvent.emit({
                sender: this,
                newState: this._State,
                previousState: previousState
            });
        }
    }
}
