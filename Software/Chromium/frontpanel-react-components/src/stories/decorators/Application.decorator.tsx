import React from "react";

import type { Decorator } from "@storybook/react";

import Application from "../../primitives/Application";

const withApplication: Decorator = (Story) => (
    <Application>
        <Story />
    </Application>
);

export default withApplication;
