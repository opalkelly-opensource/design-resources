import React, { Component } from "react";

import { IFrontPanel, WorkQueue } from "@opalkellytech/frontpanel-chromium-core";

import "./FrontPanel.css";

import FFTSignalGeneratorView from "./FFTSignalGeneratorView";
import DigitalSignalSamplerView from "./DigitalSignalSamplerView";
import SpectrumAnalyzerView from "./SpectrumAnalyzerView";

import Panel from "./Panel";

export interface FrontPanelProps {
    name: string;
}

class FrontPanel extends Component<FrontPanelProps> {
    private readonly _FrontPanel: IFrontPanel = window.FrontPanel;

    private readonly _SpectrumAnalyzerRef: React.RefObject<SpectrumAnalyzerView>;

    private readonly _WorkQueue: WorkQueue = new WorkQueue();

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
                            frontpanel={this._FrontPanel}
                            workQueue={this._WorkQueue}
                        />
                    </Panel>
                    <Panel
                        title="Time Domain"
                        description="ADC Input"
                        className="ChartControlPanel">
                        <DigitalSignalSamplerView
                            label="OutputView"
                            updatePeriodMilliseconds={180}
                            frontpanel={this._FrontPanel}
                            workQueue={this._WorkQueue}
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
                        frontpanel={this._FrontPanel}
                        label="OutputSpectrumView"
                        workQueue={this._WorkQueue}
                    />
                </Panel>
            </div>
        );
    }

    private async OnSampleChannelsUpdate(sampleChannels: Int16Array[]): Promise<void> {
        await this._SpectrumAnalyzerRef.current?.UpdateChartData(sampleChannels);
    }
}

export default FrontPanel;
