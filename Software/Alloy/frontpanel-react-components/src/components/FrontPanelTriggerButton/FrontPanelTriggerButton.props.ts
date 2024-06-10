/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

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
