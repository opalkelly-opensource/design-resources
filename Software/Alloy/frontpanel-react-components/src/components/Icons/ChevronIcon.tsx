/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import * as React from "react";

import { IconProps } from "./types";

export enum ChevronDirection {
    Up,
    Down
}

export interface ChevronIconProps extends IconProps {
    direction: ChevronDirection;
}

const DirectionChevron = (direction: ChevronDirection, color: string): React.ReactNode => {
    let arrow: React.ReactNode;

    if (direction === ChevronDirection.Up) {
        arrow = (
            <path
                d="M6.75593 7.12713C6.35716 7.58759 5.64284 7.58759 5.24407 7.12713L2.23682 3.65465C1.67594 3.00701 2.136 2 2.99275 2L9.00725 2C9.864 2 10.3241 3.00701 9.76318 3.65465L6.75593 7.12713Z"
                fill={color}
            />
        );
    } else if (direction === ChevronDirection.Down) {
        arrow = (
            <path
                d="M6.75593 7.12713C6.35716 7.58759 5.64284 7.58759 5.24407 7.12713L2.23682 3.65465C1.67594 3.00701 2.136 2 2.99275 2L9.00725 2C9.864 2 10.3241 3.00701 9.76318 3.65465L6.75593 7.12713Z"
                fill={color}
            />
        );
    } else {
        arrow = (
            <path
                d="M6.75593 7.12713C6.35716 7.58759 5.64284 7.58759 5.24407 7.12713L2.23682 3.65465C1.67594 3.00701 2.136 2 2.99275 2L9.00725 2C9.864 2 10.3241 3.00701 9.76318 3.65465L6.75593 7.12713Z"
                fill={color}
            />
        );
    }

    return arrow;
};

const ChevronIcon = React.forwardRef<SVGSVGElement, ChevronIconProps>((props, forwardedRef) => {
    const { direction = ChevronDirection.Down, color = "#343434", ...iconProps } = props;

    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            width="12"
            height="8"
            viewBox="0 0 12 8"
            fill="none"
            {...iconProps}
            ref={forwardedRef}>
            {DirectionChevron(direction, color)}
        </svg>
    );
});

export default ChevronIcon;

ChevronIcon.displayName = "ChevronIcon";
