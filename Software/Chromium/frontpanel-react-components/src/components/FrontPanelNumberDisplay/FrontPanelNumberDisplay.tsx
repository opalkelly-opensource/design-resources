/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import "./FrontPanelNumberDisplay.css";

import { NumberDisplay } from "../../primitives";

import FrontPanelNumberDisplayProps from "./FrontPanelNumberDisplay.props";

import { FrontPanelContext } from "../../contexts";

import { CalculateBitLength } from "../../core";

import { IFrontPanel, WIREOUT_ADDRESS_RANGE } from "@opalkellytech/frontpanel-chromium-core";

type FrontPanelNumberDisplayElement = React.ElementRef<typeof NumberDisplay>;

interface FrontPanelNumberDisplayCombinedProps
    extends Omit<
            React.ComponentPropsWithoutRef<typeof NumberDisplay>,
            "value" | "maximumValue" | "minimumValue"
        >,
        FrontPanelNumberDisplayProps {}

export type { FrontPanelNumberDisplayCombinedProps };

/**
 * `FrontPanelNumberDisplay` is a React component that renders a number display to represent the value of a WireOut endpoint using
 * binary, octal, decimal, or hexadecimal numeral systems. It also allows to optionally set the decimal scale of the number when
 * using the decimal numeral system.
 *
 * @component
 * @param {object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the number display
 *
 * @returns {React.Node} The rendered FrontPanelNumberDisplay component
 *
 * @example
 * ```jsx
 * <FrontPanelNumberDisplay
 *     fpEndpoint={{epAddress: 0x20, bitOffset: 1}}
 *     maximumValue=0xffffffff />
 * ```
 */
const FrontPanelNumberDisplay = React.forwardRef<
    FrontPanelNumberDisplayElement,
    FrontPanelNumberDisplayCombinedProps
>((props, forwardedRef) => {
    const [value, setValue] = React.useState<bigint>(0n);

    const { device, workQueue, eventSource } = React.useContext(FrontPanelContext);

    const { maximumValue, fpEndpoint, ...rootProps } = props;

    const targetBitLength: number = React.useMemo(() => {
        return CalculateBitLength(maximumValue);
    }, [maximumValue]);

    const targetWireSpanBitMask =
        ((1n << BigInt(targetBitLength)) - 1n) << BigInt(fpEndpoint.bitOffset);

    const onUpdateWireValue = React.useCallback(
        async (sender: IFrontPanel): Promise<void> => {
            await workQueue.Post(async () => {
                // Get the wire value for the endpoint
                let sourceWireValue = await sender.getWireOutValue(fpEndpoint.epAddress);
                let targetWireBitMask = targetWireSpanBitMask & 0xffffffffn;
                let sourceSpanValue =
                    (BigInt(sourceWireValue) & targetWireBitMask) >> BigInt(fpEndpoint.bitOffset);

                if (targetWireSpanBitMask > 0xffffffffn) {
                    // The operations spans multiple endpoints
                    let currentWireSpanBitOffset = 32n - BigInt(fpEndpoint.bitOffset);
                    let currentWireSpanBitMask = targetWireSpanBitMask >> 32n;

                    for (
                        let sourceWireAddress = fpEndpoint.epAddress + 1;
                        sourceWireAddress <= WIREOUT_ADDRESS_RANGE.Maximum &&
                        currentWireSpanBitMask > 0n;
                        sourceWireAddress++
                    ) {
                        // Get the wire value for the next endpoint
                        sourceWireValue = await sender.getWireOutValue(sourceWireAddress);
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

        const subscription =
            eventSource?.WireOutValuesChangedEvent.SubscribeAsync(onUpdateWireValue);

        return () => {
            subscription?.Cancel();
        };
    }, [device, eventSource, onUpdateWireValue]);

    return (
        <NumberDisplay
            {...rootProps}
            ref={forwardedRef}
            maximumValue={maximumValue}
            minimumValue={0n}
            value={value}
        />
    );
});

FrontPanelNumberDisplay.displayName = "FrontPanelNumberDisplay";

export default FrontPanelNumberDisplay;
