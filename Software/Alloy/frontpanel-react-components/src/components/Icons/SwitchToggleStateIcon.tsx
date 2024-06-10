/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import * as React from "react";

import { StateIconProps } from "./types";

import { ToggleState } from "../../core";

export interface SwitchToggleStateIconProps extends StateIconProps {
    state: ToggleState;
}

const StateIcon = (
    state: ToggleState,
    color: string,
    colorOnState: string,
    colorOffState: string
): React.ReactNode => {
    let icon: React.ReactNode;

    switch (state) {
        case ToggleState.On:
            icon = <circle cx="4" cy="4" r="3.75" fill={colorOnState} />;
            break;
        case ToggleState.Off:
            icon = <circle cx="4" cy="4" r="3.75" fill={colorOffState} />;
            break;
        default:
            icon = <circle cx="4" cy="4" r="3.75" fill={color} />;
            break;
    }

    return icon;
};

const SwitchToggleStateIcon = React.forwardRef<SVGSVGElement, SwitchToggleStateIconProps>(
    (props, forwardedRef) => {
        const {
            state,
            color = "white",
            colorOnState = "white",
            colorOffState = "white",
            ...iconProps
        } = props;

        return (
            <svg
                xmlns="http://www.w3.org/2000/svg"
                width="8"
                height="8"
                viewBox="0 0 8 8"
                fill="none"
                {...iconProps}
                ref={forwardedRef}>
                {StateIcon(state, color, colorOnState, colorOffState)}
            </svg>
        );
    }
);

export default SwitchToggleStateIcon;

SwitchToggleStateIcon.displayName = "SwitchToggleStateIcon";
