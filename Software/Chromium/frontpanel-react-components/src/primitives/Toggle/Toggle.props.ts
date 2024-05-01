import { ToggleState } from "../../core";

export type ToggleSize = 1 | 2 | 3;
export type ToggleStateChangeEventHandler = (state: ToggleState) => void;

/**
 * Interface for the properties of the `Toggle` component.
 */
interface ToggleProps extends React.PropsWithChildren<NonNullable<unknown>> {
    /**
     * Current state of the toggle, defined in ToggleState
     */
    state: ToggleState;

    /**
     * Optional CSS class to apply to the toggle
     */
    className?: string;

    /**
     * Optional size of the toggle
     * @default 1
     */
    size?: ToggleSize;

    /**
     * Optional tooltip text to be displayed on hover
     */
    tooltip?: string;

    /**
     * Optional event handler for the toggle state change event
     */
    onToggleStateChanged?: ToggleStateChangeEventHandler;
}

export default ToggleProps;
