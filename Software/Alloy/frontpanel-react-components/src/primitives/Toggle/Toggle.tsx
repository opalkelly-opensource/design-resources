/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import React from "react";

import classNames from "classnames";

import ToggleProps from "./Toggle.props";

import "../../index.css";

import "./Toggle.css";

import { ToggleState } from "../../core";

type ToggleElement = React.ElementRef<"button">;

interface ToggleCombinedProps extends React.ComponentPropsWithoutRef<"button">, ToggleProps {}

export type { ToggleCombinedProps };

/**
 * `Toggle` is a React component that renders a toggle button to toggle between an "on" and "off"
 * state when the button is clicked. Notification of the state transtion is provided through the
 * `onToggleStateChanged` event handler.
 *
 * @component
 * @param {Object} props - The properties that define the `Toggle` component.
 * @param {React.Ref<ToggleElement>} forwardedRef - A ref that is forwarded to the `Toggle` component.
 *
 * @returns {React.ReactElement} The `Toggle` component.
 *
 * @example
 * ```jsx
 * <Toggle
 *    state={ToggleState.On}
 *    onToggleStateChanged={(newState) => console.log(newState)}>
 *   <span>Toggle<span>
 * </Toggle>
 * ```
 */
const Toggle = React.forwardRef<ToggleElement, ToggleCombinedProps>((props, forwardedRef) => {
    const {
        className,
        size = 1,
        disabled = false,
        tooltip,
        state,
        children,
        onToggleStateChanged,
        ...toggleProps
    } = props;

    const dataState: string = React.useMemo(() => {
        switch (state) {
            case ToggleState.On:
                return "on";
            case ToggleState.Off:
                return "off";
            default:
                return "indeterminate";
        }
    }, [state]);

    const OnButtonClick = React.useCallback((): void => {
        const newState: ToggleState = state === ToggleState.On ? ToggleState.Off : ToggleState.On;

        onToggleStateChanged?.(newState);
    }, [state]);

    return (
        <button
            data-disabled={disabled || undefined}
            ref={forwardedRef}
            {...toggleProps}
            className={classNames("okToggle", className, "ok-r-size-" + size)}
            data-state={dataState}
            onClick={OnButtonClick}>
            {children}
        </button>
    );
});

Toggle.displayName = "Toggle";

export default Toggle;
