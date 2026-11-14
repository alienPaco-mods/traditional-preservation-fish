-- Traditional Preservation (Fish & Meat): the Smokehouse, its Firebox and the flue are TP Core's (Smokehouse.lua,
-- SmokehouseUI.lua). Firebox Info adds what a Stone Hearth joined to the Smokehouse does to this mod's stacks in the shed.
local HearthUI = require "TraditionalPreservationCore/HearthUI"
local Smokehouse = require "TraditionalPreservationCore/Smokehouse"

HearthUI.addFireboxNotes(function(info, notes)
    if info.joinedSpec and info.joinedSpec.id == Smokehouse.ID then table.insert(notes, getText("IGUI_TraditionalPreservationFishMeat_FlueSmokes")) end
end)
