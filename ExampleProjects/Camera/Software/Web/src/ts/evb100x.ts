import * as frontpanelWs from '@opalkelly/frontpanel-ws';
import $ from 'jquery';
import { CameraApp } from './camera-app';
import { CameraError, CameraErrorCode } from './camera-error';
import {
    bayerToMono,
    bayerToRGBA,
    Camera,
    fillBayerData,
    IMAGE_BUFFER_DEPTH_AUTO,
    TestMode
} from './frontpanel-camera';
import { readBinaryFile, readTextFile } from './read-file';

const DISABLE_CONTROL_DELAY = 500; // 0.5 sec.
const CAMERA_ERROR_DELAY = 1000; // 1 sec.
const CAMERA_ERROR_TIMEOUT = 10000; // 10 sec.

const IMAGE_CAPTURE_ID = 100;
const IMAGE_CAPTURE_NAME = 'Image Capture';

enum Page {
    Connect,
    Camera
}

enum DisplayMode {
    RawBayer = 0,
    RawMono = 1,
    RGB = 2
}

interface IDisableControlsOptions {
    withDelay?: boolean;
}

function getTestModeName(mode: TestMode) {
    switch (mode) {
        case TestMode.ColorField:
            return 'Test: Color Field';
        case TestMode.HorizontalGradient:
            return 'Test: Horizontal Gradient';
        case TestMode.VerticalGradient:
            return 'Test: Vertical Gradient';
        case TestMode.DiagonalGradient:
            return 'Test: Diagonal';
        case TestMode.Classic:
            return 'Test: Classic';
        case TestMode.Walking1s:
            return 'Test: Walking 1s';
        case TestMode.MonochromeHorizontalBars:
            return 'Test: Monochrome Horizontal Bars';
        case TestMode.MonochromeVerticalBars:
            return 'Test: Monochrome Vertical Bars';
        case TestMode.VerticalColorBars:
            return 'Test: Vertical Color Bars';
    }
}

