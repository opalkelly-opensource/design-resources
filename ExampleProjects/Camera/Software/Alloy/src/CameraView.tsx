/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component, RefObject } from "react";

import "./CameraView.css";

import {
    Button,
    ToggleState,
    ToggleSwitch,
    NumberEntry,
    RangeSlider,
    SelectEntry,
    NumeralSystem
} from "@opalkelly/frontpanel-react-components";

import CanvasView, { FrameDisplayMode } from "./CanvasView";

import ICamera, {
    FrameConfiguration,
    FrameCaptureResult,
    FrameCount,
    TestMode,
    CameraShutterWidth
} from "./ICamera";

import { FrontPanelDeviceI2C } from "./FrontPanelDeviceI2C";

import {
    IMAGE_BUFFER_DEPTH_MIN,
    IMAGE_BUFFER_DEPTH_MAX,
    IMAGE_BUFFER_DEPTH_AUTO
} from "./FrontPanelCamera";

import { SZYGYCamera } from "./SYZYGYCamera";

import { IFrontPanel, WorkQueue } from "@opalkelly/frontpanel-alloy-core";

import CameraEvent from "./CameraEvent";

import { IMatrixDimensions } from "./MatrixData";

import FrameCaptureStatusView from "./FrameCaptureStatusView";
import FrameBufferStatusView from "./FrameBufferStatusView";

const DEVICE_ADDRESS_AR0330 = 0x30;

/**
 * Type representing a selectable item.
 */
type SelectItem<T> = {
    id: string;
    label: string;
    value: T;
};

/**
 * Type representing the frame capture mode.
 */
type FrameCaptureMode = TestMode | undefined;

/**
 * Properties for the camera view component.
 */
interface CameraViewProps {
    name: string;
}

/**
 * Interface for the state of a camera view component.
 */
interface CameraViewState {
    frameDimensionsList: SelectItem<FrameConfiguration>[];
    frameCaptureTestModesList: SelectItem<TestMode>[];
    frameDisplayModesList: SelectItem<FrameDisplayMode>[];

    selectedFrameSizeId: string;
    selectedFrameCaptureModeId: string;
    selectedFrameDisplayModeId: string;

    continuousFrameCaptureState: boolean;
    exposure: number;
    frameBufferDepth: number;
    frameDisplayMode: FrameDisplayMode;

    frameRate: number;
    missedFrameCount: number;
    receivedFrameCount: number;
    bufferedFrameCount: number;

    canvasWidth: number;
    canvasHeight: number;
}

/**
 * Class representing a camera view component.
 */
class CameraView extends Component<CameraViewProps, CameraViewState> {
    private readonly _FrontPanel: IFrontPanel = window.FrontPanel;

    private readonly _Camera: ICamera;

    private readonly _FrameCaptureEvent = new CameraEvent();

    private readonly _WorkQueue: WorkQueue = new WorkQueue();

    private readonly _CanvasViewRef: RefObject<CanvasView>;

    componentDidMount(): void {
        this.Initialize();
    }

    constructor(props: CameraViewProps) {
        super(props);

        const deviceI2C: FrontPanelDeviceI2C = new FrontPanelDeviceI2C(
            this._FrontPanel,
            DEVICE_ADDRESS_AR0330
        );

        this._Camera = new SZYGYCamera(this._FrontPanel, deviceI2C);

        this._CanvasViewRef = React.createRef();

        // Get the list of options for the frame size, test modes, and display modes.
        const frameSizeSet: SelectItem<FrameConfiguration>[] = this.GetFrameConfigurationSet();
        const frameCaptureTestModeSet: SelectItem<TestMode>[] = this.GetFrameCaptureTestModeSet();
        const frameDisplayModeSet: SelectItem<FrameDisplayMode>[] = this.GetFrameDisplayModeSet();

        // Initialize the state.
        this.state = {
            frameDimensionsList: frameSizeSet,
            frameCaptureTestModesList: frameCaptureTestModeSet,
            frameDisplayModesList: frameDisplayModeSet,

            selectedFrameSizeId: frameSizeSet[0].id,
            selectedFrameCaptureModeId: "ImageCapture",
            selectedFrameDisplayModeId: frameDisplayModeSet[0].id,

            continuousFrameCaptureState: true,
            exposure: 2000,
            frameBufferDepth: 5,
            frameDisplayMode: frameDisplayModeSet[0].value,

            frameRate: 0,
            missedFrameCount: 0,
            receivedFrameCount: 0,
            bufferedFrameCount: 0,

            canvasWidth: frameSizeSet[0].value.dimensions.columnCount,
            canvasHeight: frameSizeSet[0].value.dimensions.rowCount
        };
    }

