import React, { Component } from "react";

import {
    FrontPanelSelectEntry,
    FrontPanelNumberDisplay,
    NumeralSystem,
    FrontPanelIndicator,
    FrontPanelPushButton,
    FrontPanelToggleSwitch
} from "@opalkellytech/frontpanel-react-components";

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
                            fpEndpoint={
                                this.props.endpointConfiguration.settingsEndpoint.updateSpeed
                            }
                        />
                        <FrontPanelSelectEntry.Root
                            label={{
                                text: "Speed Advertised",
                                verticalPosition: "top",
                                horizontalPosition: "right"
                            }}
                            size={1}
                            tooltip="Speed Advertised"
                            fpEndpoint={
                                this.props.endpointConfiguration.settingsEndpoint.speedAdvertised
                            }
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
                            fpEndpoint={
                                this.props.endpointConfiguration.settingsEndpoint.generateTxData
                            }
                        />
                        <FrontPanelToggleSwitch
                            label="Check RX Data"
                            tooltip="Toggle Check RX Data"
                            fpEndpoint={
                                this.props.endpointConfiguration.settingsEndpoint.checkRxData
                            }
                        />
                        <FrontPanelToggleSwitch
                            label="PHY Loopback"
                            tooltip="Toggle PHY Loopback"
                            fpEndpoint={
                                this.props.endpointConfiguration.settingsEndpoint.phyLoopback
                            }
                        />
                        <FrontPanelToggleSwitch
                            label="Enable HDL Loopback"
                            tooltip="Toggle Enable HDL Loopback"
                            fpEndpoint={
                                this.props.endpointConfiguration.settingsEndpoint.hdlLoopback
                            }
                        />
                        <FrontPanelToggleSwitch
                            label="HDL Loopback Address Swap"
                            tooltip="Toggle HDL Loopback Address Swap"
                            fpEndpoint={
                                this.props.endpointConfiguration.settingsEndpoint
                                    .hdlLoopbackAddressSwap
                            }
                        />
                    </div>

                    {/* Error Panel */}
                    <div className="Panel ErrorPanel">
                        <FrontPanelPushButton
                            label="Reset Error"
                            tooltip="Reset Error"
                            fpEndpoint={
                                this.props.endpointConfiguration.settingsEndpoint.resetError
                            }
                        />
                        <FrontPanelPushButton
                            label="Inject Error"
                            tooltip="Inject Error"
                            fpEndpoint={
                                this.props.endpointConfiguration.settingsEndpoint.injectError
                            }
                        />
                        <FrontPanelIndicator
                            label="Error Occurred"
                            tooltip="Error Occurred"
                            fpEndpoint={this.props.endpointConfiguration.statusEndpoint.error}
                        />
                    </div>
                </div>

                <div style={{ display: "flex", flexDirection: "row", gap: "8px" }}>
                    {/* Status Indicator Panel */}
                    <div className="Panel StatusIndicatorPanel">
                        <FrontPanelIndicator
                            label="Link On"
                            tooltip="Link On"
                            fpEndpoint={this.props.endpointConfiguration.statusEndpoint.link}
                        />
                        <FrontPanelIndicator
                            label="Duplex On"
                            tooltip="Duplex On"
                            fpEndpoint={this.props.endpointConfiguration.statusEndpoint.duplex}
                        />
                        <FrontPanelIndicator
                            label="Rx Activity"
                            tooltip="Rx Activity"
                            fpEndpoint={this.props.endpointConfiguration.statusEndpoint.rxActivity}
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
                            fpEndpoint={this.props.endpointConfiguration.statusEndpoint.phyNegSpeed}
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
                            fpEndpoint={
                                this.props.endpointConfiguration.packetStatisticsEndpoint
                                    .packetsSent
                            }
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
                            fpEndpoint={
                                this.props.endpointConfiguration.packetStatisticsEndpoint
                                    .packetsReceived
                            }
                            maximumValue={BigInt(0xffffffff)}
                            numeralSystem={NumeralSystem.Decimal}
                        />
                        <FrontPanelPushButton
                            label="Rst Counters"
                            tooltip="Reset Counters"
                            fpEndpoint={this.props.endpointConfiguration.resetEndpoint.counters}
                        />
                    </div>
                </div>

                <div style={{ display: "flex", flexDirection: "row", gap: "8px" }}>
                    {/* MAC Address Status Panel */}
                    <div className="Panel MACAddressStatusPanel">
                        <MACAddressView
                            label="Unique MAC address from EEPROM"
                            fpEndpoints={[
                                this.props.endpointConfiguration.macAddressEndpoint.highOrder,
                                this.props.endpointConfiguration.macAddressEndpoint.lowOrder
                            ]}
                            numeralSystem={NumeralSystem.Hexadecimal}
                        />
                        <MACAddressView
                            label="Current destination MAC address"
                            description="(used for generation/check)"
                            fpEndpoints={[
                                this.props.endpointConfiguration
                                    .destinationGenCheckMACAddressEndpoint.highOrder,
                                this.props.endpointConfiguration
                                    .destinationGenCheckMACAddressEndpoint.lowOrder
                            ]}
                            numeralSystem={NumeralSystem.Hexadecimal}
                        />
                        <MACAddressView
                            label="Current source MAC address"
                            description="(used for generation/check)"
                            fpEndpoints={[
                                this.props.endpointConfiguration.sourceGenCheckMACAddressEndpoint
                                    .highOrder,
                                this.props.endpointConfiguration.sourceGenCheckMACAddressEndpoint
                                    .lowOrder
                            ]}
                            numeralSystem={NumeralSystem.Hexadecimal}
                        />
                    </div>

                    {/* MAC Address Settings Panel */}
                    <div className="Panel MACAddressSettingsPanel">
                        <MACAddressEntry
                            label="Destination MAC address to set"
                            fpEndpoints={[
                                this.props.endpointConfiguration.destinationMACAddressEndpoint
                                    .highOrder,
                                this.props.endpointConfiguration.destinationMACAddressEndpoint
                                    .lowOrder
                            ]}
                            numeralSystem={NumeralSystem.Hexadecimal}
                        />
                        <MACAddressEntry
                            label="Source Mac Address to set"
                            fpEndpoints={[
                                this.props.endpointConfiguration.sourceMACAddressEndpoint.highOrder,
                                this.props.endpointConfiguration.sourceMACAddressEndpoint.lowOrder
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
                        fpEndpoint={this.props.endpointConfiguration.settingsEndpoint.setPort}
                    />
                    <FrontPanelPushButton
                        label="Reset Port"
                        tooltip="Reset Port"
                        fpEndpoint={this.props.endpointConfiguration.resetEndpoint.port}
                    />
                </div>
            </div>
        );
    }
}

export default EthernetPortView;
