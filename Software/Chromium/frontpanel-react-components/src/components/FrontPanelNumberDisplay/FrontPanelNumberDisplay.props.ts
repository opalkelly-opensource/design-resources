/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
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