    render() {
        return (
            <div className="okCameraView">
                <div className="okCameraControlPanel">
                    <Button label="Reset" onButtonDown={() => this.ResetButtonClick()} />
                    <div className="okCameraControlVerticalSeparator" />
                    <div className="okCameraFrameStatusRowPanel">
                        <FrameCaptureStatusView
                            camera={this._Camera}
                            frameCaptureEvent={this._FrameCaptureEvent}
                        />
                    </div>
                    <div className="okCameraControlVerticalSeparator" />
                    <div className="okCameraFrameCaptureRowPanel">
                        <ToggleSwitch
                            label="Continuous"
                            state={
                                this.state.continuousFrameCaptureState
                                    ? ToggleState.On
                                    : ToggleState.Off
                            }
                            onToggleStateChanged={this.ContinousFrameCaptureStateChanged}
                        />
                        <Button
                            label="Capture"
                            onButtonDown={() => this.CaptureFrameButtonClick()}
                        />
                    </div>
                    <div className="okCameraControlVerticalSeparator" />
                    <SelectEntry.Root
                        label={{
                            text: "Capture Size",
                            horizontalPosition: "left",
                            verticalPosition: "top"
                        }}
                        size={1}
                        value={this.state.selectedFrameSizeId}
                        onValueChange={this.SelectedFrameSizeChanged}>
                        <SelectEntry.Trigger placeholder="Select capture size�" />
                        <SelectEntry.Content>
                            {this.state.frameDimensionsList.map((item, i) => (
                                <SelectEntry.Item key={i} value={item.id}>
                                    {item.label}
                                </SelectEntry.Item>
                            ))}
                        </SelectEntry.Content>
                    </SelectEntry.Root>
                    <NumberEntry
                        label={{
                            text: "Exposure",
                            horizontalPosition: "left",
                            verticalPosition: "top"
                        }}
                        size={1}
                        numeralSystem={NumeralSystem.Decimal}
                        minimumValue={BigInt(0)}
                        maximumValue={BigInt(10000)}
                        value={BigInt(this.state.exposure)}
                        onValueChange={this.ExposureChanged}
                    />
                    <SelectEntry.Root
                        label={{
                            text: "Display Mode",
                            horizontalPosition: "left",
                            verticalPosition: "top"
                        }}
                        size={1}
                        value={this.state.selectedFrameDisplayModeId}
                        onValueChange={this.SelectedFrameDisplayModeChanged}>
                        <SelectEntry.Trigger placeholder="Select a display mode�" />
                        <SelectEntry.Content>
                            {this.state.frameDisplayModesList.map((item, i) => (
                                <SelectEntry.Item key={i} value={item.id}>
                                    {item.label}
                                </SelectEntry.Item>
                            ))}
                        </SelectEntry.Content>
                    </SelectEntry.Root>
                    <SelectEntry.Root
                        label={{
                            text: "Capture Mode",
                            horizontalPosition: "left",
                            verticalPosition: "top"
                        }}
                        size={1}
                        value={this.state.selectedFrameCaptureModeId}
                        onValueChange={this.SelectedFrameCaptureModeChanged}>
                        <SelectEntry.Trigger placeholder="Select a capture mode�" />
                        <SelectEntry.Content>
                            <SelectEntry.Group>
                                <SelectEntry.Item key={"ImageCapture"} value={"ImageCapture"}>
                                    {"Image Capture"}
                                </SelectEntry.Item>
                            </SelectEntry.Group>
                            <SelectEntry.Group>
                                <SelectEntry.Label></SelectEntry.Label>Test Modes
                                {this.state.frameCaptureTestModesList.map((item, i) => (
                                    <SelectEntry.Item key={i} value={item.id}>
                                        {item.label}
                                    </SelectEntry.Item>
                                ))}
                            </SelectEntry.Group>
                        </SelectEntry.Content>
                    </SelectEntry.Root>
                    <RangeSlider
                        label={{ text: "Buffer Capacity (frames)" }}
                        value={this.state.frameBufferDepth}
                        minimumValue={IMAGE_BUFFER_DEPTH_MIN}
                        maximumValue={IMAGE_BUFFER_DEPTH_MAX}
                        onValueChange={this.FrameBufferDepthChanged}
                    />
                    <div className="okCameraControlVerticalSeparator" />
                    <FrameBufferStatusView
                        camera={this._Camera}
                        bufferCapacity={this.state.frameBufferDepth}
                        updateStatusEvent={this._FrameCaptureEvent}
                    />
                </div>
                <CanvasView
                    ref={this._CanvasViewRef}
                    width={this.state.canvasWidth}
                    height={this.state.canvasHeight}
                    frameDisplayMode={this.state.frameDisplayMode}
                />
            </div>
        );
    }

