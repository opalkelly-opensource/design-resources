/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component } from "react";

import {
    IFrontPanel,
    WorkQueue,
    FrontPanelPeriodicUpdateTimer
} from "@opalkelly/frontpanel-alloy-core";

import "./FrontPanel.css";

import SignalGeneratorView from "./SignalGeneratorView";
import ScopeControl from "./ScopeControl";
import SignalCaptureView from "./SignalCaptureView";

import Panel from "./Panel";

export interface FrontPanelProps {
    name: string;
}

export interface FrontPanelState {
    device: IFrontPanel;
    updateTimer: FrontPanelPeriodicUpdateTimer;
}

class FrontPanel extends Component<FrontPanelProps, FrontPanelState> {
    private readonly _FrontPanel: IFrontPanel = window.FrontPanel;

    private readonly _WorkQueue: WorkQueue = new WorkQueue();

    constructor(props: FrontPanelProps) {
        super(props);
        this.state = {
            device: window.FrontPanel,
            updateTimer: new FrontPanelPeriodicUpdateTimer(window.FrontPanel, 10)
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
                            frontpanel={this._FrontPanel}
                            workQueue={this._WorkQueue}
                        />
                    </Panel>
                </div>
                <Panel title="Scope" description="ADC Input" className="SignalCaptureViewPanel">
                    <ScopeControl
                        label="OutputView"
                        frontpanel={this._FrontPanel}
                        workQueue={this._WorkQueue}
                    />
                    <SignalCaptureView
                        label="OutputSpectrumView"
                        frontpanel={this._FrontPanel}
                        workQueue={this._WorkQueue}
                    />
                </Panel>
            </div>
        );
    }

    private async Initialize(): Promise<void> {
        await this._WorkQueue.Post(async () => {
            await this._FrontPanel.setWireInValue(0x00, 0x4, 0x4); // ADC Auto reset
            await this._FrontPanel.updateWireIns();
            await this._FrontPanel.setWireInValue(0x00, 0x0, 0x4); // Deassert auto reset
            await this._FrontPanel.updateWireIns();
        });
    }
}

export default FrontPanel;
