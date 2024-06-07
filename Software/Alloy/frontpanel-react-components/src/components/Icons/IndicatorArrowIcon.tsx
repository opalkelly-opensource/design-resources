/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import * as React from "react";

import { IconProps } from "./types";

export enum IndicatorArrowDirection {
    Up,
    Down
}

export interface IndicatorArrowIconProps extends IconProps {
    direction: IndicatorArrowDirection;
}

const IndicatorArrow = (direction: IndicatorArrowDirection, color: string): React.ReactNode => {
    let arrow: React.ReactNode;

    switch (direction) {
        case IndicatorArrowDirection.Up:
            arrow = <path d="M5 5.1656e-07L10 4L0 4L5 5.1656e-07Z" fill={color} />;
            break;
        case IndicatorArrowDirection.Down:
            arrow = <path d="M5 4L0 0L10 8.88334e-07L5 4Z" fill={color} />;
            break;
        default:
            arrow = <path d="M5 5.1656e-07L10 4L0 4L5 5.1656e-07Z" fill={color} />;
            break;
    }

    return arrow;
};

const IndicatorArrowIcon = React.forwardRef<SVGSVGElement, IndicatorArrowIconProps>(
    (props, forwardedRef) => {
        const { direction = IndicatorArrowDirection.Down, color = "#343434", ...iconProps } = props;
        return (
            <svg
                xmlns="http://www.w3.org/2000/svg"
                width="10"
                height="4"
                viewBox="0 0 10 4"
                fill="none"
                {...iconProps}
                ref={forwardedRef}>
                {IndicatorArrow(direction, color)}
            </svg>
        );
    }
);

export default IndicatorArrowIcon;

IndicatorArrowIcon.displayName = "IndicatorArrowIcon";
