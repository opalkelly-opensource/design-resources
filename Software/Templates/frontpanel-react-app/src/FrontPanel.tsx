
import React from "react"

import {
    IFPGADataPortClassic,
    FPGADataPortClassicPeriodicUpdateTimer,
    WorkQueue
} from "@opalkelly/frontpanel-platform-api";

import { Card, Flex, Box, Heading, TextField, Button } from "@radix-ui/themes";

import "./FrontPanel.css";

export interface FrontPanelProps {
    name: string;
    fpgaDataPort: IFPGADataPortClassic;
    workQueue: WorkQueue;
}

function FrontPanel(props: FrontPanelProps) {
    const [counterValue, setCounterValue] = React.useState<number>();

    const onUpdateWireValues = React.useCallback(async (sender?: IFPGADataPortClassic) => {
        props.workQueue.post(async () => {
            try {
                const counterValue = await props.fpgaDataPort.getWireOutValue(0x20) & 0xff;
                
                setCounterValue(counterValue);
            }
            catch (error) {
                console.error(error);
                throw new Error(`Failed to update counter value: ${error}`);
            }
        });
    }, [props.fpgaDataPort, props.workQueue]);

    React.useEffect(() => {
        const updateTimer = new FPGADataPortClassicPeriodicUpdateTimer(props.fpgaDataPort, props.workQueue, 10);

        onUpdateWireValues(props.fpgaDataPort);

        const subscription = updateTimer.wireOutValuesChangedEvent.subscribe(onUpdateWireValues);

        updateTimer.start();

        return () => {
            updateTimer.stop();

            subscription?.cancel();
        };
    }, [props.fpgaDataPort, onUpdateWireValues]);

    // Event Handlers
    const onCounterResetButtonDown = async () => {
        console.log("Counter Reset Button Down");
        await props.workQueue.post(async () => {
            props.fpgaDataPort.setWireInValue(0x00, 0xffffffff, 0x01);
            await props.fpgaDataPort.updateWireIns();
        });
    }

    const onCounterResetButtonUp = async () => {
        console.log("Counter Reset Button Up");
        await props.workQueue.post(async () => {
            props.fpgaDataPort.setWireInValue(0x00, 0, 0x01);
            await props.fpgaDataPort.updateWireIns();
        });
    }

    return (
        <Card>
            <Flex direction="column" gap="4">
                <Heading size="5" weight="medium">Counter #1</Heading>
                <Flex direction="column" align="center" gap="2">
                    <Box width="80px">
                        <TextField.Root placeholder="Counter #1 (Decimal)" value={counterValue?.toString()} readOnly>
                        </TextField.Root>
                    </Box>
                    <Box width="80px">
                        <TextField.Root placeholder="Counter #1 (Hexadecimal)" value={`0x${counterValue?.toString(16)}`} readOnly>
                        </TextField.Root>
                    </Box>
                </Flex>
                <Flex direction="row" align="center" justify="end" gap="2">
                    <Button size="1" color="red" onMouseDown={onCounterResetButtonDown} onMouseUp={onCounterResetButtonUp}>Reset</Button>
                </Flex>
            </Flex>
        </Card>
    );
}

export default FrontPanel;
