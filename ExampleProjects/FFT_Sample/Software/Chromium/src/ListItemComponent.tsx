import React, { Component, ReactNode } from "react";

import classNames from "classnames";

import "./ListItemComponent.css";

import { Button, ToggleState, ToggleSwitch } from "@opalkellytech/frontpanel-react-components";

//
export type IsEnabledChangeEventHandler = (id: number, isEnabled: boolean) => void;
export type RemoveListItemHandler = (id: number) => void;

//
interface ListItemComponentProps extends React.PropsWithChildren<NonNullable<unknown>> {
    className?: string;
    id: number;
    isEnabled: boolean;
    onIsEnabledChange: IsEnabledChangeEventHandler;
    onRemove: RemoveListItemHandler;
}

class ListItemComponent extends Component<ListItemComponentProps> {
    render(): ReactNode {
        return (
            <div className={classNames("okListItemComponent", this.props.className)}>
                {this.props.children}
                <ToggleSwitch
                    label="Enabled"
                    state={this.props.isEnabled ? ToggleState.On : ToggleState.Off}
                    onToggleStateChanged={this.onIsEnabledChange.bind(this)}
                />
                <Button label="X" onButtonDown={this.onRemove.bind(this)} />
            </div>
        );
    }

    // Event Handlers
    private onIsEnabledChange(state: ToggleState) {
        this.props.onIsEnabledChange(this.props.id, state === ToggleState.On);
    }

    private onRemove() {
        this.props.onRemove(this.props.id);
    }
}

export default ListItemComponent;
