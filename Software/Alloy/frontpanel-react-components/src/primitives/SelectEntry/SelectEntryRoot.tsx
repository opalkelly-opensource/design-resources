/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import * as SelectPrimitive from "@radix-ui/react-select";

import SelectEntryRootProps from "./SelectEntryRoot.props";

type SelectEntryContextValue = SelectEntryRootCombinedProps;

export const SelectEntryContext = React.createContext<SelectEntryContextValue>({
    label: { text: "", horizontalPosition: "right", verticalPosition: "top" },
    size: 1,
    value: undefined
});

interface SelectEntryRootCombinedProps
    extends React.ComponentPropsWithoutRef<typeof SelectPrimitive.Root>,
        SelectEntryRootProps {}

export type { SelectEntryRootCombinedProps };

/**
 * `SelectEntryRoot` is a React component that is the root component of a select entry. The children of this
 * component are used to specify the component parts. The parts include the trigger that can be clicked on to
 * show a list of options to select from, and the content that is the list of options.
 *
 * @component
 * @param {object} props - Properties passed to component
 *
 * @returns {ReactNode} The rendered SelectEntryRoot component
 *
 * @example
 * ```jsx
 * <SelectEntryRoot>
 *     <SelectEntry.Trigger />
 *     <SelectEntry.Content>
 *         <SelectEntry.Group>
 *            <SelectEntry.Label>Options</SelectEntry.Label>
 *            <SelectEntry.Item value="0">Option 0</SelectEntry.Item>
 *            <SelectEntry.Item value="1">Option 1</SelectEntry.Item>
 *        </SelectEntry.Group>
 *     </SelectEntry.Content>
 * </SelectEntryRoot>
 * ```
 */
const SelectEntryRoot: React.FC<SelectEntryRootCombinedProps> = (props) => {
    const { label, children, size = 1, tooltip, value, ...rootProps } = props;
    return (
        <SelectPrimitive.Root value={value} {...rootProps}>
            <SelectEntryContext.Provider
                value={React.useMemo(
                    () => ({ label, size, tooltip, value }),
                    [label, size, tooltip, value]
                )}>
                {children}
            </SelectEntryContext.Provider>
        </SelectPrimitive.Root>
    );
};

SelectEntryRoot.displayName = "SelectEntryRoot";

export default SelectEntryRoot;
