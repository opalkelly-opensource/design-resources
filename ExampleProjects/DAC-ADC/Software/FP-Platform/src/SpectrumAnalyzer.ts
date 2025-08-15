/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { IFPGADataPortClassic, ByteCount } from "@opalkelly/frontpanel-platform-api";

/**
 * Spectrum Analyzer
 */
export class SpectrumAnalyzer {
    private readonly _FPGADataPort: IFPGADataPortClassic;
    private readonly _SampleSize: ByteCount;
    private readonly _SampleCount: number;

    public get SampleSize() {
        return this._SampleSize;
    }

    public get SampleCount() {
        return this._SampleCount;
    }

    /**
     * Creates a new instance of the Spectrum Analyzer
     * @param fpgaDataPort - Object that implements the IFPGADataPortClassic interface used to communicate with device.
     * @param sampleSize - Sample size
     * @param sampleCount - Sample count
     */
    constructor(fpgaDataPort: IFPGADataPortClassic, sampleSize: ByteCount, sampleCount: number) {
        this._FPGADataPort = fpgaDataPort;
        this._SampleSize = sampleSize;
        this._SampleCount = sampleCount;
    }

    /**
     * Computes the spectrum of the input samples
     * @param sourceSamples - Time domain signal samples
     * @param outputSamples - Frequency domain samples
     * @returns True if the operation was successful, otherwise false
     */
    public async ComputeSpectrum(
        sourceSamples: Int16Array,
        outputSamples: Float64Array
    ): Promise<boolean> {
        // Write Samples
        await this._FPGADataPort.writeToPipeIn(
            0x80,
            sourceSamples.byteLength,
            sourceSamples.buffer as ArrayBuffer
        );

        // Check for program empty
        await this._FPGADataPort.updateWireOuts();

        let isProgramEmpty: boolean =
            ((this._FPGADataPort.getWireOutValue(0x20)) & 0x10) === 0x10;

        while (isProgramEmpty) {
            await this._FPGADataPort.updateWireOuts();

            isProgramEmpty = ((this._FPGADataPort.getWireOutValue(0x20)) & 0x10) === 0x10;
        }

        // Start FFT Calculation
        await this._FPGADataPort.activateTriggerIn(0x40, 2);

        // Wait for program full
        let isProgramFull: boolean = ((this._FPGADataPort.getWireOutValue(0x20)) & 0x8) === 0x8;

        while (!isProgramFull) {
            await this._FPGADataPort.updateWireOuts();

            isProgramFull = ((this._FPGADataPort.getWireOutValue(0x20)) & 0x8) === 0x8;
        }

        // Read via pipe poa1
        const outputDataSize: ByteCount = this._SampleSize * this._SampleCount; // Each sample has two components (real, imaginary)

        const outputData: ArrayBuffer = new ArrayBuffer(outputDataSize);

        await this._FPGADataPort.readFromPipeOut(0xa1, outputDataSize, outputData);

        const output: DataView = new DataView(outputData);

        for (let sampleIndex = 0; sampleIndex < this._SampleCount; sampleIndex++) {
            const byteOffset: ByteCount = sampleIndex * this._SampleSize;

            // The real and imaginary components are 3 bytes in length
            const real: number = (output.getUint32(byteOffset + 1, false) << 8) >> 8;
            const imaginary: number = (output.getUint32(byteOffset + 4, false) << 8) >> 8;

            outputSamples[sampleIndex] = Math.sqrt(real * real + imaginary * imaginary);
        }

        return true;
    }
}
