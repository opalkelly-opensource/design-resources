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

import "./SelectEntryLabel.css";

type SelectEntryLabelElement = React.ElementRef<typeof SelectPrimitive.Label>;

interface SelectEntryLabelCombinedProps
    extends React.ComponentPropsWithoutRef<typeof SelectPrimitive.Label> {}

export type { SelectEntryLabelCombinedProps };

const SelectEntryLabel = React.forwardRef<SelectEntryLabelElement, SelectEntryLabelCombinedProps>(
    (props, forwardedRef) => {
        const { className, ...labelProps } = props;
        const { size } = React.useContext(SelectEntryContext);
        return (
            <SelectPrimitive.Label
                {...labelProps}
                ref={forwardedRef}
                className={classNames("okSelectEntryLabel", className, "ok-r-size-" + size)}
            />
        );
    }
);

SelectEntryLabel.displayName = "SelectEntryLabel";

export default SelectEntryLabel;
