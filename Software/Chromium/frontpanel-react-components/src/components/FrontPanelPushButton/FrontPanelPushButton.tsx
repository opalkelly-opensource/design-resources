import React from "react";

import { Button } from "../../primitives";

import FrontPanelPushButtonProps from "./FrontPanelPushButton.props";

import { FrontPanelContext } from "../../contexts";

type FrontPanelPushButtonElement = React.ElementRef<typeof Button>;

interface FrontPanelPushButtonCombinedProps
    extends Omit<
            React.ComponentPropsWithoutRef<typeof Button>,
            "asChild" | "onButtonClick" | "onButtonDown" | "onButtonUp"
        >,
        FrontPanelPushButtonProps {}

export type { FrontPanelPushButtonCombinedProps };

/**
 * `FrontPanelPushButton` is a React component that renders a push button that asserts a WireIn endpoint
 * when pressed and deasserts it when released.
 *
 * @component
 * @param {object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the button
 *
 * @returns {React.Node} The rendered FrontPanelPushButton component
 *
 * @example
 * ```jsx
 * <FrontPanelPushButton
 *     label="Pushbutton"
 *     fpEndpoint={{epAddress: 0x00, bitOffset: 1}} />
 * ```
 */
const FrontPanelPushButton = React.forwardRef<
    FrontPanelPushButtonElement,
    FrontPanelPushButtonCombinedProps
>((props, forwardedRef) => {
    const { device, workQueue } = React.useContext(FrontPanelContext);

    const { fpEndpoint, ...buttonProps } = props;

    const targetWireBitMask = 1 << fpEndpoint.bitOffset;

    const onButtonUp = React.useCallback(async (): Promise<void> => {
        await workQueue.Post(async () => {
            await device.setWireInValue(fpEndpoint.epAddress, 0, targetWireBitMask);
            await device.updateWireIns();
        });
    }, [device, fpEndpoint, targetWireBitMask, workQueue]);

    const onButtonDown = React.useCallback(async (): Promise<void> => {
        await workQueue.Post(async () => {
            await device.setWireInValue(fpEndpoint.epAddress, 0xffffffff, targetWireBitMask);
            await device.updateWireIns();
        });
    }, [device, fpEndpoint, targetWireBitMask, workQueue]);

    return (
        <Button
            {...buttonProps}
            ref={forwardedRef}
            onButtonUp={onButtonUp}
            onButtonDown={onButtonDown}
        />
    );
});

FrontPanelPushButton.displayName = "FrontPanelPushButton";

export default FrontPanelPushButton;
