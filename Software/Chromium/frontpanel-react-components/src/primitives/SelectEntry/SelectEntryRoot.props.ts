import LabelProps from "../Label/Label.props";

export type SelectEntrySize = 1 | 2 | 3;

/**
 * Interface for the properties of the `SelectEntryRoot` component.
 */
interface SelectEntryRootProps {
    /**
     * Optional CSS class to apply to the select entry root
     */
    className?: string;

    /**
     * Optional label properties for the select entry root
     */
    label?: LabelProps;

    /**
     * Optional size of the select entry root
     * @default 1
     */
    size?: SelectEntrySize;

    /**
     * Optional tooltip text to be displayed on hover
     */
    tooltip?: string;
}

export default SelectEntryRootProps;
