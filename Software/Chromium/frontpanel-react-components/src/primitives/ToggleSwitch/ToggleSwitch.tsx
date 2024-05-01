import React from "react";

import classnames from "classnames";

import Toggle from "../Toggle/Toggle";

import ToggleSwitchProps from "./ToggleSwitch.props";

import "../../index.css";

import "./ToggleSwitch.css";

import { withTooltip } from "../TooltipUtility";

import { SwitchToggleStateIcon } from "../../components/Icons";

type ToggleSwitchElement = React.ElementRef<typeof Toggle>;

/**
 * `ToggleSwitch` is a React component that renders a toggle switch with a label and a switch button
 * that represents the current toggle state. When the switch is clicked, the toggle
 * state will transition to the next state. Notification of the state transtion is provided through the
 * `onToggleStateChanged` event handler.
 *
 * @component
 * @param {Object} props - Properties passed to component
 * @param {React.Ref<ToggleSwitchElement>} forwardedRef - Forwarded ref for the button
 *
 * @returns {React.ReactElement} The rendered ToggleSwitch component
 *
 * @example
 * ```jsx
 * <ToggleSwitch
 *     label="Toggle"
 *     state={ToggleState.On}
 *     onToggleStateChanged={(newState) => console.log(newState)} />
 * ```
 */
const ToggleSwitch = React.forwardRef<ToggleSwitchElement, ToggleSwitchProps>(
    (props, forwardedRef) => {
        const { className, size = 1, label, disabled = false, state, ...toggleSwitchProps } = props;

        const ToggleButtonWithTooltip = withTooltip(
            <span
                className={classnames("okToggleSwitchRoot", className, "ok-r-size-" + size)}
                data-disabled={disabled || undefined}>
                <Toggle
                    className={classnames("okToggleSwitch")}
                    ref={forwardedRef}
                    {...toggleSwitchProps}
                    size={size}
                    disabled={disabled}
                    state={state}>
                    <SwitchToggleStateIcon className="okIndicatorIcon" state={state} />
                </Toggle>
                <span className={classnames("okToggleSwitchLabel")}>{label}</span>
            </span>
        );

        return <ToggleButtonWithTooltip {...props} />;
    }
);

ToggleSwitch.displayName = "ToggleSwitch";

export default ToggleSwitch;
