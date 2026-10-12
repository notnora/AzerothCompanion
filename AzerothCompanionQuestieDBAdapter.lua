local _, namespace = ...
local requiredContract = namespace.Constants.UI.questieDbContractRequired

local function getProvider()
    local provider = _G.LibQuestieDB
    if type(provider) ~= "table" then
        return nil, "not_installed"
    end

    if type(provider.RequireContract) ~= "function"
        or type(provider.Quest) ~= "table"
    then
        return nil, "api_unavailable"
    end

    local compatible, message = provider.RequireContract(requiredContract)
    if not compatible then
        return nil, "contract_mismatch", message
    end

    return provider.Quest
end

local function readField(questDatabase, fieldName, questID)
    local getter = questDatabase[fieldName]
    if type(getter) ~= "function" then
        return nil
    end

    local success, value = pcall(getter, questID)
    if success then
        return value
    end
    return nil
end

local function normalizeNumber(value)
    if type(value) == "number" and value ~= 0 then
        return value
    end
    return nil
end

local function normalizeQuestIDs(value)
    if type(value) ~= "table" then
        return {}
    end

    local questIDs = {}
    for _, questID in ipairs(value) do
        if type(questID) == "number" and questID > 0 then
            table.insert(questIDs, questID)
        end
    end
    return questIDs
end

local function normalizeEntityIDs(value)
    if type(value) ~= "table" then
        return {}
    end

    local entityIDs = {}
    for _, entityID in ipairs(value) do
        if type(entityID) == "number" and entityID > 0 then
            table.insert(entityIDs, entityID)
        end
    end
    return entityIDs
end

local function getAreaName(areaID)
    local mapAPI = _G.C_Map
    if type(areaID) ~= "number" or not mapAPI or type(mapAPI.GetAreaInfo) ~= "function" then
        return nil
    end

    local success, areaName = pcall(mapAPI.GetAreaInfo, areaID)
    if success and type(areaName) == "string" and areaName ~= "" then
        return areaName
    end
    return nil
end

local function getTurnInLocations(questID)
    if type(questID) ~= "number" or questID < 1 or questID % 1 ~= 0 then
        return {}
    end

    local questDatabase, reason, detail = getProvider()
    if not questDatabase then
        return nil, reason, detail
    end

    local provider = _G.LibQuestieDB
    local npcDatabase = provider and provider.Npc
    if type(npcDatabase) ~= "table" then
        return nil, "api_unavailable"
    end

    local finishers = readField(questDatabase, "finishedBy", questID)
    local npcIDs = type(finishers) == "table" and normalizeEntityIDs(finishers[1]) or {}
    local locations = {}
    local seenLocations = {}

    for _, npcID in ipairs(npcIDs) do
        local npcName = readField(npcDatabase, "name", npcID)
        local zoneID = readField(npcDatabase, "zoneID", npcID)
        local zoneName = getAreaName(zoneID)
        local spawnAreas = readField(npcDatabase, "spawns", npcID)
        local areaIDs = {}

        if type(spawnAreas) == "table" then
            for areaID in pairs(spawnAreas) do
                if type(areaID) == "number" and areaID > 0 then
                    table.insert(areaIDs, areaID)
                end
            end
            table.sort(areaIDs)
        end

        if #areaIDs == 0 and type(zoneID) == "number" then
            areaIDs[1] = zoneID
        end

        for _, areaID in ipairs(areaIDs) do
            local areaName = getAreaName(areaID)
            local locationParts = {}
            local subzoneName

            if zoneName then
                table.insert(locationParts, zoneName)
            elseif areaName then
                table.insert(locationParts, areaName)
            end

            if areaName and areaID ~= zoneID and areaName ~= zoneName then
                subzoneName = areaName
                table.insert(locationParts, areaName)
            end

            if type(npcName) == "string" and npcName ~= "" then
                table.insert(locationParts, npcName)
            end

            if #locationParts > 0 then
                local location = table.concat(locationParts, " - ")
                if not seenLocations[location] then
                    seenLocations[location] = true
                    table.insert(locations, {
                        text = location,
                        zone = zoneName,
                        subzone = subzoneName,
                    })
                end
            end
        end
    end

    return locations
end

local function getStatus()
    local questDatabase, reason, detail = getProvider()
    if not questDatabase then
        return {
            available = false,
            reason = reason,
            detail = detail,
        }
    end

    return {
        available = true,
        contractVersion = _G.LibQuestieDB.contractVersion,
        minimumContract = _G.LibQuestieDB.minSupportedContract,
    }
end

local function getQuest(questID)
    if type(questID) ~= "number" or questID < 1 or questID % 1 ~= 0 then
        return nil, "invalid_id"
    end

    local questDatabase, reason, detail = getProvider()
    if not questDatabase then
        return nil, reason, detail
    end

    local success, exists = pcall(questDatabase.Exists, questID)
    if not success then
        return nil, "read_failed", exists
    end
    if exists ~= true then
        return nil, "not_found"
    end

    local questName = readField(questDatabase, "name", questID)
    if type(questName) ~= "string" then
        return nil, "read_failed", "QuestDB.name returned no name"
    end

    return {
        id = questID,
        title = questName,
        minLevel = normalizeNumber(readField(questDatabase, "requiredLevel", questID)),
        questLevel = normalizeNumber(readField(questDatabase, "questLevel", questID)),
        requiredRaces = normalizeNumber(readField(questDatabase, "requiredRaces", questID)),
        requiredClasses = normalizeNumber(readField(questDatabase, "requiredClasses", questID)),
        preQuestSingle = normalizeQuestIDs(readField(questDatabase, "preQuestSingle", questID)),
        preQuestGroup = normalizeQuestIDs(readField(questDatabase, "preQuestGroup", questID)),
        nextQuestInChain = normalizeNumber(readField(questDatabase, "nextQuestInChain", questID)),
        zoneOrSort = normalizeNumber(readField(questDatabase, "zoneOrSort", questID)),
        sourceItemId = normalizeNumber(readField(questDatabase, "sourceItemId", questID)),
        objectives = readField(questDatabase, "objectives", questID),
        dataSource = "QuestieDB",
    }
end

namespace.QuestieDBAdapter = {
    getStatus = getStatus,
    getQuest = getQuest,
    getTurnInLocations = getTurnInLocations,
}