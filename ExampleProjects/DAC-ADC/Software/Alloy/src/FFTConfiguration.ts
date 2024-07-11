/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 * Type representing a bin number in an FFT.
 */
export type BinNumber = number;

/**
 * Type representing a frequency in hertz.
 */
export type Hertz = number;

/**
 * Configuration for an FFT.
 */
class FFTConfiguration {
    private readonly _FFTLength: number;
    private readonly _SampleRate: Hertz;
    private readonly _MaximumAmplitudeValue: number;

    /**
     * Get the length of the FFT.
     */
    public get FFTLength() {
        return this._FFTLength;
    }

    /**
     * Get the sample rate of the FFT in hertz.
     */
    public get SampleRate() {
        return this._SampleRate;
    }

    /**
     * Get the maximum amplitude value of the FFT.
     */
    public get MaximumAmplitudeValue() {
        return this._MaximumAmplitudeValue;
    }

    constructor(fftLength: number, sampleRate: Hertz, maximumAmplitudeValue: number) {
        this._FFTLength = fftLength;
        this._SampleRate = sampleRate;
        this._MaximumAmplitudeValue = maximumAmplitudeValue;
    }

    /**
     * Computes the frequency corresponding to the specified bin.
     * @param bin - Bin number of the bin to query.
     * @returns Frequency corresponding to the specified bin in hertz.
     */
    public GetBinFrequency(bin: BinNumber): Hertz {
        return this._SampleRate * (bin / this._FFTLength);
    }
}

export default FFTConfiguration;
