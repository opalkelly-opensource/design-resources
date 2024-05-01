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
