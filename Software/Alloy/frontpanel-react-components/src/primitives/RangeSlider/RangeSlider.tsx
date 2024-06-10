/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import classNames from "classnames";

import * as SliderPrimitive from "@radix-ui/react-slider";

import RangeSliderProps from "./RangeSlider.props";

import "../../index.css";

import "./RangeSlider.css";

import Label from "../Label";
import Tooltip from "../Tooltip";

type RangeSliderElement = React.ElementRef<typeof SliderPrimitive.Root>;

/**
 * `RangeSlider` is a React component that renders a range slider to allow setting a value within a specified
 * range by clicking and dragging the slider thumb or by using the arrow keys. The slider can optionally show
 * a label and/or a tooltip.
 *
 * @component
 * @param {object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the range slider
 *
 * @returns {React.Node} The rendered RangeSlider component
 *
 * @example
 * ```jsx
 * <RangeSlider
 *    defaultValue={50}
 *    maximumValue={100}
 *    minimumValue={0}
 *    valueStep={1}
 *    onValueChange={(value) => console.log(value)} />
 * ```
 */
const RangeSlider = React.forwardRef<RangeSliderElement, RangeSliderProps>(
    (props, forwardedRef) => {
        const { label, tooltip, ...sliderProps } = props;

        const showLabel = label != null;
        const showTooltip = tooltip != null;

        if (showLabel && showTooltip) {
            return (
                <Label className="okRangeSliderLabel" {...label}>
                    <Tooltip content={tooltip}>
                        <div style={{ width: "100%" }}>
                            <RangeSliderImpl ref={forwardedRef} {...sliderProps} />
                        </div>
                    </Tooltip>
                </Label>
            );
        } else if (showLabel) {
            return (
                <Label className="okRangeSliderLabel" {...label}>
                    <div style={{ width: "100%" }}>
                        <RangeSliderImpl ref={forwardedRef} {...sliderProps} />
                    </div>
                </Label>
            );
        } else if (showTooltip) {
            return (
                <Tooltip content={tooltip}>
                    <div style={{ width: "100%" }}>
                        <RangeSliderImpl ref={forwardedRef} {...sliderProps} />
                    </div>
                </Tooltip>
            );
        } else {
            return <RangeSliderImpl ref={forwardedRef} {...sliderProps} />;
        }
    }
);

RangeSlider.displayName = "RangeSlider";

export default RangeSlider;

interface RangeSliderImplProps
    extends Omit<React.ComponentPropsWithoutRef<typeof RangeSlider>, "label"> {}

const RangeSliderImpl = React.forwardRef<RangeSliderElement, RangeSliderImplProps>(
    (props, forwardedRef) => {
        const {
            className,
            tooltip,
            minimumValue = 0,
            maximumValue = 100,
            onValueChange,
            defaultValue = minimumValue,
            value,
            valueStep = 1,
            showThumbLabel = true,
            showTrackLabels = true,
            disabled = false
        } = props;

        const initialValue = value ?? defaultValue;

        const [controlValue, setControlValue] = React.useState<[number]>([initialValue]);

        React.useEffect(() => {
            setControlValue([initialValue]);
        }, [initialValue]);

        const updateControlValue = React.useCallback(
            (value: number): void => {
                setControlValue([value]);
                onValueChange?.(value);
            },
            [onValueChange]
        );

        const RangeSliderTrack = () => {
            return (
                <SliderPrimitive.Track className="okRangeSliderTrack">
                    <SliderPrimitive.Range className="okRangeSliderRange" />
                </SliderPrimitive.Track>
            );
        };

        const showTooltip = tooltip != null;

        return (
            <div
                className={classNames("okRangeSlider", className)}
                data-disabled={disabled || undefined}>
                {showTrackLabels ? <span>{minimumValue}</span> : null}
                <SliderPrimitive.Root
                    ref={forwardedRef}
                    min={minimumValue}
                    max={maximumValue}
                    step={valueStep}
                    value={controlValue}
                    onValueChange={(value) => updateControlValue(value[0])}
                    orientation="horizontal"
                    className="okRangeSliderRoot"
                    disabled={disabled}>
                    {showTooltip ? (
                        <Tooltip content={tooltip}>
                            <RangeSliderTrack />
                        </Tooltip>
                    ) : (
                        <RangeSliderTrack />
                    )}
                    <SliderPrimitive.Thumb className="okRangeSliderThumb">
                        {showThumbLabel ? (
                            <div className="okRangeSliderThumbLabel">{controlValue}</div>
                        ) : null}
                    </SliderPrimitive.Thumb>
                </SliderPrimitive.Root>
                {showTrackLabels ? <span>{maximumValue}</span> : null}
            </div>
        );
    }
);

RangeSliderImpl.displayName = "RangeSliderImpl";
