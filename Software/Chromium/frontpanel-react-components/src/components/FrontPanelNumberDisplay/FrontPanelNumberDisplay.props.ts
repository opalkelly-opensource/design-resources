import { EndpointAddressProps } from "../types";

/**
 * Interface for the properties of the `FrontPanelNumberDisplay` component.
 *
 * @interface
 */
interface FrontPanelNumberDisplayProps {
    /**
     * Address of the frontpanel endpoint
     */
    fpEndpoint: EndpointAddressProps;

    /**
     * Maximum value that the number display will allow
     */
    maximumValue: bigint;
}

export default FrontPanelNumberDisplayProps;
