import React from "react";

import "./App.css";

import FrontPanel from "./FrontPanel";

import {
    IDevice,
    IFrontPanel,
    WorkQueue,
    DataProgressCallback,
    ByteCount
} from "@opalkelly/frontpanel-platform-api";

import { Application } from "@opalkelly/frontpanel-react-components";

import FrontPanelLogo from "../assets/logo512.png";

//TODO: Necessary to allow opening a device on Ubuntu
window.FrontPanelAPI.deviceManager.startMonitoring();

/**
 * Loads the specified configuration file into the FPGA on the specified device.
 * @param filename The name of the configuration file to load.
 * @param device The device to load the configuration file into.
 */
const loadConfiguration = async (filename: string, device: IDevice): Promise<void> => {
    console.log("Loading Configuration File:", filename);
    try {
        const response = await fetch("frontpanel://localhost/assets/bitfiles/" + filename);

        if (!response.ok) {
            throw new Error("Network response was not ok");
        }

        const arrayBuffer = await response.arrayBuffer();

        const reportProgress: DataProgressCallback = (total: ByteCount, completed: ByteCount) => {
            console.log("Configuration Progress: ", completed, " of ", total);
        };

        await device
            .getFPGA()
            .loadConfiguration(arrayBuffer, arrayBuffer.byteLength, reportProgress);

        console.log("Load Configuration Complete");
    } catch (error) {
        console.error("Failed to load configuration file:", filename, "\n", error);
    }
};

/**
 * Initializes the application by opening the specified device and
 * configuring the device with specified configuration file.
 * @param serialNumber The serial number of the device to open.
 * @param configurationFilename The name of the configuration file to load.
 * @returns {Promise<IDevice>} A promise that resolves to the opened device.
 */
const initializeDevice = async (
    serialNumber: string,
    configurationFilename: string
): Promise<IDevice> => {
    console.log("Opening Device...");

    const device = await window.FrontPanelAPI.deviceManager.openDevice(serialNumber);

    const deviceInfo = await device.getInfo();

    console.log("Opened Device:", deviceInfo.productName, " SerialNumber:", deviceInfo.serialNumber);

    await loadConfiguration(configurationFilename, device);

    return device;
};

const DeviceWorkQueue = new WorkQueue();

function App() {
    const [frontpanel, setFrontPanel] = React.useState<IFrontPanel>();

    React.useEffect(() => {
        let device: IDevice;

        DeviceWorkQueue.post(async () => {
            try {
                //TODO: Replace 'frontpanel.bit' with the name of the configuration file to load.
                device = await initializeDevice("", "frontpanel.bit");

                const frontpanel = await device.getFPGA().getFrontPanel();

                setFrontPanel(frontpanel);
            }
            catch (error) {
                device?.close();
                console.error(error);
            }
        });

        return () => {
            DeviceWorkQueue.post(() => {
                return new Promise((resolve) => {
                    console.log("Closing Device...");
                    device?.close();
                    resolve();
                });
            });
        };
    }, []);

    if (frontpanel !== undefined) {
        return (
            <div className="App">
                <Application>
                    <FrontPanel
                        name="FrontPanel"
                        frontpanel={frontpanel}
                        workQueue={DeviceWorkQueue}
                    />
                </Application>
            </div>
        );
    } else {
        return (
            <div className="App">
                <img src={FrontPanelLogo} />
            </div>
        );
    }
}

export default App;
