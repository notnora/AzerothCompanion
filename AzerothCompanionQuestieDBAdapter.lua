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
}