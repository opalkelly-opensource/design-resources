/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

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
