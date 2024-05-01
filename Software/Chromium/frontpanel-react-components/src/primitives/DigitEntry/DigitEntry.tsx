import React from "react";

import classNames from "classnames";

import { IndicatorArrowIcon, IndicatorArrowDirection } from "../../components/Icons";
import { IndicatorBarIcon } from "../../components/Icons";

import DigitEntryProps from "./DigitEntry.props";

import "../../index.css";

import "./DigitEntry.css";

import { NumeralSystem } from "../../core";

type DigitEntryElement = React.ElementRef<"div">;

/**
 * `DigitEntry` is a React component that renders a digit entry field to allow setting the value of the digit represented
 * in binary, octal, decimal, or hexadecimal number systems. The value of the digit can be entered by key or the current
 * value can be incremented or decremented using the up and down arrow keys and or the mouse wheel. A maximum and minimum
 * value can be specified to limit the range of values that the digit entry field can have. Indicators are displayed to
 * show when the value can be incremented or decremented based on the maximum and minimum values.
 *
 * @component
 * @param {Object} props - Properties passed to component
 * @param {React.Ref<DigitEntryElement>} forwardedRef - Forwarded ref for the number display
 *
 * @returns {React.ReactElement} The rendered DigitEntry component
 *
 * @example
 * ```jsx
 * <DigitEntry
 *     value={0}
 *     maximum={5}
 *     minimum={2} />
 * ```
 */
const DigitEntry: React.FC<DigitEntryProps> = (props) => {
    const digitEntryRef = React.useRef<DigitEntryElement>(null);

    const {
        className,
        variant = "standard",
        size = 1,
        value,
        maximum,
        minimum,
        numeralSystem = NumeralSystem.Decimal,
        onValueChanged
    } = props;

    const valueRef = React.useRef(value);

    valueRef.current = props.value;

    const valueChangedRef = React.useRef(onValueChanged);

    valueChangedRef.current = onValueChanged;

    const onDigitKeyboardEventHandler = (event: React.KeyboardEvent<HTMLDivElement>) => {
        let isHandled: boolean = false;

        switch (event.key) {
            case "ArrowUp":
                onValueChanged?.(value + 1, false);
                isHandled = true;
                break;
            case "ArrowDown":
                onValueChanged?.(value - 1, false);
                isHandled = true;
                break;
            case "ArrowRight":
                {
                    const nextElement: HTMLDivElement | null = event.currentTarget
                        .nextElementSibling as HTMLDivElement;
                    nextElement?.focus();
                    isHandled = true;
                }
                break;
            case "ArrowLeft":
                {
                    const previousElement: HTMLDivElement | null = event.currentTarget
                        .previousElementSibling as HTMLDivElement;
                    previousElement?.focus();
                    isHandled = true;
                }
                break;
            default:
                isHandled = false;
                break;
        }

        if (isHandled) {
            event.stopPropagation();
            event.preventDefault();
        } else {
            const numericValue: number = parseInt(event.key, numeralSystem);

            if (!Number.isNaN(numericValue)) {
                onValueChanged?.(numericValue, true);

                const nextElement: HTMLDivElement | null = event.currentTarget
                    .nextElementSibling as HTMLDivElement;

                nextElement?.focus();
            }
        }
    };

    React.useEffect(() => {
        const onDigitMouseWheelEventHandler = (event: WheelEvent) => {
            if (event.deltaY < 0) {
                valueChangedRef.current?.(valueRef.current + 1, false);

                event.stopPropagation();
                event.preventDefault();
            } else if (event.deltaY > 0) {
                valueChangedRef.current?.(valueRef.current - 1, false);

                event.stopPropagation();
                event.preventDefault();
            }
        };

        digitEntryRef.current?.addEventListener("wheel", onDigitMouseWheelEventHandler, {
            passive: false
        });

        return () => {
            digitEntryRef.current?.removeEventListener("wheel", onDigitMouseWheelEventHandler);
        };
    }, [digitEntryRef]);

    const canIncrement = maximum != null ? value < maximum : true;
    const canDecrement = minimum != null ? value > minimum : true;

    const DigitEntryIncrementIndicator = (): React.ReactNode => {
        let indicator: React.ReactNode;

        switch (variant) {
            case "standard":
                indicator = (
                    <IndicatorArrowIcon
                        className={classNames("okDigitEntryIncrementIndicator")}
                        direction={IndicatorArrowDirection.Up}
                        color="#343434"
                        data-enabled={canIncrement}
                    />
                );
                break;
            case "compact":
                indicator = (
                    <IndicatorBarIcon
                        className={classNames("okDigitEntryIncrementIndicator")}
                        color="#343434"
                        data-enabled={canIncrement}
                    />
                );
                break;
            default:
                indicator = null;
                break;
        }

        return indicator;
    };

    const DigitEntryDecrementIndicator = (): React.ReactNode => {
        let indicator: React.ReactNode;

        switch (variant) {
            case "standard":
                indicator = (
                    <IndicatorArrowIcon
                        className={classNames("okDigitEntryDecrementIndicator")}
                        direction={IndicatorArrowDirection.Down}
                        color="#343434"
                        data-enabled={canDecrement}
                    />
                );
                break;
            case "compact":
                indicator = (
                    <IndicatorBarIcon
                        className={classNames("okDigitEntryDecrementIndicator")}
                        color="#343434"
                        data-enabled={canDecrement}
                    />
                );
                break;
            default:
                indicator = null;
                break;
        }

        return indicator;
    };

    return (
        <div
            className={classNames("okDigitEntry", className, "ok-r-size-" + size)}
            ref={digitEntryRef}
            tabIndex={-1}
            onMouseEnter={(e) => e.currentTarget.focus()}
            onMouseLeave={(e) => e.currentTarget.blur()}
            onKeyDown={onDigitKeyboardEventHandler}>
            <DigitEntryIncrementIndicator />
            <div className={classNames("okDigitEntryContent", "ok-r-size-" + size)}>
                {Math.abs(value).toString(Number(numeralSystem))}
            </div>
            <DigitEntryDecrementIndicator />
        </div>
    );
};

DigitEntry.displayName = "DigitEntry";

export default DigitEntry;
