import React, { ChangeEvent, Component, ReactNode } from "react";

import {
    NumberDisplay,
    NumberEntry,
    NumeralSystem,
    RangeSlider
} from "@opalkellytech/frontpanel-react-components";

import { FrequencyBinNumber, dBFS, hertz } from "./FFTSignalGenerator";
import { FrequencyVector } from "./FFTSignalGenerator2";

import "./FrequencyVectorComponent.css";

//
export type FrequencyVectorChangeEventHandler = (vectorId: number, vector: FrequencyVector) => void;

//
interface FrequencyVectorComponentProps {
    id: number;
    frequency: hertz;
    vector: FrequencyVector;
    onVectorChange: FrequencyVectorChangeEventHandler;
}

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

    // Event Handlers
    private onBinNumberChange(event: ChangeEvent<HTMLInputElement>) {
        const targetBinNumber: FrequencyBinNumber = Number(event.target.value);

        this.props.onVectorChange(this.props.id, {
            bin: targetBinNumber,
            amplitude: this.props.vector.amplitude
        });
    }

    private onBinNumberSliderChange(value: number) {
        this.props.onVectorChange(this.props.id, {
            bin: value,
            amplitude: this.props.vector.amplitude
        });
    }

    //
    private onAmplitudeValueChange(value: bigint) {
        const targetAmplitude: dBFS = Number(value);

        this.props.onVectorChange(this.props.id, {
            bin: this.props.vector.bin,
            amplitude: targetAmplitude
        });
    }

    private onAmplitudeSliderChange(value: number[]) {
        this.props.onVectorChange(this.props.id, {
            bin: this.props.vector.bin,
            amplitude: value[0]
        });
    }
}

export default FrequencyVectorComponent;
