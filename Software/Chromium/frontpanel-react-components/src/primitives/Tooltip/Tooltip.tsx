/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import classNames from "classnames";

import * as TooltipPrimitive from "@radix-ui/react-tooltip";

import TooltipProps from "./Tooltip.props";

import "../../index.css";

import "./Tooltip.css";

type TooltipElement = React.ElementRef<typeof TooltipPrimitive.Content>;

interface TooltipCombinedProps
    extends React.ComponentPropsWithoutRef<typeof TooltipPrimitive.Root>,
        Omit<React.ComponentPropsWithoutRef<typeof TooltipPrimitive.Content>, "content">,
        TooltipProps {
    content: NonNullable<TooltipProps["content"]>;
    container?: React.ComponentProps<typeof TooltipPrimitive.Portal>["container"];
}

export type { TooltipCombinedProps };

/**
 * `Tooltip` is a React component that displays a popup with text when the mouse cursor hovers
 * over the child component.
 *
 * @component *
 * @param {object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the button
 *
 * @returns {ReactElement} The rendered Tooltip component
 *
 * @example
 * ```jsx
 * <Tooltip content="Tooltip text">
 *   <button>Hover over me</button>
 * </Tooltip>
 * ```
 */
const Tooltip = React.forwardRef<TooltipElement, TooltipCombinedProps>((props, forwardedRef) => {
    const {
        children,
        className,
        open,
        defaultOpen,
        onOpenChange,
        delayDuration,
        disableHoverableContent,
        content,
        container,
        forceMount,
        ...tooltipContentProps
    } = props;

    const rootProps = {
        open,
        defaultOpen,
        onOpenChange,
        delayDuration,
        disableHoverableContent
    };

    return (
        <TooltipPrimitive.Root {...rootProps}>
            <TooltipPrimitive.Trigger asChild>{children}</TooltipPrimitive.Trigger>
            <TooltipPrimitive.Portal container={container} forceMount={forceMount}>
                <TooltipPrimitive.Content
                    sideOffset={4}
                    collisionPadding={10}
                    {...tooltipContentProps}
                    ref={forwardedRef}
                    className={classNames("okTooltipContent", className)}>
                    <p className="okTooltipText">{content}</p>
                </TooltipPrimitive.Content>
            </TooltipPrimitive.Portal>
        </TooltipPrimitive.Root>
    );
});

export default Tooltip;

Tooltip.displayName = "Tooltip";
