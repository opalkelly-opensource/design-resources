import { IFrontPanel, ByteCount } from "@opalkellytech/frontpanel-chromium-core";

export class SpectrumAnalyzer {
    private readonly _FrontPanel: IFrontPanel;
    private readonly _SampleSize: ByteCount;
    private readonly _SampleCount: number;

    public get SampleSize() {
        return this._SampleSize;
    }

    public get SampleCount() {
        return this._SampleCount;
    }

    constructor(frontpanel: IFrontPanel, sampleSize: ByteCount, sampleCount: number) {
        this._FrontPanel = frontpanel;
        this._SampleSize = sampleSize;
        this._SampleCount = sampleCount;
    }

    public async ComputeSpectrum(
        sourceSamples: Int16Array,
        outputSamples: Float64Array
    ): Promise<boolean> {
        // Write Samples
        await this._FrontPanel.writeToPipeIn(
            0x80,
            sourceSamples.byteLength,
            (data: ArrayBuffer) => {
                const target: Int16Array = new Int16Array(data);

                target.set(sourceSamples);
            }
        );

        // Check for program empty
        await this._FrontPanel.updateWireOuts();

        let isProgramEmpty: boolean =
            ((await this._FrontPanel.getWireOutValue(0x20)) & 0x10) === 0x10;

        while (isProgramEmpty) {
            await this._FrontPanel.updateWireOuts();

            isProgramEmpty = ((await this._FrontPanel.getWireOutValue(0x20)) & 0x10) === 0x10;
        }

        // Start FFT Calculation
        await this._FrontPanel.activateTriggerIn(0x40, 2);

        // Wait for program full
        let isProgramFull: boolean = ((await this._FrontPanel.getWireOutValue(0x20)) & 0x8) === 0x8;

        while (!isProgramFull) {
            await this._FrontPanel.updateWireOuts();

            isProgramFull = ((await this._FrontPanel.getWireOutValue(0x20)) & 0x8) === 0x8;
        }

        // Read via pipe poa1
        const outputDataSize: ByteCount = this._SampleSize * this._SampleCount; // Each sample has two components (real, imaginary)

        const outputData: ArrayBuffer = await this._FrontPanel.readFromPipeOut(
            0xa1,
            outputDataSize
        );

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
