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
