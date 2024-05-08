/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { EthernetPortConfiguration } from "./EthernetPortConfiguration";

/**
 * Ethernet Port View Component Properties
 * @property label - The label to display for the Ethernet Port.
 * @property configuration - The configuration specifying the FrontPanel Endpoints for the Ethernet Port.
 */
interface EthernetPortViewProps {
    label: string;
    configuration: EthernetPortConfiguration;
}

export default EthernetPortViewProps;
