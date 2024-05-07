/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { FFTSignalGenerator, FrequencyBin } from "./FFTSignalGenerator";

import { BinNumber } from "./FFTConfiguration";

export type dBFS = number;

/**
 * Frequency Vector that contains a frequency bin number and an amplitude value.
 */
export type FrequencyVector = {
    bin: BinNumber;
    amplitude: dBFS;
};

/**
 * TODO: Rename this Class
 * Signal Generator that outputs a set of frequency bins
 */
export class FFTSignalGenerator2 {
    private readonly _SignalGenerator: FFTSignalGenerator;

    private readonly _FrequencyBinMap: Map<BinNumber, FrequencyBin> = new Map<
        BinNumber,
        FrequencyBin
    >();

    private _AmplitudeScaleFactor = 1.0;

    /**
     * Get the amplitude scale factor that was used to scale the amplitudes of the frequency bins.
     */
    public get AmplitudeScaleFactor() {
        return this._AmplitudeScaleFactor;
    }

    /**
     * Creates a new instance of the FFTSignalGenerator2 class.
     * @param signalGenerator - TODO:
     */
    constructor(signalGenerator: FFTSignalGenerator) {
        this._SignalGenerator = signalGenerator;
    }

    /**
     * Add a Frequency Vector to be output by the signal generator. If a Fequency Vector with matching bin number already exists, then
     * the amplitude of the specified vector will be added to the amplitude of the existing vector.
     * @param vector Frequency Vector to add to the output of the signal generator.
     */
    public AddFrequencyVector(vector: FrequencyVector): void {
        // Retrieve the Frequency Bin
        let targetFrequencyBin: FrequencyBin | undefined = this._FrequencyBinMap.get(vector.bin);

        if (targetFrequencyBin === undefined) {
            // Target frequency bin does not exist, then create it
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
            // Target frequency bin does exist, then add the amplitude of the source vector to the target bin
            targetFrequencyBin.amplitude += FFTSignalGenerator2.GetAmplitudeValue(vector.amplitude);

            console.log(
                "Update FrequencyBin Number=" +
                    targetFrequencyBin.number +
                    " Amplitude=" +
                    targetFrequencyBin.amplitude
            );
        }
    }

    /**
     * Remove a Frequency Vector from the output of the signal generator by subtracting the amplitude of the specified vector.
     * @param vector Frequency Vector to remove from the output of the signal generator.
     * @returns Promise that resolves to true if the Frequency Vector was removed, otherwise false.
     */
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

    /**
     * Updates the Frequency Vectors that are output by the signal generator to scale their amplitude using a scale factor. If the
     * autoscale parameter is true, then the amplitude scale factor will be automatically computed. Otherwise, the amplitude scale factor
     * will be set to 1.0.
     * @param autoscale - If true, then the amplitude scale factor will be computed automatically.
     * @returns Promise that resolves to the value of the amplitude scale factor.
     */
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

    /**
     * Computes the amplitude scale factor necessary so that the sum of all the amplitudes of the frequency bins is less than or equal to 1.0.
     * @returns The amplitude scale factor that is computed.
     */
    private ComputeAmplitudeScaleFactor(): number {
        let amplitudeSum = 0;

        this._FrequencyBinMap.forEach((value) => {
            amplitudeSum += value.amplitude;
        });

        // If the sum of the amplitudes is greater than 1.0, then we need to scale the amplitudes
        return amplitudeSum > 1.0 ? 1.0 / amplitudeSum : 1.0;
    }

    /**
     * Converts a dBFS value to an amplitude value.
     * @param value - The dBFS value to convert.
     * @returns The amplitude value that is computed.
     */
    private static GetAmplitudeValue(value: dBFS): number {
        if (value === 0) {
            return 1.0;
        } else {
            return Math.pow(10, value / 20);
        }
    }
}
