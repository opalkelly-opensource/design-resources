/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

export type LabelVerticalPosition = "top" | "bottom";
export type LabelHorizontalPosition = "left" | "right";

/**
 * Interface for the properties of the `Label` component.
 */
interface LabelProps extends React.PropsWithChildren<NonNullable<unknown>> {
    /**
     * Text to be displayed on the label
     */
    text: string;

    /**
     * Optional CSS class to apply to the label
     */
    className?: string;

    /**
     * Optional horizontal position of the label, defined in LabelHorizontalPosition
     * @default "left"
     */
    horizontalPosition?: LabelHorizontalPosition;

    /**
     * Optional vertical position of the label, defined in LabelVerticalPosition
     * @default "top"
     */
    verticalPosition?: LabelVerticalPosition;
}

export default LabelProps;
