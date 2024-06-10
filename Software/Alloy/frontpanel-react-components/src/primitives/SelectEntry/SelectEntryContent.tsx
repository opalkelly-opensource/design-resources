/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import * as SelectPrimitive from "@radix-ui/react-select";
import * as ScrollAreaPrimitive from "@radix-ui/react-scroll-area";

import classNames from "classnames";

import { SelectEntryContext } from "./SelectEntryRoot";

import "../../index.css";

import "./SelectEntryContent.css";

type SelectEntryContentElement = React.ElementRef<typeof SelectPrimitive.Content>;

interface SelectContentCombinedProps
    extends React.ComponentPropsWithoutRef<typeof SelectPrimitive.Content> {
    container?: React.ComponentProps<typeof SelectPrimitive.Portal>["container"];
}

export type { SelectContentCombinedProps };

const SelectEntryContent = React.forwardRef<SelectEntryContentElement, SelectContentCombinedProps>(
    (props, forwardedRef) => {
        const { className, children, container, ...contentProps } = props;
        const { size } = React.useContext(SelectEntryContext);
        return (
            <SelectPrimitive.Portal container={container}>
                <SelectPrimitive.Content
                    sideOffset={4}
                    {...contentProps}
                    ref={forwardedRef}
                    className={classNames("okSelectEntryContent", className, "ok-r-size-" + size)}
                    position="popper"
                    align="start">
                    <ScrollAreaPrimitive.Root type="auto" className="okScrollArea">
                        <SelectPrimitive.Viewport asChild>
                            <ScrollAreaPrimitive.Viewport className="okScrollAreaViewport">
                                <div className="okSelectEntryContentInner">{children}</div>
                            </ScrollAreaPrimitive.Viewport>
                        </SelectPrimitive.Viewport>
                        <ScrollAreaPrimitive.Scrollbar
                            className="okScrollAreaScrollbar"
                            orientation="vertical">
                            <ScrollAreaPrimitive.Thumb className="okScrollAreaThumb" />
                        </ScrollAreaPrimitive.Scrollbar>
                    </ScrollAreaPrimitive.Root>
                </SelectPrimitive.Content>
            </SelectPrimitive.Portal>
        );
    }
);

SelectEntryContent.displayName = "SelectEntryContent";

export default SelectEntryContent;
