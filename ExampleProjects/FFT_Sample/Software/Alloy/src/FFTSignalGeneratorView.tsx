/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component, ReactNode } from "react";

import "./FFTSignalGeneratorView.css";

import FrequencyVectorComponent from "./FrequencyVectorComponent";

import FFTConfiguration from "./FFTConfiguration";

import {
    FFTSignalGenerator,
    FFTSignalGeneratorState,
    FFTSignalGeneratorStateChangeEventArgs
} from "./FFTSignalGenerator";

import { FFTSignalGeneratorAdapter, FrequencyVector } from "./FFTSignalGeneratorAdapter";

import ListItemComponent from "./ListItemComponent";

import { IFrontPanel, WorkQueue } from "@opalkelly/frontpanel-alloy-core";

import { Button, ToggleState, ToggleSwitch } from "@opalkelly/frontpanel-react-components";

import { Subscription } from "sub-events";

/**
 * Type representing the state of a Frequency Vector.
 */
type FrequencyVectorState = {
    vector: FrequencyVector;
    isEnabled: boolean;
};

/**
 * FFT Signal Generator View Properties
 */
interface FFTSignalGeneratorViewProps {
    label: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
}

/**
 * FFT Signal Generator View State
 */
interface FFTSignalGeneratorViewState {
    frequencyVectors: FrequencyVectorState[];
    isAutoScaleEnabled: boolean;
    isOperationPending: boolean;
    amplitudeScaleFactor: number;
}

/**
 * FFT Signal Generator View component used to configure the FFT Signal Generator.
 */
class FFTSignalGeneratorView extends Component<
    FFTSignalGeneratorViewProps,
    FFTSignalGeneratorViewState
