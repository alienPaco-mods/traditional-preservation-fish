-- Traditional Preservation (Fish & Meat): the Smokehouse, its Firebox and the flue are TP Core's (Smokehouse.lua,
-- SmokehouseUI.lua). Firebox Info adds what a joined Firebox's fire does to this mod's stacks in the shed.
local HearthUI = require "TraditionalPreservationCore/HearthUI"

HearthUI.addFireboxNotes(function(info, notes)
    if info.copper and info.copper.flue then table.insert(notes, getText("IGUI_TraditionalPreservationFishMeat_FlueSmokes")) end
end)
