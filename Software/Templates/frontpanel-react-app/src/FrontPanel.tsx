import { Component } from "react";

import {
    IFrontPanel,
    WorkQueue
} from "@opalkelly/frontpanel-platform-api";

import { FrontPanel as FrontPanelContext } from "@opalkelly/frontpanel-react-components";

import "./FrontPanel.css";

export interface FrontPanelProps {
    name: string;
    frontpanel: IFrontPanel;
    workQueue: WorkQueue;
}

export interface FrontPanelState {
}

class FrontPanel extends Component<FrontPanelProps, FrontPanelState> {
    // Constructor
    constructor(props: FrontPanelProps) {
        super(props);

        this.state = {};
    }

    // Component Lifecycle Methods
    componentDidMount() {
        //TODO: Add any initialization code here
    }

    componentWillUnmount() {
        //TODO: Add any cleanup code here
    }

    render() {
        return (
            <FrontPanelContext
                device={this.props.frontpanel}
                workQueue={this.props.workQueue}>
                <div className="ControlPanel">{/* TODO: Add your FrontPanel controls here */}</div>
            </FrontPanelContext>
        );
    }
}

export default FrontPanel;
