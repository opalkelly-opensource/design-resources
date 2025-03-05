/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { Component } from "react";

import {
    IFrontPanel,
    FrontPanelPeriodicUpdateTimer,
    WorkQueue
} from "@opalkelly/frontpanel-platform-api";

import { FrontPanel as FrontPanelContext } from "@opalkelly/frontpanel-react-components";

import EthernetPortView from "./EthernetPortView";

import "./FrontPanel.css";
import EthernetPortA from "./EthernetPortA";
import EthernetPortC from "./EthernetPortC";

export interface FrontPanelProps {
    name: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
}

export interface FrontPanelState {
    updateTimer: FrontPanelPeriodicUpdateTimer;
}

/**
 * Front Panel Component used to display and control the Ethernet Ports.
 */
class FrontPanel extends Component<FrontPanelProps, FrontPanelState> {
    constructor(props: FrontPanelProps) {
        super(props);

        this.state = {
            updateTimer: new FrontPanelPeriodicUpdateTimer(this.props.frontpanel, 10)
        };
    }

    componentDidMount() {
        this.state.updateTimer.start();
    }

    componentWillUnmount() {
        this.state.updateTimer.stop();
    }

    render() {
        return (
            <div className="okFrontPanel">
                <FrontPanelContext
                    device={this.props.frontpanel}
                    workQueue={this.props.workQueue}
                    eventSource={this.state.updateTimer}>
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
