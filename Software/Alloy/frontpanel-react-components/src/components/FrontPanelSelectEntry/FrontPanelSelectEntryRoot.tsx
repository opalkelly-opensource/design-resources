/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import { SelectEntry } from "../../primitives";

import FrontPanelSelectEntryRootProps from "./FrontPanelSelectEntryRoot.props";

import { FrontPanelContext } from "../../contexts";

import { CalculateBitLength } from "../../core";

import { IFrontPanel, WIREIN_ADDRESS_RANGE } from "@opalkelly/frontpanel-alloy-core";

interface FrontPanelSelectEntryRootCombinedProps
    extends React.ComponentPropsWithoutRef<typeof SelectEntry.Root>,
        FrontPanelSelectEntryRootProps {}

export type { FrontPanelSelectEntryRootCombinedProps };

/**
 * `FrontPanelSelectEntryRoot` is a React component that is the root component of a select entry that
 * allows setting a WireIn endpoint. The children of this component are used to specify the component
 * parts. The parts include the trigger that can be clicked on to show a list of options to select from,
 * and the content that is the list of options.
 *
 * @component
 * @param {object} props - Properties passed to component
 * @param {object} rootProps - Any additional properties to pass to the root component
 *
 * @returns {React.Node} The rendered FrontPanelSelectEntryRoot component
 *
 * @example
 * ```jsx
 * <FrontPanelSelectEntryRoot
 *     fpEndpoint={{epAddress: 0x00, bitOffset: 1}}
 *     maximumValue=2 />
 *     <FrontPanelSelectEntry.Trigger />
 *     <FrontPanelSelectEntry.Content>
 *         <FrontPanelSelectEntry.Group>
 *             <FrontPanelSelectEntry.Label>Options</FrontPanelSelectEntry.Label>
 *             <FrontPanelSelectEntry.Item value="0">Option 0</FrontPanelSelectEntry.Option>
 *             <FrontPanelSelectEntry.Item value="1">Option 1</FrontPanelSelectEntry.Option>
 *             <FrontPanelSelectEntry.Item value="2">Option 2</FrontPanelSelectEntry.Option>
 *         </FrontPanelSelectEntry.Group>
 *    </FrontPanelSelectEntry.Content>
 * </FrontPanelSelectEntryRoot>
 * ```
 */
const FrontPanelSelectEntryRoot: React.FC<FrontPanelSelectEntryRootCombinedProps> = (props) => {
    const [value, setValue] = React.useState<bigint>(0n);

    const { device, workQueue } = React.useContext(FrontPanelContext);

    const { fpEndpoint, maximumValue, ...rootProps } = props;

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

    const onSelectedValueChangeHandler = React.useCallback(
        (value: string) => {
            const targetWireSpanValue = BigInt(value);
            workQueue.Post(async () => {
                let targetWireBitMask = targetWireSpanBitMask & 0xffffffffn;
                let targetWireValue = Number(
                    (targetWireSpanValue << BigInt(fpEndpoint.bitOffset)) & targetWireBitMask
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

                    const maxWireCount = 0x20 - fpEndpoint.epAddress;

                    for (
                        let wireIndex = 1;
                        wireIndex < maxWireCount && currentWireSpanBitMask > 0n;
                        wireIndex++
                    ) {
                        targetWireBitMask = currentWireSpanBitMask & 0xffffffffn;
                        targetWireValue = Number(
                            (targetWireSpanValue >> currentWireSpanBitOffset) & targetWireBitMask
                        );

                        // Set the wire value for the next endpoint
                        await device.setWireInValue(
                            fpEndpoint.epAddress + wireIndex,
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
        [device, fpEndpoint, workQueue, onUpdateWireValue]
    );

    React.useEffect(() => {
        onUpdateWireValue(device);
    }, [device, onUpdateWireValue]);

    return (
        <SelectEntry.Root
            {...rootProps}
            value={value.toString()}
            onValueChange={onSelectedValueChangeHandler}
        />
    );
};

FrontPanelSelectEntryRoot.displayName = "FrontPanelSelectEntryRoot";

export default FrontPanelSelectEntryRoot;
