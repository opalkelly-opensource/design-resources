import React, { useState, useEffect, useRef } from 'react';
import HistogramView from './HistogramView';
import { IFrontPanel, WorkQueue } from "@opalkelly/frontpanel-alloy-core";
import { sleep } from "./Utilities"; 

// Define a functional component that accepts a WorkQueue as a prop
const DispHist = ({ workQueue }: { workQueue: WorkQueue }) => {
    const [data, setData] = useState<number[]>([]);
    const [loading, setLoading] = useState<boolean>(true);
    const _FrontPanel: IFrontPanel = window.FrontPanel;
    const intervalRef = useRef<NodeJS.Timeout | null>(null);

    useEffect(() => {
        const fetchData = async () => {
            await workQueue.Post(async () => {
                try {
                    let i = 0;
                    await _FrontPanel.updateWireOuts();
                    let done: boolean = ((await _FrontPanel.getWireOutValue(0x25))) !== 0;
                    for (i = 0; (i < 10) && !done; i++) {
                        await sleep(1);
                        await _FrontPanel.updateWireOuts();
                        done = ((await _FrontPanel.getWireOutValue(0x25))) !== 0;
                    }
                    const HISTOGRAM_SIZE_BYTES=768;
                    if (done) {
                        const arrayBuffer = await _FrontPanel.readFromPipeOut(0xa1, HISTOGRAM_SIZE_BYTES * 4);
                        const uint32Array = new Uint32Array(arrayBuffer);
                        setData(Array.from(uint32Array));
                    }
                } catch (error) {
                    console.error('Failed to fetch data:', error);
                } finally {
                    setLoading(false);
                }
            });
        };

        
        fetchData();
        intervalRef.current = setInterval(fetchData, 240);

        return () => {
            if (intervalRef.current) {
                clearInterval(intervalRef.current);
            }
        };
    }, []); 

    if (loading) {
        return <div>Loading...</div>;
    }

    return (
        <HistogramView
            red={data.slice(0, 255)} 
            blue={data.slice(256, 511)}
            green={data.slice(512, 767)} 
            width={768} 
            height={200} 
        />
    );
};

export default DispHist;
