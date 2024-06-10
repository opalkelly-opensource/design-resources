/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import * as React from "react";

export interface IconProps extends React.SVGAttributes<SVGElement> {
    children?: never;
    color?: string;
}

export interface StateIconProps extends React.SVGAttributes<SVGElement> {
    children?: never;
    color?: string;
    colorOnState?: string;
    colorOffState?: string;
}
