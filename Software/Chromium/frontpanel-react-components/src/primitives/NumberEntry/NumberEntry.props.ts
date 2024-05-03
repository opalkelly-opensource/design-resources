/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { NumeralSystem } from "../../core";

import { LabelProps } from "../Label";

import { DigitEntryVariant } from "../DigitEntry";

export type NumberEntrySize = 1 | 2 | 3;
export type NumberEntryValueChangeEventHandler = (value: bigint) => void;

/**
 * Interface for the properties of the `NumberEntry` component.
 */
interface NumberEntryProps {
    /**
     * Current value of the number entry
     */
    value: bigint;

    /**
     * Maximum value that can be entered
     */
    maximumValue: bigint;

    /**
     * Minimum value that can be entered
     */
    minimumValue: bigint;

    /**
     * Optional CSS class to apply to the number entry
     */
    className?: string;

    /**
     * Optional decimal scale for the number entry (Only used when numeral system is NumeralSystem.Decimal)
     */
    decimalScale?: number;

    /**
     * Optional disable the number entry
     * @default false
     */
    disabled?: boolean;

    /**
     * Optional label properties for the number entry
     */
    label?: LabelProps;

    /**
     * Optional numeral system to be used for the number entry, defined in NumeralSystem
     * @default Decimal
     */
    numeralSystem?: NumeralSystem;

    /**
     * Optional Size of the number entry
     * @default 1
     */
    size?: NumberEntrySize;

    /**
     * Optional tooltip text to be displayed on hover
     */
    tooltip?: string;

    /**
     * Optional variant of the digit entry
     * @default standard
     */
    variant?: DigitEntryVariant;

    /**
     * Optional event handler for the value changed event
     */
    onValueChange?: NumberEntryValueChangeEventHandler;
}

export default NumberEntryProps;
