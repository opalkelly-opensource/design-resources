/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import { Component } from "react";

import ICamera, { FrameCount } from "./ICamera";

import { ICameraEvent } from "./ICameraEvent";

import { IEventSubscription } from "@opalkelly/frontpanel-platform-api";

import "./FrameCaptureStatusView.css";

type TimeStamp = number;

/**
 * Properties for the frame capture status view component.
 */
interface FrameCaptureStatusViewProps {
    camera: ICamera;
    frameCaptureEvent: ICameraEvent;
}

/**
 * Interface for the state of a frame capture status view component.
 */
interface FrameCaptureStatusViewState {
    frameRate: number;
    missedFrameCount: FrameCount;
    receivedFrameCount: FrameCount;
}

/**
 * Class representing a frame capture status view component.
 */
class FrameCaptureStatusView extends Component<
    FrameCaptureStatusViewProps,
    FrameCaptureStatusViewState
> {
    private _FrameCaptureEventSubscription?: IEventSubscription;

    private _FrameCaptureStartTimeStamp: TimeStamp = 0;
    private _FrameCaptureCount: FrameCount = 0;

    constructor(props: FrameCaptureStatusViewProps) {
        super(props);

        // Initialize the state.
        this.state = {
            frameRate: 0,
            missedFrameCount: 0,
            receivedFrameCount: 0
        };
    }

    componentDidMount(): void {
        this._FrameCaptureEventSubscription = this.props.frameCaptureEvent.subscribeAsync(
            this.OnFrameCaptureEventHandler.bind(this)
        );

        this._FrameCaptureCount = 0;
        this._FrameCaptureStartTimeStamp = 0;
    }

    componentWillUnmount(): void {
        this._FrameCaptureEventSubscription?.cancel();
    }

    render() {
        return (
            <>
                <div className="okCameraTextPanel">
                    <span className="okCameraTextPanelLabel">fps</span>
                    <span className="okCameraTextPanelContent">
                        {this.state.frameRate.toFixed(2)}
                    </span>
                </div>
                <div className="okCameraTextPanel">
                    <span className="okCameraTextPanelLabel">missed frames</span>
                    <span className="okCameraTextPanelContent">{this.state.missedFrameCount}</span>
                </div>
            </>
        );
    }

    /**
     * Event handler for the frame capture event.
     * @param sender - The camera that raised the event.
     */
    public async OnFrameCaptureEventHandler(sender: ICamera) {
        this._FrameCaptureCount++;

        if (this._FrameCaptureCount >= 20) {
            const endTimeStamp = window.performance.now();

            const elapsedTime: number = endTimeStamp - this._FrameCaptureStartTimeStamp;

            this.UpdateFrameRate(this._FrameCaptureCount, elapsedTime);

            this._FrameCaptureCount = 0;
            this._FrameCaptureStartTimeStamp = endTimeStamp;
        }

        // Retrieve missed frame count and update the state.
        const missedFrameCount: number = await sender.GetMissedFrameCount();

        this.setState({ missedFrameCount: missedFrameCount });
    }

    /**
     * Calculates the frame rate in units of frames per second and updates the state.
     * @param frameCount - The number of frames captured during the interval.
     * @param elapsedTime - The elapsed time of the interval in milliseconds.
     */
    private UpdateFrameRate(frameCount: number, elapsedTime: number) {
        let frameRate: number;

        if (elapsedTime !== 0) {
            frameRate = (frameCount / elapsedTime) * 1000;
        } else {
            frameRate = 0;
        }

        this.setState({ frameRate: frameRate });
    }
}

export default FrameCaptureStatusView;
