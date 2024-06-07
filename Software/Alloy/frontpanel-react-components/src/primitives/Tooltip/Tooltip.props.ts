/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
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
