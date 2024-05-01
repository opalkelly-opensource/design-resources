import ToggleProps from "../Toggle/Toggle.props";

/**
 * Interface for the properties of the `ToggleSwitch` component.
 */
interface ToggleSwitchProps extends ToggleProps {
    /**
     * Label to be displayed on the toggle switch
     */
    label: string;

    /**
     * Optional disable the toggle switch
     * @default false
     */
    disabled?: boolean;
}

export default ToggleSwitchProps;
