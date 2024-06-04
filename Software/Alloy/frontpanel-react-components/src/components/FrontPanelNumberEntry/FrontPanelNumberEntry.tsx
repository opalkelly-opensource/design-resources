/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import "./FrontPanelNumberEntry.css";

import { NumberEntry } from "../../primitives";

import FrontPanelNumberEntryProps from "./FrontPanelNumberEntry.props";

import { FrontPanelContext } from "../../contexts";

import { CalculateBitLength } from "../../core";

import { IFrontPanel, WIREIN_ADDRESS_RANGE } from "@opalkellytech/frontpanel-chromium-core";

type FrontPanelNumberEntryElement = React.ElementRef<typeof NumberEntry>;

interface FrontPanelNumberEntryCombinedProps
    extends Omit<
            React.ComponentPropsWithoutRef<typeof NumberEntry>,
            "value" | "maximumValue" | "minimumValue" | "onValueChange"
        >,
        FrontPanelNumberEntryProps {}

export type { FrontPanelNumberEntryCombinedProps };

/**
 * `FrontPanelNumberEntry` is a React component that renders a number entry field to allow setting the value of a WireIn endpoint
 * represented in binary, octal, decimal, or hexadecimal numeral systems. The values of the individual digits of the number can
 * be entered by key or they can be incremented and decremented using the up and down arrow keys and or the mouse wheel.
 *
 * @component
 * @param {Object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the number display
 *
 * @returns {React.Node} The rendered FrontPanelNumberDisplay component
 *
 * @example
 * ```jsx
 * <FrontPanelNumberEntry
 *     fpEndpoint={{epAddress: 0x00, bitOffset: 1}}
 *     maximumValue=0xffffffff />
 * ```
 */
const FrontPanelNumberEntry = React.forwardRef<
    FrontPanelNumberEntryElement,
    FrontPanelNumberEntryCombinedProps
>((props, forwardedRef) => {
    const [value, setValue] = React.useState<bigint>(props.minimumValue ?? 0n);

    const { device, workQueue } = React.useContext(FrontPanelContext);

    const { maximumValue, minimumValue, fpEndpoint, ...rootProps } = props;

    const clampedMinimumValue = React.useMemo(() => {
        return typeof minimumValue !== "undefined"
            ? ClampValue(minimumValue, maximumValue, 0n)
            : 0n;
    }, [minimumValue, maximumValue]);

    const targetBitLength: number = React.useMemo(() => {
        return CalculateBitLength(maximumValue);
    }, [maximumValue]);

    const targetWireSpanBitMask =
        ((1n << BigInt(targetBitLength)) - 1n) << BigInt(fpEndpoint.bitOffset);

    const onUpdateWireValue = React.useCallback(
        async (sender: IFrontPanel): Promise<void> => {
            await workQueue.Post(async () => {
                // Get the wire value for the endpoint
                let sourceWireValue = await sender.getWireInValue(fpEndpoint.epAddress);
                let targetWireBitMask = targetWireSpanBitMask & 0xffffffffn;
                let sourceSpanValue =
                    (BigInt(sourceWireValue) & targetWireBitMask) >> BigInt(fpEndpoint.bitOffset);

                if (targetWireSpanBitMask > 0xffffffffn) {
                    // The operations spans multiple endpoints
                    let currentWireSpanBitOffset = 32n - BigInt(fpEndpoint.bitOffset);
                    let currentWireSpanBitMask = targetWireSpanBitMask >> 32n;

                    for (
                        let sourceWireAddress = fpEndpoint.epAddress + 1;
                        sourceWireAddress <= WIREIN_ADDRESS_RANGE.Maximum &&
                        currentWireSpanBitMask > 0n;
                        sourceWireAddress++
                    ) {
                        // Get the wire value for the next endpoint
                        sourceWireValue = await sender.getWireInValue(sourceWireAddress);
                        targetWireBitMask = currentWireSpanBitMask & 0xffffffffn;
                        sourceSpanValue |=
                            (BigInt(sourceWireValue) & targetWireBitMask) <<
                            currentWireSpanBitOffset;

                        currentWireSpanBitOffset += 32n;
                        currentWireSpanBitMask >>= 32n;
                    }
                }

                setValue(sourceSpanValue);
            });
        },
        [fpEndpoint, targetWireSpanBitMask]
    );

    React.useEffect(() => {
        onUpdateWireValue(device);
    }, [device, onUpdateWireValue]);

    const onNumberEntryValueChange = React.useCallback(
        async (value: bigint): Promise<void> => {
            await workQueue.Post(async () => {
                let targetWireBitMask = targetWireSpanBitMask & 0xffffffffn;
                let targetWireValue = Number(
                    (value << BigInt(fpEndpoint.bitOffset)) & targetWireBitMask
                );

                // Set the wire value for the endpoint
                await device.setWireInValue(
                    fpEndpoint.epAddress,
                    targetWireValue,
                    Number(targetWireBitMask)
                );

                if (targetWireSpanBitMask > 0xffffffffn) {
                    // The operations spans multiple endpoints
                    let currentWireSpanBitOffset = 32n - BigInt(fpEndpoint.bitOffset);
                    let currentWireSpanBitMask = targetWireSpanBitMask >> 32n;

                    for (
                        let targetWireAddress = fpEndpoint.epAddress + 1;
                        targetWireAddress <= WIREIN_ADDRESS_RANGE.Maximum &&
                        currentWireSpanBitMask > 0n;
                        targetWireAddress++
                    ) {
                        targetWireBitMask = currentWireSpanBitMask & 0xffffffffn;
                        targetWireValue = Number(
                            (value >> currentWireSpanBitOffset) & targetWireBitMask
                        );

                        // Set the wire value for the next endpoint
                        await device.setWireInValue(
                            targetWireAddress,
                            targetWireValue,
                            Number(targetWireBitMask)
                        );

                        currentWireSpanBitOffset += 32n;
                        currentWireSpanBitMask >>= 32n;
                    }
                }

                await device.updateWireIns();
            });

            onUpdateWireValue(device);
        },
        [device, workQueue, fpEndpoint, targetWireSpanBitMask, onUpdateWireValue]
    );

    return (
        <NumberEntry
            {...rootProps}
            ref={forwardedRef}
            maximumValue={maximumValue}
            minimumValue={clampedMinimumValue}
            value={value}
            onValueChange={onNumberEntryValueChange}
        />
    );
});

FrontPanelNumberEntry.displayName = "FrontPanelNumberEntry";

export default FrontPanelNumberEntry;

function ClampValue(value: bigint, maximumLimit: bigint, minimumLimit: bigint): bigint {
    let retval: bigint;

    if (value < minimumLimit) {
        retval = minimumLimit;
    } else if (value > maximumLimit) {
        retval = maximumLimit;
    } else {
        retval = value;
    }

    return retval;
}
