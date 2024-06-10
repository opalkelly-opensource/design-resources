/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import * as SelectPrimitive from "@radix-ui/react-select";

import classNames from "classnames";

import "../../index.css";

import "./SelectEntrySeparator.css";

type SelectEntrySeparatorElement = React.ElementRef<typeof SelectPrimitive.Separator>;

interface SelectEntrySeparatorCombinedProps
    extends React.ComponentPropsWithoutRef<typeof SelectPrimitive.Separator> {}

export type { SelectEntrySeparatorCombinedProps };

const SelectEntrySeparator = React.forwardRef<
    SelectEntrySeparatorElement,
    SelectEntrySeparatorCombinedProps
>((props, forwardedRef) => (
    <SelectPrimitive.Separator
        {...props}
        ref={forwardedRef}
        className={classNames("okSelectEntrySeparator", props.className)}
    />
));

SelectEntrySeparator.displayName = "SelectEntrySeparator";

export default SelectEntrySeparator;
