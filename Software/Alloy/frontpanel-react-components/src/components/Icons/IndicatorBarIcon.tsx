/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import * as React from "react";

import { IconProps } from "./types";

const IndicatorBarIcon = React.forwardRef<SVGSVGElement, IconProps>((props, forwardedRef) => {
    const { color = "#343434", ...iconProps } = props;

    return (
        <svg
            xmlns="http://www.w3.org/2000/svg"
            width="10"
            height="1"
            viewBox="0 0 10 1"
            fill="none"
            {...iconProps}
            ref={forwardedRef}>
            <path
                d="M8.74228e-08 -8.74228e-07L10 -9.53674e-07L10 1L0 0.999999L8.74228e-08 -8.74228e-07Z"
                fill={color}
            />
        </svg>
    );
});

export default IndicatorBarIcon;

IndicatorBarIcon.displayName = "IndicatorBarIcon";
