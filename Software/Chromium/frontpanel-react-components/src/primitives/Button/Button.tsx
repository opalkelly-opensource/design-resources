import React from "react";

import classNames from "classnames";

import ButtonProps from "./Button.props";

import "../../index.css";

import "./Button.css";

//import { Slot } from "@radix-ui/react-slot";

import { withTooltip } from "../TooltipUtility";

type ButtonElement = React.ElementRef<"button">;

interface ButtonCombinedProps extends React.ComponentPropsWithoutRef<"button">, ButtonProps {}

export type { ButtonCombinedProps };

/**
 * `Button` is a React component that renders a button with an optional label and optional tooltip.
 * The button event handlers provide notification when the button is clicked, pressed, or released
 * and can be used to perform actions in response to these events.
 *
 * @component
 * @param {object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the button
 *
 * @returns {React.Node} The rendered Button component
 *
 * @example
 * ```jsx
 * <Button
 *     label="Button"
 *     onButtonClick={() => console.log("Button clicked")} />
 * ```
 */
const Button = React.forwardRef<ButtonElement, ButtonCombinedProps>((props, forwardedRef) => {
    const {
        className,
        label,
        size = 1,
        onButtonUp,
        onButtonDown,
        onButtonClick,
        ...buttonProps
    } = props;

    const ButtonWithTooltip = withTooltip(
        <button
            data-disabled={buttonProps.disabled || undefined}
            {...buttonProps}
            ref={forwardedRef}
            className={classNames("okButton", className, "ok-r-size-" + size)}
            onMouseDown={onButtonDown}
            onMouseUp={onButtonUp}
            onClick={onButtonClick}>
            {label}
        </button>
    );

    return <ButtonWithTooltip {...props} />;
});

Button.displayName = "Button";

export default Button;