    /**
     * Initializes the camera device.
     */
    private async Initialize() {
        await this._WorkQueue.Post(async (): Promise<void> => {
            const version: number = await this._Camera.Initialize();

            console.log("Initialize version=" + version.toString(16));

            await this._Camera.SetImageBufferDepth(IMAGE_BUFFER_DEPTH_AUTO);

            // Turn off the programmable empty setting in hardware, this is not used in
            // this implementation.

            await this._FrontPanel.setWireInValue(0x04, 0, 0xfff);
            await this._FrontPanel.updateWireIns();
        });

        // Initialize the Camera state.
        const frameConfiguration: FrameConfiguration = this.GetFrameConfiguration(
            this.state.selectedFrameSizeId
        );
        const frameCaptureMode: FrameCaptureMode = this.GetFrameCaptureMode(
            this.state.selectedFrameCaptureModeId
        );

        await this.SetCameraState(
            this._Camera.DefaultSize,
            frameConfiguration,
            frameCaptureMode,
            this.state.frameBufferDepth,
            this.state.exposure
        );

        if (this.state.continuousFrameCaptureState) {
            this.StartContinuousCapture();
        }
    }

    /**
     * Sets the state of the camera device.
     */
    private async SetCameraState(
        dimensions: IMatrixDimensions,
        frameConfiguration: FrameConfiguration,
        frameCaptureMode: FrameCaptureMode,
        frameBufferDepth: FrameCount,
        exposure: CameraShutterWidth
    ) {
        await this._WorkQueue.Post(async (): Promise<void> => {
            await this._Camera.SetShutterWidth(exposure);

            console.log("Set Exposure: " + exposure);

            await this._Camera.SetSize(dimensions);

            console.log(
                "Set Size: columnCount=" +
                    dimensions.columnCount +
                    " rowCount=" +
                    dimensions.rowCount
            );

            await this._Camera.SetSkips(frameConfiguration.skips);

            console.log(
                "Set Skips: columnCount=" +
                    frameConfiguration.skips.columnCount +
                    " rowCount =" +
                    frameConfiguration.skips.rowCount
            );

            if (frameCaptureMode === undefined) {
                // Disable test mode.
                await this._Camera.SetTestMode(false, TestMode.Classic);

                console.log("Set Frame Capture Mode: Image Capture");
            } else {
                // Enable test mode.
                await this._Camera.SetTestMode(true, frameCaptureMode);

                console.log("Set Frame Capture Mode: " + frameCaptureMode);
            }

            await this._Camera.SetImageBufferDepth(frameBufferDepth);

            console.log("Set Frame Buffer Depth: " + frameBufferDepth);
        });

        this.setState({
            canvasWidth: frameConfiguration.dimensions.columnCount,
            canvasHeight: frameConfiguration.dimensions.rowCount
        });
    }

    /**
     * The continuous frame capture loop that captures frames at a fixed interval.
     * @param frameCount - The number of frames captured during the interval.
     * @param frameFailureCount - The number of frames that failed to capture during the interval.
     * @param startTimeStamp - The time stamp of the start of the interval.
     */
    private async ContinuousFrameLoop(): Promise<void> {
        await this._WorkQueue.Post(async () => {
            const result: FrameCaptureResult = await this._Camera.BufferedFrameCapture();

            if (result.data != null) {
                if (this._CanvasViewRef.current != null) {
                    this._CanvasViewRef.current.UpdateFrameImage(result.data);
                }
            } else {
                console.log("ERROR: Failed to Capture Frame Code=" + result.result);
            }
        });

        this._FrameCaptureEvent.Dispatch(this._Camera);

        // Continue the frame capture loop if the continuous frame capture state is enabled.
        if (this.state.continuousFrameCaptureState) {
            const delay = 5;

            setTimeout(async () => {
                await this.ContinuousFrameLoop();
            }, delay);
        }
    }

