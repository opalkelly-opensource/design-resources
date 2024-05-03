/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

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
