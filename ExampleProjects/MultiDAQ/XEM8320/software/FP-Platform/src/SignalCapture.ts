/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { IFPGADataPortClassic, ByteCount } from "@opalkelly/frontpanel-platform-api";

export interface ADCChannelData {
    data: number[];
}

export class SignalCapture {
    private readonly _FPGADataPort: IFPGADataPortClassic;
    private readonly _SampleSize: ByteCount;

    public get SampleSize() {
        return this._SampleSize;
    }

    constructor(fpgaDataPort: IFPGADataPortClassic, sampleSize: ByteCount) {
        this._FPGADataPort = fpgaDataPort;
        this._SampleSize = sampleSize;
    }

    public async readSamples(): Promise<ADCChannelData[] | undefined> {
        // Read via pipe poa1
        const REF_VOLTAGE = 4.096;
        const UPPER_RANGE = REF_VOLTAGE * 2.5;
        const RESOLUTION = 2 ** 16 - 1;
        const VOLTS_PER_STEP = (UPPER_RANGE * 2) / RESOLUTION;
        const BYTES_PER_WORD = 4;

        const formattedData: ADCChannelData[] = new Array(8).fill(0).map(() => ({ data: [] }));
        const outputDataSize: ByteCount = this._SampleSize * BYTES_PER_WORD;

        // Check for program empty
        await this._FPGADataPort.updateWireOuts();

        let isProgramFull: boolean = ((this._FPGADataPort.getWireOutValue(0x28)) & 0x1) === 0x1;

        for (let ii = 0; ii < 200 && !isProgramFull; ii++) {
            await this._FPGADataPort.updateWireOuts();

            isProgramFull = ((this._FPGADataPort.getWireOutValue(0x28)) & 0x1) === 0x1;
        }

        if (!isProgramFull) {
            console.log("ADC FIFO never filled up.");
            return undefined;
        }

        const outputData: ArrayBuffer = new ArrayBuffer(outputDataSize);
        
        await this._FPGADataPort.readFromPipeOut(
            0xa0,
            outputDataSize,
            outputData
        );

        //const output: Uint32Array = new Uint32Array(outputData);
        const output: DataView = new DataView(outputData);
        for (let sampleIndex = 0; sampleIndex < output.byteLength; sampleIndex += 4) {
            // each 32 bit chunk is organized like so:
            // bit 31-16 contains the Ch number
            // bit 15-0 contains the data

            // FIFO Architecture:
            // {CH#}{DATA}
            // 1022 more times...
            // {CH#}{DATA}
            const num = output.getUint32(sampleIndex, false);
            const data = num & 0xffff; // The next 16 bits represent the channel number
            const channelNumber = (num & 0xffff0000) >> 16; // The first 16 bits represent the data

            // put the voltage data into the correct spot in the formattedData array
            // put the voltage data (right hand) into the nth array (0-7) of formatted data's data variable
            formattedData[channelNumber - 1].data.push((data - (2 ** 15 - 1)) * VOLTS_PER_STEP);
        }
        return formattedData;
    }

    public toString(inData: ADCChannelData[]) {
        let textOut = "";
        for (let ii = 0; ii < inData.length; ii++) {
            textOut += inData[ii].data + "\n";
        }
        return textOut;
    }
}
