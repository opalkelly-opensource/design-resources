/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
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
