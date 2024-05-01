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
