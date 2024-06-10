/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import { RangeSlider } from "../../primitives";

import FrontPanelRangeSliderProps from "./FrontPanelRangeSlider.props";

import { FrontPanelContext } from "../../contexts";

import { CalculateBitLength } from "../../core";

import { IFrontPanel } from "@opalkelly/frontpanel-alloy-core";

type FrontPanelRangeSliderElement = React.ElementRef<typeof RangeSlider>;

interface FrontPanelRangeSliderCombinedProps
    extends Omit<
            React.ComponentPropsWithoutRef<typeof RangeSlider>,
            "defaultValue" | "value" | "maximumValue" | "onValueChange" | "onValueCommit"
        >,
        FrontPanelRangeSliderProps {}

export type { FrontPanelRangeSliderCombinedProps };

/**
 * `FrontPanelRangeSlider` is a React component that renders a range slider to allow setting the value of a WireIn endpoint
 * within a specified range of values by clicking and dragging the slider thumb or by using the arrow keys.
 *
 * @component
 * @param {object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the range slider
 *
 * @returns {React.Node} The rendered FrontPanelRangeSlider component
 *
 * @example
 * ```jsx
 * <FrontPanelRangeSlider
 *     fpEndpoint={{epAddress: 0x00, bitOffset: 1}}
 *     maximumValue=0xff />
 * ```
 */
const FrontPanelRangeSlider = React.forwardRef<
    FrontPanelRangeSliderElement,
    FrontPanelRangeSliderCombinedProps
>((props, forwardedRef) => {
    const [value, setValue] = React.useState<bigint>(0n);

    const { device, workQueue } = React.useContext(FrontPanelContext);

    const { fpEndpoint, maximumValue, ...rootProps } = props;

    const targetBitLength: number = React.useMemo(() => {
        return CalculateBitLength(BigInt(maximumValue));
    }, [maximumValue]);

    const targetWireBitMask =
        ((1n << BigInt(targetBitLength)) - 1n) << BigInt(fpEndpoint.bitOffset);

    const onUpdateWireValue = React.useCallback(
        async (sender: IFrontPanel): Promise<void> => {
            await workQueue.Post(async () => {
                const sourceWireValue = await sender.getWireInValue(fpEndpoint.epAddress);
                const sourceValue =
                    (BigInt(sourceWireValue) & targetWireBitMask) >> BigInt(fpEndpoint.bitOffset);
                setValue(sourceValue);
            });
        },
        [fpEndpoint, targetWireBitMask]
    );

    const onSelectedValueChangeHandler = React.useCallback(
        (value: number) => {
            workQueue.Post(async () => {
                await device.setWireInValue(
                    fpEndpoint.epAddress,
                    value << fpEndpoint.bitOffset,
                    Number(targetWireBitMask)
                );
                await device.updateWireIns();
            });
        },
        [device, fpEndpoint, workQueue, targetWireBitMask]
    );

    React.useEffect(() => {
        onUpdateWireValue(device);
    }, [device, onUpdateWireValue]);

    return (
        <RangeSlider
            {...rootProps}
            ref={forwardedRef}
            defaultValue={Number(value)}
            maximumValue={maximumValue}
            onValueChange={onSelectedValueChangeHandler}
        />
    );
});

FrontPanelRangeSlider.displayName = "FrontPanelRangeSlider";

export default FrontPanelRangeSlider;
