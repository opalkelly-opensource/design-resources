/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import classnames from "classnames";

import NumberDisplayProps from "./NumberDisplay.props";

import "../../index.css";

import "./NumberDisplay.css";

import Label from "../Label";

import { withTooltip } from "../TooltipUtility";

import { NumeralSystem, NumericDigits } from "../../core";

function FormatValueString(
    value: bigint | null,
    digitCount: bigint,
    numeralSystem: NumeralSystem,
    decimalScale: number
): string {
    let retval: string;

    if (value != null) {
        const outputValue: bigint = value >= 0n ? value : -value;
        const outputDigitCount: number = Number(digitCount);

        const outputValueStr: string = outputValue
            .toString(numeralSystem)
            .padStart(outputDigitCount, "0");

        if (numeralSystem === NumeralSystem.Decimal && decimalScale > 0) {
            const integerDigitCount: number = outputDigitCount - decimalScale;

            if (integerDigitCount > 0) {
                retval =
                    outputValueStr.slice(0, integerDigitCount) +
                    "." +
                    outputValueStr.slice(integerDigitCount);
            } else {
                const prefixString: string = "0.";
                const paddedPrefixString = prefixString.padEnd(
                    prefixString.length - integerDigitCount,
                    "0"
                );

                retval = paddedPrefixString + outputValueStr;
            }
        } else {
            retval = outputValueStr;
        }
    } else {
        retval = "Error"; //ERROR: Value is null
    }

    return retval;
}

type NumberDisplayElement = React.ElementRef<"div">;

/**
 * `NumberDisplay` is a React component that renders a number represented in binary, octal,
 * decimal, or hexadecimal numeral systems with optional tooltip. It also allows to
 * optionally set the decimal scale of the number when using the decimal numeral system.
 *
 * @component
 * @param {object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the NumberDisplay
 * @returns {React.Node} The rendered NumberDisplay component
 *
 * @example
 * ```jsx
 * <NumberDisplay
 *    label="Number Display"
 *    value={23456}
 *    maximumValue={65535}
 *    minimumValue={0} />
 * ```
 */
const NumberDisplay = React.forwardRef<NumberDisplayElement, NumberDisplayProps>(
    (props, forwardedRef) => {
        const {
            className,
            label,
            size = 1,
            numeralSystem = NumeralSystem.Decimal,
            decimalScale = 0,
            maximumValue,
            minimumValue,
            value
        } = props;

        const digitCount: bigint = React.useMemo(() => {
            const maximumValueDigitCount: bigint = NumericDigits.ComputeDigitCountFromValue(
                maximumValue,
                numeralSystem
            );
            const minimumValueDigitCount: bigint = NumericDigits.ComputeDigitCountFromValue(
                minimumValue,
                numeralSystem
            );

            const maximumDigitCount: bigint =
                maximumValueDigitCount > minimumValueDigitCount
                    ? maximumValueDigitCount
                    : minimumValueDigitCount;

            return maximumDigitCount;
        }, [maximumValue, minimumValue, numeralSystem]);

        const negativeSign = React.useMemo(
            () => <span className={classnames("okNumberDisplayText", "ok-r-size-" + size)}>-</span>,
            [size]
        );

        const NumberDisplayWithTooltip = withTooltip(
            <div
                ref={forwardedRef}
                className={classnames("okNumberDisplay", className, "ok-r-size-" + size)}>
                <div className="okNumberDisplayContent">
                    {value < 0n && negativeSign}
                    <span className="okNumberDisplayText">
                        {FormatValueString(value, digitCount, numeralSystem, decimalScale)}
                    </span>
                </div>
            </div>
        );

        const showLabel = label != null;

        if (showLabel) {
            return (
                <Label {...label}>
                    <div style={{ width: "100%" }}>
                        <NumberDisplayWithTooltip {...props} />
                    </div>
                </Label>
            );
        } else {
            <NumberDisplayWithTooltip {...props} />;
        }
    }
);

NumberDisplay.displayName = "NumberDisplay";

export default NumberDisplay;
