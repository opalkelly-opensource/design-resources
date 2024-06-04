/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import * as React from "react";

import { StateIconProps } from "./types";

import { ToggleState } from "../../core";

export interface IndicatorStateIconProps extends StateIconProps {
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
            icon = (
                <path
                    d="M5 10C7.76142 10 10 7.76142 10 5C10 2.23858 7.76142 0 5 0C2.23858 0 0 2.23858 0 5C0 7.76142 2.23858 10 5 10Z"
                    fill={colorOnState}
                />
            );
            break;
        case ToggleState.Off:
            icon = (
                <path
                    d="M5 10C7.76142 10 10 7.76142 10 5C10 2.23858 7.76142 0 5 0C2.23858 0 0 2.23858 0 5C0 7.76142 2.23858 10 5 10Z"
                    fill={colorOffState}
                />
            );
            break;
        default:
            icon = (
                <path
                    d="M5 10C7.76142 10 10 7.76142 10 5C10 2.23858 7.76142 0 5 0C2.23858 0 0 2.23858 0 5C0 7.76142 2.23858 10 5 10Z"
                    fill={color}
                />
            );
            break;
    }

    return icon;
};

const IndicatorStateIcon = React.forwardRef<SVGSVGElement, IndicatorStateIconProps>(
    (props, forwardedRef) => {
        const {
            state,
            color = "#D0D7DF",
            colorOnState = "#44BD84",
            colorOffState = "#D0D7DF"
        } = props;

        return (
            <svg
                xmlns="http://www.w3.org/2000/svg"
                width="10"
                height="10"
                viewBox="0 0 10 10"
                fill="none"
                {...props}
                ref={forwardedRef}>
                {StateIcon(state, color, colorOnState, colorOffState)}
            </svg>
        );
    }
);

export default IndicatorStateIcon;

IndicatorStateIcon.displayName = "IndicatorStateIcon";
