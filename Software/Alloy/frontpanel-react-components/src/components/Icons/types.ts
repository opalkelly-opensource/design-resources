/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
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
