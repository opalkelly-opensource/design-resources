/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import * as SelectPrimitive from "@radix-ui/react-select";

import classNames from "classnames";

import "../../index.css";

import "./SelectEntryGroup.css";

type SelectEntryGroupElement = React.ElementRef<typeof SelectPrimitive.Group>;

interface SelectEntryGroupCombinedProps
    extends React.ComponentPropsWithoutRef<typeof SelectPrimitive.Group> {}

export type { SelectEntryGroupCombinedProps };

const SelectEntryGroup = React.forwardRef<SelectEntryGroupElement, SelectEntryGroupCombinedProps>(
    (props, forwardedRef) => (
        <SelectPrimitive.Group
            {...props}
            ref={forwardedRef}
            className={classNames("okSelectEntryGroup", props.className)}
        />
    )
);

SelectEntryGroup.displayName = "SelectEntryGroup";

export default SelectEntryGroup;
