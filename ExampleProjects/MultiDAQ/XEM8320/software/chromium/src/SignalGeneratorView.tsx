/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component, ReactNode } from "react";

import "./SignalGeneratorView.css";

import { IFrontPanel, WorkQueue } from "@opalkelly/frontpanel-alloy-core";

import {
    Button,
    FrontPanelNumberEntry,
    ToggleState,
    ToggleSwitch
} from "@opalkelly/frontpanel-react-components";

export type IsEnabledChangeEventHandler = (id: number, isEnabled: boolean) => void;

interface SignalGeneratorViewProps {
    label: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
}

interface SignalGeneratorViewState {
    statusMessage: string;
    isChannelEnabled: boolean[];
}

class FFTSignalGeneratorView extends Component<SignalGeneratorViewProps, SignalGeneratorViewState> {
    constructor(props: SignalGeneratorViewProps) {
        super(props);
        this.state = {
            statusMessage: "",
            isChannelEnabled: new Array(8).fill(false) // Initialize all channels as disabled
        };
    }

    render(): ReactNode {
        return (
            <div className="okSignalGenerator">
                <div className="okSignalGeneratorControlPanel">
                    <Button label="Enable All" onButtonUp={this.EnableAll.bind(this)} />
                    <Button label="Disable All" onButtonUp={this.DisableAll.bind(this)} />
                </div>
                <div className="okSignalGeneratorContentPanel">
                    {this.state.isChannelEnabled.map((isEnabled, index) => (
                        <div className="dacControlElement" key={`Ch ${index + 1}`}>
                            <ToggleSwitch
                                label={`Ch ${index + 1}`}
                                state={isEnabled ? ToggleState.On : ToggleState.Off}
                                onToggleStateChanged={() =>
                                    this.OnUpdateChannelEnabled(index, isEnabled)
                                }
                            />
                            <FrontPanelNumberEntry
                                fpEndpoint={{ epAddress: index + 1, bitOffset: 0 }}
                                maximumValue={BigInt(0xffffffff)}
                            />
                            <text>{"Hz"}</text>
                        </div>
                    ))}
                </div>
            </div>
        );
    }

    // Event Handlers
    private async OnUpdateChannelEnabled(channelIndex: number, isEnabled: boolean): Promise<void> {
        this.setState((prevState) => {
            const newState = prevState.isChannelEnabled.slice(0);

            newState[channelIndex] = !newState[channelIndex];

            return { isChannelEnabled: newState };
        });

        const enableMask = (0x01 << channelIndex) << 8;
        await this.props.workQueue.Post(async () => {
            await this.props.frontpanel.setWireInValue(
                0x00,
                isEnabled ? 0x00 : 0xffffffff,
                enableMask
            );
            await this.props.frontpanel.updateWireIns();
        });
    }

    private async EnableAll(): Promise<void> {
        this.setState({ isChannelEnabled: this.state.isChannelEnabled.map(() => true) });

        await this.props.workQueue.Post(async () => {
            await this.props.frontpanel.setWireInValue(0x00, 0xff00, 0xff00);
            await this.props.frontpanel.updateWireIns();
        });
    }

    private async DisableAll(): Promise<void> {
        this.setState({ isChannelEnabled: this.state.isChannelEnabled.map(() => false) });

        await this.props.workQueue.Post(async () => {
            await this.props.frontpanel.setWireInValue(0x00, 0x0000, 0xff00);
            await this.props.frontpanel.updateWireIns();
        });
    }
}

export default FFTSignalGeneratorView;
