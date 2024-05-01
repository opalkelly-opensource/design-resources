import React from "react";

import classnames from "classnames";

import NumberEntryProps, { NumberEntrySize } from "./NumberEntry.props";

import "../../index.css";

import "./NumberEntry.css";

import NumberEntryDigits from "./NumberEntryDigits";

import { DigitEntryState } from "./NumberEntryDigits.props";

import { NumeralSystem, NumericDigits } from "../../core";

import Label from "../Label";
import Tooltip from "../Tooltip";

type NumberEntryElement = React.ElementRef<"div">;

/**
 * `NumberEntry` is a React component that renders a number entry field to allow setting the value of a number
 * represented in binary, octal, decimal, or hexadecimal numeral systems. The values of the individual digits of
 * the number can be entered by key or they can incremented and decremented using the up and down arrow keys and or
 * the mouse wheel. The maximum and minimum values of the number can be specified to limit the range of values that
 * that can be set. Each individual digit shows an indicator to show if the value of that digit can be incremented
 * or decremented based on the maximum and minimum values.
 *
 * @component
 * @param {Object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the number display
 *
 * @returns {React.Node} The rendered NumberEntry component.
 *
 * @example
 * ```jsx
 * <NumberEntry
 *     value={0}
 *     maximumValue={65535}
 *     minimumValue={0} />
 * ```
 */
const NumberEntry = React.forwardRef<NumberEntryElement, NumberEntryProps>(
    (props, forwardedRef) => {
        const { label, tooltip, ...sliderProps } = props;

        const showLabel = label != null;
        const showTooltip = tooltip != null;

        if (showLabel && showTooltip) {
            return (
                <Label {...label}>
                    <Tooltip content={tooltip}>
                        <div style={{ width: "100%" }}>
                            <NumberEntryImpl ref={forwardedRef} {...sliderProps} />
                        </div>
                    </Tooltip>
                </Label>
            );
        } else if (showLabel) {
            return (
                <Label {...label}>
                    <div style={{ width: "100%" }}>
                        <NumberEntryImpl ref={forwardedRef} {...sliderProps} />
                    </div>
                </Label>
            );
        } else if (showTooltip) {
            return (
                <Tooltip content={tooltip}>
                    <div>
                        <NumberEntryImpl ref={forwardedRef} {...sliderProps} />
                    </div>
                </Tooltip>
            );
        } else {
            return <NumberEntryImpl ref={forwardedRef} {...sliderProps} />;
        }
    }
);

NumberEntry.displayName = "NumberEntry";

export default NumberEntry;

interface NumberEntryImplProps
    extends Omit<React.ComponentPropsWithoutRef<typeof NumberEntry>, "label" | "tooltip"> {}

const NumberEntryImpl = React.forwardRef<NumberEntryElement, NumberEntryImplProps>(
    (props, forwardedRef) => {
        const {
            className,
            variant = "standard",
            size = 1,
            disabled = false,
            numeralSystem = NumeralSystem.Decimal,
            decimalScale = 0,
            maximumValue,
            minimumValue,
            value,
            onValueChange
        } = props;

        const digitCount: number = React.useMemo(() => {
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

            return Number(maximumDigitCount);
        }, [maximumValue, minimumValue, numeralSystem]);

        const radix: bigint = BigInt(numeralSystem);

        const digitStates: DigitEntryState[] = ComputeDigitStatesFromValue(
            value,
            maximumValue,
            minimumValue,
            radix,
            digitCount
        );

        const onDigitStatesChange = (
            newDigitStates: readonly DigitEntryState[],
            _isKeyDown: boolean
        ) => {
            let newValue: bigint = ComputeValueFromDigitStates(newDigitStates, radix);

            const crossedZero: boolean = newValue >= 0n !== value >= 0n && newValue !== 0n;

            if (crossedZero) {
                newValue += 2n * -value;
            }

            //console.log("onDigitStatesChange: Value:" + value + "=>" + newValue);

            if (newValue <= maximumValue && newValue >= minimumValue) {
                onValueChange?.(newValue);
            }
        };

        const NegativeSign = (size: NumberEntrySize): JSX.Element => (
            <span className={classnames("okNumberEntryText", "ok-r-size-" + size)}>-</span>
        );

        return (
            <div
                ref={forwardedRef}
                className={classnames("okNumberEntry", className, "ok-r-size-" + size)}
                data-disabled={disabled || undefined}>
                <div className="okNumberEntryContent">
                    {value < 0n && NegativeSign(size)}
                    <NumberEntryDigits
                        variant={variant}
                        size={size}
                        numeralSystem={numeralSystem}
                        decimalScale={decimalScale}
                        digitStates={digitStates}
                        onDigitStatesChange={onDigitStatesChange}
                    />
                </div>
            </div>
        );
    }
);

NumberEntryImpl.displayName = "NumberEntryImpl";

const ComputeValueFromDigitStates = (
    digitStates: readonly DigitEntryState[],
    radix: bigint
): bigint => {
    const digitCount: number = digitStates.length;

    const startDigitIndex: number = digitCount - 1;

    let numericValue: bigint = BigInt(digitStates[startDigitIndex].value);

    for (let digitIndex: number = startDigitIndex - 1; digitIndex >= 0; digitIndex--) {
        numericValue = numericValue * radix + BigInt(digitStates[digitIndex].value);
    }

    return numericValue;
};

const ComputeDigitStatesFromValue = (
    value: bigint,
    maximum: bigint,
    minimum: bigint,
    radix: bigint,
    digitCount: number
): DigitEntryState[] => {
    const retval: DigitEntryState[] = [];

    let currentValue: bigint = value;
    let currentMaxDifference: bigint = maximum - value;
    let currentMinDifference: bigint = minimum - value;

    for (let digitIndex: number = 0; digitIndex < digitCount; digitIndex++) {
        const digitValue: number = Number(currentValue % radix);
        const digitMaximum: number = Math.floor(Number(currentMaxDifference + BigInt(digitValue)));
        const digitMinimum: number = Math.ceil(Number(currentMinDifference + BigInt(digitValue)));

        retval[digitIndex] = {
            id: digitIndex,
            value: digitValue,
            maximum: ComputeDigitLimitValue(digitMaximum, Number(radix)),
            minimum: ComputeDigitLimitValue(digitMinimum, Number(radix))
        };

        currentValue = currentValue / radix;
        currentMaxDifference = currentMaxDifference / radix;
        currentMinDifference = currentMinDifference / radix;
    }

    return retval;
};

const ComputeDigitLimitValue = (
    digitValueDifference: number,
    radix: number
): number | undefined => {
    let retval: number | undefined;

    if (digitValueDifference >= 0) {
        retval = digitValueDifference < radix ? digitValueDifference : undefined;
    } else {
        retval = digitValueDifference > -radix ? digitValueDifference : undefined;
    }

    return retval;
};
