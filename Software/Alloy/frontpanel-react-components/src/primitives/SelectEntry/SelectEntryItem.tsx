/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import * as SelectPrimitive from "@radix-ui/react-select";

import classNames from "classnames";

import { SelectEntryContext } from "./SelectEntryRoot";

import "../../index.css";

import "./SelectEntryItem.css";

import { ToggleState } from "../../core";

import { RadioToggleStateIcon } from "../../components/Icons";

type SelectEntryItemElement = React.ElementRef<typeof SelectPrimitive.Item>;

interface SelectEntryItemCombinedProps
    extends React.ComponentPropsWithoutRef<typeof SelectPrimitive.Item> {}

export type { SelectEntryItemCombinedProps };

const SelectEntryItem = React.forwardRef<SelectEntryItemElement, SelectEntryItemCombinedProps>(
    (props, forwardedRef) => {
        const { className, children, ...itemProps } = props;
        const { size, value } = React.useContext(SelectEntryContext);
        return (
            <SelectPrimitive.Item
                {...itemProps}
                ref={forwardedRef}
                className={classNames("okSelectEntryItem", className, "ok-r-size-" + size)}>
                <RadioToggleStateIcon
                    state={value === props.value ? ToggleState.On : ToggleState.Off}
                />
                <SelectPrimitive.ItemText>{children}</SelectPrimitive.ItemText>
            </SelectPrimitive.Item>
        );
    }
);

SelectEntryItem.displayName = "SelectEntryItem";

export default SelectEntryItem;
