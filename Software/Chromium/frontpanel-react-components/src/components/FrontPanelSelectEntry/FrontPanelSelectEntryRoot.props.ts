import { EndpointAddressProps } from "../types";

/**
 * Interface for the properties of the `FrontPanelSelectEntryRoot` component.
 */
interface FrontPanelSelectEntryRootProps {
    /**
     * Address of the frontpanel endpoint
     */
    fpEndpoint: EndpointAddressProps;

    /**
     * Maximum value that the select entry will allow
     */
    maximumValue: bigint;
}

export default FrontPanelSelectEntryRootProps;
