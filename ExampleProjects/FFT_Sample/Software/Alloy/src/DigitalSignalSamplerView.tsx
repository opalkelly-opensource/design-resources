/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component, ReactNode } from "react";

import "./DigitalSignalSamplerView.css";

import {
    Chart as ChartJS,
    LinearScale,
    PointElement,
    LineElement,
    Title,
    Legend,
    ChartOptions
} from "chart.js";

import { Line } from "react-chartjs-2";

import { Subscription } from "sub-events";

import {
    DigitalSignalSampler,
    DigitalSignalSamplerState,
    DigitalSignalSamplerStateChangeEventArgs
} from "./DigitalSignalSampler";

import { Vector2D } from "./Vector";

import { WorkQueue, ByteCount, IFrontPanel } from "@opalkelly/frontpanel-alloy-core";

import { Button, ToggleSwitch, ToggleState } from "@opalkelly/frontpanel-react-components";

/**
 * Event handler for the SampleChannelsUpdate event.
 */
export type SampleChannelsUpdateEventHandler = (sampleChannels: Int16Array[]) => Promise<void>;

/**
 * Digital Signal Sampler View Properties
 */
interface DigitalSignalSamplerViewProps {
    label: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
    updatePeriodMilliseconds: number;
    onSampleChannelsUpdate: SampleChannelsUpdateEventHandler;
}

/**
 * Digital Signal Sampler View State
 */
interface DigitalSignalSamplerViewState {
    isOperationPending: boolean;
    isUpdateTimerEnabled: boolean;
}

/**
 * Digital Signal Sampler view component used to display the output of a Digital Signal Sampler.
 */
class DigitalSignalSamplerView extends Component<
    DigitalSignalSamplerViewProps,
    DigitalSignalSamplerViewState
