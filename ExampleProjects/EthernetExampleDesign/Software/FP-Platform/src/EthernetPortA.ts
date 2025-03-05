/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { EthernetPortConfiguration } from "./EthernetPortConfiguration";

const RESET_ENDPOINT = 0x00;
const SETTINGS_ENDPOINT = 0x01;
const STATUS_ENDPOINT = 0x20;
const PACKET_STATISTICS_ENDPOINTS = [0x22, 0x23];
const MAC_ADDRESS_ENDPOINTS = [0x34, 0x35];
const DESTINATION_MAC_ADDRESS_ENDPOINTS = [0x03, 0x04];
const SOURCE_MAC_ADDRESS_ENDPOINTS = [0x05, 0x06];
const DESTINATION_GEN_CHECK_MAC_ADDRESS_ENDPOINTS = [0x26, 0x27];
const SOURCE_GEN_CHECK_MAC_ADDRESS_ENDPOINTS = [0x28, 0x29];

/**
 * Configuration for Ethernet Port A used to bind components to corresponding FrontPanel endpoints.
 */
const EthernetPortA: EthernetPortConfiguration = {
    settings: {
        generateTxData: { epAddress: SETTINGS_ENDPOINT, bitOffset: 4 },
        checkRxData: { epAddress: SETTINGS_ENDPOINT, bitOffset: 5 },
        phyLoopback: { epAddress: SETTINGS_ENDPOINT, bitOffset: 10 },
        hdlLoopback: { epAddress: SETTINGS_ENDPOINT, bitOffset: 7 },
        hdlLoopbackAddressSwap: { epAddress: SETTINGS_ENDPOINT, bitOffset: 9 },
        resetError: { epAddress: SETTINGS_ENDPOINT, bitOffset: 6 },
        injectError: { epAddress: SETTINGS_ENDPOINT, bitOffset: 8 },
        updateSpeed: { epAddress: SETTINGS_ENDPOINT, bitOffset: 2 },
        speedAdvertised: { epAddress: SETTINGS_ENDPOINT, bitOffset: 0 },
        setPort: { epAddress: SETTINGS_ENDPOINT, bitOffset: 11 }
    },
    reset: {
        counters: { epAddress: RESET_ENDPOINT, bitOffset: 2 },
        port: { epAddress: RESET_ENDPOINT, bitOffset: 0 }
    },
    status: {
        error: { epAddress: STATUS_ENDPOINT, bitOffset: 4 },
        link: { epAddress: STATUS_ENDPOINT, bitOffset: 0 },
        duplex: { epAddress: STATUS_ENDPOINT, bitOffset: 3 },
        rxActivity: { epAddress: STATUS_ENDPOINT, bitOffset: 5 },
        phyNegSpeed: { epAddress: STATUS_ENDPOINT, bitOffset: 1 }
    },
    packetStatistics: {
        packetsSent: { epAddress: PACKET_STATISTICS_ENDPOINTS[0], bitOffset: 0 },
        packetsReceived: { epAddress: PACKET_STATISTICS_ENDPOINTS[1], bitOffset: 0 }
    },
    macAddress: {
        highOrder: { epAddress: MAC_ADDRESS_ENDPOINTS[1], bitOffset: 0 },
        lowOrder: { epAddress: MAC_ADDRESS_ENDPOINTS[0], bitOffset: 0 }
    },
    sourceMACAddress: {
        highOrder: { epAddress: SOURCE_MAC_ADDRESS_ENDPOINTS[1], bitOffset: 0 },
        lowOrder: { epAddress: SOURCE_MAC_ADDRESS_ENDPOINTS[0], bitOffset: 0 }
    },
    destinationMACAddress: {
        highOrder: { epAddress: DESTINATION_MAC_ADDRESS_ENDPOINTS[1], bitOffset: 0 },
        lowOrder: { epAddress: DESTINATION_MAC_ADDRESS_ENDPOINTS[0], bitOffset: 0 }
    },
    sourceGenCheckMACAddress: {
        highOrder: { epAddress: SOURCE_GEN_CHECK_MAC_ADDRESS_ENDPOINTS[1], bitOffset: 0 },
        lowOrder: { epAddress: SOURCE_GEN_CHECK_MAC_ADDRESS_ENDPOINTS[0], bitOffset: 0 }
    },
    destinationGenCheckMACAddress: {
        highOrder: { epAddress: DESTINATION_GEN_CHECK_MAC_ADDRESS_ENDPOINTS[1], bitOffset: 0 },
        lowOrder: { epAddress: DESTINATION_GEN_CHECK_MAC_ADDRESS_ENDPOINTS[0], bitOffset: 0 }
    }
};

export default EthernetPortA;
