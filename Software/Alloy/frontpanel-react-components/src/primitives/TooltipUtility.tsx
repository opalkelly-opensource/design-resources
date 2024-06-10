/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React, { ReactNode } from "react";

import Tooltip from "./Tooltip";

interface TooltipProps {
    tooltip?: string;
}

export function withTooltip<T extends TooltipProps>(targetComponent: ReactNode) {
    return function ComponentWithTooltip(props: T) {
        if (props.tooltip != null) {
            return <Tooltip content={props.tooltip}>{targetComponent}</Tooltip>;
        } else {
            return targetComponent;
        }
    };
}
