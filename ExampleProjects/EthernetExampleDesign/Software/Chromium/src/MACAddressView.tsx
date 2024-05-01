import React, { Component } from "react";

import {
    EndpointAddressProps,
    FrontPanelNumberDisplay,
    NumeralSystem
} from "@opalkellytech/frontpanel-react-components";

/**
 * MAC Address View Component Properties
 * @property label - The label to display for the MAC Address.
 * @property description - The description to display for the MAC Address.
 * @property fpEndpoints - The FrontPanel Endpoints for the high and low order values of the MAC Address.
 * @property numeralSystem - The numeral system to use for displaying the MAC Address.
 */
export interface MACAddressViewProps {
    label: string;
    description?: string;
    fpEndpoints: EndpointAddressProps[];
    numeralSystem: NumeralSystem;
}

/**
 * MAC Address View Component used to display the high and low order values of a MAC Address.
 */
class MACAddressView extends Component<MACAddressViewProps> {
    render() {
        return (
            <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
                <span className="LabelText">{this.props.label}</span>
                <span className="LabelText">
                    {this.props.description != null ? this.props.description : ""}
                </span>
                <div style={{ display: "flex", flexDirection: "row", gap: "4px" }}>
                    <FrontPanelNumberDisplay
                        label={{
                            text: "High",
                            verticalPosition: "top",
                            horizontalPosition: "right"
                        }}
                        tooltip="High Order Value"
                        fpEndpoint={this.props.fpEndpoints[0]}
                        maximumValue={BigInt(0xffff)}
                        numeralSystem={this.props.numeralSystem}
                    />
                    <FrontPanelNumberDisplay
                        label={{
                            text: "Low",
                            verticalPosition: "top",
                            horizontalPosition: "right"
                        }}
                        tooltip="Low Order Value"
                        fpEndpoint={this.props.fpEndpoints[1]}
                        maximumValue={BigInt(0xffffffff)}
                        numeralSystem={this.props.numeralSystem}
                    />
                </div>
            </div>
        );
    }
}

export default MACAddressView;