$(window).on('load', async () => {
    // This is the script engine ID which is fixed to 1 here as we use only a
    // single scripting engine.
    const scriptEngine = 1;
    let camera: Camera | undefined;
    let serialCamera: string | undefined;
    let continuousCapture = false;
    let numFrames = 0;
    let currentDepth = 0;
    let cameraSettingsChanged = false;
    let currentPage = Page.Connect;
    let cameraErrorDelay: number | undefined;
    let cameraErrorTimeout: number | undefined;

    function getCamera(): Camera {
        if (camera === undefined) {
            throw Error('Camera is not opened');
        }
        return camera;
    }

    const app = new CameraApp();
    app.onError = async (e: any) => {
        app.log(e);

        switch (currentPage) {
            case Page.Connect:
                $('#error').slideDown('fast');
                $('#errorContent').text(e);
                break;
            case Page.Camera:
                $('#alertContent').text(e);
                $('#alertButton').on('click', () => {
                    $('#alert').removeClass('active');
                    showPage(Page.Connect);
                });
                $('#alert').addClass('active');
                break;
        }

        // Disconnect on any error.
        app.disconnect();
    };

    app.onConnect = async () => {
        showPage(Page.Camera);
        $('#spinnerCamera').hide();

        // Clear the devices list.
        $('#devicesList').empty();

        // Process devices.
        for (const serial of app.devices) {
            await app.onAddDevice?.(serial);
        }
    };

    app.onDisconnect = async () => {
        cleanupCamera();
    };

    app.onAddDevice = async (serial: string) => {
        await app.callAndCheckErrors(async () => {
            const deviceHTML = `<option>${serial}</option>`;
            $('#devicesList').append(deviceHTML);

            app.log(`Device ${serial} connected`);

            if (serialCamera === undefined) {
                if (await openCamera(serial)) {
                    $(`#devicesList option:contains("${serial}")`).prop(
                        'selected',
                        true
                    );
                }
            }
        });
    };

    app.onRemoveDevice = async (serial: string) => {
        await app.callAndCheckErrors(async () => {
            $('#devicesList option').each(
                (_i: number, element: HTMLElement) => {
                    if ($(element).text() === serial) {
                        element.remove();
                    }
                }
            );

            if (serialCamera === serial) {
                app.log('Camera connection lost');
                cleanupCamera();
            } else {
                app.log(`Device ${serial} disconnected`);
            }
        });
    };

    $(window).resize(async () => {
        await app.callAndCheckErrors(async () => {
            // Do nothing if the camera is not opened.
            if (camera === undefined) {
                return;
            }
            updateCanvasSize();
        });
    });

    function showPage(page: Page): void {
        switch (page) {
            case Page.Connect:
                $('#log')
                    .addClass('log-hidden')
                    .removeClass('log-expanded')
                    .removeClass('log-switch-expanded');
                $('#logSwitch').removeClass('log-switch-active');
                $('#containerConnect').append($('#log'));

                $('#containerConnect').show();
                $('#containerCamera').hide();
                $('#buttonControls').hide();
                break;
            case Page.Camera:
                $('#log')
                    .removeClass('log-hidden')
                    .removeClass('log-expanded')
                    .removeClass('log-switch-expanded');
                $('.content-primary').append($('#log'));

                $('#error').hide();
                $('#containerConnect').hide();
                $('#containerCamera').show();
                $('#buttonControls').show();
                $('.led').hide();
                break;
        }
        currentPage = page;
    }

    // Clear camera error timers if any.
    function cleanupCameraError() {
        if (cameraErrorDelay !== undefined) {
            window.clearTimeout(cameraErrorDelay);
            cameraErrorDelay = undefined;
        }
        if (cameraErrorTimeout !== undefined) {
            window.clearTimeout(cameraErrorTimeout);
            cameraErrorTimeout = undefined;
        }
    }

    function showCameraError(text: string) {
        cleanupCameraError();
        // Show the camera error with some delay to avoid error message flashing
        // if the first camera failed to open (with the error message) and then
        // successfully opened the second camera.
        cameraErrorDelay = window.setTimeout(() => {
            cameraErrorDelay = undefined;
            $('#cameraError').slideDown('fast').text(text);
            cameraErrorTimeout = window.setTimeout(() => {
                cameraErrorTimeout = undefined;
                $('#cameraError').slideUp('fast');
            }, CAMERA_ERROR_TIMEOUT);
        }, CAMERA_ERROR_DELAY);
    }

    function hideCameraError() {
        cleanupCameraError();
        $('#cameraError').slideUp('fast');
    }

    function cleanupCamera(): void {
        $('#containerCameraControls').hide();
        stopContinuous();
        camera = undefined;
        serialCamera = undefined;
    }

    async function closeCamera(): Promise<void> {
        if (serialCamera === undefined) {
            return;
        }
        cleanupCamera();
        if (app.isConnected) {
            await app.fp.closeDevice();
        }
    }

    async function openCamera(serial: string): Promise<boolean> {
        app.disableControl('#devicesList');
        app.log(`Opening camera ${serial}...`);
        if (serialCamera !== undefined) {
            await closeCamera();
        }

        serialCamera = serial;

        await app.fp.openDevice(serial);

        const bitfileName = await Camera.getBitfileName(app.fp);
        if (bitfileName === undefined) {
            const errorMessage = `Device ${serial} can't be used as a camera`;
            app.log(errorMessage);
            showCameraError(errorMessage);
            await closeCamera();
            app.enableControl('#devicesList');
            return false;
        }
        hideCameraError();

        // Asynchronously configure and initialize the camera (don't `await`).
        app.callWithSpinnerAndCheckErrors(async () => {
            const logConfiguring = (filename: string) => {
                app.log(
                    `Configuring ${serial} with '${filename}' bit file...`
                );
            };
            let bitfileData: Uint8Array;
            const appOpenedFromLocalFile = window.location.href.startsWith(
                'file://'
            );
            if (appOpenedFromLocalFile) {
                app.log(`Selecting a bit file...`);
                bitfileData = await readBinaryFile(
                    app,
                    'Select the bitfile to configure the device',
                    `(${bitfileName})`,
                    'Configure',
                    logConfiguring
                );
            } else {
                logConfiguring(bitfileName);
                const bitfilePath = `bitfiles/${bitfileName}`;
                bitfileData = await app.httpBinaryRequest(bitfilePath);
            }
            await app.fp.configureFPGA(bitfileData);

            const logInitializing = (filename: string) => {
                app.log(`Initializing with '${filename}' script...`);
            };
            const scriptPath = 'camera.lua';
            let scriptContent: string;
            if (appOpenedFromLocalFile) {
                app.log(`Selecting a Lua script...`);
                scriptContent = await readTextFile(
                    app,
                    'Select the Lua script performing the camera initialization',
                    `(${scriptPath})`,
                    'Initialize',
                    logInitializing
                );
            } else {
                logInitializing(scriptPath);
                scriptContent = await app.httpTextRequest(scriptPath);
            }
            camera = new Camera();
            await camera.initialize(
                app.fp,
                scriptEngine,
                scriptPath,
                scriptContent
            );

            const defaultSize = camera.getDefaultSize();
            const supportedSkips = camera.getSupportedSkips();
            $('#selectCaptureSize').empty();
            supportedSkips.forEach(skips => {
                const size = Camera.getSizeWithSkips(defaultSize, skips, skips);
                $('#selectCaptureSize').append(
                    $('<option>', {
                        value: `${skips}`,
                        text: `${size.width} x ${size.height}`
                    })
                );
            });
            $('#selectCaptureSize option:nth-child(2)').prop('selected', true);

            const supportedTestModes = camera.getSupportedTestModes();
            $('#selectCaptureMode').empty();
            supportedTestModes.forEach(mode => {
                $('#selectCaptureMode').append(
                    $('<option>', {
                        value: `${mode}`,
                        text: `${getTestModeName(mode)}`
                    })
                );
            });
            $('#selectCaptureMode').append(
                $('<option>', {
                    value: `${IMAGE_CAPTURE_ID}`,
                    text: `${IMAGE_CAPTURE_NAME}`
                })
            );
            $(`#selectCaptureMode option[value="${IMAGE_CAPTURE_ID}"]`).prop(
                'selected',
                true
            );

            await setupCamera();

            await captureSingleImage();

            app.log(`Use camera ${serial}`);

            app.enableControl('#devicesList');
            $('[name="toggleCapture"][value="single"]').prop('checked', true);
            $('#containerCameraControls').show();
        });
        return true;
    }

    async function setupCameraSize(): Promise<void> {
        const defaultSize = getCamera().getDefaultSize();
        await getCamera().setSize(defaultSize.width, defaultSize.height);
        const skip = Number($('#selectCaptureSize').val());
        await getCamera().setSkips(skip, skip);

        const canvas = document.getElementById('image') as HTMLCanvasElement;
        const cameraWidth = getCamera().width;
        const cameraHeight = getCamera().height;

        // Setting `width` or `height` properties invalidates the canvas
        // (clearing it), so do it only if necessary.
        if (canvas.width !== cameraWidth || canvas.height !== cameraHeight) {
            canvas.width = cameraWidth;
            canvas.height = cameraHeight;
        }

        updateCanvasSize();
    }

    async function setupCamera(): Promise<void> {
        const exposure = Number($('#inputExposure').val());
        await getCamera().setShutterWidth(exposure);

        await setupCameraSize();

        const mode = Number($('#selectCaptureMode').val());
        if (mode === IMAGE_CAPTURE_ID) {
            await getCamera().setTestMode(false);
        } else {
            await getCamera().setTestMode(true, mode);
        }

        await setupBufferDepth();
    }

    function updateCanvasSize(): void {
        const container = $('#imageContainer');
        const containerWidth = container.width() || 648;
        const containerHeight = container.height() || 486;

        const cameraWidth = getCamera().width;
        const cameraHeight = getCamera().height;
        // Check that the camera height is not zero, as we divide by it later.
        if (cameraHeight === 0) {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                'The camera height unexpectedly zero'
            );
        }

        const canvas = document.getElementById('image') as HTMLCanvasElement;
        let newCanvasWidth = canvas.width;
        let newCanvasHeight = canvas.height;
        if ($('[name="toggleZoomMode"]:checked').val() === 'fit') {
            newCanvasWidth = cameraWidth;
            newCanvasHeight = cameraHeight;
        } else {
            // Scale the canvas preserving the camera aspect ratio.
            const containerRatio = containerWidth / containerHeight;
            const cameraRatio = cameraWidth / cameraHeight;
            if (containerRatio < cameraRatio) {
                newCanvasWidth = containerWidth;
                newCanvasHeight = Math.ceil(containerWidth / cameraRatio);
            } else {
                newCanvasWidth = Math.ceil(containerHeight * cameraRatio);
                newCanvasHeight = containerHeight;
            }
        }

        $('#image')
            .css('width', `${newCanvasWidth}px`)
            .css('height', `${newCanvasHeight}px`);
    }

    // Set up the current depth from the depth slider control.
    async function setupBufferDepth() {
        // The slider allows to select the buffer depth, up to the maximum
        // supported by the device in the current resolution.
        const min = Camera.getMinDepth();
        const max = getCamera().getMaxDepthForResolution();
        const depthPercent = Number($('#rangeDepth').val());
        currentDepth = min + Math.round((depthPercent * (max - min)) / 100);
        await getCamera().setImageBufferDepth(
            depthPercent === 100 ? IMAGE_BUFFER_DEPTH_AUTO : currentDepth
        );
        $('#textDepth').text(
            `Frame Buffer Depth (max = ${currentDepth} frames)`
        );
    }

    function setCurrentBufferLevel(frames: number) {
        $('#textCurrentDepth').text(`Current Buffer Level (${frames} frames)`);
    }

    async function startContinuous() {
        disableCameraControls();
        continuousCapture = true;
        $('.led').show();

        await camera?.enablePingPong(true);

        let fpsIntervalStart = window.performance.now();

        // Loop updating continuous capture statistics such as FPS and buffer
        // depth. Don't `await`.
        app.repeatWhile(
            () => {
                return continuousCapture;
            },
            async () => {
                if (numFrames === 0) {
                    $('#textFPS').text('< 1');
                } else {
                    const fps =
                        (1000 * numFrames) /
                        (window.performance.now() - fpsIntervalStart);
                    $('#textFPS').text(`${fps.toFixed(2)}`);
                    numFrames = 0;
                    fpsIntervalStart = window.performance.now();
                }

                // If still in the continuous capture mode.
                if (continuousCapture) {
                    // Update the buffer depth.
                    const currentValue = await getCamera().getBufferedImageCount();
                    const percentValue = Math.round(
                        (100 * currentValue) / currentDepth
                    );
                    $('#progressCurrentDepth')
                        .css('width', `${percentValue}%`)
                        .attr('title', currentValue);
                    setCurrentBufferLevel(currentValue);
                }
            },
            1000
        );

        // Capture loop. Don't `await`.
        app.repeatWhile(
            () => {
                return continuousCapture;
            },
            async () => {
                const data = await tryCapture(() => {
                    return getCamera().bufferedCapture();
                });
                if (data === undefined) {
                    return;
                }

                ++numFrames;
                showImage(data);

                // Get the number of missed frames.
                await app.fp.updateWireOuts();

                // Continuous mode could be switched off while we were waiting
                // for wire outs, so check for it again to avoid overwriting
                // the text value set by stopContinuous().
                if (continuousCapture) {
                    const missedFrames = app.fp.getWireOutValue(0x23) & 0xff;
                    $('#textMissedFrames').text(`${missedFrames}`);
                }
            },
            10
        );
    }

    function stopContinuous() {
        continuousCapture = false;
        $('[name="toggleCapture"][value="single"]').prop('checked', true);
        $('#textFPS').text('-');
        $('#textMissedFrames').text('-');
        $('#progressCurrentDepth')
            .css('width', '0%')
            .attr('title', 0);
        setCurrentBufferLevel(0);
        $('.led').hide();
        enableCameraControls();
    }

    function showImage(buf: Uint8Array): void {
        if (camera === undefined) {
            return;
        }

        const canvas = document.getElementById('image') as HTMLCanvasElement;
        if (canvas === null) {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                '`image` element not found'
            );
        }
        const ctx = canvas.getContext('2d', { alpha: false });
        if (ctx === null) {
            throw new frontpanelWs.FrontPanelError(
                frontpanelWs.ErrorCode.Failed,
                'Failed to get image context'
            );
        }

        const width = camera.width;
        const height = camera.height;
        const imageData = ctx.createImageData(width, height);

        const mode = Number(
            $('#selectDisplayMode option:selected').prop('value')
        );
        switch (mode) {
            case DisplayMode.RGB:
                bayerToRGBA(width, height, buf, imageData.data);
                break;
            case DisplayMode.RawBayer:
                fillBayerData(width, height, buf, imageData.data);
                break;
            case DisplayMode.RawMono:
                bayerToMono(width, height, buf, imageData.data);
                break;
        }

        ctx.putImageData(imageData, 0, 0);
    }

    async function tryCapture(
        capture: () => Promise<Uint8Array>
    ): Promise<Uint8Array | undefined> {
        try {
            // Update camera settings if necessary.
            if (cameraSettingsChanged) {
                cameraSettingsChanged = false;

                await setupCamera();
            }

            return await capture();
        } catch (e) {
            if (e instanceof CameraError) {
                switch (e.code) {
                    case CameraErrorCode.Timeout:
                    case CameraErrorCode.ImageReadoutShort:
                        // Log an error and keep capturing.
                        app.log(e.message);
                        break;
                    case CameraErrorCode.Failed:
                    case CameraErrorCode.ImageReadoutError:
                        // Log an error and stop capturing.
                        app.log(e.message);
                        stopContinuous();
                        break;
                    default:
                        // Unknown errors: rethrow to disconnect.
                        throw e;
                }
            } else {
                throw e;
            }
        }
        return undefined;
    }

    async function captureSingleImage(): Promise<void> {
        const disableTimer = disableCameraControls({ withDelay: true });
        app.disableControl('[name="toggleCapture"]');
        $('.led').show();

        const data = await tryCapture(() => {
            return getCamera().singleCapture();
        });
        if (data !== undefined) {
            showImage(data);
            app.log(`Got image data of length ${data.length}`);
        }

        $('.led').hide();
        enableCameraControls(disableTimer);
        app.enableControl('[name="toggleCapture"]');
    }

    function enableCameraControls(delayTimer?: number): void {
        if (delayTimer !== undefined) {
            // See disableCameraControls().
            window.clearTimeout(delayTimer);
        }
        app.enableButton('#buttonCapture');
        app.enableButton('#buttonCMOSReset');
    }

    function disableCameraControls(
        options?: IDisableControlsOptions
    ): number | undefined {
        const doDisable = () => {
            app.disableButton('#buttonCapture');
            app.disableButton('#buttonCMOSReset');
        };
        if (options?.withDelay) {
            // Button was constantly flickering when it was temporarily disabled
            // for just a short time.
            // So now we just set `disabled` property without changing buttons
            // visual state by adding `button-disabled` SCC class. And only
            // change its visual state once the given delay expires -- because
            // we could actually have reenabled it by then, and in this case we
            // won't need to change its appearance at all.
            $('#buttonCapture').prop('disabled', true);
            $('#buttonCMOSReset').prop('disabled', true);
            return window.setTimeout(doDisable, DISABLE_CONTROL_DELAY);
        }
        doDisable();
        return undefined;
    }

    // GUI event handlers.
    app.bindSubmit('#formConnect', async () => {
        try {
            let errorMessage: string | undefined;
            const validateAndGetValue = (
                element: string,
                name: string
            ): string => {
                const val = $(element).val() as string;
                if (!val && !errorMessage) {
                    $(`${element}Group`).addClass('has-danger');
                    errorMessage = `${name} should not be empty`;
                } else {
                    $(`${element}Group`).removeClass('has-danger');
                }
                return val;
            };
            let server = validateAndGetValue('#inputServer', 'Server URI');

            if (!errorMessage) {
                // If the protocol is not set, append the default value.
                if (server.search('://') === -1) {
                    server = 'wss://' + server;
                }

                try {
                    const serverURI = new URL(server);

                    // If the server port is not set, append the default value.
                    if (!serverURI.port) {
                        server += ':9999';
                    }
                } catch (e) {
                    $('#inputServerGroup').addClass('has-danger');
                    errorMessage = String(e);
                }
            }

            const username = validateAndGetValue('#inputUsername', 'User name');
            const password = validateAndGetValue('#inputPassword', 'Password');

            if (!errorMessage) {
                // Validation succeed, ensure that the error message is hidden.
                $('#contextualError').slideUp('fast');
            } else {
                // Validation failed.
                $('#contextualErrorText').text(errorMessage);
                $('#contextualError').slideDown('fast');
                return;
            }

            app.disableButton('#buttonConnect');

            await app.connectAndLogin(server, username, password);

            app.log(`Opened connection to "${server}"`);

            // The server loop.
            app.repeatWhile(
                () => {
                    return app.isConnected;
                },
                async () => {
                    await app.processServerNotifications();
                },
                100
            );
        } finally {
            app.enableButton('#buttonConnect');
        }
    });

    app.bindSubmit('#formCameraControls', async () => {
        // Empty handler for the camera controls form submit event
        // to prevent page refreshing by pressing Enter on input controls.
    });

    app.bindClickButton(
        '#buttonStatus',
        async () => {
            if (app.isConnected) {
                await app.disconnect();
                app.log('Closed connection');
            }
            showPage(Page.Connect);
        },
        { disabledWhileHandling: true }
    );

    app.bindClickButton('#buttonCapture', captureSingleImage);

    app.bindClickButton('#buttonCMOSReset', async () => {
        const disableTimer = disableCameraControls({ withDelay: true });
        app.disableControl('[name="toggleCapture"]');
        await camera?.logicReset();
        enableCameraControls(disableTimer);
        app.enableControl('[name="toggleCapture"]');
    });

    app.bindChange('#devicesList', async () => {
        const serial = $('#devicesList option:selected').text();
        if (!serial || serialCamera === serial) {
            return;
        }
        await openCamera(serial);
    });

    app.bindChange('[name="toggleCapture"]', async () => {
        if (camera === undefined) {
            return;
        }
        if ($('[name="toggleCapture"]:checked').val() === 'continuous') {
            await startContinuous();

            app.log('Buffered Capture...');
        } else {
            stopContinuous();
        }
    });

    const cameraSettingsChangedCallback = async () => {
        cameraSettingsChanged = true;
    };
    app.bindChange('#inputExposure', cameraSettingsChangedCallback);
    app.bindChange('#selectCaptureSize', async () => {
        // When the size is changed, we should update buffer depth controls.
        if (continuousCapture) {
            // But we can't do it immediately in continuous capture mode.
            cameraSettingsChanged = true;
        } else {
            await setupCameraSize();
            await setupBufferDepth();
        }
    });
    app.bindChange('#selectCaptureMode', cameraSettingsChangedCallback);

    app.bindChange('#rangeDepth', cameraSettingsChangedCallback);
    app.bindChange('[name="toggleZoomMode"]', async () => {
        updateCanvasSize();
    });
});
