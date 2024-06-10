/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import * as React from "react";

import * as TooltipPrimitive from "@radix-ui/react-tooltip";

import { ApplicationProps } from "./Application.props";

type ApplicationElement = React.ElementRef<"div">;

const Application = React.forwardRef<ApplicationElement, ApplicationProps>(
    (props, _forwardedRef) => {
        return <TooltipPrimitive.Provider>{props.children}</TooltipPrimitive.Provider>;
    }
);

Application.displayName = "Application";

export default Application;
