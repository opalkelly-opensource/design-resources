import React from "react";

import {
    IDevice,
    IDeviceInfo,
    IFPGAConfiguration,
    IFPGADataPortClassic,
    WorkQueue,
    DataProgressCallback,
    ByteCount
} from "@opalkelly/frontpanel-platform-api";

import { AlertDialog, Text, Button, Flex, Separator } from "@radix-ui/themes";

import "./App.css";

import "./FPGAConfigurationFiles";

import FrontPanelLogo from "../assets/logo192.png";

import FrontPanel from "./FrontPanel";

const DeviceWorkQueue = new WorkQueue();

interface ErrorProperties { title: string, description: string, details: string, solution: string };

function App() {
    const [fpgaDataPort, setFPGADataPort] = React.useState<IFPGADataPortClassic>();
    const [error, setError] = React.useState<ErrorProperties>();

    React.useEffect(() => {
        /**
         * Loads the specified configuration file using the FPGA configuration interface of a device.
         * @param filename - The name of the configuration file to load.
         * @param fpgaConfiguration - The FPGA configuration interface of the device.
         */
        const loadFPGAConfiguration = async (filename: string, fpgaConfiguration: IFPGAConfiguration): Promise<void> => {
            let response;

            // Retrieve the contents of the bitfile from the bundled assets using the 'frontpanel://' protocol
            try {
                response = await fetch("frontpanel://localhost/assets/bitfiles/" + filename);
            }
            catch (error) {
                throw new Error(`Failed to retrieve ${filename}`);
            }

            if (!response.ok) {
                console.error(`Fetch response error status: ${response.ok}`);
            }

            const arrayBuffer = await response.arrayBuffer();

            // Specify a function to use as a callback to report FPGA configuration progress
            const reportProgress: DataProgressCallback = (total: ByteCount, completed: ByteCount) => {
                console.log(`FPGA Configuration Progress: ${completed} of ${total} bytes`);
            };

            // Start the FPGA configuration operation
            await fpgaConfiguration.loadConfigurationFromMemory(arrayBuffer, arrayBuffer.byteLength, reportProgress);
        };

        /**
         * Initializes the device by configuring the FPGA on the device with the file 
         * corresponding to the product name of the device.
         * @param device - The device to initialize.
         * @returns {Promise<IDevice>} A promise that resolves to the opened device.
         */
        const initializeDevice = async (device: IDevice): Promise<void> => {
            const deviceInfo = await device.getDeviceInfo();

            console.log(`Initializing Device Product: ${deviceInfo.productName} SerialNumber: '${deviceInfo.serialNumber}'`);

            const fpgaConfiguration = device.getFPGAConfiguration();

            //Choose the configuration file based on the product name of the device.
            const configurationFilename = deviceInfo.productName + "/counters.bit";

            await loadFPGAConfiguration(configurationFilename, fpgaConfiguration);
        };

        const targetDeviceSerialNumber = (window.FrontPanelEnv.targetDeviceSerialNumbers.length > 0) ? window.FrontPanelEnv.targetDeviceSerialNumbers[0] : "";
        const deviceManager = window.FrontPanelAPI.deviceManager;

        let device: IDevice;
        let deviceInfo: IDeviceInfo;

        DeviceWorkQueue.post(async () => {
            console.log(`Opening Device SerialNumber='${targetDeviceSerialNumber}'...`);

            await deviceManager.startMonitoring();

            // Step 1: Open the Device
            try {
                device = await window.FrontPanelAPI.deviceManager.openDevice(targetDeviceSerialNumber);

                deviceInfo = await device.getDeviceInfo();

                console.log(`Opened Device Product: '${deviceInfo.productName}' SerialNumber: '${deviceInfo.serialNumber}'`);
            }
            catch(error) {
                console.error(`Failed to open Device '${targetDeviceSerialNumber}': \n${error}`);

                setFPGADataPort(undefined);
                setError({
                    title: "Failed to Open Target Device", 
                    description: `Unable to open device with serial number ${targetDeviceSerialNumber}`,
                    details: `${error}`,
                    solution: "Verify that the device is properly connected and restart the application."
                });
            }

            if(device) {
                // Step 2: Initialize the Device and retrieve the FPGA dataport
                console.log(`Initializing Device '${deviceInfo.serialNumber}'...`);

                try {
                    await initializeDevice(device);

                    const fpgaDataPort = await device.getFPGADataPortClassic();

                    setFPGADataPort(fpgaDataPort);
                }
                catch(error) {
                    console.error(`Failed to initialize Device '${deviceInfo.serialNumber}': \n${error}`);

                    setFPGADataPort(undefined);
                    setError({
                        title: "Failed to Initialize Device", 
                        description: `Unable to initialize ${deviceInfo.productName} with serial number ${deviceInfo.serialNumber}`,
                        details: `${error}`,
                        solution: "Verify that the device is properly connected and restart the application."
                    });
                }
            }
        });

        return () => {
            console.log(`Perform Cleanup`)

            setFPGADataPort(undefined);

            // Close the Device
            DeviceWorkQueue.post(async () => {
                await deviceManager.stopMonitoring();

                console.log(`Closing Device...`);
                device?.close();
            });
        };
    }, []);

    // Event Handlers
    const onExitButtonClick = () => {
        window.close();
    }

    return (
        <div className="App">
            {(fpgaDataPort) ? 
                <FrontPanel
                    name="Counter"
                    fpgaDataPort={fpgaDataPort}
                    workQueue={DeviceWorkQueue}/>
                :
                <>
                    <img src={FrontPanelLogo} />
                    <AlertDialog.Root open={(error !== undefined)}>
                        <AlertDialog.Content maxWidth="450px">
                            <AlertDialog.Title>{error?.title}</AlertDialog.Title>
                            <Separator my="3" size="4"/>
                            <AlertDialog.Description size="2">{error?.description}</AlertDialog.Description>
                            <Flex direction="column" gap="4" p="2">
                                <Text size="2" weight="regular">{error?.details}</Text>
                                <Text size="2" weight="regular">Solution: {error?.solution}</Text>
                            </Flex>
                            <Flex gap="3" mt="4" justify="end">
                                <AlertDialog.Action>
                                    <Button onClick={onExitButtonClick} variant="solid" color="red">
                                        Exit
                                    </Button>
                                </AlertDialog.Action>
                            </Flex>
                        </AlertDialog.Content>
                    </AlertDialog.Root>
                </>
            }
        </div>
    );
}

export default App;
