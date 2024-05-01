import React, { Component, ReactNode } from "react";

import "./SpectrumAnalyzerView.css";

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

import { SpectrumAnalyzer } from "./SpectrumAnalyzer";

import { IFrontPanel, WorkQueue, ByteCount } from "@opalkellytech/frontpanel-chromium-core";

import FFTConfiguration, { hertz } from "./FFTConfiguration";

import { Vector2D } from "./Vector";

export type UpdateChartDataEventHandler = (data: Vector2D[]) => void;

interface SpectrumAnalyzerViewProps {
    label: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
}

class SpectrumAnalyzerView extends Component<SpectrumAnalyzerViewProps> {
    private readonly _FFTConfiguration: FFTConfiguration;
    private readonly _SpectrumAnalyzer: SpectrumAnalyzer;

    private readonly _SampleChannels: Float64Array[];

    private _ChartRef: React.RefObject<ChartJS<"line">>;
    private _ChartOptions: ChartOptions<"line">;
    private _ChartData;

    private _FrequencyScale = 0.000001;

    protected get WorkQueue(): WorkQueue {
        return this.props.workQueue;
    }

    constructor(props: SpectrumAnalyzerViewProps) {
        super(props);

        // Create FFT Signal Generator
        const fftLength = 1024; // 1024 bin FFT Length
        const sampleRate: hertz = 125000000; // 125MHz Sample Rate
        const maxAmplitudeValue = 0x1fffff;
        //const maxAmplitudeValue = 0x7ffff;      // 19 bits

        this._FFTConfiguration = new FFTConfiguration(fftLength, sampleRate, maxAmplitudeValue);

        const sampleSize: ByteCount = 8;
        const sampleCount: number = this._FFTConfiguration.FFTLength;

        this._SpectrumAnalyzer = new SpectrumAnalyzer(props.frontpanel, sampleSize, sampleCount);

        //
        this._SampleChannels = new Array(2);

        this._SampleChannels[0] = new Float64Array(this._SpectrumAnalyzer.SampleCount);
        this._SampleChannels[1] = new Float64Array(this._SpectrumAnalyzer.SampleCount);

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
                    max: this._FFTConfiguration.GetBinFrequency(512) * this._FrequencyScale,
                    ticks: { display: true, stepSize: 5 },
                    title: { display: true, text: "Frequency (MHz)" }
                },
                y: {
                    type: "linear",
                    min: -130.0,
                    max: 0.0,
                    ticks: { display: true, stepSize: 10.0 }
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

        channels[0] = new Array<Vector2D>(this._SpectrumAnalyzer.SampleCount)
            .fill({ x: 0.0, y: 0.0 })
            .map(() => ({ x: 0.0, y: 0.0 }));
        channels[1] = new Array<Vector2D>(this._SpectrumAnalyzer.SampleCount)
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
    }

    render(): ReactNode {
        return (
            <div className="okSpectrumAnalyzerChartContainer">
                <Line ref={this._ChartRef} options={this._ChartOptions} data={this._ChartData} />
            </div>
        );
    }

    public async UpdateChartData(sampleChannels: Int16Array[]): Promise<void> {
        //console.log("SpectrumAnalyzer::UpdateChartData")

        //const start: number = performance.now();

        //const hammingWindow = await tf.signal.hammingWindow(this._SampleCount).array();

        //channels[0][sampleIndex] = Math.round(channels[0][sampleIndex] * hammingWindow[sampleIndex]);
        //channels[1][sampleIndex] = Math.round(channels[1][sampleIndex] * hammingWindow[sampleIndex]);

        await this.WorkQueue.Post(async () => {
            await this._SpectrumAnalyzer.ComputeSpectrum(
                sampleChannels[0],
                this._SampleChannels[0]
            );
            await this._SpectrumAnalyzer.ComputeSpectrum(
                sampleChannels[1],
                this._SampleChannels[1]
            );
        });

        //const elapsed: number = performance.now() - start;

        //console.log("SpectrumAnalyzer::ComputeSpectrum ElapsedTime=" + elapsed + "ms");

        const maximumAmplitudeValue: number = this._FFTConfiguration.MaximumAmplitudeValue;

        for (let sampleIndex = 0; sampleIndex < this._SampleChannels[0].length; sampleIndex++) {
            this._ChartData.datasets[0].data[sampleIndex].x =
                this._FFTConfiguration.GetBinFrequency(sampleIndex) * this._FrequencyScale;
            this._ChartData.datasets[0].data[sampleIndex].y =
                20.0 * Math.log10(this._SampleChannels[0][sampleIndex] / maximumAmplitudeValue);
        }

        for (let sampleIndex = 0; sampleIndex < this._SampleChannels[1].length; sampleIndex++) {
            this._ChartData.datasets[1].data[sampleIndex].x =
                this._FFTConfiguration.GetBinFrequency(sampleIndex) * this._FrequencyScale;
            this._ChartData.datasets[1].data[sampleIndex].y =
                20.0 * Math.log10(this._SampleChannels[1][sampleIndex] / maximumAmplitudeValue);
        }

        if (this._ChartRef.current != null) {
            this._ChartRef.current.update("none");
        }
    }
}

export default SpectrumAnalyzerView;
