/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import { IFrontPanel, WireValue } from "@opalkelly/frontpanel-alloy-core";

import { ToggleState } from "../../core";

import { ToggleSwitch } from "../../primitives";

import { FrontPanelContext } from "../../contexts";

import FrontPanelToggleSwitchProps from "./FrontPanelToggleSwitch.props";

type FrontPanelToggleSwitchElement = React.ElementRef<typeof ToggleSwitch>;

interface FrontPanelToggleSwitchCombinedProps
    extends Omit<
            React.ComponentPropsWithoutRef<typeof ToggleSwitch>,
            "state" | "onToggleStateChanged"
        >,
        FrontPanelToggleSwitchProps {}

export type { FrontPanelToggleSwitchCombinedProps };

/**
 * `FrontPanelToggleSwitch` is a React component that renders a toggle switch with an optional label and or tooltip
 *  to toggle the state of a WireIn endpoint.
 *
 * @component
 * @param {Object} props - The properties that define the `FrontPanelToggleSwitch` component.
 * @param {React.Ref<FrontPanelToggleSwitchElement>} forwardedRef - A ref that is forwarded to the `FrontPanelToggleSwitch` component.
 *
 * @returns {React.ReactElement} The `FrontPanelToggleSwitch` component.
 *
 * @example
 * ```jsx
 * <FrontPanelToggleSwitch
 *    label="Toggle"
 *    fpEndpoint={{epAddress: 0x00, bitOffset: 1}} />
 * ```
 */
const FrontPanelToggleSwitch = React.forwardRef<
    FrontPanelToggleSwitchElement,
    FrontPanelToggleSwitchCombinedProps
>((props, forwardedRef) => {
    const [state, setState] = React.useState<ToggleState>(ToggleState.Off);

    const { device, workQueue } = React.useContext(FrontPanelContext);

    const { fpEndpoint, ...buttonProps } = props;

    const targetWireBitMask = 1 << fpEndpoint.bitOffset;

    const onUpdateWireValue = React.useCallback(
        async (sender: IFrontPanel): Promise<void> => {
            await workQueue.Post(async () => {
                // Set the toggle state based on the value of the target bit of the Wire endpoint
                const sourceWireValue = await sender.getWireInValue(fpEndpoint.epAddress);
                const sourceBitValue = (sourceWireValue & targetWireBitMask) === targetWireBitMask;
                const newToggleState = sourceBitValue ? ToggleState.On : ToggleState.Off;
                setState(newToggleState);
            });
        },
        [fpEndpoint, targetWireBitMask]
    );

    const onToggleStateChanged = React.useCallback(
        async (state: ToggleState): Promise<void> => {
            await workQueue.Post(async () => {
                // Set the value of the target bit of the Wire endpoint based on the toggle state
                const targetWireValue: WireValue = state === ToggleState.On ? 0xffffffff : 0;

                await device.setWireInValue(
                    fpEndpoint.epAddress,
                    targetWireValue,
                    targetWireBitMask
                );
                await device.updateWireIns();
            });

            onUpdateWireValue(device);
        },
        [device, fpEndpoint, targetWireBitMask, workQueue]
    );

    React.useEffect(() => {
        onUpdateWireValue(device);
    }, [device, onUpdateWireValue]);

    return (
        <ToggleSwitch
            ref={forwardedRef}
            {...buttonProps}
            state={state}
            onToggleStateChanged={onToggleStateChanged}
        />
    );
});

FrontPanelToggleSwitch.displayName = "FrontPanelToggleSwitch";

export default FrontPanelToggleSwitch;
