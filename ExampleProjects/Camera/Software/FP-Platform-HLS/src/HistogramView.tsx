/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component, ReactNode } from "react";

import "HistogramView.css";

import {
    Chart as ChartJS,
    CategoryScale,
    LinearScale,
    BarElement,
    Tooltip,
    Title,
    Legend,
    ChartOptions
} from "chart.js";

import { Bar } from "react-chartjs-2";

import { sleep } from "./Utilities";

import { IFPGADataPortClassic, WorkQueue } from "@opalkelly/frontpanel-platform-api";

import { ToggleState } from "@opalkelly/frontpanel-react-components";

interface HistogramViewProps {
    fpgaDataPort: IFPGADataPortClassic;
    workQueue: WorkQueue;
    width: number;
    height: number;
    updatePeriodMilliseconds: number;
}

interface HistogramViewState {
    isLoading: boolean;
    isUpdateTimerEnabled: boolean;
}

class HistogramView extends Component<HistogramViewProps, HistogramViewState> {
    private _RedChannel: number[] = new Array<number>(256);
    private _GreenChannel: number[] = new Array<number>(256);
    private _BlueChannel: number[] = new Array<number>(256);

    private _ChartRef: React.RefObject<ChartJS<"bar">>;
    private _ChartOptions: ChartOptions<"bar">;
    private _ChartData;

    constructor(props: HistogramViewProps) {
        super(props);

        // Create ChartJS Chart Reference to display the output of the Digital Signal Sampler
        ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

        this._ChartRef = React.createRef();

        this._ChartOptions = {
            //animation: false,
            responsive: true,
            //maintainAspectRatio: false,
            scales: {
                x: { beginAtZero: true },
                y: { beginAtZero: true }
            },
            plugins: {
                legend: {
                    display: true
                    //position: "bottom" as const
                },
                //title: {
                //    display: false,
                //    text: "Output Signal"
                //},
                tooltip: {
                    callbacks: {
                        label: (context) => `Value: ${context.raw}`
                    }
                }
            }
        };

        this._RedChannel.fill(0, 0, 255);
        this._GreenChannel.fill(0, 0, 255);
        this._BlueChannel.fill(0, 0, 255);

        this._ChartData = {
            labels: this._RedChannel.map((_, index) => index),
            datasets: [
                {
                    label: "Red",
                    data: this._RedChannel,
                    //pointRadius: 0,
                    backgroundColor: "rgba(255, 0, 0, 1)",
                    borderColor: "rgba(255, 0, 0, 1)",
                    borderWidth: 1
                },
                {
                    label: "Green",
                    data: this._GreenChannel,
                    //pointRadius: 0,
                    backgroundColor: "rgba(0, 255, 0, 1)",
                    borderColor: "rgba(0, 255, 0, 1)",
                    borderWidth: 1
                },
                {
                    label: "Blue",
                    data: this._BlueChannel,
                    //pointRadius: 0,
                    backgroundColor: "rgba(0, 0, 255, 1)",
                    borderColor: "rgba(0, 0, 255, 1)",
                    borderWidth: 1
                }
            ]
        };

        this.state = {
            isLoading: true,
            isUpdateTimerEnabled: false
        };
    }

    componentDidMount(): void {
        if (!this.state.isUpdateTimerEnabled) {
            this.OnToggleChartDataUpdateTimer(ToggleState.On);
        }
    }

    componentWillUnmount(): void {
        this.setState({ isUpdateTimerEnabled: false });
    }

    render(): ReactNode {
        return (
            <div className="okHistogramChartPanel">
                <div className="okHistogramChartContainer">
                    <Bar ref={this._ChartRef} options={this._ChartOptions} data={this._ChartData} />
                </div>
            </div>
        );
    }

    private async FetchData(buffer: ArrayBuffer): Promise<void> {
        try {
            await this.props.fpgaDataPort.updateWireOuts();
            let done: boolean = (await this.props.fpgaDataPort.getWireOutValue(0x25)) !== 0;
            for (let i = 0; i < 10 && !done; i++) {
                await sleep(1);
                await this.props.fpgaDataPort.updateWireOuts();
                done = (await this.props.fpgaDataPort.getWireOutValue(0x25)) !== 0;
            }

            if (done) {
                await this.props.fpgaDataPort.readFromPipeOut(0xa1, buffer.byteLength, buffer);
                //const uint32Array = new Uint32Array(arrayBuffer);
                //setData(Array.from(uint32Array));
            }
        } catch (error) {
            console.error("Failed to fetch data:", error);
        } finally {
            this.setState({ isLoading: false });
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
        const HISTOGRAM_CHANNEL_COUNT = 3;
        const HISTOGRAM_SAMPLES_PER_CHANNEL = 256;
        const HISTOGRAM_SAMPLE_BYTEWIDTH = 4;

        const sampleBuffer = new ArrayBuffer(
            HISTOGRAM_SAMPLES_PER_CHANNEL * HISTOGRAM_SAMPLE_BYTEWIDTH * HISTOGRAM_CHANNEL_COUNT
        );

        await this.props.workQueue.post(async () => {
            await this.FetchData(sampleBuffer);
        });

        const samples = new Uint32Array(sampleBuffer);

        console.log(samples);

        for (let sampleIndex = 0; sampleIndex < HISTOGRAM_SAMPLES_PER_CHANNEL; sampleIndex++) {
            this._ChartData.datasets[0].data[sampleIndex] = samples[sampleIndex];
            this._ChartData.datasets[2].data[sampleIndex] =
                samples[sampleIndex + HISTOGRAM_SAMPLES_PER_CHANNEL];
            this._ChartData.datasets[1].data[sampleIndex] =
                samples[sampleIndex + 2 * HISTOGRAM_SAMPLES_PER_CHANNEL];
        }

        if (this._ChartRef.current != null) {
            this._ChartRef.current.update();
        }
    }
}

export default HistogramView;
