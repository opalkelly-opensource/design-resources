import { EndpointAddressProps } from "../types";

/**
 * Interface for the properties of the `FrontPanelNumberEntry` component.
 *
 * @interface
 */
interface FrontPanelNumberEntryProps {
    /**
     * Address of the frontpanel endpoint
     */
    fpEndpoint: EndpointAddressProps;

    /**
     * Maximum value that the number entry will allow.
     */
    maximumValue: bigint;

    /**
     * Optional minimum value that the number entry will allow.
     */
    minimumValue?: bigint;
}

export default FrontPanelNumberEntryProps;
