export type IndicatorSize = 1 | 2 | 3;
export type IndicatorState = boolean;

/**
 * Interface for the properties of the `Indicator` component.
 */
interface IndicatorProps {
    /**
     * Label to be displayed on the indicator
     */
    label: string;

    /**
     * Current state of the indicator
     */
    state: IndicatorState;

    /**
     * Optional CSS class to apply to the indicator
     */
    className?: string;

    /**
     * Optional size of the indicator
     * @default 1
     */
    size?: IndicatorSize;

    /**
     * Optional tooltip text to be displayed on hover
     */
    tooltip?: string;
}

export default IndicatorProps;
