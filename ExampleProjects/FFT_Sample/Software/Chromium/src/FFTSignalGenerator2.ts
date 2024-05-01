import { FFTSignalGenerator, FrequencyBin, FrequencyBinNumber, dBFS } from "./FFTSignalGenerator";

export type FrequencyVector = {
    bin: FrequencyBinNumber;
    amplitude: dBFS;
};

export class FFTSignalGenerator2 {
    private readonly _SignalGenerator: FFTSignalGenerator;

    private readonly _FrequencyBinMap: Map<FrequencyBinNumber, FrequencyBin> = new Map<
        FrequencyBinNumber,
        FrequencyBin
    >();

    private _AmplitudeScaleFactor = 1.0;

    public get AmplitudeScaleFactor() {
        return this._AmplitudeScaleFactor;
    }

    constructor(signalGenerator: FFTSignalGenerator) {
        this._SignalGenerator = signalGenerator;
    }

    public AddFrequencyVector(vector: FrequencyVector): void {
        // Retrieve the Frequency Bin
        let targetFrequencyBin: FrequencyBin | undefined = this._FrequencyBinMap.get(vector.bin);

        if (targetFrequencyBin === undefined) {
            targetFrequencyBin = {
                number: vector.bin,
                amplitude: FFTSignalGenerator2.GetAmplitudeValue(vector.amplitude)
            };

            this._FrequencyBinMap.set(targetFrequencyBin.number, targetFrequencyBin);

            console.log(
                "Add FrequencyBin Number=" +
                    targetFrequencyBin.number +
                    " Amplitude=" +
                    targetFrequencyBin.amplitude
            );
        } else {
            // Add the amplitude of the source vector to the target bin
            targetFrequencyBin.amplitude += FFTSignalGenerator2.GetAmplitudeValue(vector.amplitude);

            console.log(
                "Update FrequencyBin Number=" +
                    targetFrequencyBin.number +
                    " Amplitude=" +
                    targetFrequencyBin.amplitude
            );
        }
    }

    public async RemoveFrequencyVector(vector: FrequencyVector): Promise<boolean> {
        let retval: boolean;

        // Retrieve the target FrequencyBin
        const targetFrequencyBin: FrequencyBin | undefined = this._FrequencyBinMap.get(vector.bin);

        if (targetFrequencyBin !== undefined) {
            // Subtract the amplitude of the source vector from the target bin
            targetFrequencyBin.amplitude -= FFTSignalGenerator2.GetAmplitudeValue(vector.amplitude);

            console.log(
                "Update FrequencyBin Number=" +
                    targetFrequencyBin.number +
                    " Amplitude=" +
                    targetFrequencyBin.amplitude
            );

            if (targetFrequencyBin.amplitude <= 0) {
                await this._SignalGenerator.ClearBins([targetFrequencyBin.number]);

                retval = this._FrequencyBinMap.delete(targetFrequencyBin.number);

                console.log(
                    "Remove FrequencyBin Number=" +
                        targetFrequencyBin.number +
                        " Amplitude=" +
                        targetFrequencyBin.amplitude
                );
            } else {
                retval = true;
            }
        } else {
            retval = false;
        }

        return retval;
    }

    public async UpdateFrequencyBins(autoscale: boolean): Promise<number> {
        if (autoscale) {
            // Compute the amplitude scale factor
            this._AmplitudeScaleFactor = this.ComputeAmplitudeScaleFactor();
        } else {
            this._AmplitudeScaleFactor = 1.0;
        }

        // Set the bin registers
        await this._SignalGenerator.SetBins(
            Array.from(this._FrequencyBinMap.values()),
            this._AmplitudeScaleFactor
        );

        return this._AmplitudeScaleFactor;
    }

    //
    private ComputeAmplitudeScaleFactor(): number {
        let amplitudeSum = 0;

        this._FrequencyBinMap.forEach((value) => {
            amplitudeSum += value.amplitude;
        });

        // If the sum of the amplitudes is greater than 1.0, then we need to scale the amplitudes
        return amplitudeSum > 1.0 ? 1.0 / amplitudeSum : 1.0;
    }

    private static GetAmplitudeValue(value: dBFS): number {
        if (value === 0) {
            return 1.0;
        } else {
            return Math.pow(10, value / 20);
        }
    }
}
