/**
 * Copyright (c) 2024-2025 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component, ReactNode } from "react";

import classNames from "classnames";

import "./ListItemComponent.css";

import { ToggleState, ToggleSwitch } from "@opalkelly/frontpanel-react-components";

//
export type IsEnabledChangeEventHandler = (id: number, isEnabled: boolean) => void;
export type RemoveListItemHandler = (id: number) => void;

//
interface ListItemComponentProps extends React.PropsWithChildren<NonNullable<unknown>> {
    className?: string;
    id: number;
    isEnabled: boolean;
    onIsEnabledChange: IsEnabledChangeEventHandler;
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
            </div>
        );
    }

    // Event Handlers
    private onIsEnabledChange(state: ToggleState) {
        this.props.onIsEnabledChange(this.props.id, state === ToggleState.On);
    }
}

export default ListItemComponent;
