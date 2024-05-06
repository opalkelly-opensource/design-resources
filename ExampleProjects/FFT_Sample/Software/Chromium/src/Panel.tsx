import React, { Component } from "react";

import classnames from "classnames";

import "./Panel.css";

/**
 * Properties for the Panel component.
 */
interface PanelProps extends React.PropsWithChildren<NonNullable<unknown>> {
    title: string;
    description: string;
    className?: string;
}

/**
 * Panel component for displaying a title, description, and content.
 */
class Panel extends Component<PanelProps> {
    render() {
        return (
            <div className={classnames("okPanel", this.props.className)}>
                <div className="okPanelHeader">
                    <span className="okPanelTitleText">{this.props.title}</span>
                    <span className="okPanelDescriptionText">{this.props.description}</span>
                </div>
                <div className="okPanelContent">{this.props.children}</div>
            </div>
        );
    }
}

export default Panel;
