import React, { Component, ReactNode } from "react";

import {
    Chart as ChartJS,
    CategoryScale,
    LinearScale,
    PointElement,
    LineElement,
    Title,
    Tooltip,
    Legend,
    ChartOptions
} from "chart.js";

import { Line } from "react-chartjs-2";

import { Vector2D } from "./Vector";

export type UpdateChartDataEventHandler = (data: Vector2D[]) => void;

interface OutputSignalChartViewProps {
    label: string;

    onUpdateChartData: UpdateChartDataEventHandler;
}

class OutputSignalChartView extends Component<OutputSignalChartViewProps> {
    private _ChartRef: React.RefObject<ChartJS<"line">>;

    private _Options: ChartOptions<"line">;

    private _Data;

    constructor(props: OutputSignalChartViewProps) {
        super(props);

        ChartJS.register(
            CategoryScale,
            LinearScale,
            PointElement,
            LineElement,
            Title,
            Tooltip,
            Legend
        );

        this._ChartRef = React.createRef();

        this._Options = {
            responsive: true,
            scales: {
                x: {
                    type: "linear",
                    min: 0.0,
                    max: 0.000008192
                },
                y: {
                    type: "linear",
                    min: -1.2,
                    max: 1.2
                }
            },
            plugins: {
                legend: {
                    position: "top" as const
                },
                title: {
                    display: true,
                    text: "Expected Output"
                }
            }
        };

        const data: Vector2D[] = new Array<Vector2D>(1024)
            .fill({ x: 0.0, y: 0.0 })
            .map(() => ({ x: 0.0, y: 0.0 }));

        this._Data = {
            datasets: [
                {
                    label: "Signal",
                    data: data,
                    borderColor: "rgb(255, 99, 132)",
                    backgroundColor: "rgba(255, 99, 132, 0.5)"
                }
            ]
        };
    }

    render(): ReactNode {
        this.UpdateChartData();

        return <Line ref={this._ChartRef} options={this._Options} data={this._Data} />;
    }

    public UpdateChartData() {
        this.props.onUpdateChartData(this._Data.datasets[0].data);

        if (this._ChartRef.current != null) {
            this._ChartRef.current.update();
        }
    }
}

export default OutputSignalChartView;
