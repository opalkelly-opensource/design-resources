/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component } from "react";

import {
    IFrontPanel,
    FrontPanelPeriodicUpdateTimer
} from "@opalkelly/frontpanel-alloy-core";

import { FrontPanel as FrontPanelContext } from "@opalkelly/frontpanel-react-components";

import EthernetPortView from "./EthernetPortView";

import "./FrontPanel.css";
import EthernetPortA from "./EthernetPortA";
import EthernetPortC from "./EthernetPortC";

export interface FrontPanelProps {
    name: string;
}

export interface FrontPanelState {
    device: IFrontPanel;
    updateTimer: FrontPanelPeriodicUpdateTimer;
}

/**
 * Front Panel Component used to display and control the Ethernet Ports.
 */
class FrontPanel extends Component<FrontPanelProps, FrontPanelState> {
    constructor(props: FrontPanelProps) {
        super(props);

        this.state = {
            device: window.FrontPanel,
            updateTimer: new FrontPanelPeriodicUpdateTimer(window.FrontPanel, 10)
        };
    }

    componentDidMount() {
        this.state.updateTimer.Start();
    }

    componentWillUnmount() {
        this.state.updateTimer.Stop();
    }

    render() {
        return (
            <div className="okFrontPanel">
                <FrontPanelContext device={this.state.device} eventSource={this.state.updateTimer}>
                    <div className="okControlPanel">
                        <EthernetPortView label="MAC EX Port A" configuration={EthernetPortA} />
                    </div>
                    <div className="okControlPanel">
                        <EthernetPortView label="MAC EX Port C" configuration={EthernetPortC} />
                    </div>
                </FrontPanelContext>
            </div>
        );
    }
}

export default FrontPanel;
