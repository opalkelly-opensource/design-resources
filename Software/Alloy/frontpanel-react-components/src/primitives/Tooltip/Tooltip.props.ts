/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import { ReactNode } from "react";

/**
 * Interface for the properties of the `Tooltip` component.
 */
interface TooltipProps extends React.PropsWithChildren<NonNullable<unknown>> {
    /**
     * Content to be displayed within the tooltip
     */
    content: ReactNode;
}

export default TooltipProps;
