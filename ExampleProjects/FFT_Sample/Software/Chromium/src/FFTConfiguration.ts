export type binNumber = number;
export type hertz = number;

class FFTConfiguration {
    private readonly _FFTLength: number;
    private readonly _SampleRate: hertz;
    private readonly _MaximumAmplitudeValue: number;

    public get FFTLength() {
        return this._FFTLength;
    }

    public get SampleRate() {
        return this._SampleRate;
    }

    public get MaximumAmplitudeValue() {
        return this._MaximumAmplitudeValue;
    }

    constructor(fftLength: number, sampleRate: hertz, maximumAmplitudeValue: number) {
        this._FFTLength = fftLength;
        this._SampleRate = sampleRate;
        this._MaximumAmplitudeValue = maximumAmplitudeValue;
    }

    public GetBinFrequency(bin: binNumber): hertz {
        return this._SampleRate * (bin / this._FFTLength);
    }
}

export default FFTConfiguration;
