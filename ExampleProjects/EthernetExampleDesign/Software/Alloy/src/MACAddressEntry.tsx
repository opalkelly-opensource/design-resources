/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component } from "react";

import {
    EndpointAddressProps,
    FrontPanelNumberEntry,
    NumeralSystem
} from "@opalkelly/frontpanel-react-components";

/**
 * MAC Address Entry Component Properties
 * @property label - The label to display for the MAC Address.
 * @property fpEndpoints - The FrontPanel Endpoints for the high and low order values of the MAC Address.
 * @property numeralSystem - The numeral system to use for entering the MAC Address.
 */
export interface MACAddressEntryProps {
    label: string;
    fpEndpoints: EndpointAddressProps[];
    numeralSystem: NumeralSystem;
}

/**
 * MAC Address Entry Component used to set the high and low order values of a MAC Address.
 */
class MACAddressEntry extends Component<MACAddressEntryProps> {
    render() {
        return (
            <div>
                <div className="LabelText">{this.props.label}</div>
                <div style={{ display: "flex", flexDirection: "row", gap: "4px" }}>
                    <FrontPanelNumberEntry
                        label={{
                            text: "High",
                            verticalPosition: "top",
                            horizontalPosition: "right"
                        }}
                        tooltip="High Order Value"
                        size={1}
                        fpEndpoint={this.props.fpEndpoints[0]}
                        maximumValue={BigInt(0xffff)}
                        numeralSystem={this.props.numeralSystem}
                    />
                    <FrontPanelNumberEntry
                        label={{
                            text: "Low",
                            verticalPosition: "top",
                            horizontalPosition: "right"
                        }}
                        tooltip="Low Order Value"
                        size={1}
                        fpEndpoint={this.props.fpEndpoints[1]}
                        maximumValue={BigInt(0xffffffff)}
                        numeralSystem={this.props.numeralSystem}
                    />
                </div>
            </div>
        );
    }
}

export default MACAddressEntry;
