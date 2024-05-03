/**
 * Copyright (c) 2024 Opal Kelly Incorporated
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import SelectEntryContent from "./SelectEntryContent";
import SelectEntryGroup from "./SelectEntryGroup";
import SelectEntryItem from "./SelectEntryItem";
import SelectEntryLabel from "./SelectEntryLabel";
import SelectEntryRoot from "./SelectEntryRoot";
import SelectEntrySeparator from "./SelectEntrySeparator";
import SelectEntryTrigger from "./SelectEntryTrigger";

const SelectEntry = Object.assign(
    {},
    {
        Root: SelectEntryRoot,
        Trigger: SelectEntryTrigger,
        Content: SelectEntryContent,
        Item: SelectEntryItem,
        Group: SelectEntryGroup,
        Label: SelectEntryLabel,
        Separator: SelectEntrySeparator
    }
);

export default SelectEntry;
