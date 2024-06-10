/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import { NumeralSystem } from "../../core";

import { LabelProps } from "../Label";

export type NumberDisplaySize = 1 | 2 | 3;

/**
 * Interface for the properties of the `NumberDisplay` component.
 */
interface NumberDisplayProps {
    /**
     * Current value to be displayed
     */
    value: bigint;

    /**
     * Maximum value that can be displayed
     */
    maximumValue: bigint;

    /**
     * Minimum value that can be displayed
     */
    minimumValue: bigint;

    /**
     * Optional CSS class to apply to the number display
     */
    className?: string;

    /**
     * Optional label properties for the number display
     */
    label?: LabelProps;

    /**
     * Optional size of the number display
     * @default 1
     */
    size?: NumberDisplaySize;

    /**
     * Optional tooltip text to be displayed on hover
     */
    tooltip?: string;

    /**
     * Optional numeral system to be used for the number display, defined in NumeralSystem
     */
    numeralSystem?: NumeralSystem;

    /**
     * Optional decimal scale for the number entry (Only used when numeral system is NumeralSystem.Decimal)
     */
    decimalScale?: number;
}

export default NumberDisplayProps;
