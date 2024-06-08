/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component, ReactNode } from "react";

import {
    NumberDisplay,
    NumberEntry,
    NumeralSystem,
    RangeSlider
} from "@opalkelly/frontpanel-react-components";

import { Hertz } from "./FFTConfiguration";

import { FrequencyVector, dBFS } from "./FFTSignalGeneratorAdapter";

import "./FrequencyVectorComponent.css";

/**
 * Event handler for handling changes in the frequency vector.
 */
export type FrequencyVectorChangeEventHandler = (vectorId: number, vector: FrequencyVector) => void;

/**
 * Properties for the Frequency Vector Component.
 */
interface FrequencyVectorComponentProps {
    id: number;
    frequency: Hertz;
    vector: FrequencyVector;
    onVectorChange: FrequencyVectorChangeEventHandler;
}

/**
 * Frequency Vector Component for displaying and editing a frequency vector.
 */
class FrequencyVectorComponent extends Component<FrequencyVectorComponentProps> {
    render(): ReactNode {
        return (
            <div className="FrequencyVectorPanel">
                <RangeSlider
                    maximumValue={512}
                    minimumValue={1}
                    defaultValue={this.props.vector.bin}
                    onValueChange={this.onBinNumberSliderChange.bind(this)}
                />

                <NumberDisplay
                    label={{
                        text: "kHz",
                        horizontalPosition: "right",
                        verticalPosition: "bottom"
                    }}
                    numeralSystem={NumeralSystem.Decimal}
                    decimalScale={3}
                    maximumValue={BigInt(99999999)}
                    minimumValue={BigInt(0)}
                    value={BigInt(Math.round(this.props.frequency))}
                />

                <NumberEntry
                    label={{
                        text: "dBFS",
                        horizontalPosition: "right",
                        verticalPosition: "bottom"
                    }}
                    numeralSystem={NumeralSystem.Decimal}
                    value={BigInt(this.props.vector.amplitude)}
                    maximumValue={BigInt(0)}
                    minimumValue={BigInt(-120)}
                    onValueChange={this.onAmplitudeValueChange.bind(this)}
                    size={1}
                />
            </div>
        );
    }

    /**
     * Event handler for changes in the bin number slider.
     * @param value - The new value of the bin number slider.
     */
    private onBinNumberSliderChange(value: number) {
        this.props.onVectorChange(this.props.id, {
            bin: value,
            amplitude: this.props.vector.amplitude
        });
    }

    /**
     * Event handler for changes in the amplitude value.
     * @param value - The new value of the amplitude value.
     */
    private onAmplitudeValueChange(value: bigint) {
        const targetAmplitude: dBFS = Number(value);

        this.props.onVectorChange(this.props.id, {
            bin: this.props.vector.bin,
            amplitude: targetAmplitude
        });
    }
}

export default FrequencyVectorComponent;
