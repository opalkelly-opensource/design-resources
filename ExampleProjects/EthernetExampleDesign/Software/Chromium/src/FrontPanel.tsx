/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component } from "react";

import {
    IFrontPanel,
    FrontPanelPeriodicUpdateTimer,
    WireAddress
} from "@opalkellytech/frontpanel-chromium-core";

import { FrontPanel as FrontPanelContext } from "@opalkellytech/frontpanel-react-components";

import EthernetPortView from "./EthernetPortView";

import "./FrontPanel.css";

import {
    ResetEndpoint,
    MACAddressEndpoint,
    PacketStatisticsEndpoint,
    PortEndpointConfiguration,
    SettingsEndpoint,
    StatusEndpoint
} from "./EthernetPortView.props";

export interface FrontPanelProps {
    name: string;
}

export interface FrontPanelState {
    device: IFrontPanel;
    updateTimer: FrontPanelPeriodicUpdateTimer;
}

const CreatePacketStatisticsConfiguration = (
    baseAddress: WireAddress
): PacketStatisticsEndpoint => {
    const configuration: PacketStatisticsEndpoint = {
        packetsSent: { epAddress: baseAddress, bitOffset: 0 },
        packetsReceived: { epAddress: baseAddress + 1, bitOffset: 0 }
    };

    return configuration;
};

const CreateMACAddressConfiguration = (baseAddress: WireAddress): MACAddressEndpoint => {
    const configuration: MACAddressEndpoint = {
        highOrder: { epAddress: baseAddress + 1, bitOffset: 0 },
        lowOrder: { epAddress: baseAddress, bitOffset: 0 }
    };

    return configuration;
};

const CreateConfiguration = (
    resetEndpoint: ResetEndpoint,
    settingsAddress: WireAddress,
    statusAddress: WireAddress,
    packetStatisticsBaseAddress: WireAddress,
    macAddressBaseAddress: WireAddress,
    destinationMacAddressBaseAddress: WireAddress,
    sourceMACAddressBaseAddress: WireAddress,
    destinationGenCheckMacAddressBaseAddress: WireAddress,
    sourceGenCheckMACAddressBaseAddress: WireAddress
): PortEndpointConfiguration => {
    const settingsEndpointConfiguration: SettingsEndpoint = {
        generateTxData: { epAddress: settingsAddress, bitOffset: 4 },
        checkRxData: { epAddress: settingsAddress, bitOffset: 5 },
        phyLoopback: { epAddress: settingsAddress, bitOffset: 10 },
        hdlLoopback: { epAddress: settingsAddress, bitOffset: 7 },
        hdlLoopbackAddressSwap: { epAddress: settingsAddress, bitOffset: 9 },
        resetError: { epAddress: settingsAddress, bitOffset: 6 },
        injectError: { epAddress: settingsAddress, bitOffset: 8 },
        updateSpeed: { epAddress: settingsAddress, bitOffset: 2 },
        speedAdvertised: { epAddress: settingsAddress, bitOffset: 0 },
        setPort: { epAddress: settingsAddress, bitOffset: 11 }
    };

    const statusEndpointConfiguration: StatusEndpoint = {
        error: { epAddress: statusAddress, bitOffset: 4 },
        link: { epAddress: statusAddress, bitOffset: 0 },
        duplex: { epAddress: statusAddress, bitOffset: 3 },
        rxActivity: { epAddress: statusAddress, bitOffset: 5 },
        phyNegSpeed: { epAddress: statusAddress, bitOffset: 1 }
    };

    const configuration: PortEndpointConfiguration = {
        resetEndpoint: resetEndpoint,
        settingsEndpoint: settingsEndpointConfiguration,
        statusEndpoint: statusEndpointConfiguration,
        packetStatisticsEndpoint: CreatePacketStatisticsConfiguration(packetStatisticsBaseAddress),

        macAddressEndpoint: CreateMACAddressConfiguration(macAddressBaseAddress),
        sourceMACAddressEndpoint: CreateMACAddressConfiguration(sourceMACAddressBaseAddress),
        destinationMACAddressEndpoint: CreateMACAddressConfiguration(
            destinationMacAddressBaseAddress
        ),
        sourceGenCheckMACAddressEndpoint: CreateMACAddressConfiguration(
            sourceGenCheckMACAddressBaseAddress
        ),
        destinationGenCheckMACAddressEndpoint: CreateMACAddressConfiguration(
            destinationGenCheckMacAddressBaseAddress
        )
    };

    return configuration;
};

class FrontPanel extends Component<FrontPanelProps, FrontPanelState> {
    private readonly _PortEndpointConfigurations: PortEndpointConfiguration[];

    constructor(props: FrontPanelProps) {
        super(props);

        const resetEndpoints: ResetEndpoint[] = [
            {
                counters: { epAddress: 0x00, bitOffset: 2 },
                port: { epAddress: 0x00, bitOffset: 0 }
            },
            {
                counters: { epAddress: 0x00, bitOffset: 3 },
                port: { epAddress: 0x00, bitOffset: 1 }
            }
        ];

        const settingsAddresses: WireAddress[] = [0x01, 0x02];
        const statusAddresses: WireAddress[] = [0x20, 0x21];
        const packetStatisticsBaseAddresses: WireAddress[] = [0x22, 0x24];
        const macAddressBaseAddresses: WireAddress[] = [0x34, 0x36];
        const destinationMacAddressBaseAddresses: WireAddress[] = [0x03, 0x07];
        const sourceMACAddressBaseAddresses: WireAddress[] = [0x05, 0x09];
        const destinationGenCheckMacAddressBaseAddresses: WireAddress[] = [0x26, 0x30];
        const sourceGenCheckMACAddressBaseAddresses: WireAddress[] = [0x28, 0x32];

        this._PortEndpointConfigurations = [
            CreateConfiguration(
                resetEndpoints[0],
                settingsAddresses[0],
                statusAddresses[0],
                packetStatisticsBaseAddresses[0],
                macAddressBaseAddresses[0],
                destinationMacAddressBaseAddresses[0],
                sourceMACAddressBaseAddresses[0],
                destinationGenCheckMacAddressBaseAddresses[0],
                sourceGenCheckMACAddressBaseAddresses[0]
            ),
            CreateConfiguration(
                resetEndpoints[1],
                settingsAddresses[1],
                statusAddresses[1],
                packetStatisticsBaseAddresses[1],
                macAddressBaseAddresses[1],
                destinationMacAddressBaseAddresses[1],
                sourceMACAddressBaseAddresses[1],
                destinationGenCheckMacAddressBaseAddresses[1],
                sourceGenCheckMACAddressBaseAddresses[1]
            )
        ];

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
                        <EthernetPortView
                            label="MAC EX Port A"
                            endpointConfiguration={this._PortEndpointConfigurations[0]}
                        />
                    </div>
                    <div className="okControlPanel">
                        <EthernetPortView
                            label="MAC EX Port C"
                            endpointConfiguration={this._PortEndpointConfigurations[1]}
                        />
                    </div>
                </FrontPanelContext>
            </div>
        );
    }
}

export default FrontPanel;
