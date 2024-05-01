import React, { useContext } from "react";

import * as SelectPrimitive from "@radix-ui/react-select";

import classNames from "classnames";

import { SelectEntryContext } from "./SelectEntryRoot";

import SelectEntryTriggerProps from "./SelectEntryTrigger.props";

import "../../index.css";

import "./SelectEntryTrigger.css";

import { ChevronIcon, ChevronDirection } from "../../components/Icons";

import Label from "../Label";
import Tooltip from "../Tooltip";

type SelectEntryTriggerElement = React.ElementRef<typeof SelectPrimitive.Trigger>;

interface SelectEntryTriggerCombinedProps
    extends Omit<React.ComponentPropsWithoutRef<typeof SelectPrimitive.Trigger>, "asChild">,
        SelectEntryTriggerProps {}

export type { SelectEntryTriggerCombinedProps };

const SelectEntryTrigger = React.forwardRef<
    SelectEntryTriggerElement,
    SelectEntryTriggerCombinedProps
>((props, forwardedRef) => {
    const { label, tooltip, ...triggerProps } = useContext(SelectEntryContext);

    const showLabel = label != null;
    const showTooltip = tooltip != null;

    if (showLabel && showTooltip) {
        return (
            <Label {...label}>
                <Tooltip content={tooltip}>
                    <SelectEntryTriggerImpl
                        ref={forwardedRef}
                        {...props}
                        style={{ width: "100%" }}
                    />
                </Tooltip>
            </Label>
        );
    } else if (showLabel) {
        return (
            <Label {...label}>
                <SelectEntryTriggerImpl
                    ref={forwardedRef}
                    {...triggerProps}
                    style={{ width: "100%" }}
                />
            </Label>
        );
    } else if (showTooltip) {
        return (
            <Tooltip content={tooltip}>
                <div>
                    <SelectEntryTriggerImpl ref={forwardedRef} {...triggerProps} />
                </div>
            </Tooltip>
        );
    } else {
        return <SelectEntryTriggerImpl ref={forwardedRef} {...triggerProps} />;
    }
});

SelectEntryTrigger.displayName = "SelectEntryTrigger";

export default SelectEntryTrigger;

interface SelectTriggerEntryImplProps
    extends Omit<React.ComponentPropsWithoutRef<typeof SelectEntryTrigger>, "label" | "tooltip"> {}

const SelectEntryTriggerImpl = React.forwardRef<
    SelectEntryTriggerElement,
    SelectTriggerEntryImplProps
>((props, forwardedRef) => {
    const { className, placeholder, ...triggerProps } = props;

    const { size } = React.useContext(SelectEntryContext);

    return (
        <SelectPrimitive.Trigger asChild>
            <button
                {...triggerProps}
                ref={forwardedRef}
                className={classNames("okSelectEntryTrigger", className, "ok-r-size-" + size)}>
                <span className="okSelectEntryTriggerInner">
                    <SelectPrimitive.Value placeholder={placeholder} />
                </span>
                <SelectPrimitive.Icon asChild>
                    <ChevronIcon direction={ChevronDirection.Down} />
                </SelectPrimitive.Icon>
            </button>
        </SelectPrimitive.Trigger>
    );
});

SelectEntryTriggerImpl.displayName = "SelectEntryTriggerImpl";
