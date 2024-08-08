/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component } from "react";

import ICamera, { FrameCount } from "./ICamera";

import { ICameraEvent } from "./ICameraEvent";

import * as Progress from "@radix-ui/react-progress";

import { IEventSubscription } from "@opalkelly/frontpanel-alloy-core";

import "./FrameBufferStatusView.css";

/**
 * Properties for the frame buffer status view component.
 */
interface FrameBufferStatusViewProps {
    camera: ICamera;
    bufferCapacity: FrameCount;
    updateStatusEvent: ICameraEvent;
}

/**
 * Interface for the state of a frame buffer status view component.
 */
interface FrameBufferStatusViewState {
    bufferedFrameCount: FrameCount;
}

/**
 * Class representing a frame buffer status view component.
 */
class FrameBufferStatusView extends Component<
    FrameBufferStatusViewProps,
    FrameBufferStatusViewState
> {
    private _UpdateStatusEventSubscription?: IEventSubscription;

    constructor(props: FrameBufferStatusViewProps) {
        super(props);

        // Initialize the state.
        this.state = {
            bufferedFrameCount: 0
        };
    }

    componentDidMount(): void {
        this._UpdateStatusEventSubscription = this.props.updateStatusEvent.SubscribeAsync(
            this.OnUpdateStatusEventHandler.bind(this)
        );
    }

    componentWillUnmount(): void {
        this._UpdateStatusEventSubscription?.Cancel();
    }

    render() {
        return (
            <>
                <div className="okCameraTextPanel">
                    <span className="okCameraTextPanelLabel">buffer level (frames)</span>
                    <span className="okCameraTextPanelContent">
                        {this.state.bufferedFrameCount}
                    </span>
                </div>
                <Progress.Root
                    className="okCameraProgressRoot"
                    value={this.state.bufferedFrameCount}
                    max={this.props.bufferCapacity}>
                    <Progress.Indicator
                        className="okCameraProgressIndicator"
                        style={{
                            transform: `translateX(-${FrameBufferStatusView.CalculateRemainingCapacityPercentage(this.state.bufferedFrameCount, this.props.bufferCapacity)}%)`
                        }}
                    />
                </Progress.Root>
            </>
        );
    }

    /**
     * Event handler for the update status event.
     * @param sender - The camera that raised the event.
     */
    private async OnUpdateStatusEventHandler(sender: ICamera) {
        const bufferedFrameCount: number = await sender.GetBufferedFrameCount();

        this.setState({ bufferedFrameCount: bufferedFrameCount });
    }

    /**
     * Calculates the remaining frame capacity as a percentage of the total frame capacity.
     * @param count - The number of frames currently in the buffer.
     * @param capacity - The total number of frames that the buffer can hold.
     * @returns - The remaining frame capacity as a percentage of the total frame capacity.
     */
    private static CalculateRemainingCapacityPercentage(
        count: FrameCount,
        capacity: FrameCount
    ): number {
        return capacity > 0 ? ((capacity - count) / capacity) * 100.0 : 0.0;
    }
}

export default FrameBufferStatusView;