> {
    private readonly _Sampler: DigitalSignalSampler;

    private readonly _SampleChannels: Int16Array[];

    private _ChartRef: React.RefObject<ChartJS<"line">>;
    private _ChartOptions: ChartOptions<"line">;
    private _ChartData;

    private _SamplerStateChangeEventSubscription: Subscription | null = null;

    protected get WorkQueue(): WorkQueue {
        return this.props.workQueue;
    }

    constructor(props: DigitalSignalSamplerViewProps) {
        super(props);

        // Create Digital Signal Sampler
        const sampleSize: ByteCount = 4;
        const sampleCount = 1024;

        this._Sampler = new DigitalSignalSampler(props.frontpanel, sampleSize, sampleCount);

        // Creates an array of two Int16Array objects one for each of the two channels available.
        this._SampleChannels = new Array(2);

        this._SampleChannels[0] = new Int16Array(this._Sampler.SampleCount);
        this._SampleChannels[1] = new Int16Array(this._Sampler.SampleCount);

        // Create ChartJS Chart Reference to display the output of the Digital Signal Sampler
        ChartJS.register(LinearScale, PointElement, LineElement, Title, Legend);

        this._ChartRef = React.createRef();

        this._ChartOptions = {
            animation: false,
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                x: {
                    type: "linear",
                    min: 0.0,
                    max: 1024.0
                },
                y: {
                    type: "linear",
                    min: -8192,
                    max: 8192
                }
            },
            plugins: {
                legend: {
                    position: "bottom" as const
                },
                title: {
                    display: false,
                    text: "Output Signal"
                }
            }
        };

        // Create Chart Data that will be displayed by the ChartJS Chart
        const channels: Vector2D[][] = Array(2);

        channels[0] = new Array<Vector2D>(this._Sampler.SampleCount)
            .fill({ x: 0.0, y: 0.0 })
            .map(() => ({ x: 0.0, y: 0.0 }));
        channels[1] = new Array<Vector2D>(this._Sampler.SampleCount)
            .fill({ x: 0.0, y: 0.0 })
            .map(() => ({ x: 0.0, y: 0.0 }));

        this._ChartData = {
            datasets: [
                {
                    label: "Channel 1",
                    data: channels[0],
                    pointRadius: 0,
                    borderColor: "rgb(255, 99, 132)",
                    backgroundColor: "rgba(255, 99, 132, 0.5)"
                },
                {
                    label: "Channel 2",
                    data: channels[1],
                    pointRadius: 0,
                    borderColor: "rgb(53, 162, 235)",
                    backgroundColor: "rgba(53, 162, 235, 0.5)"
                }
            ]
        };

        // Set the initial state of the component
        this.state = {
            isOperationPending: false,
            isUpdateTimerEnabled: false
        };
    }

    componentDidMount(): void {
        this.setState({
            isOperationPending:
                this._Sampler.State === DigitalSignalSamplerState.InitializePending ||
                this._Sampler.State === DigitalSignalSamplerState.ResetPending
        });

        this._SamplerStateChangeEventSubscription = this._Sampler.StateChangedEvent.subscribe(
            this.OnSamplerStateChange.bind(this)
        );

        this.OnReset();
    }

    componentWillUnmount(): void {
        this.setState({ isUpdateTimerEnabled: false });

        this._SamplerStateChangeEventSubscription?.cancel();
    }

    render(): ReactNode {
        return (
            <div className="okDigitalSignalSampler">
                <div className="okDigitalSignalSamplerControlPanel">
                    <ToggleSwitch
                        label="Enabled"
                        state={this.state.isUpdateTimerEnabled ? ToggleState.On : ToggleState.Off}
                        onToggleStateChanged={this.OnToggleChartDataUpdateTimer.bind(this)}
                        disabled={this.state.isOperationPending}
                    />
                    <Button
                        label="Sample"
                        onButtonDown={this.UpdateChartData.bind(this)}
                        disabled={this.state.isOperationPending}
                    />
                    <Button
                        label="Reset"
                        onButtonDown={this.OnReset.bind(this)}
                        disabled={this.state.isOperationPending}
                    />
                </div>
                <div className="okDigitalSignalSamplerChartPanel">
                    <div className="okDigitalSignalChartContainer">
                        <Line
                            ref={this._ChartRef}
                            options={this._ChartOptions}
                            data={this._ChartData}
                        />
                    </div>
                </div>
            </div>
        );
    }

    /**
     * Event handler for the Resetting.
     * @returns Promise that resolves when the Digital Signal Sampler has been reset.
     */
    private async OnReset(): Promise<void> {
        await this.WorkQueue.Post(async () => {
            await this._Sampler.Reset();
        });

        // Start the periodic update timer if it is not already running.
        if (!this.state.isUpdateTimerEnabled) {
            this.OnToggleChartDataUpdateTimer(ToggleState.On);
        }
    }

    /**
     * Event handler for the Starting and Stoping the periodic update timer.
     * @param state - New state of the ToggleSwitch.
     */
    private OnToggleChartDataUpdateTimer(state: ToggleState) {
        this.setState(() => {
            if (state == ToggleState.On) {
                this.UpdateChartDataLoop();
            }

            return { isUpdateTimerEnabled: state === ToggleState.On };
        });
    }

    /**
     * Loop that periodically reads samples from the Digital Signal Sampler and updates the
     * Chart with the new data.
     */
    private async UpdateChartDataLoop(): Promise<void> {
        const start: number = performance.now();

        await this.UpdateChartData();

        const elapsed: number = performance.now() - start;

        if (this.state.isUpdateTimerEnabled) {
            const delay: number = this.props.updatePeriodMilliseconds - elapsed;

            setTimeout(
                async () => {
                    await this.UpdateChartDataLoop();
                },
                delay > 10 ? delay : 10
            );
        }
    }

    /**
     * Reads samples from the Digital Signal Sampler and updates the Chart with the new data.
     * @returns Promise that resolves when the Chart has been updated with the new data.
     */
    private async UpdateChartData(): Promise<void> {
        await this.WorkQueue.Post(async () => {
            await this._Sampler.ReadSamples(this._SampleChannels);
        });

        for (let sampleIndex = 0; sampleIndex < this._SampleChannels[0].length; sampleIndex++) {
            this._ChartData.datasets[0].data[sampleIndex].x = sampleIndex;
            this._ChartData.datasets[0].data[sampleIndex].y = this._SampleChannels[0][sampleIndex];
        }

        for (let sampleIndex = 0; sampleIndex < this._SampleChannels[1].length; sampleIndex++) {
            this._ChartData.datasets[1].data[sampleIndex].x = sampleIndex;
            this._ChartData.datasets[1].data[sampleIndex].y = this._SampleChannels[1][sampleIndex];
        }

        if (this._ChartRef.current != null) {
            this._ChartRef.current.update();
        }

        return this.props.onSampleChannelsUpdate(this._SampleChannels);
    }

    /**
     * Event handler used to monitor the state of the Digital Signal Sampler.
     * @param args - Event arguments detailing the state transition.
     */
    private OnSamplerStateChange(args: DigitalSignalSamplerStateChangeEventArgs): void {
        this.setState({
            isOperationPending:
                args.newState === DigitalSignalSamplerState.InitializePending ||
                args.newState === DigitalSignalSamplerState.ResetPending
        });

        console.log("Sampler State: " + args.previousState + " => " + args.newState);
    }
}

export default DigitalSignalSamplerView;