> {
    private readonly _SignalGenerator: FFTSignalGenerator;
    private readonly _SignalGeneratorAdapter: FFTSignalGeneratorAdapter;

    private _SignalGeneratorStateChangeEventSubscription: Subscription | null = null;

    protected get WorkQueue(): WorkQueue {
        return this.props.workQueue;
    }

    constructor(props: FFTSignalGeneratorViewProps) {
        super(props);

        // Create FFT Signal Generator
        const fftLength = 1024; // 1024 bin FFT Length
        const sampleRate = 125000000; // 125MHz Sample Rate
        const maxAmplitudeValue = 0x1fffff;
        //TODO: Check this value
        //const maxAmplitudeValue = 0x7ffff;      // 19 bits

        const fftConfiguration = new FFTConfiguration(fftLength, sampleRate, maxAmplitudeValue);
        const retryCount = 100;

        this._SignalGenerator = new FFTSignalGenerator(
            props.frontpanel,
            fftConfiguration,
            retryCount
        );
        this._SignalGeneratorAdapter = new FFTSignalGeneratorAdapter(this._SignalGenerator);

        // Set Initial State
        const frequencyVectors: FrequencyVectorState[] = [];

        frequencyVectors.push({ isEnabled: false, vector: { bin: 1, amplitude: -1 } });
        frequencyVectors.push({ isEnabled: false, vector: { bin: 2, amplitude: -7 } });
        frequencyVectors.push({ isEnabled: false, vector: { bin: 18, amplitude: -28 } });
        frequencyVectors.push({ isEnabled: false, vector: { bin: 1, amplitude: 0 } });

        this.state = {
            frequencyVectors: frequencyVectors,
            isAutoScaleEnabled: true,
            isOperationPending: false,
            amplitudeScaleFactor: 1.0
        };
    }

    componentDidMount(): void {
        this.setState({
            isOperationPending:
                this._SignalGenerator.State === FFTSignalGeneratorState.InitializePending ||
                this._SignalGenerator.State === FFTSignalGeneratorState.ResetPending
        });

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
            <Button
                label="Initialize"
                onButtonDown={this.Initialize.bind(this)}
                disabled={this.state.isOperationPending}
            />
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
                    <Button
                        label="Reset"
                        onButtonDown={this.Reset.bind(this)}
                        disabled={this.state.isOperationPending}
                    />
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
                                frequency={this._SignalGenerator.FFTConfiguration.GetBinFrequency(
                                    item.vector.bin
                                )}
                                vector={item.vector}
                                onVectorChange={this.OnFrequencyVectorChange.bind(this)}
                            />
                        </ListItemComponent>
                    ))}
                </div>
            </div>
        );
    }

    /**
     * Initialize the FFT Signal Generator.
     * @returns A Promise that resolves when the FFT Signal Generator has been initialized.
     */
    public async Initialize(): Promise<void> {
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
            this._SignalGeneratorAdapter.AddFrequencyVector(vector)
        );

        // Update the Signal Generator Frequency Bins
        const start: number = performance.now();

        await this.WorkQueue.Post(async () => {
            await this._SignalGeneratorAdapter.UpdateFrequencyBins(false);
        });

        const elapsed: number = performance.now() - start;

        console.log("Initialize Frequency Bins ElapsedTime=" + elapsed + "ms");
    }

    /**
     * Reset the FFT Signal Generator.
     * @returns A Promise that resolves when the FFT Signal Generator has been reset.
     */
    public async Reset(): Promise<void> {
        await this.WorkQueue.Post(async () => {
            await this._SignalGeneratorAdapter.Reset();
        });

        // Reset the state of all the Frequency Vectors
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

    /**
     * Remove a Frequency Vector from the output of the signal generator.
     * @param vector - Frequency Vector to remove from the output of the signal generator.
     * @returns A Promise that resolves when the Frequency Vector has been removed.
     */
    private async RemoveFrequencyVector(vector: FrequencyVector): Promise<void> {
        let amplitudeScaleFactor: number = this._SignalGeneratorAdapter.AmplitudeScaleFactor;

        await this.WorkQueue.Post(async () => {
            await this._SignalGeneratorAdapter.RemoveFrequencyVector(vector);

            amplitudeScaleFactor = await this._SignalGeneratorAdapter.UpdateFrequencyBins(
                this.state.isAutoScaleEnabled
            );
        });

        this.setState({ amplitudeScaleFactor: amplitudeScaleFactor });
    }

    /**
     * Adds or removes a Frequency Vector from the output of the signal generator based
     * on the specified isEnabled flag.
     * @param vector - Frequency Vector to add or remove from the output of the signal generator.
     * @param isEnabled - Flag indicating whether the Frequency Vector should be added or removed.
     * @returns A Promise that resolves when the Frequency Vector has been added or removed.
     */
    private async EnableFrequencyVector(
        vector: FrequencyVector,
        isEnabled: boolean
    ): Promise<void> {
        let amplitudeScaleFactor: number = this._SignalGeneratorAdapter.AmplitudeScaleFactor;

        await this.WorkQueue.Post(async () => {
            if (isEnabled) {
                this._SignalGeneratorAdapter.AddFrequencyVector(vector);
            } else {
                await this._SignalGeneratorAdapter.RemoveFrequencyVector(vector);
            }

            amplitudeScaleFactor = await this._SignalGeneratorAdapter.UpdateFrequencyBins(
                this.state.isAutoScaleEnabled
            );
        });

        this.setState({ amplitudeScaleFactor: amplitudeScaleFactor });
    }

    /**
     * Updates an existing Frequency Vector with a new Frequency Vector.
     * @param newVector - New Frequency Vector to update the existing Frequency Vector.
     * @param previousVector - Existing Frequency Vector to update.
     * @returns A Promise that resolves when the Frequency Vector has been updated.
     */
    private async UpdateFrequencyVector(
        newVector: FrequencyVector,
        previousVector: FrequencyVector
    ): Promise<void> {
        let amplitudeScaleFactor: number = this._SignalGeneratorAdapter.AmplitudeScaleFactor;

        await this.WorkQueue.Post(async () => {
            await this._SignalGeneratorAdapter.RemoveFrequencyVector(previousVector);

            this._SignalGeneratorAdapter.AddFrequencyVector(newVector);

            amplitudeScaleFactor = await this._SignalGeneratorAdapter.UpdateFrequencyBins(
                this.state.isAutoScaleEnabled
            );
        });

        this.setState({ amplitudeScaleFactor: amplitudeScaleFactor });
    }

    /**
     * Formats the string representation of a decibel value.
     * @param value - Decibel value to format.
     * @returns String representation of the decibel value.
     */
    private FormatDecibelString(value: number): string {
        const decibelValue: number = 20.0 * Math.log10(value);

        return decibelValue.toPrecision(3) + " dB";
    }

    /**
     * Event handler that appends a new Frequency Vector with an initial state.
     */
    private OnAddFrequencyVector(): void {
        this.setState((previousState: FFTSignalGeneratorViewState) => {
            const newFrequencyVectors: FrequencyVectorState[] =
                previousState.frequencyVectors.slice();

            newFrequencyVectors.push({ isEnabled: false, vector: { bin: 1, amplitude: 0.0 } });

            return { frequencyVectors: newFrequencyVectors };
        });
    }

    /**
     * Event handler that removes a Frequency Vector from the output of the signal generator.
     * @param vectorId - Identifier of the Frequency Vector to remove.
     * @returns A Promise that resolves when the Frequency Vector has been removed.
     */
    private async OnRemoveFrequencyVector(vectorId: number): Promise<void> {
        this.setState((previousState: FFTSignalGeneratorViewState) => {
            const newFrequencyVectors: FrequencyVectorState[] =
                previousState.frequencyVectors.slice();

            newFrequencyVectors
                .splice(vectorId, 1)
                .forEach((vectorState: FrequencyVectorState) =>
                    this.RemoveFrequencyVector(vectorState.vector)
                );

            return { frequencyVectors: newFrequencyVectors };
        });
    }

    /**
     * Event handler that updates a Frequency Vector with a new Frequency Vector.
     * @param vectorId - Identifier of the Frequency Vector to update.
     * @param vector - New Frequency Vector to update the existing Frequency Vector.
     * @returns A Promise that resolves when the Frequency Vector has been updated.
     */
    private async OnFrequencyVectorChange(vectorId: number, vector: FrequencyVector) {
        this.setState((previousState: FFTSignalGeneratorViewState) => {
            const previousVector: FrequencyVector = previousState.frequencyVectors[vectorId].vector;

            const newFrequencyVectors: FrequencyVectorState[] =
                previousState.frequencyVectors.slice();

            newFrequencyVectors[vectorId].vector = vector;

            if (newFrequencyVectors[vectorId].isEnabled) {
                this.UpdateFrequencyVector(newFrequencyVectors[vectorId].vector, previousVector);
            }

            return { frequencyVectors: newFrequencyVectors };
        });
    }

    /**
     * Event handler that updates the isEnabled state of a Frequency Vector.
     * @param vectorId - Identifier of the Frequency Vector to update.
     * @param isEnabled - New state of the isEnabled flag.
     * @returns A Promise that resolves when the isEnabled state of the Frequency Vector has been updated.
     */
    private async OnFrequencyVectorIsEnabledChange(vectorId: number, isEnabled: boolean) {
        this.setState((previousState: FFTSignalGeneratorViewState) => {
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

    /**
     * Event handler that is called when the state of the Signal Generator changes.
     * @param args - Event arguments containing the previous and new state of the Signal Generator.
     */
    private OnSignalGeneratorStateChange(args: FFTSignalGeneratorStateChangeEventArgs): void {
        this.setState({
            isOperationPending:
                args.newState === FFTSignalGeneratorState.InitializePending ||
                args.newState === FFTSignalGeneratorState.ResetPending
        });

        console.log("SignalGenerator State: " + args.previousState + " => " + args.newState);
    }

    /**
     * Event handler that is called when the AutoScale state changes.
     * @param state - New state of the AutoScale switch.
     */
    private async OnUpdateAutoScaleChange(state: ToggleState): Promise<void> {
        let amplitudeScaleFactor: number = this._SignalGeneratorAdapter.AmplitudeScaleFactor;

        await this.WorkQueue.Post(async () => {
            amplitudeScaleFactor = await this._SignalGeneratorAdapter.UpdateFrequencyBins(
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