    /**
     * Starts the continuous frame capture loop.
     */
    private async StartContinuousCapture(): Promise<void> {
        this._WorkQueue.Post(async () => {
            await this._Camera.EnablePingPong(true);
        });

        this.ContinuousFrameLoop();
    }

    /**
     * Generates the set of selectable frame configuration items that are supported.
     * @returns The set of selectable frame configuration items.
     */
    private GetFrameConfigurationSet(): SelectItem<FrameConfiguration>[] {
        const retval: SelectItem<FrameConfiguration>[] =
            this._Camera.SupportedFrameConfigurations.map(
                (frame: FrameConfiguration): SelectItem<FrameConfiguration> => {
                    const configId: string =
                        frame.dimensions.columnCount + "x" + frame.dimensions.rowCount;
                    return { id: configId, label: configId, value: frame };
                }
            );

        return retval;
    }

    /**
     * Generates the set of selectable frame capture test mode items for all
     * supported test modes.
     * @returns The set of selectable frame capture test mode items.
     */
    private GetFrameCaptureTestModeSet(): SelectItem<TestMode>[] {
        const retval: SelectItem<TestMode>[] = [];

        const supportedTestModes: TestMode[] = this._Camera.SupportedTestModes;

        supportedTestModes.forEach((testMode) => {
            retval.push({
                id: "Test:" + testMode,
                label: this.GetFrameCaptureTestModeLabel(testMode),
                value: testMode
            });
        });

        return retval;
    }

    /**
     * Gets the label for a frame capture test mode.
     * @param mode - The frame capture test mode.
     * @returns - The string label for the frame capture test mode.
     */
    private GetFrameCaptureTestModeLabel(mode: TestMode) {
        switch (mode) {
            case TestMode.ColorField:
                return "Color Field";
            case TestMode.Classic:
                return "Classic";
            case TestMode.Walking1s:
                return "Walking 1s";
            case TestMode.VerticalColorBars:
                return "Vertical Color Bars";
        }
    }

    /**
     * Generates the set of selectable frame display mode items for all supported display modes.
     * @returns The set of selectable frame display mode items.
     */
    private GetFrameDisplayModeSet(): SelectItem<FrameDisplayMode>[] {
        const retval: SelectItem<FrameDisplayMode>[] = [];

        retval.push({ id: "RGB", label: "RGB", value: FrameDisplayMode.RGB });
        retval.push({ id: "BayerRaw", label: "Bayer Raw", value: FrameDisplayMode.RawBayer });
        retval.push({ id: "BayerMono", label: "Bayer Mono", value: FrameDisplayMode.RawMono });

        return retval;
    }

    /**
     * Retrieves the frame configuration for a specific id.
     * @param id - The id of the target frame configuration.
     * @returns The frame configuration corresponding to the id.
     */
    private GetFrameConfiguration(id: string): FrameConfiguration {
        const selectedItem: SelectItem<FrameConfiguration> | undefined =
            this.state.frameDimensionsList.find((element) => element.id === id);

        if (typeof selectedItem !== "undefined") {
            return selectedItem.value;
        } else {
            return this.state.frameDimensionsList[0].value;
        }
    }

    /**
     * Retrieves the frame capture mode that is currently selected.
     * @returns The frame capture mode that is selected.
     */
    private GetFrameCaptureMode(id: string): FrameCaptureMode {
        const selectedItem: SelectItem<TestMode> | undefined =
            this.state.frameCaptureTestModesList.find((element) => element.id === id);

        return selectedItem?.value;
    }

    private GetFrameDisplayMode(id: string): FrameDisplayMode {
        const selectedItem: SelectItem<FrameDisplayMode> | undefined =
            this.state.frameDisplayModesList.find((element) => element.id === id);
        if (typeof selectedItem !== "undefined") {
            return selectedItem.value;
        } else {
            return this.state.frameDisplayModesList[0].value;
        }
    }

    // Value Change Event Handlers
    private ContinousFrameCaptureStateChanged = (state: ToggleState) => {
        const checked: boolean = state === ToggleState.On;

        console.log("Continuous Capture State Changed: " + checked);

        this.setState(() => {
            if (checked) {
                this.StartContinuousCapture();
            }

            return { continuousFrameCaptureState: checked };
        });
    };

