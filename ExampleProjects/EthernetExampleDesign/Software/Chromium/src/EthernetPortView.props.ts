import { EndpointAddressProps } from "@opalkellytech/frontpanel-react-components";

export interface ResetEndpoint {
    counters: EndpointAddressProps;
    port: EndpointAddressProps;
}

export interface SettingsEndpoint {
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

export interface StatusEndpoint {
    error: EndpointAddressProps;
    link: EndpointAddressProps;
    duplex: EndpointAddressProps;
    rxActivity: EndpointAddressProps;
    phyNegSpeed: EndpointAddressProps;
}

export interface PacketStatisticsEndpoint {
    packetsReceived: EndpointAddressProps;
    packetsSent: EndpointAddressProps;
}

export interface MACAddressEndpoint {
    highOrder: EndpointAddressProps;
    lowOrder: EndpointAddressProps;
}

export interface PortEndpointConfiguration {
    settingsEndpoint: SettingsEndpoint;
    resetEndpoint: ResetEndpoint;
    statusEndpoint: StatusEndpoint;
    packetStatisticsEndpoint: PacketStatisticsEndpoint;
    macAddressEndpoint: MACAddressEndpoint;
    sourceMACAddressEndpoint: MACAddressEndpoint;
    destinationMACAddressEndpoint: MACAddressEndpoint;
    sourceGenCheckMACAddressEndpoint: MACAddressEndpoint;
    destinationGenCheckMACAddressEndpoint: MACAddressEndpoint;
}

/**
 * Ethernet Port View Component Properties
 * @property label - The label to display for the Ethernet Port.
 * @property endpointConfiguration - The FrontPanel Endpoints for the Ethernet Port.
 */
interface EthernetPortViewProps {
    label: string;
    endpointConfiguration: PortEndpointConfiguration;
}

export default EthernetPortViewProps;
