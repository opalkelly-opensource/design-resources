/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { Component, ReactNode } from "react";
import "./ScopeControl.css";
import { IFPGADataPortClassic, WorkQueue } from "@opalkelly/frontpanel-platform-api";
import { NumberEntry } from "@opalkelly/frontpanel-react-components";

interface ScopeControlProps {
    label: string;
    fpgaDataPort: IFPGADataPortClassic;
    workQueue: WorkQueue;
}

interface ScopeControlState {
    statusMessage: string;
    enableCount: number;
}

class ScopeControl extends Component<ScopeControlProps, ScopeControlState> {
    protected get WorkQueue(): WorkQueue {
        return this.props.workQueue;
    }

    constructor(props: ScopeControlProps) {
        super(props);
        this.state = {
            statusMessage: "",
            enableCount: 0 // Initialize all channels as disabled
        };
    }

    render(): ReactNode {
        return (
            <div className="ScopeContentPanel">
                <NumberEntry
                    label={{
                        text: "Channel Count",
                        horizontalPosition: "left",
                        verticalPosition: "top"
                    }}
                    size={3}
                    value={BigInt(this.state.enableCount)}
                    minimumValue={BigInt(0)}
                    maximumValue={BigInt(8)}
                    onValueChange={this.OnUpdateChannelEnabled}
                />
            </div>
        );
    }

    // Event Handlers
    private OnUpdateChannelEnabled = (value: bigint) => {
        console.log("Enable Count changed: " + value);
        const channels = value << BigInt(4);
        this.WorkQueue.post(async () => {
            this.props.fpgaDataPort.setWireInValue(0x00, Number(channels), 0x000000f0);
            await this.props.fpgaDataPort.updateWireIns();
        });
        this.setState({ enableCount: Number(value) });
    };
}

export default ScopeControl;
