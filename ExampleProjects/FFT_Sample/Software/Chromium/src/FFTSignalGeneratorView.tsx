import React, { Component, ReactNode } from "react";

import "./FFTSignalGeneratorView.css";

import FrequencyVectorComponent from "./FrequencyVectorComponent";

import {
    FFTSignalGenerator,
    FFTSignalGeneratorState,
    FFTSignalGeneratorStateChangeEventArgs,
    hertz
} from "./FFTSignalGenerator";

import { FFTSignalGenerator2, FrequencyVector } from "./FFTSignalGenerator2";

import ListItemComponent from "./ListItemComponent";

import { IFrontPanel, WorkQueue } from "@opalkellytech/frontpanel-chromium-core";

import { Button, ToggleState, ToggleSwitch } from "@opalkellytech/frontpanel-react-components";

import { Subscription } from "sub-events";

type FrequencyVectorState = {
    vector: FrequencyVector;
    isEnabled: boolean;
};

//
interface FFTSignalGeneratorViewProps {
    label: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
}

interface FFTSignalGeneratorViewState {
    frequencyVectors: FrequencyVectorState[];
    isAutoScaleEnabled: boolean;
    statusMessage: string;
    amplitudeScaleFactor: number;
}

class FFTSignalGeneratorView extends Component<
    FFTSignalGeneratorViewProps,
    FFTSignalGeneratorViewState
