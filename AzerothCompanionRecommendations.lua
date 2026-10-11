local _, namespace = ...
local constants = namespace.Constants
local UI = constants.UI
local MODES = constants.MODES
local FACTIONS = constants.FACTIONS
local AVAILABILITY = constants.QUEST_AVAILABILITY
local ITEM_DROP = constants.ITEM_DROP_AVAILABILITY

local function isUsableRecord(quest)
    return type(quest) == "table"
        and type(quest.id) == "string"
        and type(quest.title) == "string"
        and type(quest.mode) == "string"
        and type(quest.zone) == "string"
        and type(quest.minLevel) == "number"
        and type(quest.maxLevel) == "number"
        and type(quest.faction) == "string"
        and type(quest.availability) == "string"
        and type(quest.requiredQuestIds) == "table"
        and type(quest.storyGroup) == "string"
        and type(quest.hub) == "string"
        and type(quest.reason) == "string"
end

local function hasCompletedPrerequisites(quest, completedQuestIds)
    if #quest.requiredQuestIds > 0 and type(completedQuestIds) ~= "table" then
        return false
    end

    for _, requiredQuestId in ipairs(quest.requiredQuestIds) do
        if not completedQuestIds or completedQuestIds[requiredQuestId] ~= true then
            return false
        end
    end

    return true
end

local function matchesMode(quest, mode, currentZone)
    if quest.mode ~= mode then
        return false
    end

    if mode == MODES.CURRENT then
        return quest.zone == currentZone
    end

    return mode == MODES.MOVE_ON and quest.zone ~= currentZone
end

local function matchesPlayer(quest, playerContext)
    local level = playerContext.level
    if type(level) ~= "number" or level < quest.minLevel or level > quest.maxLevel then
        return false
    end

    if quest.faction ~= FACTIONS.ANY and quest.faction ~= playerContext.faction then
        return false
    end

    if quest.availability ~= AVAILABILITY.AVAILABLE then
        return false
    end

    return hasCompletedPrerequisites(quest, playerContext.completedQuestIds)
end

local function getRecommendations(questFixtures, playerContext, mode)
    local recommendations = {}

    if type(questFixtures) ~= "table"
        or type(questFixtures.records) ~= "table"
        or type(playerContext) ~= "table"
    then
        return recommendations
    end

    for _, quest in ipairs(questFixtures.records) do
        if isUsableRecord(quest)
            and matchesMode(quest, mode, playerContext.zone)
            and matchesPlayer(quest, playerContext)
            and not (type(playerContext.completedQuestIds) == "table" and playerContext.completedQuestIds[quest.id] == true)
        then
            table.insert(recommendations, quest)
        end
    end

    table.sort(recommendations, function(first, second)
        return first.faction == playerContext.faction and second.faction ~= playerContext.faction
    end)

    return recommendations
end

local function formatItemDropAvailability(questItem)
    if questItem.dropAvailability == ITEM_DROP.BEFORE_ACCEPTANCE then
        return UI.itemDropBeforeAcceptanceText
    end

    if questItem.dropAvailability == ITEM_DROP.AFTER_ACCEPTANCE then
        return UI.itemDropAfterAcceptanceText
    end

    return UI.itemDropUnknownText
end

local function formatRecommendations(questFixtures, playerContext, mode)
    local recommendations = getRecommendations(questFixtures, playerContext, mode)
    local lines = { UI.sampleDataText, "" }

    if #recommendations == 0 then
        table.insert(lines, UI.noMatchingFixtureText)
        return table.concat(lines, "\n")
    end

    for index, quest in ipairs(recommendations) do
        if index > UI.maximumVisibleRecommendations then
            break
        end

        table.insert(lines, string.format("%d. %s (%s) - %s", index, quest.title, quest.zone, quest.reason))
        table.insert(lines, string.format("   Story: %s | Hub: %s", quest.storyGroup, quest.hub))

        local questLineStep = quest.questLineStep
        local questLineLength = quest.questLineLength
        if type(questLineStep) == "number"
            and type(questLineLength) == "number"
            and questLineStep >= 1
            and questLineStep <= questLineLength
        then
            table.insert(lines, string.format(UI.questLinePositionFormat, questLineStep, questLineLength))
        end

        if quest.questItem then
            table.insert(lines, string.format(
                "   Quest item %s: %s",
                quest.questItem.name,
                formatItemDropAvailability(quest.questItem)
            ))
        end
    end

    return table.concat(lines, "\n")
end

namespace.Recommendations = {
    getRecommendations = getRecommendations,
    formatRecommendations = formatRecommendations,
    getItemDropAvailabilityText = formatItemDropAvailability,
}