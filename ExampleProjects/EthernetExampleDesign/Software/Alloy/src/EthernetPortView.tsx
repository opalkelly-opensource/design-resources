/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component } from "react";

import {
    FrontPanelSelectEntry,
    FrontPanelNumberDisplay,
    NumeralSystem,
    FrontPanelIndicator,
    FrontPanelPushButton,
    FrontPanelToggleSwitch
} from "@opalkelly/frontpanel-react-components";

import MACAddressView from "./MACAddressView";
import MACAddressEntry from "./MACAddressEntry";

import EthernetPortViewProps from "./EthernetPortView.props";

import "./EthernetPortView.css";

/**
 * Ethernet Port View Component used to display and control the settings and status of an Ethernet Port.
 */
class EthernetPortView extends Component<EthernetPortViewProps> {
    constructor(props: EthernetPortViewProps) {
        super(props);
    }

    render() {
        return (
            <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                <span className="TitleText">{this.props.label}</span>

                <div style={{ display: "flex", flexDirection: "row", gap: "8px" }}>
                    {/* Speed Setting Panel */}
                    <div className="Panel SpeedSettingsPanel">
                        <FrontPanelPushButton
                            label="Update Speed"
                            tooltip="Update Speed"
                            fpEndpoint={this.props.configuration.settings.updateSpeed}
                        />
                        <FrontPanelSelectEntry.Root
                            label={{
                                text: "Speed Advertised",
                                verticalPosition: "top",
                                horizontalPosition: "right"
                            }}
                            size={1}
                            tooltip="Speed Advertised"
                            fpEndpoint={this.props.configuration.settings.speedAdvertised}
                            maximumValue={BigInt(2)}>
                            <FrontPanelSelectEntry.Trigger />
                            <FrontPanelSelectEntry.Content>
                                <FrontPanelSelectEntry.Group>
                                    <FrontPanelSelectEntry.Label>
                                        Speeds
                                    </FrontPanelSelectEntry.Label>
                                    <FrontPanelSelectEntry.Item value="0">
                                        10 Mb/s
                                    </FrontPanelSelectEntry.Item>
                                    <FrontPanelSelectEntry.Item value="1">
                                        100 Mb/s
                                    </FrontPanelSelectEntry.Item>
                                    <FrontPanelSelectEntry.Item value="2">
                                        1000 Mb/s
                                    </FrontPanelSelectEntry.Item>
                                </FrontPanelSelectEntry.Group>
                            </FrontPanelSelectEntry.Content>
                        </FrontPanelSelectEntry.Root>
                    </div>

                    {/* Toggle Options Panel */}
                    <div className="Panel ToggleOptionsPanel">
                        <FrontPanelToggleSwitch
                            label="Gen TX Data"
                            tooltip="Toggle Generate TX Data"
                            fpEndpoint={this.props.configuration.settings.generateTxData}
                        />
                        <FrontPanelToggleSwitch
                            label="Check RX Data"
                            tooltip="Toggle Check RX Data"
                            fpEndpoint={this.props.configuration.settings.checkRxData}
                        />
                        <FrontPanelToggleSwitch
                            label="PHY Loopback"
                            tooltip="Toggle PHY Loopback"
                            fpEndpoint={this.props.configuration.settings.phyLoopback}
                        />
                        <FrontPanelToggleSwitch
                            label="Enable HDL Loopback"
                            tooltip="Toggle Enable HDL Loopback"
                            fpEndpoint={this.props.configuration.settings.hdlLoopback}
                        />
                        <FrontPanelToggleSwitch
                            label="HDL Loopback Address Swap"
                            tooltip="Toggle HDL Loopback Address Swap"
                            fpEndpoint={this.props.configuration.settings.hdlLoopbackAddressSwap}
                        />
                    </div>

                    {/* Error Panel */}
                    <div className="Panel ErrorPanel">
                        <FrontPanelPushButton
                            label="Reset Error"
                            tooltip="Reset Error"
                            fpEndpoint={this.props.configuration.settings.resetError}
                        />
                        <FrontPanelPushButton
                            label="Inject Error"
                            tooltip="Inject Error"
                            fpEndpoint={this.props.configuration.settings.injectError}
                        />
                        <FrontPanelIndicator
                            label="Error Occurred"
                            tooltip="Error Occurred"
                            fpEndpoint={this.props.configuration.status.error}
                        />
                    </div>
                </div>

                <div style={{ display: "flex", flexDirection: "row", gap: "8px" }}>
                    {/* Status Indicator Panel */}
                    <div className="Panel StatusIndicatorPanel">
                        <FrontPanelIndicator
                            label="Link On"
                            tooltip="Link On"
                            fpEndpoint={this.props.configuration.status.link}
                        />
                        <FrontPanelIndicator
                            label="Duplex On"
                            tooltip="Duplex On"
                            fpEndpoint={this.props.configuration.status.duplex}
                        />
                        <FrontPanelIndicator
                            label="Rx Activity"
                            tooltip="Rx Activity"
                            fpEndpoint={this.props.configuration.status.rxActivity}
                        />
                    </div>

                    {/* Status Panel */}
                    <div className="Panel StatusPanel">
                        <FrontPanelNumberDisplay
                            label={{
                                text: "PHY Neg Speed",
                                verticalPosition: "top",
                                horizontalPosition: "right"
                            }}
                            tooltip="PHY Neg Speed"
                            fpEndpoint={this.props.configuration.status.phyNegSpeed}
                            maximumValue={BigInt(2)}
                            numeralSystem={NumeralSystem.Binary}
                        />
                        <FrontPanelNumberDisplay
                            label={{
                                text: "Number of packets sent",
                                verticalPosition: "top",
                                horizontalPosition: "right"
                            }}
                            tooltip="Number of packets sent"
                            fpEndpoint={this.props.configuration.packetStatistics.packetsSent}
                            maximumValue={BigInt(0xffffffff)}
                            numeralSystem={NumeralSystem.Decimal}
                        />
                        <FrontPanelNumberDisplay
                            label={{
                                text: "Number of packets received",
                                verticalPosition: "top",
                                horizontalPosition: "right"
                            }}
                            tooltip="Number of packets received"
                            fpEndpoint={this.props.configuration.packetStatistics.packetsReceived}
                            maximumValue={BigInt(0xffffffff)}
                            numeralSystem={NumeralSystem.Decimal}
                        />
                        <FrontPanelPushButton
                            label="Rst Counters"
                            tooltip="Reset Counters"
                            fpEndpoint={this.props.configuration.reset.counters}
                        />
                    </div>
                </div>

                <div style={{ display: "flex", flexDirection: "row", gap: "8px" }}>
                    {/* MAC Address Status Panel */}
                    <div className="Panel MACAddressStatusPanel">
                        <MACAddressView
                            label="Unique MAC address from EEPROM"
                            fpEndpoints={[
                                this.props.configuration.macAddress.highOrder,
                                this.props.configuration.macAddress.lowOrder
                            ]}
                            numeralSystem={NumeralSystem.Hexadecimal}
                        />
                        <MACAddressView
                            label="Current destination MAC address"
                            description="(used for generation/check)"
                            fpEndpoints={[
                                this.props.configuration.destinationGenCheckMACAddress.highOrder,
                                this.props.configuration.destinationGenCheckMACAddress.lowOrder
                            ]}
                            numeralSystem={NumeralSystem.Hexadecimal}
                        />
                        <MACAddressView
                            label="Current source MAC address"
                            description="(used for generation/check)"
                            fpEndpoints={[
                                this.props.configuration.sourceGenCheckMACAddress.highOrder,
                                this.props.configuration.sourceGenCheckMACAddress.lowOrder
                            ]}
                            numeralSystem={NumeralSystem.Hexadecimal}
                        />
                    </div>

                    {/* MAC Address Settings Panel */}
                    <div className="Panel MACAddressSettingsPanel">
                        <MACAddressEntry
                            label="Destination MAC address to set"
                            fpEndpoints={[
                                this.props.configuration.destinationMACAddress.highOrder,
                                this.props.configuration.destinationMACAddress.lowOrder
                            ]}
                            numeralSystem={NumeralSystem.Hexadecimal}
                        />
                        <MACAddressEntry
                            label="Source Mac Address to set"
                            fpEndpoints={[
                                this.props.configuration.sourceMACAddress.highOrder,
                                this.props.configuration.sourceMACAddress.lowOrder
                            ]}
                            numeralSystem={NumeralSystem.Hexadecimal}
                        />
                    </div>
                </div>

                {/* Command Panel */}
                <div className="Panel" style={{ flexDirection: "row", gap: "8px" }}>
                    <FrontPanelPushButton
                        label="Set Port"
                        tooltip="Set Port"
                        fpEndpoint={this.props.configuration.settings.setPort}
                    />
                    <FrontPanelPushButton
                        label="Reset Port"
                        tooltip="Reset Port"
                        fpEndpoint={this.props.configuration.reset.port}
                    />
                </div>
            </div>
        );
    }
}

export default EthernetPortView;
