import React from "react";

import classnames from "classnames";

import IndicatorProps from "./Indicator.props";

import "../../index.css";

import "./Indicator.css";

import { withTooltip } from "../TooltipUtility";

import { ToggleState } from "../../core";

import { IndicatorStateIcon } from "../../components/Icons";

type IndicatorElement = React.ElementRef<"span">;

/**
 * `Indicator` is a React component that renders an indicator that represents the state of a boolean value with an
 * optional tooltip.
 *
 * @component
 * @param {object} props - Properties passed to component
 * @param {React.Ref} forwardedRef - Forwarded ref for the indicator
 *
 * @returns {React.Node} The rendered Indicator component
 *
 * @example
 * ```jsx
 * <Indicator
 *     label="Indicator"
 *     state={true} />
 * ```
 */
const Indicator = React.forwardRef<IndicatorElement, IndicatorProps>((props, forwardedRef) => {
    const { className, label, size = 1, state, ...indicatorProps } = props;

    const IndicatorWithTooltip = withTooltip(
        <span
            {...indicatorProps}
            ref={forwardedRef}
            className={classnames("okIndicator", className, "ok-r-size-" + size)}>
            <IndicatorStateIcon
                className="okIndicatorIcon"
                state={state ? ToggleState.On : ToggleState.Off}
            />
            <span className={classnames("okIndicatorLabel")}>{label}</span>
        </span>
    );

    return <IndicatorWithTooltip {...props} />;
});

Indicator.displayName = "Indicator";

export default Indicator;
