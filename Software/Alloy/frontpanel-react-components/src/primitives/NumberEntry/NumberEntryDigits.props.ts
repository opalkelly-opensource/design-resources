/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import { NumeralSystem } from "../../core";

import { DigitEntryVariant } from "../DigitEntry";

export type DigitEntrySize = 1 | 2 | 3;
export type DigitEntryStatesChangeEventHandler = (
    digitStates: readonly DigitEntryState[],
    isKeyDown: boolean
) => void;

export type DigitEntryState = {
    id: number;
    value: number;
    maximum?: number;
    minimum?: number;
};

interface NumberEntryDigitsProps {
    /**
     * Variant of the digit entry
     */
    variant?: DigitEntryVariant;

    /**
     * Size of the digit entry
     */
    size: DigitEntrySize;

    /**
     * Numeral system to be used for the number entry, defined in NumeralSystem enum
     */
    numeralSystem: NumeralSystem;

    /**
     * Current value of the number entry
     */
    digitStates: DigitEntryState[];

    /**
     * Optional decimal scale for the number entry (Only used when numeral system is NumeralSystem.Decimal)
     */
    decimalScale?: number;

    /**
     * Event handler for the number entries state change event
     */
    onDigitStatesChange?: DigitEntryStatesChangeEventHandler;
}

export default NumberEntryDigitsProps;
