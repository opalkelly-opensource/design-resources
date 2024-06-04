/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import * as React from "react";

import { StateIconProps } from "./types";

import { ToggleState } from "../../core";

export interface RadioToggleStateIconProps extends StateIconProps {
    state: ToggleState;
}

const StateIcon = (state: ToggleState, color: string, colorOnState: string): React.ReactNode => {
    let icon: React.ReactNode;

    switch (state) {
        case ToggleState.On:
            icon = (
                <>
                    <circle cx="7" cy="7" r="6" stroke={color} strokeWidth="2" />
                    <circle cx="7" cy="7" r="3" fill={colorOnState} />
                </>
            );
            break;
        case ToggleState.Off:
            icon = <circle cx="7" cy="7" r="6" stroke={color} strokeWidth="2" />;
            break;
        default:
            icon = <circle cx="7" cy="7" r="6" stroke={color} strokeWidth="2" />;
            break;
    }

    return icon;
};

const RadioToggleStateIcon = React.forwardRef<SVGSVGElement, RadioToggleStateIconProps>(
    (props, forwardedRef) => {
        const { state, color = "#343434", colorOnState = "#44BD84", ...iconProps } = props;

        return (
            <svg
                xmlns="http://www.w3.org/2000/svg"
                width="14"
                height="14"
                viewBox="0 0 14 14"
                fill="none"
                {...iconProps}
                ref={forwardedRef}>
                {StateIcon(state, color, colorOnState)}
            </svg>
        );
    }
);

export default RadioToggleStateIcon;

RadioToggleStateIcon.displayName = "RadioToggleStateIcon";
