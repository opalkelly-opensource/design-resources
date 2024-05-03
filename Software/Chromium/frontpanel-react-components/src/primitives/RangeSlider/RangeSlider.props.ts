/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import LabelProps from "../Label/Label.props";

export type RangeSliderValueChangeEventHandler = (value: number) => void;
export type RangeSliderValueCommitEventHandler = (value: number) => void;

/**
 * Interface for the properties of the `RangeSlider` component.
 *
 * @interface
 */
interface RangeSliderProps {
    /**
     * Optional CSS class to apply to the range
     */
    className?: string;

    /**
     * Optional label properties for the range slider
     */
    label?: LabelProps;

    /**
     * Optional tooltip text to be displayed on hover
     */
    tooltip?: string;

    /**
     * Optional default value of the range slider
     */
    defaultValue?: number;

    /**
     * Optional current value of the range slider
     */
    value?: number;

    /**
     * Optional step value for the range slider. This determines the increments in value for each step
     * @default 1
     */
    valueStep?: number;

    /**
     * Optional minimum value that the range slider can have
     * @default 0
     */
    minimumValue?: number;

    /**
     * Optional maximum value that the range slider can have
     * @default 100
     */
    maximumValue?: number;

    /**
     * Optional disable the range slider
     * @default false
     */
    disabled?: boolean;

    /**
     * Optional show the label for the thumb (handle) of the range slider
     * @default true
     */
    showThumbLabel?: boolean;

    /**
     * Optional show the labels for the track of the range slider
     * @default true
     */
    showTrackLabels?: boolean;

    /**
     * Optional event handler for the range slider value change event
     * @type {RangeSliderValueChangeEventHandler}
     */
    onValueChange?: RangeSliderValueChangeEventHandler;

    /**
     * Optional event handler for the range slider value committed event
     * @type {RangeSliderValueCommitEventHandler}
     */
    onValueCommit?: RangeSliderValueCommitEventHandler;
}

export default RangeSliderProps;