    /**
     * Selected Frame Size Changed Event Handler.
     * @param name - The name of the selected frame size.
     */
    private SelectedFrameSizeChanged = (name: string) => {
        console.log("Selected Frame Changed: " + name);

        const frameConfiguration: FrameConfiguration = this.GetFrameConfiguration(name);
        const frameCaptureMode: FrameCaptureMode = this.GetFrameCaptureMode(
            this.state.selectedFrameCaptureModeId
        );

        this.SetCameraState(
            this._Camera.DefaultSize,
            frameConfiguration,
            frameCaptureMode,
            this.state.frameBufferDepth,
            this.state.exposure
        );

        this.setState({ selectedFrameSizeId: name });
    };

    /**
     * Selected Frame Capture Mode Changed Event Handler.
     * @param name - The name of the selected frame capture mode.
     */
    private SelectedFrameCaptureModeChanged = (name: string) => {
        console.log("Selected Frame Capture Mode Changed: " + name);

        const frameConfiguration: FrameConfiguration = this.GetFrameConfiguration(
            this.state.selectedFrameSizeId
        );
        const frameCaptureMode: FrameCaptureMode = this.GetFrameCaptureMode(name);

        this.SetCameraState(
            this._Camera.DefaultSize,
            frameConfiguration,
            frameCaptureMode,
            this.state.frameBufferDepth,
            this.state.exposure
        );

        this.setState({ selectedFrameCaptureModeId: name });
    };

    /**
     * Selected Frame Display Mode Changed Event Handler.
     * @param name - The name of the selected frame display mode.
     */
    private SelectedFrameDisplayModeChanged = (name: string) => {
        console.log("Selected Frame Display Mode Changed: " + name);

        const frameDisplayMode = this.GetFrameDisplayMode(name);

        this.setState({ selectedFrameDisplayModeId: name, frameDisplayMode: frameDisplayMode });
    };

    /**
     * Exposure Changed Event Handler.
     * @param value - The selected exposure value.
     */
    private ExposureChanged = (value: bigint) => {
        console.log("Selected Exposure Changed: " + value);

        const frameConfiguration: FrameConfiguration = this.GetFrameConfiguration(
            this.state.selectedFrameSizeId
        );
        const frameCaptureMode: FrameCaptureMode = this.GetFrameCaptureMode(
            this.state.selectedFrameCaptureModeId
        );

        this.SetCameraState(
            this._Camera.DefaultSize,
            frameConfiguration,
            frameCaptureMode,
            this.state.frameBufferDepth,
            Number(value)
        );

        this.setState({ exposure: Number(value) });
    };

    /**
     * Frame Buffer Depth Changed Event Handler.
     * @param value - The selected frame buffer depth value.
     */
    private FrameBufferDepthChanged = (value: number) => {
        console.log("Frame Buffer Depth Changed: " + value);

        const frameConfiguration: FrameConfiguration = this.GetFrameConfiguration(
            this.state.selectedFrameSizeId
        );
        const frameCaptureMode: FrameCaptureMode = this.GetFrameCaptureMode(
            this.state.selectedFrameCaptureModeId
        );

        this.SetCameraState(
            this._Camera.DefaultSize,
            frameConfiguration,
            frameCaptureMode,
            value,
            this.state.exposure
        );

        this.setState({ frameBufferDepth: value });
    };

    /**
     * Reset Button Click Event Handler.
     */
    private async ResetButtonClick() {
        await this.Initialize();
    }

    /**
     * Capture Frame Button Click Event Handler.
     */
    private async CaptureFrameButtonClick() {
        const startTimeStamp: number = performance.now();

        await this._WorkQueue.Post(async () => {
            const result: FrameCaptureResult = await this._Camera.SingleFrameCapture();

            if (result.data != null) {
                console.log(
                    "Captured Single Frame: Code=" +
                        result.result +
                        " ColumnCount=" +
                        result.data.Dimensions.columnCount +
                        " RowCount=" +
                        result.data.Dimensions.rowCount +
                        " Size=" +
                        result.data.DataSize
                );

                if (this._CanvasViewRef.current != null) {
                    this._CanvasViewRef.current.UpdateFrameImage(result.data);
                }
            } else {
                console.log("ERROR: Failed to Capture Single Frame Code=" + result.result);
            }
        });

        const elapsedTime: number = performance.now() - startTimeStamp;

        console.log("Captured Single Frame: Elapsed=" + elapsedTime + "ms");
    }
}

export default CameraView;
