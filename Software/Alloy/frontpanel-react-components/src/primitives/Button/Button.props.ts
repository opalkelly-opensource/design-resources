/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

export type ButtonSize = 1 | 2 | 3;
export type ButtonStateChangeEventHandler = () => void;
export type ButtonClickEventHandler = () => void;

/**
 * Interface for the properties of the `Button` component.
 */
interface ButtonProps {
    /**
     * Label text to be displayed in the button
     */
    label: string;

    /**
     * Optional CSS class to apply to the button
     */
    className?: string;

    /**
     * Optional size of the button
     * @default 1
     */
    size?: ButtonSize;

    /**
     * Optional tooltip text to be displayed on hover
     */
    tooltip?: string;

    /**
     * Optional event handler for the button down event
     */
    onButtonDown?: ButtonStateChangeEventHandler;

    /**
     * Optional event handler for the button up event
     */
    onButtonUp?: ButtonStateChangeEventHandler;

    /**
     * Optional event handler for the button click event
     */
    onButtonClick?: ButtonClickEventHandler;
}

export default ButtonProps;
