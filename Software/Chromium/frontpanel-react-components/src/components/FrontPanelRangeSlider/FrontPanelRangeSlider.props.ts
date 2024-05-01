import { EndpointAddressProps } from "../types";

/**
 * Interface for the properties of the `FrontPanelRangeSlider` component.
 */
interface FrontPanelRangeSliderProps {
    /**
     * Address of the frontpanel endpoint
     */
    fpEndpoint: EndpointAddressProps;

    /**
     * Maximum value that the range slider will allow
     */
    maximumValue: number;
}

export default FrontPanelRangeSliderProps;
