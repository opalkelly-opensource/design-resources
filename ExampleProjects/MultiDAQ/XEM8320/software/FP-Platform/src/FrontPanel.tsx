/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { Component } from "react";

import {
    IFPGADataPortClassic,
    WorkQueue,
    FPGADataPortClassicPeriodicUpdateTimer
} from "@opalkelly/frontpanel-platform-api";

import "./FrontPanel.css";

import SignalGeneratorView from "./SignalGeneratorView";
import ScopeControl from "./ScopeControl";
import SignalCaptureView from "./SignalCaptureView";

import Panel from "./Panel";

export interface FrontPanelProps {
    name: string;
    fpgaDataPort: IFPGADataPortClassic;
    workQueue: WorkQueue;
}

class FrontPanel extends Component<FrontPanelProps> {
    constructor(props: FrontPanelProps) {
        super(props);
        this.state = {
            fpgaDataPort: this.props.fpgaDataPort,
            updateTimer: new FPGADataPortClassicPeriodicUpdateTimer(this.props.fpgaDataPort, this.props.workQueue, 10)
        };
    }
    public componentDidMount(): void {
        this.Initialize();
    }
    render() {
        return (
            <div className="FrontPanel">
                <div className="RowLayoutContainer">
                    <Panel
                        title="Signal Generator"
                        description="DAC Output"
                        className="SignalGeneratorViewPanel">
                        <SignalGeneratorView
                            label="OutputView"
                            fpgaDataPort={this.props.fpgaDataPort}
                            workQueue={this.props.workQueue}
                        />
                    </Panel>
                </div>
                <Panel title="Scope" description="ADC Input" className="SignalCaptureViewPanel">
                    <ScopeControl
                        label="OutputView"
                        fpgaDataPort={this.props.fpgaDataPort}
                        workQueue={this.props.workQueue}
                    />
                    <SignalCaptureView
                        label="OutputSpectrumView"
                        fpgaDataPort={this.props.fpgaDataPort}
                        workQueue={this.props.workQueue}
                    />
                </Panel>
            </div>
        );
    }

    private async Initialize(): Promise<void> {
        await this.props.workQueue.post(async () => {
            this.props.fpgaDataPort.setWireInValue(0x00, 0x4, 0x4); // ADC Auto reset
            await this.props.fpgaDataPort.updateWireIns();
            this.props.fpgaDataPort.setWireInValue(0x00, 0x0, 0x4); // Deassert auto reset
            await this.props.fpgaDataPort.updateWireIns();
        });
    }
}

export default FrontPanel;
