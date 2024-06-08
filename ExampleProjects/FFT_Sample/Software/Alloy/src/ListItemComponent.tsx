/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React, { Component, ReactNode } from "react";

import classNames from "classnames";

import "./ListItemComponent.css";

import { Button, ToggleState, ToggleSwitch } from "@opalkelly/frontpanel-react-components";

/**
 * Event handler for handling changes to the isEnabled state of a list item.
 */
export type IsEnabledChangeEventHandler = (id: number, isEnabled: boolean) => void;

/**
 * Event handler for removing a list item.
 */
export type RemoveListItemEventHandler = (id: number) => void;

/**
 * Properties for the List Item Component.
 */
interface ListItemComponentProps extends React.PropsWithChildren<NonNullable<unknown>> {
    className?: string;
    id: number;
    isEnabled: boolean;
    onIsEnabledChange: IsEnabledChangeEventHandler;
    onRemove: RemoveListItemEventHandler;
}

/**
 * List Item Component that displays child components along with a toggle switch and remove button.
 */
class ListItemComponent extends Component<ListItemComponentProps> {
    render(): ReactNode {
        return (
            <div className={classNames("okListItemComponent", this.props.className)}>
                {this.props.children}
                <ToggleSwitch
                    label="Enabled"
                    state={this.props.isEnabled ? ToggleState.On : ToggleState.Off}
                    onToggleStateChanged={this.OnIsEnabledChange.bind(this)}
                />
                <Button label="X" onButtonDown={this.OnRemove.bind(this)} />
            </div>
        );
    }

    /**
     * Event handler for handling changes to the isEnabled state of the list item.
     * @param state - New state of the toggle switch.
     */
    private OnIsEnabledChange(state: ToggleState) {
        this.props.onIsEnabledChange(this.props.id, state === ToggleState.On);
    }

    /**
     * Event handler for removing the list item.
     */
    private OnRemove() {
        this.props.onRemove(this.props.id);
    }
}

export default ListItemComponent;
