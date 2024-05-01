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

import { WorkQueue, ByteCount, IFrontPanel } from "@opalkellytech/frontpanel-chromium-core";

import { Button, ToggleSwitch, ToggleState } from "@opalkellytech/frontpanel-react-components";

export type SampleChannelsUpdateEventHandler = (sampleChannels: Int16Array[]) => Promise<void>;

interface DigitalSignalSamplerViewProps {
    label: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
    updatePeriodMilliseconds: number;
    onSampleChannelsUpdate: SampleChannelsUpdateEventHandler;
}

interface DigitalSignalSamplerViewState {
    statusMessage: string;
    isUpdateTimerEnabled: boolean;
}

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

        const sampleSize: ByteCount = 4;
        const sampleCount = 1024;

        this._Sampler = new DigitalSignalSampler(props.frontpanel, sampleSize, sampleCount);

        //
        this._SampleChannels = new Array(2);

        this._SampleChannels[0] = new Int16Array(this._Sampler.SampleCount);
        this._SampleChannels[1] = new Int16Array(this._Sampler.SampleCount);

        ChartJS.register(LinearScale, PointElement, LineElement, Title, Legend);

        this._ChartRef = React.createRef();

        this._ChartOptions = {
            animation: false,
            responsive: true,
            maintainAspectRatio: false,
            //aspectRatio: 1.0,
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
                    borderColor: "rgb(255, 99, 132)",
                    backgroundColor: "rgba(255, 99, 132, 0.5)"
                },
                {
                    label: "Channel 2",
                    data: channels[1],
                    borderColor: "rgb(53, 162, 235)",
                    backgroundColor: "rgba(53, 162, 235, 0.5)"
                }
            ]
        };

        this.state = {
            statusMessage: this.GetStatusMessage(this._Sampler.State),
            isUpdateTimerEnabled: false
        };
    }

    componentDidMount(): void {
        this._SamplerStateChangeEventSubscription = this._Sampler.StateChangedEvent.subscribe(
            this.OnSamplerStateChange.bind(this)
        );
    }

    componentWillUnmount(): void {
        this._SamplerStateChangeEventSubscription?.cancel();
    }

    render(): ReactNode {
        return (
            <div className="okDigitalSignalSampler">
                <div className="okDigitalSignalSamplerControlPanel">
                    <Button label="Reset" onButtonDown={this.Reset.bind(this)} />
                    <ToggleSwitch
                        label="Start"
                        state={this.state.isUpdateTimerEnabled ? ToggleState.On : ToggleState.Off}
                        onToggleStateChanged={this.ToggleChartDataUpdateTimer.bind(this)}
                    />
                    <Button label="Sample" onButtonDown={this.UpdateChartData.bind(this)} />
                    {/*<Text>{this.state.statusMessage}</Text>*/}
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

    private async Reset(): Promise<void> {
        await this.WorkQueue.Post(async () => {
            await this._Sampler.Reset();
        });
    }

    private ToggleChartDataUpdateTimer(state: ToggleState) {
        this.setState(() => {
            if (state == ToggleState.On) {
                this.UpdateChartDataLoop();
            }

            return { isUpdateTimerEnabled: state == ToggleState.On };
        });
    }

    private async UpdateChartDataLoop(): Promise<void> {
        const start: number = performance.now();

        await this.UpdateChartData();

        const elapsed: number = performance.now() - start;

        //console.log("UpdateChartData ElapsedTime=" + elapsed + "ms");

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

    private async UpdateChartData(): Promise<void> {
        //console.log("DigitalSignalSampler::UpdateChartData")

        //const start: number = performance.now();

        await this.WorkQueue.Post(async () => {
            await this._Sampler.ReadSamples(this._SampleChannels);
        });

        //const elapsed: number = performance.now() - start;

        //console.log("DigitalSignalSampler::ReadSamples ElapsedTime=" + elapsed + "ms");

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

    private GetStatusMessage(state: DigitalSignalSamplerState): string {
        let message: string;

        switch (state) {
            case DigitalSignalSamplerState.Initial:
                message = "Initial";
                break;
            case DigitalSignalSamplerState.InitializePending:
                message = "Initializing...";
                break;
            case DigitalSignalSamplerState.InitializationComplete:
                message = "Ready";
                break;
            case DigitalSignalSamplerState.InitializationFailed:
                message = "Initialization Failed";
                break;
            case DigitalSignalSamplerState.ResetPending:
                message = "Resetting...";
                break;
            case DigitalSignalSamplerState.ResetComplete:
                message = "Ready";
                break;
            case DigitalSignalSamplerState.ResetFailed:
                message = "Reset Failed";
                break;
            default:
                message = "None";
                break;
        }

        return message;
    }

    // Event Handlers
    private OnSamplerStateChange(args: DigitalSignalSamplerStateChangeEventArgs): void {
        const message: string = this.GetStatusMessage(args.newState);

        console.log("Sampler State: " + args.previousState + " => " + args.newState);

        this.setState({ statusMessage: message });
    }
}

export default DigitalSignalSamplerView;
