-- Traditional Preservation (Fish & Meat): a station's info, in its own crafting window under In Progress, Done and
-- Take All (TP Core's StationInfo), for the Salting Tub, the Drying Frame, the Hanging Beam, the Gantry and the
-- Smokehouse. One look at the whole station: where it stands, what it holds, the weather, and a bar for every
-- running batch with what is stopping or spoiling it. It reads the same status the stack popups do (F.stackStatus,
-- F.charqueStatus, F.pressStatus), so the two agree, and nothing is simulated here.
local UI = require "TraditionalPreservationCore/UI"
local StationInfo = require "TraditionalPreservationCore/StationInfo"
local Hearth = require "TraditionalPreservationCore/Hearth"
local Weather = require "TraditionalPreservationCore/Weather"
local F = TraditionalPreservationFishMeat

TraditionalPreservationFishMeatInfo = TraditionalPreservationFishMeatInfo or {}
local Info = TraditionalPreservationFishMeatInfo

local KEY = "IGUI_TraditionalPreservationFishMeat_"
-- Places with a word of their own (TP Core's); anything else under a roof reads as indoors.
local PLACES = { Open = true, Covered = true, Sheltered = true, Loft = true, Basement = true, Enclosed = true }
-- A running batch's kind, by its recipe's short name.
local KINDS = { HangFishToDry = "salt", HangFishToColdDry = "cold", HangMeatToDry = "meat",
    PressSaltedFish = "fishCure", PressSaltedMeat = "corn", [F.LONG_CURE_RECIPE] = "long" }
local KIND_NAMES = { salt = KEY .. "InfoSalt", cold = KEY .. "InfoCold", meat = KEY .. "InfoCharque",
    fishCure = KEY .. "InfoCure", corn = KEY .. "InfoCorn", long = KEY .. "InfoLongCure" }
local GOOD_COLOUR, SLOW_COLOUR = { 0.35, 0.6, 0.3 }, { 0.75, 0.55, 0.2 }

local function weightOf(items)
    local weight = 0
    for _, item in ipairs(items) do weight = weight + item:getActualWeight() end
    return weight
end

-- One running batch: its name (a key), progress, the text on its bar, whether something holds it back, and the
-- lines to say about it below. kind is KINDS'.
function Info.batch(kind, modData, ledger, now)
    local isPress = kind == "fishCure" or kind == "corn" or kind == "long"
    local isCold, isMeat = kind == "cold", kind == "meat"
    local status = isPress and F.pressStatus(modData, now, ledger)
        or isMeat and F.charqueStatus(modData, ledger) or F.stackStatus(isCold, modData, ledger)
    local row = { name = status.hotOnly and KEY .. "InfoHotOnly" or status.dryCuring and KEY .. "InfoDryCure" or KIND_NAMES[kind],
        progress = status.progress, notes = {} }
    local share = UI.percent(status.progress)
    if status.reason then
        row.value, row.slow = UI.say(KEY .. "InfoShare", share, getText(KEY .. "Stopped" .. status.reason)), true
    elseif status.hoursLeft then
        local hours = math.ceil(status.hoursLeft)
        row.value = UI.say(KEY .. "InfoLeft", share, tostring(math.floor(hours / 24)), tostring(hours % 24))
        row.weather = not isPress
    else
        row.value, row.slow = UI.say(KEY .. "InfoShare", share, getText(KEY .. "Paused")), true
    end

    local warning
    if isPress then
        warning = status.spoiling and KEY .. "SpoilingWarmCure" or status.spoiled > 0 and KEY .. "Spoiled" or nil
    else
        warning = F.spoilWarning(status, isCold)
    end
    if warning then
        table.insert(row.notes, UI.say(warning, UI.percent(status.spoiled)))
        row.slow = true
    end
    if status.underSalted then
        table.insert(row.notes, UI.say(KEY .. (status.hotOnly and "UnderSaltedHotOnly" or "UnderSaltedShed"), string.format("%.0f", status.shedTemperature)))
        row.slow = true
    end
    if isPress then return row end
    -- In a Smokehouse joined to a Firebox: a stoked run that is cooking the stack, and its smoke so far.
    if F.cookShare(modData) then
        table.insert(row.notes, UI.say(KEY .. "InfoCooking", string.format("%.1f", modData.hot), string.format("%.0f", modData.hotNeed)))
    end
    if not modData.hotOnly and (modData.smokeFrom or (modData.cold or 0) > 0) then
        table.insert(row.notes, UI.say(KEY .. "ColdSmokeNeed", string.format("%.1f", modData.cold or 0), string.format("%.0f", F.coldNeed(modData))))
    end
    return row
end

-- Everything the block shows, from the World's look at the station (its inspect): rows of label key and value,
-- a bar for each batch and the notes under them. fire is "none", "out", "banked" or "stoked" for a Smokehouse.
function Info.rows(found, ledger, now, fire)
    local hanger = found.hanger
    local rows, bars, notes = {}, {}, {}
    table.insert(rows, { KEY .. "Place", UI.placeName(PLACES[found.place] and found.place or "Sheltered") })
    if hanger then
        table.insert(rows, { KEY .. "InfoHolds", UI.say(KEY .. "InfoStacks", tostring(found.finishedStacks + #found.batches),
            tostring(hanger.stacks), tostring(hanger.stackWeight)) })
    elseif #found.batches > 0 or found.finished > 0 then
        table.insert(rows, { KEY .. "InfoHolds", getText(KEY .. "InfoTubBusy") })
    else
        table.insert(rows, { KEY .. "InfoHolds", UI.say(KEY .. "InfoTub", string.format("%.1f", weightOf(found.waiting)),
            tostring(F.TUB_CAPACITY), tostring(#found.waiting), tostring(F.TUB_MAX_ITEMS)) })
    end
    local temperature = ledger.temperature or 0
    -- Below ground, in a loft and in a room the stacks and the tub go by the place's own temperature, not the day's
    -- (the Smokehouse, Enclosed, goes by the day's as the open air does).
    if found.place == "Basement" or found.place == "Loft" or found.place == "Sheltered" then
        table.insert(rows, { KEY .. "InfoAir", UI.placeText(found.place, F.ownTemperature(ledger, found.place)) })
    else
        table.insert(rows, { KEY .. "InfoAir", UI.say(KEY .. "InfoAirValue", UI.degrees(temperature),
            UI.degrees(ledger.seasonTemperature or temperature)) })
    end
    -- Wind and rain reach a hanger in the open or under an open roof; the tub goes by the season alone.
    if hanger and (found.place == "Open" or found.place == "Covered") then
        table.insert(rows, { KEY .. "Wind", getText(F.windWord(ledger.wind)) })
    end
    if hanger and found.place == "Open" then
        table.insert(rows, { KEY .. "InfoWetness", UI.percent(ledger.wetness or 0) })
    end
    if fire then
        table.insert(rows, { KEY .. "InfoFire", getText(KEY .. "InfoFire" .. string.upper(string.sub(fire, 1, 1)) .. string.sub(fire, 2)) })
    end

    local weather = false
    for index, batch in ipairs(found.batches) do
        local recipe = batch.data:getRecipe()
        local kind = recipe and KINDS[UI.shortName(recipe)]
        if kind then
            local row = Info.batch(kind, batch.data:getModData(), ledger, now)
            -- A tub cures one batch at a time, so its bar and notes need no number.
            local name = getText(row.name)
            table.insert(bars, { text = hanger and UI.say(KEY .. "InfoBatch", tostring(#bars + 1), name) or name,
                share = row.progress, value = row.value, colour = row.slow and SLOW_COLOUR or GOOD_COLOUR })
            for _, note in ipairs(row.notes) do
                table.insert(notes, hanger and UI.say(KEY .. "InfoNote", tostring(#bars), note) or note)
            end
            weather = weather or row.weather == true
        end
    end
    if #found.waiting > 0 and (hanger or #found.batches == 0) then
        table.insert(notes, UI.say(KEY .. "InfoWaiting", tostring(#found.waiting)))
    end
    if found.finished > 0 then
        table.insert(notes, hanger and UI.say(KEY .. "InfoFinished", tostring(found.finished), tostring(found.finishedStacks))
            or UI.say(KEY .. "InfoFinishedTub", tostring(found.finished)))
    end
    if weather then table.insert(notes, getText(KEY .. "InfoWeather")) end
    if #bars == 0 and #notes == 0 then table.insert(notes, getText(KEY .. "InfoEmpty")) end
    return { rows = rows, bars = bars, notes = notes }
end

-- The joined Firebox's fire, for a Smokehouse; nil for any other station.
local function fireOf(found)
    if not (found.hanger and found.hanger.closed) then return nil end
    local firebox = F.joinedFirebox(found.station)
    if not firebox then return "none" end
    if Hearth.isBanked(firebox) then return "banked" end
    return Hearth.isBurning(firebox) and "stoked" or "out"
end

-- The block in the station's own window (Core's StationInfo), for the mod's stations only: looked up by sprite
-- first, so any other crafting window costs one table lookup.
function Info.forEntity(entity)
    if not instanceof(entity, "IsoObject") or not F.stationIndex(entity) then return nil end
    local found = TraditionalPreservationFishMeatWorld and TraditionalPreservationFishMeatWorld.inspect(entity)
    return found and Info.rows(found, F.getLedger(), getGameTime():getWorldAgeHours(), fireOf(found)) or nil
end

StationInfo.add(Info.forEntity)
