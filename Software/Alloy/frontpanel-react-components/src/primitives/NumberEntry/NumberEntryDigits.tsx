/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import classnames from "classnames";

import NumberEntryDigitsProps from "./NumberEntryDigits.props";

import "../../index.css";

import "./NumberEntry.css";

import DigitEntry from "../DigitEntry";

import { NumeralSystem } from "../../core";

/**
 * `NumberEntryDigits` is a React component that renders a list of `DigitEntry` components.
 * Each `DigitEntry` represents a digit in a number entry field.
 * The digits are displayed in the specified numeral system and can be incremented and decremented.
 *
 * @component
 * @param {Object} props - The properties that define the `NumberEntryDigits` component.
 * @param {number} props.size - The size of the digits in the number entry field. Default is 1.
 * @param {number} props.numeralSystem - The numeral system to use for displaying the digits.
 * @param {number} props.decimalScale - The scale of the decimal part of the number entry field. Default is 0.
 * @param {Array} props.digitStates - An array of objects that represent the state of each digit in the number entry field.
 * @param {function} props.onDigitStatesChange - Function to be called when the state of any digit in the number entry field changes.
 *
 * @returns {React.ReactElement} The `NumberEntryDigits` component.
 */
const NumberEntryDigits: React.FC<NumberEntryDigitsProps> = (props) => {
    const {
        variant = "standard",
        size = 1,
        numeralSystem,
        decimalScale = 0,
        digitStates,
        onDigitStatesChange
    } = props;

    const digitListItems = (): JSX.Element[] => {
        const digitEntries = digitStates.map((digitState, digitIndex) => {
            const onDigitValueChanged = (value: number, isKeyDown: boolean) => {
                //console.log("onDigitValueChanged: " + "[" + digitIndex + "], " + value + ", isKeyDown: " + isKeyDown);

                //console.log("oldDigitStates: " + JSON.stringify(digitStates));

                const newDigitStates = [...digitStates];
                newDigitStates[digitIndex] = {
                    ...digitStates[digitIndex],
                    value: value
                };

                //console.log("newDigitStates: " + JSON.stringify(newDigitStates));

                onDigitStatesChange?.(newDigitStates, isKeyDown);
            };

            return (
                <DigitEntry
                    key={"digit-" + digitState.id}
                    variant={variant}
                    size={size}
                    numeralSystem={numeralSystem}
                    value={digitState.value}
                    maximum={digitState.maximum}
                    minimum={digitState.minimum}
                    onValueChanged={onDigitValueChanged}
                />
            );
        });

        if (numeralSystem === NumeralSystem.Decimal && decimalScale > 0) {
            const excessDecimalScale: number = decimalScale - digitEntries.length;

            if (excessDecimalScale < 0) {
                digitEntries.splice(
                    decimalScale,
                    0,
                    <span
                        key={"digit-decimal-point"}
                        className={classnames("okNumberEntryText", "ok-r-size-" + size)}>
                        .
                    </span>
                );
            } else {
                const prefixString: string = "0.";
                const paddedPrefixString = prefixString.padEnd(
                    prefixString.length + excessDecimalScale,
                    "0"
                );

                digitEntries.push(
                    <span
                        key={"digit-decimal-prefix"}
                        className={classnames("okNumberEntryText", "ok-r-size-" + size)}>
                        {paddedPrefixString}
                    </span>
                );
            }
        }

        return digitEntries.reverse();
    };

    return <>{digitListItems()}</>;
};

NumberEntryDigits.displayName = "NumberEntryDigits";

export default NumberEntryDigits;
