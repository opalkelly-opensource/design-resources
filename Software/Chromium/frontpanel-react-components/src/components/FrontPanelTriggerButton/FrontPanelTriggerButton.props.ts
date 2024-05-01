import { EndpointAddressProps } from "../types";

/**
 * Interface for the properties of the FrontPanelTriggerButton component.
 * This interface extends the properties of the TriggerButton component.
 */
interface FrontPanelTriggerButtonProps {
    /**
     * Address of the frontpanel endpoint
     */
    fpEndpoint: EndpointAddressProps;
}

export default FrontPanelTriggerButtonProps;
