/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the FrontPanel license.
 * See the LICENSE file found in the root directory of this project.
 */

import FrontPanelSelectEntryRoot from "./FrontPanelSelectEntryRoot";

import SelectEntryContent from "../../primitives/SelectEntry/SelectEntryContent";
import SelectEntryGroup from "../../primitives/SelectEntry/SelectEntryGroup";
import SelectEntryItem from "../../primitives/SelectEntry/SelectEntryItem";
import SelectEntryLabel from "../../primitives/SelectEntry/SelectEntryLabel";
import SelectEntrySeparator from "../../primitives/SelectEntry/SelectEntrySeparator";
import SelectEntryTrigger from "../../primitives/SelectEntry/SelectEntryTrigger";

const FrontPanelSelectEntry = Object.assign(
    {},
    {
        Root: FrontPanelSelectEntryRoot,
        Trigger: SelectEntryTrigger,
        Content: SelectEntryContent,
        Item: SelectEntryItem,
        Group: SelectEntryGroup,
        Label: SelectEntryLabel,
        Separator: SelectEntrySeparator
    }
);

export default FrontPanelSelectEntry;
