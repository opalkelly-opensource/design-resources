import React from "react";

import classNames from "classnames";

import LabelProps from "./Label.props";

import "../../index.css";

import "./Label.css";

type LabelElement = React.ElementRef<"div">;

/**
 * `Label` is a React component that renders a label with optional positioning.
 *
 * @component
 * @param {object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the indicator
 *
 * @returns {ReactNode} The rendered Label component
 *
 * @example
 * ```jsx
 * <Label
 *     text="Label"
 *     horizontalPosition="left"
 *     verticalPosition="top">
 *     <input type="text" />
 * </Label>
 * ```
 */
const Label = React.forwardRef<LabelElement, LabelProps>((props, forwardedRef) => {
    const {
        className,
        text,
        horizontalPosition = "left",
        verticalPosition = "top",
        children,
        ...labelProps
    } = props;

    return (
        <div
            {...labelProps}
            ref={forwardedRef}
            className={classNames(
                "okLabel",
                className,
                "ok-pos-" + horizontalPosition + "-" + verticalPosition
            )}>
            <span className={classNames("okLabelText")}>{text}</span>
            {children}
        </div>
    );
});

Label.displayName = "Label";

export default Label;
