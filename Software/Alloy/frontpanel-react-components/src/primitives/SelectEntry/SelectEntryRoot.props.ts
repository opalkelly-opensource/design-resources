/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import LabelProps from "../Label/Label.props";

export type SelectEntrySize = 1 | 2 | 3;

/**
 * Interface for the properties of the `SelectEntryRoot` component.
 */
interface SelectEntryRootProps {
    /**
     * Optional CSS class to apply to the select entry root
     */
    className?: string;

    /**
     * Optional label properties for the select entry root
     */
    label?: LabelProps;

    /**
     * Optional size of the select entry root
     * @default 1
     */
    size?: SelectEntrySize;

    /**
     * Optional tooltip text to be displayed on hover
     */
    tooltip?: string;
}

export default SelectEntryRootProps;
