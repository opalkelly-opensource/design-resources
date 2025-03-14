/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component } from "react";

import { IFrontPanel, WorkQueue } from "@opalkelly/frontpanel-platform-api";

import "./FrontPanel.css";

import FFTSignalGeneratorView from "./FFTSignalGeneratorView";
import DigitalSignalSamplerView from "./DigitalSignalSamplerView";
import SpectrumAnalyzerView from "./SpectrumAnalyzerView";

import Panel from "./Panel";

export interface FrontPanelProps {
    name: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
}

class FrontPanel extends Component<FrontPanelProps> {
    private readonly _SpectrumAnalyzerRef: React.RefObject<SpectrumAnalyzerView>;

    constructor(props: FrontPanelProps) {
        super(props);

        this._SpectrumAnalyzerRef = React.createRef();
    }

    render() {
        return (
            <div className="FrontPanel">
                <div className="RowLayoutContainer">
                    <Panel title="Signal Generator" description="DAC Output">
                        <FFTSignalGeneratorView
                            label="OutputView"
                            frontpanel={this.props.frontpanel}
                            workQueue={this.props.workQueue}
                        />
                    </Panel>
                    <Panel
                        title="Time Domain"
                        description="ADC Input"
                        className="ChartControlPanel">
                        <DigitalSignalSamplerView
                            label="OutputView"
                            updatePeriodMilliseconds={35}
                            frontpanel={this.props.frontpanel}
                            workQueue={this.props.workQueue}
                            onSampleChannelsUpdate={this.OnSampleChannelsUpdate.bind(this)}
                        />
                    </Panel>
                </div>
                <Panel
                    title="Spectrum - (1,024-pt FFT)"
                    description="ADC Input"
                    className="SpectrumAnalyzerChartPanel">
                    <SpectrumAnalyzerView
                        ref={this._SpectrumAnalyzerRef}
                        frontpanel={this.props.frontpanel}
                        label="OutputSpectrumView"
                        workQueue={this.props.workQueue}
                    />
                </Panel>
            </div>
        );
    }

    /**
     * Event handler called by the Digital Signal Sampler when it has retrieved a new set of samples
     * for the two channels.
     * @param sampleChannels - Array of two Int16Arrays that store the samples for each channel.
     */
    private async OnSampleChannelsUpdate(sampleChannels: Int16Array[]): Promise<void> {
        // Update the Spectrum Analyzer with the new samples.
        await this._SpectrumAnalyzerRef.current?.UpdateChartData(sampleChannels);
    }
}

export default FrontPanel;
