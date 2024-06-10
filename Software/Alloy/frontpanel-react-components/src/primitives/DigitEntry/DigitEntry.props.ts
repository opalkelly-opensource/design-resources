/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import { NumeralSystem } from "../../core";

export type DigitEntryVariant = "standard" | "compact";
export type DigitEntrySize = 1 | 2 | 3;
export type DigitEntryValueChangeEventHandler = (value: number, isKeyDown: boolean) => void;

/**
 * Interface for the properties of the `DigitEntry` component.
 */
interface DigitEntryProps {
    /**
     * The current value of the digit entry
     */
    value: number;

    /**
     * Optional CSS class to apply to the digit entry
     */
    className?: string;

    /**
     * The maximum value that the digit entry can have
     */
    maximum?: number;

    /**
     * The minimum value that the digit entry can have
     */
    minimum?: number;

    /**
     * The numeral system for the digit entry
     * @default Decimal
     */
    numeralSystem?: NumeralSystem;

    /**
     * Size of the digit entry
     * @default 1
     */
    size?: DigitEntrySize;

    /**
     * Variant of the digit entry
     * @default standard
     */
    variant?: DigitEntryVariant;

    /**
     * Optional event handler for the value changed event
     */
    onValueChanged?: DigitEntryValueChangeEventHandler;
}

export default DigitEntryProps;