> {
    private readonly _SignalGenerator: FFTSignalGenerator;
    private readonly _SignalGenerator2: FFTSignalGenerator2;

    private _SignalGeneratorStateChangeEventSubscription: Subscription | null = null;

    protected get WorkQueue(): WorkQueue {
        return this.props.workQueue;
    }

    constructor(props: FFTSignalGeneratorViewProps) {
        super(props);

        const retryCount = 100;

        // Create FFT Signal Generator
        const fftLength = 1024; // 1024 bin FFT Length
        const sampleRate: hertz = 125000000; // 125MHz Sample Rate
        const maxAmplitudeValue = 0x1fffff;
        //const maxAmplitudeValue = 0x7ffff;      // 19 bits

        this._SignalGenerator = new FFTSignalGenerator(
            props.frontpanel,
            fftLength,
            sampleRate,
            maxAmplitudeValue,
            retryCount
        );
        this._SignalGenerator2 = new FFTSignalGenerator2(this._SignalGenerator);

        // Set Initial State
        const frequencyVectors: FrequencyVectorState[] = [];

        frequencyVectors.push({ isEnabled: false, vector: { bin: 1, amplitude: -1 } });
        frequencyVectors.push({ isEnabled: false, vector: { bin: 2, amplitude: -7 } });
        frequencyVectors.push({ isEnabled: false, vector: { bin: 18, amplitude: -28 } });
        frequencyVectors.push({ isEnabled: false, vector: { bin: 1, amplitude: 0 } });

        this.state = {
            frequencyVectors: frequencyVectors,
            isAutoScaleEnabled: true,
            statusMessage: this.FormatStatusMessage(this._SignalGenerator.State),
            amplitudeScaleFactor: 1.0
        };
    }

    componentDidMount(): void {
        this._SignalGeneratorStateChangeEventSubscription =
            this._SignalGenerator.StatechangedEvent.subscribe(
                this.OnSignalGeneratorStateChange.bind(this)
            );

        this.Initialize();
    }

    componentWillUnmount(): void {
        this._SignalGeneratorStateChangeEventSubscription?.cancel();
    }

    render(): ReactNode {
        const initializeButton: ReactNode = (this._SignalGenerator.State ===
            FFTSignalGeneratorState.InitializationFailed ||
            this._SignalGenerator.State === FFTSignalGeneratorState.Initial) ?? (
            <Button label="Initialize" onButtonDown={this.Initialize.bind(this)} />
        );

        const autoscaleText: string =
            "Autoscale " + this.FormatDecibelString(this.state.amplitudeScaleFactor);
        return (
            <div className="okSignalGenerator">
                <div className="okSignalGeneratorControlPanel">
                    <Button label="Add Tone" onButtonDown={this.OnAddFrequencyVector.bind(this)} />
                    <ToggleSwitch
                        label={autoscaleText}
                        state={this.state.isAutoScaleEnabled ? ToggleState.On : ToggleState.Off}
                        onToggleStateChanged={this.OnUpdateAutoScaleChange.bind(this)}
                    />
                    {initializeButton}
                    <Button label="Reset" onButtonDown={this.Reset.bind(this)} />
                    {/*<Text>{this.state.statusMessage}</Text>*/}
                </div>
                <div className="okSignalGeneratorContentPanel">
                    {this.state.frequencyVectors.map((item, i) => (
                        <ListItemComponent
                            className="okSignalGeneratorListItem"
                            key={i}
                            id={i}
                            isEnabled={item.isEnabled}
                            onIsEnabledChange={this.OnFrequencyVectorIsEnabledChange.bind(this)}
                            onRemove={this.OnRemoveFrequencyVector.bind(this)}>
                            <FrequencyVectorComponent
                                id={i}
                                frequency={this._SignalGenerator.GetBinFrequency(item.vector.bin)}
                                vector={item.vector}
                                onVectorChange={this.OnFrequencyVectorChange.bind(this)}
                            />
                        </ListItemComponent>
                    ))}
                </div>
            </div>
        );
    }

    //
    private async Initialize(): Promise<void> {
        await this.WorkQueue.Post(async () => {
            await this._SignalGenerator.Initialize();

            await this._SignalGenerator.Reset();
        });

        // Retrieve the set of enabled Frequency Vectors
        const vectors: FrequencyVector[] = this.state.frequencyVectors
            .filter((value) => value.isEnabled)
            .map((value) => value.vector);

        // Add the Frequency Vectors to the Signal Generator
        vectors.forEach((vector: FrequencyVector) =>
            this._SignalGenerator2.AddFrequencyVector(vector)
        );

        // Update the Signal Generator Frequency Bins
        const start: number = performance.now();

        await this.WorkQueue.Post(async () => {
            await this._SignalGenerator2.UpdateFrequencyBins(false);
        });

        const elapsed: number = performance.now() - start;

        console.log("Initialize Frequency Bins ElapsedTime=" + elapsed + "ms");
    }

    private async Reset(): Promise<void> {
        await this.WorkQueue.Post(async () => {
            await this._SignalGenerator.Reset();
        });

        this.setState((previousState: FFTSignalGeneratorViewState) => {
            const newFrequencyVectors: FrequencyVectorState[] =
                previousState.frequencyVectors.slice();

            for (let vectorIndex = 0; vectorIndex < newFrequencyVectors.length; vectorIndex++) {
                newFrequencyVectors[vectorIndex].isEnabled = false;
                newFrequencyVectors[vectorIndex].vector.bin = 0;
                newFrequencyVectors[vectorIndex].vector.amplitude = 0.0;
            }

            return { frequencyVectors: newFrequencyVectors };
        });
    }

    private async RemoveFrequencyVector(vector: FrequencyVector): Promise<void> {
        let amplitudeScaleFactor: number = this._SignalGenerator2.AmplitudeScaleFactor;

        await this.WorkQueue.Post(async () => {
            await this._SignalGenerator2.RemoveFrequencyVector(vector);

            amplitudeScaleFactor = await this._SignalGenerator2.UpdateFrequencyBins(
                this.state.isAutoScaleEnabled
            );
        });

        this.setState({ amplitudeScaleFactor: amplitudeScaleFactor });
    }

    private async EnableFrequencyVector(
        vector: FrequencyVector,
        isEnabled: boolean
    ): Promise<void> {
        let amplitudeScaleFactor: number = this._SignalGenerator2.AmplitudeScaleFactor;

        await this.WorkQueue.Post(async () => {
            if (isEnabled) {
                this._SignalGenerator2.AddFrequencyVector(vector);
            } else {
                await this._SignalGenerator2.RemoveFrequencyVector(vector);
            }

            amplitudeScaleFactor = await this._SignalGenerator2.UpdateFrequencyBins(
                this.state.isAutoScaleEnabled
            );
        });

        this.setState({ amplitudeScaleFactor: amplitudeScaleFactor });
    }

    private async UpdateFrequencyVector(
        newVector: FrequencyVector,
        previousVector: FrequencyVector
    ): Promise<void> {
        let amplitudeScaleFactor: number = this._SignalGenerator2.AmplitudeScaleFactor;

        await this.WorkQueue.Post(async () => {
            await this._SignalGenerator2.RemoveFrequencyVector(previousVector);

            this._SignalGenerator2.AddFrequencyVector(newVector);

            amplitudeScaleFactor = await this._SignalGenerator2.UpdateFrequencyBins(
                this.state.isAutoScaleEnabled
            );
        });

        this.setState({ amplitudeScaleFactor: amplitudeScaleFactor });
    }

    //
    private FormatStatusMessage(state: FFTSignalGeneratorState): string {
        let message: string;

        switch (state) {
            case FFTSignalGeneratorState.Initial:
                message = "Initial";
                break;
            case FFTSignalGeneratorState.InitializePending:
                message = "Initializing...";
                break;
            case FFTSignalGeneratorState.InitializationComplete:
                message = "Ready";
                break;
            case FFTSignalGeneratorState.InitializationFailed:
                message = "Initialization Failed";
                break;
            case FFTSignalGeneratorState.ResetPending:
                message = "Resetting...";
                break;
            case FFTSignalGeneratorState.ResetComplete:
                message = "Ready";
                break;
            case FFTSignalGeneratorState.ResetFailed:
                message = "Reset Failed";
                break;
            default:
                message = "None";
                break;
        }

        return message;
    }

    private FormatDecibelString(value: number): string {
        const decibelValue: number = 20.0 * Math.log10(value);

        return decibelValue.toPrecision(3) + " dB";
    }

    // Event Handlers
    private OnAddFrequencyVector(): void {
        this.setState((previousState: FFTSignalGeneratorViewState) => {
            const newFrequencyVectors: FrequencyVectorState[] =
                previousState.frequencyVectors.slice();

            newFrequencyVectors.push({ isEnabled: false, vector: { bin: 1, amplitude: 0.0 } });

            return { frequencyVectors: newFrequencyVectors };
        });
    }

    private async OnRemoveFrequencyVector(id: number): Promise<void> {
        this.setState((previousState: FFTSignalGeneratorViewState) => {
            const newFrequencyVectors: FrequencyVectorState[] =
                previousState.frequencyVectors.slice();

            newFrequencyVectors
                .splice(id, 1)
                .forEach((vectorState: FrequencyVectorState) =>
                    this.RemoveFrequencyVector(vectorState.vector)
                );

            return { frequencyVectors: newFrequencyVectors };
        });
    }

    private async OnFrequencyVectorChange(vectorId: number, vector: FrequencyVector) {
        this.setState((previousState: FFTSignalGeneratorViewState) => {
            const previousVector: FrequencyVector = previousState.frequencyVectors[vectorId].vector;

            const newFrequencyVectors: FrequencyVectorState[] =
                previousState.frequencyVectors.slice();

            newFrequencyVectors[vectorId].vector = vector;

            if (newFrequencyVectors[vectorId].isEnabled) {
                console.log(
                    "Freqency Vector Changed (Id=" +
                        vectorId +
                        " [Bin=" +
                        newFrequencyVectors[vectorId].vector.bin +
                        " Amplitude=" +
                        newFrequencyVectors[vectorId].vector.amplitude +
                        " dBFS]" +
                        " <= [Bin=" +
                        previousVector.bin +
                        " Amplitude=" +
                        previousVector.amplitude +
                        " dBFS])"
                );

                this.UpdateFrequencyVector(newFrequencyVectors[vectorId].vector, previousVector);
            }

            return { frequencyVectors: newFrequencyVectors };
        });
    }

    private async OnFrequencyVectorIsEnabledChange(vectorId: number, isEnabled: boolean) {
        this.setState((previousState: FFTSignalGeneratorViewState) => {
            console.log(
                "Freqency Vector Changed (Id=" +
                    vectorId +
                    " [IsEnabled=" +
                    isEnabled +
                    " <= " +
                    previousState.frequencyVectors[vectorId].isEnabled +
                    "])"
            );

            const newFrequencyVectors: FrequencyVectorState[] =
                previousState.frequencyVectors.slice();

            newFrequencyVectors[vectorId].isEnabled = isEnabled;

            this.EnableFrequencyVector(
                newFrequencyVectors[vectorId].vector,
                newFrequencyVectors[vectorId].isEnabled
            );

            return { frequencyVectors: newFrequencyVectors };
        });
    }

    private OnSignalGeneratorStateChange(args: FFTSignalGeneratorStateChangeEventArgs): void {
        const message: string = this.FormatStatusMessage(args.newState);

        console.log("SignalGenerator State: " + args.previousState + " => " + args.newState);

        this.setState({ statusMessage: message });
    }

    private async OnUpdateAutoScaleChange(state: ToggleState): Promise<void> {
        let amplitudeScaleFactor: number = this._SignalGenerator2.AmplitudeScaleFactor;

        await this.WorkQueue.Post(async () => {
            amplitudeScaleFactor = await this._SignalGenerator2.UpdateFrequencyBins(
                state === ToggleState.On
            );
        });

        this.setState({
            isAutoScaleEnabled: state === ToggleState.On,
            amplitudeScaleFactor: amplitudeScaleFactor
        });
    }
}

export default FFTSignalGeneratorView;
