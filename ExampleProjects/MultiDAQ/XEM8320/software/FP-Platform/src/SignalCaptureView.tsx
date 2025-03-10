/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component, ReactNode } from "react";

import "./SignalCaptureView.css";

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

import { SignalCapture, ADCChannelData } from "./SignalCapture";

import { IFrontPanel, WorkQueue } from "@opalkelly/frontpanel-platform-api";

export type Vector2D = {
    x: number;
    y: number;
};

interface SignalCaptureViewProps {
    label: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
}

interface SignalCaptureViewState {
    text: string;
}

class SignalCaptureView extends Component<SignalCaptureViewProps, SignalCaptureViewState> {
    private readonly _SignalCapture: SignalCapture;

    private _ChartRef: React.RefObject<ChartJS<"line">>;
    private _ChartOptions: ChartOptions<"line">;
    private _ChartData;

    private readonly _ChartSamples = 16384;
    private readonly _MaxChannelCount = 8;

    private readonly _FrameSize = 16384;

    private _IsStopPending = false;
    private updatePeriodMilliseconds: number;

    protected get WorkQueue(): WorkQueue {
        return this.props.workQueue;
    }

    constructor(props: SignalCaptureViewProps) {
        super(props);

        const channels: Vector2D[][] = Array(this._MaxChannelCount);
        this.state = { text: "" };
        this.updatePeriodMilliseconds = 100;

        this._SignalCapture = new SignalCapture(props.frontpanel, this._FrameSize);

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
                    max: this._ChartSamples,
                    ticks: { display: true, stepSize: 128 },
                    title: { display: true, text: "Sample Number" }
                },
                y: {
                    type: "linear",
                    min: 0,
                    max: 1.5,
                    ticks: { display: true, stepSize: 0.1 },
                    title: { display: true, text: "Voltage" }
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

        for (let ii = 0; ii < channels.length; ii++) {
            channels[ii] = new Array<Vector2D>(this._SignalCapture.SampleSize)
                .fill({ x: 8192, y: 0.0 })
                .map(() => ({ x: 8192, y: 0.0 }));
        }

        this._ChartData = {
            datasets: [
                {
                    label: "Channel 1",
                    pointRadius: 0,
                    data: channels[0],
                    borderColor: "rgb(255, 0, 0)", // Red
                    backgroundColor: "rgba(255, 0, 0, 0.5)"
                },
                {
                    label: "Channel 2",
                    pointRadius: 0,
                    data: channels[1],
                    borderColor: "rgb(255, 127, 0)", // Orange
                    backgroundColor: "rgba(255, 127, 0, 0.5)"
                },
                {
                    label: "Channel 3",
                    pointRadius: 0,
                    data: channels[2],
                    borderColor: "rgb(255, 201, 14)", // Yellow
                    backgroundColor: "rgba(255, 201, 14, 0.5)"
                },
                {
                    label: "Channel 4",
                    pointRadius: 0,
                    data: channels[3],
                    borderColor: "rgb(0, 255, 0)", // Green
                    backgroundColor: "rgba(0, 255, 0, 0.5)"
                },
                {
                    label: "Channel 5",
                    pointRadius: 0,
                    data: channels[4],
                    borderColor: "rgb(0, 0, 255)", // Blue
                    backgroundColor: "rgba(0, 0, 255, 0.5)"
                },
                {
                    label: "Channel 6",
                    pointRadius: 0,
                    data: channels[5],
                    borderColor: "rgb(75, 0, 130)", // Indigo
                    backgroundColor: "rgba(75, 0, 130, 0.5)"
                },
                {
                    label: "Channel 7",
                    pointRadius: 0,
                    data: channels[6],
                    borderColor: "rgb(148, 0, 211)", // Violet
                    backgroundColor: "rgba(148, 0, 211, 0.5)"
                },
                {
                    label: "Channel 8",
                    pointRadius: 0,
                    data: channels[7],
                    borderColor: "rgb(139, 69, 19)", // Brown
                    backgroundColor: "rgba(139, 69, 19, 0.5)"
                }
            ]
        };
    }

    public componentDidMount(): void {
        this.UpdateChartDataLoop();
    }

    render(): ReactNode {
        return (
            <div className="SignalCaptureChartContainer">
                <Line ref={this._ChartRef} options={this._ChartOptions} data={this._ChartData} />
            </div>
        );
    }

    public async UpdateChartData(): Promise<void> {
        const formattedSampleData = await this.GetData();
        // priming read
        if (formattedSampleData == undefined) {
            console.log("no data to log");
            return;
        }

        let numEnabled = 0;
        // parses the data to figure out what channels are present
        for (let ch = 0; ch < formattedSampleData.length; ch++) {
            if (formattedSampleData[ch].data.length != 0) {
                // if empty, nothing enabled
                numEnabled++;
            }
        }
        console.log("found channels: %d", numEnabled);

        // calcuates how many samples we need to fill the chart up with samples from every channel enabled
        if (this._ChartRef.current != null) {
            const chartSampleMax = Math.floor(this._ChartSamples / numEnabled);
            if (
                this._ChartRef.current.options.scales != undefined &&
                this._ChartRef.current.options.scales.x != undefined
            ) {
                this._ChartRef.current.options.scales.x.max = chartSampleMax;
            }

            for (let ch = 0; ch < numEnabled; ch++) {
                // rolls through channels and their data samples
                for (
                    let chartIndex = 0, sampleIndex = 0;
                    chartIndex < chartSampleMax;
                    chartIndex++, sampleIndex++
                ) {
                    this._ChartData.datasets[ch].data[chartIndex].y =
                        formattedSampleData[ch].data[sampleIndex];
                    this._ChartData.datasets[ch].data[chartIndex].x = chartIndex;
                }
            }

            // Zero out unused channels
            for (let ch = numEnabled; ch < this._MaxChannelCount; ch++) {
                this._ChartData.datasets[ch].data.forEach((point) => {
                    point.x = chartSampleMax;
                    point.y = 0;
                });
            }
            this._ChartRef.current.update();
        }
    }

    private async GetData(): Promise<ADCChannelData[] | undefined> {
        let result: ADCChannelData[] | undefined;
        await this.props.workQueue.post(async () => {
            result = await this._SignalCapture.readSamples();
        });

        return result;
    }

    /**
     * Loop that periodically reads samples from the Digital Signal Sampler and updates the
     * Chart with the new data.
     */
    private async UpdateChartDataLoop(): Promise<void> {
        const start: number = performance.now();

        await this.UpdateChartData();

        const elapsed: number = performance.now() - start;

        if (!this._IsStopPending) {
            const delay: number = this.updatePeriodMilliseconds - elapsed;

            setTimeout(
                async () => {
                    await this.UpdateChartDataLoop();
                },
                delay > this.updatePeriodMilliseconds ? delay : this.updatePeriodMilliseconds
            );
        }
    }
}

export default SignalCaptureView;
