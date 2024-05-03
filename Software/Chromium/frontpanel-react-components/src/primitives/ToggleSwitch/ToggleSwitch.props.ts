/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import ToggleProps from "../Toggle/Toggle.props";

/**
 * Interface for the properties of the `ToggleSwitch` component.
 */
interface ToggleSwitchProps extends ToggleProps {
    /**
     * Label to be displayed on the toggle switch
     */
    label: string;

    /**
     * Optional disable the toggle switch
     * @default false
     */
    disabled?: boolean;
}

export default ToggleSwitchProps;
