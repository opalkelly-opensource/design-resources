/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { EndpointAddressProps } from "@opalkellytech/frontpanel-react-components";

/**
 * Ethernet Port Reset Configuration.
 */
export interface ResetConfiguration {
    counters: EndpointAddressProps;
    port: EndpointAddressProps;
}

/**
 * Ethernet Port Settings Configuration.
 */
export interface SettingsConfiguration {
    generateTxData: EndpointAddressProps;
    checkRxData: EndpointAddressProps;
    phyLoopback: EndpointAddressProps;
    hdlLoopback: EndpointAddressProps;
    hdlLoopbackAddressSwap: EndpointAddressProps;
    resetError: EndpointAddressProps;
    injectError: EndpointAddressProps;
    updateSpeed: EndpointAddressProps;
    speedAdvertised: EndpointAddressProps;
    setPort: EndpointAddressProps;
}

/**
 * Ethernet Port Status Configuration.
 */
export interface StatusConfiguration {
    error: EndpointAddressProps;
    link: EndpointAddressProps;
    duplex: EndpointAddressProps;
    rxActivity: EndpointAddressProps;
    phyNegSpeed: EndpointAddressProps;
}

/**
 * Ethernet Port Packet Statistics Configuration.
 */
export interface PacketStatisticsConfiguration {
    packetsReceived: EndpointAddressProps;
    packetsSent: EndpointAddressProps;
}

/**
 * Ethernet Port MAC Address Configuration.
 */
export interface MACAddressConfiguration {
    highOrder: EndpointAddressProps;
    lowOrder: EndpointAddressProps;
}

/**
 * Ethernet Port Configuration.
 */
export interface EthernetPortConfiguration {
    settings: SettingsConfiguration;
    reset: ResetConfiguration;
    status: StatusConfiguration;
    packetStatistics: PacketStatisticsConfiguration;
    macAddress: MACAddressConfiguration;
    sourceMACAddress: MACAddressConfiguration;
    destinationMACAddress: MACAddressConfiguration;
    sourceGenCheckMACAddress: MACAddressConfiguration;
    destinationGenCheckMACAddress: MACAddressConfiguration;
}
