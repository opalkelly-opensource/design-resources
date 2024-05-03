/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import React from "react";

import type { Decorator } from "@storybook/react";

import Application from "../../primitives/Application";

const withApplication: Decorator = (Story) => (
    <Application>
        <Story />
    </Application>
);

export default withApplication;
