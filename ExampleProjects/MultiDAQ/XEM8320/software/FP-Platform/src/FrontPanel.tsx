/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { Component } from "react";

import {
    IFrontPanel,
    WorkQueue,
    FrontPanelPeriodicUpdateTimer
} from "@opalkelly/frontpanel-platform-api";

import "./FrontPanel.css";

import SignalGeneratorView from "./SignalGeneratorView";
import ScopeControl from "./ScopeControl";
import SignalCaptureView from "./SignalCaptureView";

import Panel from "./Panel";

export interface FrontPanelProps {
    name: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
}

class FrontPanel extends Component<FrontPanelProps> {
    constructor(props: FrontPanelProps) {
        super(props);
        this.state = {
            frontpanel: this.props.frontpanel,
            updateTimer: new FrontPanelPeriodicUpdateTimer(this.props.frontpanel, 10)
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
                            frontpanel={this.props.frontpanel}
                            workQueue={this.props.workQueue}
                        />
                    </Panel>
                </div>
                <Panel title="Scope" description="ADC Input" className="SignalCaptureViewPanel">
                    <ScopeControl
                        label="OutputView"
                        frontpanel={this.props.frontpanel}
                        workQueue={this.props.workQueue}
                    />
                    <SignalCaptureView
                        label="OutputSpectrumView"
                        frontpanel={this.props.frontpanel}
                        workQueue={this.props.workQueue}
                    />
                </Panel>
            </div>
        );
    }

    private async Initialize(): Promise<void> {
        await this.props.workQueue.post(async () => {
            this.props.frontpanel.setWireInValue(0x00, 0x4, 0x4); // ADC Auto reset
            await this.props.frontpanel.updateWireIns();
            this.props.frontpanel.setWireInValue(0x00, 0x0, 0x4); // Deassert auto reset
            await this.props.frontpanel.updateWireIns();
        });
    }
}

export default FrontPanel;
