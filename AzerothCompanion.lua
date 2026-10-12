local addonName, namespace = ...
local constants = namespace.Constants
local UI = constants.UI
local questFixtures = namespace.QuestFixtures
local Recommendations = namespace.Recommendations
local QuestieDBAdapter = namespace.QuestieDBAdapter
local FRAME_TYPES = constants.FRAME_TYPES
local FRAME_TEMPLATES = constants.FRAME_TEMPLATES
local UI_TEXTURES = constants.UI_TEXTURES
local FRAME_POINTS = constants.FRAME_POINTS
local DRAW_LAYERS = constants.DRAW_LAYERS
local FONT_OBJECTS = constants.FONT_OBJECTS
local TEXT_JUSTIFICATION = constants.TEXT_JUSTIFICATION
local FRAME_SCRIPTS = constants.FRAME_SCRIPTS
local MOUSE_BUTTONS = constants.MOUSE_BUTTONS
local PLAYER_UNIT = constants.PLAYER_UNIT
local MODES = constants.MODES
local QUEST_PROXIMITY = constants.QUEST_PROXIMITY
local EVENTS = constants.EVENTS

local addon = CreateFrame(FRAME_TYPES.FRAME, addonName .. "Frame", UIParent)
local coordinateDisplay
addon:RegisterEvent(EVENTS.PLAYER_LOGIN)
addon:RegisterEvent(EVENTS.PLAYER_ENTERING_WORLD)
addon:RegisterEvent(EVENTS.ZONE_CHANGED_NEW_AREA)
addon:RegisterEvent(EVENTS.QUEST_LOG_UPDATE)
addon:RegisterEvent(EVENTS.PLAYER_STARTED_MOVING)
addon:RegisterEvent(EVENTS.PLAYER_STOPPED_MOVING)

local function getDefaultDatabase()
    return {
        window = {
            x = UI.defaultWindowX,
            y = UI.defaultWindowY,
            width = UI.frameWidth,
            height = UI.frameHeight,
        },
        dismissedZones = {},
        sampleData = true,
    }
end

local function ensureDatabase()
    local defaultDatabase = getDefaultDatabase()

    if AzerothCompanionDB == nil then
        AzerothCompanionDB = defaultDatabase
    else
        for key, value in pairs(defaultDatabase) do
            if AzerothCompanionDB[key] == nil then
                AzerothCompanionDB[key] = value
            end
        end

        for key, value in pairs(defaultDatabase.window) do
            if AzerothCompanionDB.window[key] == nil then
                AzerothCompanionDB.window[key] = value
            end
        end
    end
end

local function getPlayerContext()
    local playerName = UnitName(PLAYER_UNIT) or "Unknown player"
    local playerClass = UnitClass(PLAYER_UNIT) or "Unknown class"
    local playerLevel = UnitLevel(PLAYER_UNIT) or 1
    local playerFaction = UnitFactionGroup(PLAYER_UNIT) or "Unknown faction"
    local zone = GetRealZoneText() or "Unknown zone"

    return {
        playerName = playerName,
        playerClass = playerClass,
        playerLevel = playerLevel,
        playerFaction = playerFaction,
        zone = zone,
    }
end

local function refreshCoordinates()
    if not coordinateDisplay or not coordinateDisplay.text then
        return
    end

    local mapAPI = _G.C_Map
    if not mapAPI or not mapAPI.GetBestMapForUnit or not mapAPI.GetPlayerMapPosition then
        coordinateDisplay.text:SetText(UI.coordinatesUnavailableText)
        return
    end

    local mapID = mapAPI.GetBestMapForUnit(PLAYER_UNIT)
    local position = mapID and mapAPI.GetPlayerMapPosition(mapID, PLAYER_UNIT)

    if not position or not position.GetXY then
        coordinateDisplay.text:SetText(UI.coordinatesUnavailableText)
        return
    end

    local x, y = position:GetXY()
    if type(x) ~= "number" or type(y) ~= "number" then
        coordinateDisplay.text:SetText(UI.coordinatesUnavailableText)
        return
    end

    coordinateDisplay.text:SetText(string.format(UI.coordinatesFormat, x * 100, y * 100))
end

local function ensureCoordinateDisplay()
    local minimap = _G.Minimap
    if not minimap then
        return
    end

    local legacyCoordinateDisplay = _G[UI.legacyCoordinatesFrameName]
    if legacyCoordinateDisplay then
        legacyCoordinateDisplay:Hide()
    end

    coordinateDisplay = _G[UI.coordinatesFrameName]
    if not coordinateDisplay then
        coordinateDisplay = CreateFrame(
            FRAME_TYPES.FRAME,
            UI.coordinatesFrameName,
            UIParent,
            FRAME_TEMPLATES.BACKDROP
        )
    end

    coordinateDisplay:SetSize(UI.coordinatesFrameWidth, UI.coordinatesFrameHeight)
    coordinateDisplay:SetBackdrop({
        bgFile = UI_TEXTURES.PANEL_BACKGROUND,
        edgeFile = UI_TEXTURES.PANEL_BORDER,
        tile = true,
        tileSize = UI.backdropTileSize,
        edgeSize = UI.backdropEdgeSize,
        insets = {
            left = UI.backdropInset,
            right = UI.backdropInset,
            top = UI.backdropInset,
            bottom = UI.backdropInset,
        },
    })
    coordinateDisplay:SetBackdropColor(
        UI.coordinatesBackgroundColor.r,
        UI.coordinatesBackgroundColor.g,
        UI.coordinatesBackgroundColor.b,
        UI.coordinatesBackgroundColor.a
    )
    coordinateDisplay:SetBackdropBorderColor(
        UI.coordinatesBorderColor.r,
        UI.coordinatesBorderColor.g,
        UI.coordinatesBorderColor.b,
        UI.coordinatesBorderColor.a
    )
    coordinateDisplay:ClearAllPoints()

    local zoneTextFrame = _G[UI.minimapZoneTextFrameName]
    if zoneTextFrame then
        coordinateDisplay:SetPoint(FRAME_POINTS.BOTTOM, zoneTextFrame, FRAME_POINTS.TOP, 0, UI.coordinatesOffsetY)
    else
        coordinateDisplay:SetPoint(FRAME_POINTS.BOTTOM, minimap, FRAME_POINTS.TOP, 0, UI.coordinatesOffsetY)
    end

    if not coordinateDisplay.text then
        coordinateDisplay.text = coordinateDisplay:CreateFontString(nil, DRAW_LAYERS.OVERLAY, FONT_OBJECTS.SMALL_HIGHLIGHT)
        coordinateDisplay.text:SetJustifyH(TEXT_JUSTIFICATION.CENTER)
    end
    coordinateDisplay.text:ClearAllPoints()
    coordinateDisplay.text:SetPoint(
        FRAME_POINTS.TOPLEFT,
        coordinateDisplay,
        FRAME_POINTS.TOPLEFT,
        UI.coordinatesTextPaddingX,
        -UI.coordinatesTextPaddingY
    )
    coordinateDisplay.text:SetPoint(
        FRAME_POINTS.BOTTOMRIGHT,
        coordinateDisplay,
        FRAME_POINTS.BOTTOMRIGHT,
        -UI.coordinatesTextPaddingX,
        UI.coordinatesTextPaddingY
    )
    coordinateDisplay.text:SetTextColor(
        UI.coordinatesTextColor.r,
        UI.coordinatesTextColor.g,
        UI.coordinatesTextColor.b,
        UI.coordinatesTextColor.a
    )

    coordinateDisplay:EnableMouse(false)
    coordinateDisplay:Show()
    refreshCoordinates()
end

local function onCoordinateUpdate(self, elapsed)
    self.coordinateElapsed = (self.coordinateElapsed or 0) + elapsed
    if self.coordinateElapsed >= UI.coordinatesUpdateInterval then
        self.coordinateElapsed = 0
        refreshCoordinates()
    end
end

local function startCoordinateUpdates()
    ensureCoordinateDisplay()
    if coordinateDisplay then
        coordinateDisplay.coordinateElapsed = 0
        coordinateDisplay:SetScript(FRAME_SCRIPTS.ON_UPDATE, onCoordinateUpdate)
    end
end

local function stopCoordinateUpdates()
    if coordinateDisplay then
        coordinateDisplay:SetScript(FRAME_SCRIPTS.ON_UPDATE, nil)
        coordinateDisplay.coordinateElapsed = 0
        refreshCoordinates()
    end
end

local function getRecommendationsForMode(mode)
    local playerContext = getPlayerContext()
    local recommendationContext = {
        level = playerContext.playerLevel,
        faction = playerContext.playerFaction,
        zone = playerContext.zone,
        completedQuestIds = {},
    }

    return Recommendations.getRecommendations(questFixtures, recommendationContext, mode)
end

local function getActiveQuestLog()
    local getNumQuestLogEntries = _G.GetNumQuestLogEntries
    local getQuestLogTitle = _G.GetQuestLogTitle
    if type(getNumQuestLogEntries) ~= "function" or type(getQuestLogTitle) ~= "function" then
        return nil
    end

    local entryCount = getNumQuestLogEntries()
    if type(entryCount) ~= "number" then
        return nil
    end

    local quests = {}
    for index = 1, entryCount do
        local title, _, _, isHeader, _, isComplete, _, questID = getQuestLogTitle(index)
        if title and not isHeader then
            local statusPrefix = ""
            if isComplete == -1 then
                statusPrefix = UI.statusQuestFailedPrefix
            end

            table.insert(quests, {
                title = title,
                questID = questID,
                statusPrefix = statusPrefix,
                isReady = isComplete == 1,
                questLogIndex = index,
            })
        end
    end

    return quests
end

local function getIncompleteObjectiveProgress(questID)
    local questLogAPI = _G.C_QuestLog
    if type(questID) ~= "number"
        or not questLogAPI
        or type(questLogAPI.GetQuestObjectives) ~= "function"
    then
        return {}
    end

    local success, objectives = pcall(questLogAPI.GetQuestObjectives, questID)
    if not success or type(objectives) ~= "table" then
        return {}
    end

    local progress = {}
    for _, objective in ipairs(objectives) do
        if type(objective) == "table" and objective.finished ~= true then
            local objectiveText = type(objective.text) == "string" and objective.text or ""
            objectiveText = objectiveText:gsub("%s*:%s*%d+/%d+%s*$", "")

            if type(objective.numFulfilled) == "number"
                and type(objective.numRequired) == "number"
                and objective.numRequired > 0
            then
                local progressText = string.format(
                    "%d/%d%s",
                    objective.numFulfilled,
                    objective.numRequired,
                    objectiveText ~= "" and " " .. objectiveText or ""
                )
                table.insert(progress, progressText)
            elseif objectiveText ~= "" then
                table.insert(progress, objectiveText)
            end
        end
    end

    return progress
end

local function getQuestProximity(quest, playerZone, playerSubzone)
    local locations = quest.turnInLocations or {}
    local nearestRank = QUEST_PROXIMITY.UNKNOWN

    for _, location in ipairs(locations) do
        local rank = QUEST_PROXIMITY.OTHER_ZONE
        if location.zone == playerZone
            and location.subzone
            and playerSubzone ~= ""
            and location.subzone == playerSubzone
        then
            rank = QUEST_PROXIMITY.CURRENT_SUBZONE
        elseif location.zone and location.zone == playerZone then
            rank = QUEST_PROXIMITY.CURRENT_ZONE
        elseif not location.zone then
            rank = QUEST_PROXIMITY.UNKNOWN
        end

        nearestRank = math.min(nearestRank, rank)
    end

    return nearestRank
end

local function sortActiveQuests(quests, playerZone, playerSubzone)
    for _, quest in ipairs(quests) do
        quest.turnInLocations = quest.questID and QuestieDBAdapter.getTurnInLocations(quest.questID) or {}
        quest.proximityRank = getQuestProximity(quest, playerZone, playerSubzone)
    end

    table.sort(quests, function(left, right)
        if left.proximityRank ~= right.proximityRank then
            return left.proximityRank < right.proximityRank
        end
        if left.isReady ~= right.isReady then
            return left.isReady
        end
        return left.questLogIndex < right.questLogIndex
    end)
end

local function keepFieldTogether(value)
    local formattedValue = tostring(value):gsub(" ", UI.nonBreakingSpace)
    return formattedValue
end

local createQuestFontString

local function summarizePlayerStatus(frame)
    local context = getPlayerContext()
    local currentRecommendations = getRecommendationsForMode(MODES.CURRENT)
    local moveOnRecommendations = getRecommendationsForMode(MODES.MOVE_ON)

    local metaParts = {
        string.format("Lvl %s", context.playerLevel),
        context.playerFaction,
        context.zone,
    }

    local lines = {
        "Her er du nå:",
        table.concat(metaParts, " • "),
    }

    if #currentRecommendations > 0 then
        local topQuest = currentRecommendations[1]
        local tag = "Story"
        if topQuest.questItem then
            tag = string.format("Drop • %s", Recommendations.getItemDropAvailabilityText(topQuest.questItem))
        end
        table.insert(lines, string.format("Nå: %s | %s", topQuest.title, tag))
    else
        table.insert(lines, "Ingen passende forslag i denne sonen akkurat nå.")
    end

    if #moveOnRecommendations > 0 then
        local nextQuest = moveOnRecommendations[1]
        table.insert(lines, string.format("Neste: %s | %s | %s", nextQuest.title, nextQuest.hub, nextQuest.zone))
    else
        table.insert(lines, "Ingen tydelig neste hub i denne retningen.")
    end

    return table.concat(lines, "\n")
end

local function renderStatusCard(frame)
    local context = getPlayerContext()
    local currentRecommendations = getRecommendationsForMode(MODES.CURRENT)
    local moveOnRecommendations = getRecommendationsForMode(MODES.MOVE_ON)
    local activeQuests = getActiveQuestLog()
    if activeQuests then
        local playerSubzone = type(_G.GetSubZoneText) == "function" and _G.GetSubZoneText() or ""
        sortActiveQuests(activeQuests, context.zone, playerSubzone)
    end

    if not activeQuests or #activeQuests <= UI.maximumStatusQuestLines then
        frame.statusQuestsExpanded = false
    end

    if not frame.statusCard or not frame.statusTitleText or not frame.statusMetaText or not frame.statusActiveText or not frame.statusNextText then
        return
    end

    local statusTitle = "Her er du nå"
    local metaText = string.format("Lvl %s • %s • %s", context.playerLevel, context.playerFaction, context.zone)

    local activeHeading
    local questLines = {}
    local toggleText
    if not activeQuests then
        activeHeading = UI.statusQuestLogUnavailable
    elseif #activeQuests == 0 then
        activeHeading = UI.statusQuestLogEmpty
    else
        activeHeading = string.format(UI.statusQuestLogHeadingFormat, #activeQuests)
        local visibleCount = frame.statusQuestsExpanded and #activeQuests
            or math.min(#activeQuests, UI.maximumStatusQuestLines)
        for index = 1, visibleCount do
            local quest = activeQuests[index]
            local questLine = string.format("- %s%s", quest.statusPrefix, quest.title)

            if quest.isReady then
                local turnInTexts = {}
                for _, location in ipairs(quest.turnInLocations or {}) do
                    if type(location.text) == "string" then
                        turnInTexts[#turnInTexts + 1] = location.text
                    end
                end
                local turnInText = UI.statusQuestTurnInUnknown
                if #turnInTexts > 0 then
                    turnInText = table.concat(turnInTexts, UI.statusQuestTurnInSeparator)
                end
                questLine = UI.statusQuestReadyColorEscape
                    .. questLine
                    .. UI.statusQuestSecondaryColorEscape
                    .. string.format(UI.statusQuestTurnInFormat, turnInText)
                    .. UI.statusQuestColorReset
            else
                questLine = UI.statusQuestIncompleteColorEscape .. questLine
                local objectiveProgress = getIncompleteObjectiveProgress(quest.questID)
                if #objectiveProgress > 0 then
                    questLine = questLine
                        .. " "
                        .. UI.statusQuestSecondaryColorEscape
                        .. "("
                        .. table.concat(objectiveProgress, "; ")
                        .. ")"
                end
                    questLine = questLine .. UI.statusQuestColorReset
            end
                    questLines[#questLines + 1] = questLine
        end

        local hiddenCount = #activeQuests - visibleCount
        if hiddenCount > 0 then
            toggleText = string.format(UI.statusQuestOverflowFormat, hiddenCount)
        elseif frame.statusQuestsExpanded and #activeQuests > UI.maximumStatusQuestLines then
            toggleText = UI.statusQuestCollapseText
        end
    end
    local nextLines = {}
    if #currentRecommendations > 0 then
        nextLines[#nextLines + 1] = UI.statusExampleRecommendationPrefix .. currentRecommendations[1].title
    end
    if #moveOnRecommendations > 0 then
        local nextQuest = moveOnRecommendations[1]
        nextLines[#nextLines + 1] = string.format("%s%s • %s", UI.statusExampleNextHubPrefix, nextQuest.hub, nextQuest.zone)
    end
    if #nextLines == 0 then
        nextLines[1] = "Ingen eksempelanbefalinger tilgjengelig her."
    end
    local nextText = table.concat(nextLines, "\n")

    frame.statusTitleText:SetText(statusTitle)
    frame.statusMetaText:SetText(metaText)
    frame.statusActiveText:SetText(activeHeading)
    frame.statusNextText:SetText(nextText)

    local cardWidth = math.max(1, frame.playerText:GetWidth())
    local horizontalPadding = UI.statusCardWidthPadding / 2
    local verticalPadding = UI.statusCardHeightPadding / 2
    local textWidth = math.max(1, cardWidth - UI.statusCardWidthPadding)
    local yOffset = -verticalPadding

    local function layoutText(fontString, text, color)
        fontString:ClearAllPoints()
        fontString:SetWidth(textWidth)
        fontString:SetHeight(UI.questCardTextMeasurementHeight)
        fontString:SetWordWrap(true)
        fontString:SetTextColor(color.r, color.g, color.b, color.a)
        fontString:SetText(text)

        local lineHeight = fontString:GetLineHeight()
        local textHeight = math.max(lineHeight, fontString:GetNumLines() * lineHeight)
        fontString:SetHeight(textHeight)
        fontString:SetPoint(FRAME_POINTS.TOPLEFT, frame.statusCard, FRAME_POINTS.TOPLEFT, horizontalPadding, yOffset)
        yOffset = yOffset - textHeight - UI.statusCardSectionGap
    end

    frame.statusCard:SetWidth(cardWidth)
    layoutText(frame.statusTitleText, statusTitle, UI.statusCardTitleColor)
    layoutText(frame.statusMetaText, metaText, UI.statusCardMetaColor)
    layoutText(frame.statusActiveText, activeHeading, UI.statusCardActiveColor)

    frame.statusQuestTexts = frame.statusQuestTexts or {}
    for index, questLine in ipairs(questLines) do
        local questText = frame.statusQuestTexts[index]
        if not questText then
            questText = createQuestFontString(frame.statusCard, frame.playerText, 0.95)
            questText:SetJustifyH(TEXT_JUSTIFICATION.LEFT)
            frame.statusQuestTexts[index] = questText
        end
        layoutText(questText, questLine, UI.statusCardActiveColor)
        questText:Show()
    end
    for index = #questLines + 1, #frame.statusQuestTexts do
        frame.statusQuestTexts[index]:Hide()
    end

    if toggleText and frame.statusQuestToggleButton then
        local toggleButton = frame.statusQuestToggleButton
        local toggleTextString = toggleButton.text
        toggleTextString:SetText(toggleText)
        toggleTextString:SetTextColor(
            UI.statusCardActiveColor.r,
            UI.statusCardActiveColor.g,
            UI.statusCardActiveColor.b,
            UI.statusCardActiveColor.a
        )
        toggleTextString:SetWidth(textWidth)
        toggleTextString:SetHeight(UI.questCardTextMeasurementHeight)
        toggleTextString:SetWordWrap(true)
        local toggleLineHeight = toggleTextString:GetLineHeight()
        local toggleTextHeight = math.max(
            toggleLineHeight,
            toggleTextString:GetNumLines() * toggleLineHeight
        )
        toggleTextString:SetHeight(toggleTextHeight)
        toggleTextString:ClearAllPoints()
        toggleButton:ClearAllPoints()
        toggleTextString:SetPoint(FRAME_POINTS.TOPLEFT, toggleButton, FRAME_POINTS.TOPLEFT, 0, -2)
        toggleButton:SetSize(textWidth, toggleTextHeight + UI.statusQuestToggleButtonPadding)
        toggleButton:SetPoint(FRAME_POINTS.TOPLEFT, frame.statusCard, FRAME_POINTS.TOPLEFT, horizontalPadding, yOffset)
        toggleButton:Show()
        yOffset = yOffset - toggleTextHeight - UI.statusQuestToggleButtonPadding - UI.statusCardSectionGap
    elseif frame.statusQuestToggleButton then
        frame.statusQuestToggleButton:Hide()
    end

    layoutText(frame.statusNextText, nextText, UI.statusCardNextColor)
    local cardHeight = math.max(UI.statusCardMinimumHeight, -yOffset + verticalPadding)
    frame.statusCard:SetHeight(cardHeight)

    if frame.statusQuestsExpanded then
        if not frame.statusExpansionOriginalHeight then
            frame.statusExpansionOriginalHeight = frame:GetHeight()
        end
        local collapsedCardHeight = frame.statusCollapsedCardHeight or cardHeight
        local expandedWindowHeight = math.min(
            UI.maximumFrameHeight,
            frame.statusExpansionOriginalHeight + math.max(0, cardHeight - collapsedCardHeight)
        )
        if expandedWindowHeight > frame:GetHeight() then
            frame:SetHeight(expandedWindowHeight)
        end
    else
        frame.statusCollapsedCardHeight = cardHeight
        local originalHeight = frame.statusExpansionOriginalHeight
        frame.statusExpansionOriginalHeight = nil
        if originalHeight and originalHeight ~= frame:GetHeight() then
            frame:SetHeight(originalHeight)
        end
    end
    frame.statusCard:Show()
end

local function refreshPlayerInfo(frame)
    local context = getPlayerContext()

    if frame.titleText then
        frame.titleText:SetText(UI.titleText)
    end

    if frame.playerText then
        frame.playerText:SetText(
            string.format(
                UI.playerLabelFormat,
                keepFieldTogether(context.playerName),
                keepFieldTogether(context.playerClass),
                keepFieldTogether("Lvl " .. context.playerLevel),
                keepFieldTogether(context.playerFaction),
                keepFieldTogether(context.zone)
            )
        )
    end

    if frame.statusCard then
        renderStatusCard(frame)
    elseif frame.statusText then
        frame.statusText:SetText(summarizePlayerStatus(frame))
    end
end

local updateRecommendationContent

local function updateContentWidths(frame)
    local contentWidth = frame:GetWidth() - UI.contentHorizontalPadding

    if frame.playerText then
        frame.playerText:SetWidth(contentWidth)
    end

    if frame.statusCard then
        frame.statusCard:SetWidth(math.max(1, contentWidth))
        frame.statusCard:ClearAllPoints()
        frame.statusCard:SetPoint(FRAME_POINTS.TOPLEFT, frame.playerText, FRAME_POINTS.BOTTOMLEFT, 0, -12)
        renderStatusCard(frame)
    end

    if frame.statusText then
        frame.statusText:SetWidth(contentWidth)
    end

    if frame.recommendationScrollFrame then
        updateRecommendationContent(frame)
    end
end

local function setQuestCardText(fontString, text, width, color)
    if not text then
        fontString:Hide()
        return 0
    end

    fontString:ClearAllPoints()
    fontString:SetWidth(math.max(1, width))
    fontString:SetHeight(UI.questCardTextMeasurementHeight)
    fontString:SetWordWrap(true)
    fontString:SetText(text)
    fontString:SetTextColor(color.r, color.g, color.b, color.a)

    local lineHeight = fontString:GetLineHeight()
    local textHeight = math.max(lineHeight, fontString:GetNumLines() * lineHeight)
    fontString:SetHeight(textHeight)
    fontString:Show()
    return textHeight
end

createQuestFontString = function(parent, fontReference, fontScale)
    local fontString = parent:CreateFontString(nil, DRAW_LAYERS.OVERLAY)
    local fontPath, fontHeight, fontFlags = fontReference:GetFont()
    fontString:SetFont(
        fontPath or UI.fallbackFontPath,
        (fontHeight or UI.fallbackFontHeight) * fontScale,
        fontFlags or UI.fallbackFontFlags
    )
    return fontString
end

local function createQuestCard(parent, fontReference)
    local card = CreateFrame(FRAME_TYPES.FRAME, nil, parent, FRAME_TEMPLATES.BACKDROP)
    card:SetBackdrop({
        bgFile = UI_TEXTURES.PANEL_BACKGROUND,
        edgeFile = UI_TEXTURES.PANEL_BORDER,
        tile = true,
        tileSize = UI.questCardTileSize,
        edgeSize = UI.questCardEdgeSize,
        insets = {
            left = UI.questCardBackdropInset,
            right = UI.questCardBackdropInset,
            top = UI.questCardBackdropInset,
            bottom = UI.questCardBackdropInset,
        },
    })
    card:SetBackdropColor(
        UI.questCardBackgroundColor.r,
        UI.questCardBackgroundColor.g,
        UI.questCardBackgroundColor.b,
        UI.questCardBackgroundColor.a
    )
    card:SetBackdropBorderColor(
        UI.questCardBorderColor.r,
        UI.questCardBorderColor.g,
        UI.questCardBorderColor.b,
        UI.questCardBorderColor.a
    )

    card.titleText = createQuestFontString(card, fontReference, UI.questCardTitleFontScale)
    card.divider = card:CreateTexture(nil, DRAW_LAYERS.OVERLAY)
    card.divider:SetTexture(UI_TEXTURES.QUEST_DIVIDER)
    card.zoneText = createQuestFontString(card, fontReference, UI.questCardMetadataFontScale)
    card.storyText = createQuestFontString(card, fontReference, UI.questCardMetadataFontScale)
    card.hubText = createQuestFontString(card, fontReference, UI.questCardMetadataFontScale)
    card.questLineText = createQuestFontString(card, fontReference, UI.questCardMetadataFontScale)
    card.reasonText = createQuestFontString(card, fontReference, UI.questCardBodyFontScale)
    card.itemText = createQuestFontString(card, fontReference, UI.questCardMetadataFontScale)

    return card
end

local function layoutQuestCard(card, quest, cardWidth)
    local textWidth = cardWidth - UI.questCardPadding * 2
    local yOffset = -UI.questCardPadding

    local function addText(fontString, text, color)
        local textHeight = setQuestCardText(fontString, text, textWidth, color)
        if textHeight > 0 then
            fontString:SetPoint(FRAME_POINTS.TOPLEFT, card, FRAME_POINTS.TOPLEFT, UI.questCardPadding, yOffset)
            yOffset = yOffset - textHeight - UI.questCardSectionGap
        end
    end

    addText(card.titleText, quest.title, UI.questCardTitleColor)

    card.divider:ClearAllPoints()
    card.divider:SetSize(textWidth, UI.questCardDividerHeight)
    card.divider:SetPoint(FRAME_POINTS.TOPLEFT, card, FRAME_POINTS.TOPLEFT, UI.questCardPadding, yOffset)
    card.divider:Show()
    yOffset = yOffset - UI.questCardDividerHeight - UI.questCardSectionGap

    addText(card.zoneText, string.format(UI.questCardZoneFormat, quest.zone), UI.questCardMetadataColor)
    addText(card.storyText, string.format(UI.questCardStoryFormat, quest.storyGroup), UI.questCardMetadataColor)
    addText(card.hubText, string.format(UI.questCardHubFormat, quest.hub), UI.questCardMetadataColor)

    local questLineText
    local questLineStep = quest.questLineStep
    local questLineLength = quest.questLineLength
    if type(questLineStep) == "number"
        and type(questLineLength) == "number"
        and questLineStep >= 1
        and questLineStep <= questLineLength
        and type(UI.questLinePositionFormat) == "string"
    then
        questLineText = string.format(UI.questLinePositionFormat, questLineStep, questLineLength)
    end
    addText(card.questLineText, questLineText, UI.questCardMetadataColor)

    addText(card.reasonText, quest.reason, UI.questCardBodyColor)

    local itemText
    if quest.questItem then
        itemText = string.format(
            UI.questCardItemFormat,
            quest.questItem.name,
            Recommendations.getItemDropAvailabilityText(quest.questItem)
        )
    end
    addText(card.itemText, itemText, UI.questCardItemColor)

    local cardHeight = math.max(UI.questCardMinimumHeight, -yOffset + UI.questCardPadding)
    card:SetHeight(cardHeight)
    return cardHeight
end

updateRecommendationContent = function(frame)
    local scrollFrame = frame.recommendationScrollFrame
    if not scrollFrame or not frame.recommendationContent then
        return
    end

    local viewportWidth = scrollFrame:GetWidth()
    local viewportHeight = scrollFrame:GetHeight()
    if viewportWidth <= 0 or viewportHeight <= 0 then
        return
    end

    frame.recommendationContent:SetWidth(viewportWidth)
    local contentHeight = UI.questCardListPadding
    local recommendations = frame.currentRecommendations or {}

    if #recommendations == 0 then
        local emptyText = frame.emptyRecommendationText
        emptyText:ClearAllPoints()
        emptyText:SetPoint(
            FRAME_POINTS.TOPLEFT,
            frame.recommendationContent,
            FRAME_POINTS.TOPLEFT,
            UI.questCardListPadding,
            -UI.questCardListPadding
        )
        emptyText:SetWidth(math.max(1, viewportWidth - UI.questCardListPadding * 2))
        emptyText:SetHeight(UI.questCardTextMeasurementHeight)
        emptyText:SetWordWrap(true)
        local emptyHeight = math.max(1, emptyText:GetNumLines()) * emptyText:GetLineHeight()
        emptyText:SetHeight(emptyHeight)
        emptyText:Show()
        contentHeight = contentHeight + emptyHeight + UI.questCardListPadding
    else
        frame.emptyRecommendationText:Hide()
        local cardWidth = math.max(
            1,
            viewportWidth - UI.questCardScrollBarPadding - UI.questCardListPadding * 2
        )
        local visibleCount = math.min(#recommendations, UI.maximumVisibleRecommendations)

        for index = 1, visibleCount do
            local card = frame.recommendationCards[index]
            if not card then
                card = createQuestCard(frame.recommendationContent, frame.playerText)
                frame.recommendationCards[index] = card
            end

            card:ClearAllPoints()
            card:SetWidth(cardWidth)
            local cardHeight = layoutQuestCard(card, recommendations[index], cardWidth)
            card:SetPoint(
                FRAME_POINTS.TOPLEFT,
                frame.recommendationContent,
                FRAME_POINTS.TOPLEFT,
                UI.questCardListPadding,
                -contentHeight
            )
            card:Show()
            contentHeight = contentHeight + cardHeight + UI.questCardGap
        end

        for index = visibleCount + 1, #frame.recommendationCards do
            frame.recommendationCards[index]:Hide()
        end
    end

    frame.recommendationContent:SetHeight(math.max(viewportHeight, contentHeight))
    scrollFrame:UpdateScrollChildRect()

    local scrollRange = scrollFrame:GetVerticalScrollRange()
    if scrollFrame:GetVerticalScroll() > scrollRange then
        scrollFrame:SetVerticalScroll(scrollRange)
    end
end

local function setRecommendationText(frame, mode)
    frame.currentRecommendations = getRecommendationsForMode(mode)
    frame.emptyRecommendationText:SetText(
        #frame.currentRecommendations == 0 and UI.noMatchingFixtureText or ""
    )
    if frame.statusText then
        frame.statusText:SetText(summarizePlayerStatus(frame))
    end
    updateRecommendationContent(frame)
    frame.recommendationScrollFrame:SetVerticalScroll(0)
end

local function saveWindowState(frame)
    local _, _, _, xOffset, yOffset = frame:GetPoint()
    if xOffset ~= nil and yOffset ~= nil then
        AzerothCompanionDB.window.x = xOffset
        AzerothCompanionDB.window.y = yOffset
    end
    AzerothCompanionDB.window.width = frame:GetWidth()
    AzerothCompanionDB.window.height = frame.statusExpansionOriginalHeight or frame:GetHeight()
end

local function configureActionButton(button, label)
    button:SetHeight(UI.buttonHeight)
    button:SetText(label)

    local fontString = button:GetFontString()
    fontString:SetJustifyH(TEXT_JUSTIFICATION.CENTER)
    button:SetWidth(fontString:GetStringWidth() + UI.buttonTextHorizontalPadding * 2)
end

local function buildFrame()
    local frame = CreateFrame(FRAME_TYPES.FRAME, UI.frameName, UIParent, FRAME_TEMPLATES.BACKDROP)
    frame:SetSize(AzerothCompanionDB.window.width, AzerothCompanionDB.window.height)
    frame:SetResizable(true)
    frame:SetResizeBounds(
        UI.minimumFrameWidth,
        UI.minimumFrameHeight,
        UI.maximumFrameWidth,
        UI.maximumFrameHeight
    )
    frame:SetPoint(FRAME_POINTS.TOPLEFT, UIParent, FRAME_POINTS.TOPLEFT, AzerothCompanionDB.window.x, AzerothCompanionDB.window.y)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile = UI_TEXTURES.PANEL_BACKGROUND,
        edgeFile = UI_TEXTURES.PANEL_BORDER,
        tile = true,
        tileSize = UI.backdropTileSize,
        edgeSize = UI.backdropEdgeSize,
        insets = {
            left = UI.backdropInset,
            right = UI.backdropInset,
            top = UI.backdropInset,
            bottom = UI.backdropInset,
        },
    })
    frame:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    frame:SetBackdropBorderColor(0.55, 0.80, 1.0, 1.0)
    frame:SetClampedToScreen(true)

    frame.titleText = frame:CreateFontString(nil, DRAW_LAYERS.OVERLAY, FONT_OBJECTS.TITLE)
    frame.titleText:SetPoint(FRAME_POINTS.TOPLEFT, frame, FRAME_POINTS.TOPLEFT, 16, -14)
    frame.titleText:SetText(UI.titleText)

    local closeButton = CreateFrame(FRAME_TYPES.BUTTON, nil, frame, FRAME_TEMPLATES.CLOSE_BUTTON)
    closeButton:SetPoint(FRAME_POINTS.TOPRIGHT, frame, FRAME_POINTS.TOPRIGHT, -4, -4)
    closeButton:SetScript(FRAME_SCRIPTS.ON_CLICK, function()
        frame:Hide()
    end)

    frame.playerText = frame:CreateFontString(nil, DRAW_LAYERS.OVERLAY, FONT_OBJECTS.SMALL_HIGHLIGHT)
    frame.playerText:SetPoint(FRAME_POINTS.TOPLEFT, frame.titleText, FRAME_POINTS.BOTTOMLEFT, 0, -8)
    frame.playerText:SetJustifyH(TEXT_JUSTIFICATION.LEFT)
    frame.playerText:SetWordWrap(true)
    frame.playerText:SetText(UI.loadingText)

    frame.statusCard = CreateFrame(FRAME_TYPES.FRAME, nil, frame, FRAME_TEMPLATES.BACKDROP)
    frame.statusCard:SetBackdrop({
        bgFile = UI_TEXTURES.PANEL_BACKGROUND,
        edgeFile = UI_TEXTURES.PANEL_BORDER,
        tile = true,
        tileSize = UI.backdropTileSize,
        edgeSize = UI.backdropEdgeSize,
        insets = {
            left = UI.backdropInset,
            right = UI.backdropInset,
            top = UI.backdropInset,
            bottom = UI.backdropInset,
        },
    })
    frame.statusCard:SetBackdropColor(
        UI.statusCardBackgroundColor.r,
        UI.statusCardBackgroundColor.g,
        UI.statusCardBackgroundColor.b,
        UI.statusCardBackgroundColor.a
    )
    frame.statusCard:SetBackdropBorderColor(
        UI.statusCardBorderColor.r,
        UI.statusCardBorderColor.g,
        UI.statusCardBorderColor.b,
        UI.statusCardBorderColor.a
    )
    frame.statusCard:SetPoint(FRAME_POINTS.TOPLEFT, frame.playerText, FRAME_POINTS.BOTTOMLEFT, 0, -12)
    frame.statusCard:SetHeight(82)

    frame.statusTitleText = frame.statusCard:CreateFontString(nil, DRAW_LAYERS.OVERLAY, FONT_OBJECTS.HIGHLIGHT)
    frame.statusTitleText:SetPoint(FRAME_POINTS.TOPLEFT, frame.statusCard, FRAME_POINTS.TOPLEFT, 12, -10)
    frame.statusTitleText:SetTextColor(
        UI.statusCardTitleColor.r,
        UI.statusCardTitleColor.g,
        UI.statusCardTitleColor.b,
        UI.statusCardTitleColor.a
    )

    frame.statusMetaText = frame.statusCard:CreateFontString(nil, DRAW_LAYERS.OVERLAY, FONT_OBJECTS.SMALL_HIGHLIGHT)
    frame.statusMetaText:SetJustifyH(TEXT_JUSTIFICATION.LEFT)
    frame.statusMetaText:SetTextColor(
        UI.statusCardMetaColor.r,
        UI.statusCardMetaColor.g,
        UI.statusCardMetaColor.b,
        UI.statusCardMetaColor.a
    )

    frame.statusActiveText = createQuestFontString(frame.statusCard, frame.playerText, 0.95)
    frame.statusActiveText:SetJustifyH(TEXT_JUSTIFICATION.LEFT)
    frame.statusActiveText:SetTextColor(
        UI.statusCardActiveColor.r,
        UI.statusCardActiveColor.g,
        UI.statusCardActiveColor.b,
        UI.statusCardActiveColor.a
    )

    frame.statusQuestToggleButton = CreateFrame(
        FRAME_TYPES.BUTTON,
        nil,
        frame.statusCard
    )
    frame.statusQuestToggleButton.text = createQuestFontString(
        frame.statusQuestToggleButton,
        frame.playerText,
        0.95
    )
    frame.statusQuestToggleButton.text:SetPoint(FRAME_POINTS.TOPLEFT, frame.statusQuestToggleButton, FRAME_POINTS.TOPLEFT, 0, -2)
    frame.statusQuestToggleButton.text:SetJustifyH(TEXT_JUSTIFICATION.LEFT)
    frame.statusQuestToggleButton:SetScript(FRAME_SCRIPTS.ON_CLICK, function()
        frame.statusQuestsExpanded = not frame.statusQuestsExpanded
        renderStatusCard(frame)
    end)
    frame.statusQuestsExpanded = false

    frame.statusNextText = createQuestFontString(frame.statusCard, frame.playerText, 0.92)
    frame.statusNextText:SetJustifyH(TEXT_JUSTIFICATION.LEFT)
    frame.statusNextText:SetTextColor(
        UI.statusCardNextColor.r,
        UI.statusCardNextColor.g,
        UI.statusCardNextColor.b,
        UI.statusCardNextColor.a
    )

    frame.statusText = createQuestFontString(frame, frame.playerText, 0.95)
    frame.statusText:SetPoint(FRAME_POINTS.TOPLEFT, frame.statusCard, FRAME_POINTS.BOTTOMLEFT, 0, -12)
    frame.statusText:SetJustifyH(TEXT_JUSTIFICATION.LEFT)
    frame.statusText:SetWordWrap(true)
    frame.statusText:SetText("Her er du nå:\nLaster status...")
    frame.statusText:Hide()

    local currentButton = CreateFrame(FRAME_TYPES.BUTTON, nil, frame, FRAME_TEMPLATES.PANEL_BUTTON)
    configureActionButton(currentButton, UI.buttonCurrentText)
    currentButton:SetPoint(FRAME_POINTS.TOPLEFT, frame.statusCard, FRAME_POINTS.BOTTOMLEFT, 0, -14)
    currentButton:SetScript(FRAME_SCRIPTS.ON_CLICK, function()
        setRecommendationText(frame, MODES.CURRENT)
        refreshPlayerInfo(frame)
    end)

    local moveOnButton = CreateFrame(FRAME_TYPES.BUTTON, nil, frame, FRAME_TEMPLATES.PANEL_BUTTON)
    configureActionButton(moveOnButton, UI.buttonMoveOnText)
    moveOnButton:SetPoint(FRAME_POINTS.TOPLEFT, currentButton, FRAME_POINTS.TOPRIGHT, UI.buttonGap, 0)
    moveOnButton:SetScript(FRAME_SCRIPTS.ON_CLICK, function()
        setRecommendationText(frame, MODES.MOVE_ON)
        refreshPlayerInfo(frame)
    end)

    local recommendationScrollFrame = CreateFrame(
        FRAME_TYPES.SCROLL_FRAME,
        nil,
        frame,
        FRAME_TEMPLATES.SCROLL_FRAME
    )
    recommendationScrollFrame:SetPoint(FRAME_POINTS.TOPLEFT, currentButton, FRAME_POINTS.BOTTOMLEFT, 0, -18)
    recommendationScrollFrame:SetPoint(
        FRAME_POINTS.BOTTOMRIGHT,
        frame,
        FRAME_POINTS.BOTTOMRIGHT,
        -UI.recommendationScrollRightPadding,
        UI.recommendationScrollBottomPadding
    )
    recommendationScrollFrame:EnableMouseWheel(true)
    recommendationScrollFrame:SetScript(FRAME_SCRIPTS.ON_MOUSE_WHEEL, function(scrollFrame, delta)
        local scrollRange = scrollFrame:GetVerticalScrollRange()
        local nextScroll = scrollFrame:GetVerticalScroll() - delta * UI.recommendationScrollStep
        scrollFrame:SetVerticalScroll(math.max(0, math.min(scrollRange, nextScroll)))
    end)

    frame.recommendationScrollFrame = recommendationScrollFrame
    frame.recommendationContent = CreateFrame(FRAME_TYPES.FRAME, nil, recommendationScrollFrame)
    frame.recommendationContent:SetSize(UI.frameWidth, UI.recommendationTextMeasurementHeight)
    recommendationScrollFrame:SetScrollChild(frame.recommendationContent)

    frame.recommendationCards = {}
    frame.currentRecommendations = {}
    frame.emptyRecommendationText = createQuestFontString(
        frame.recommendationContent,
        frame.playerText,
        UI.questCardBodyFontScale
    )
    frame.emptyRecommendationText:SetJustifyH(TEXT_JUSTIFICATION.LEFT)
    frame.emptyRecommendationText:SetWordWrap(true)
    frame.emptyRecommendationText:SetText(UI.emptyRecommendationText)

    recommendationScrollFrame:SetScript(FRAME_SCRIPTS.ON_SIZE_CHANGED, function()
        updateRecommendationContent(frame)
    end)
    frame:SetScript(FRAME_SCRIPTS.ON_SIZE_CHANGED, updateContentWidths)
    updateContentWidths(frame)

    local resizeButton = CreateFrame(FRAME_TYPES.BUTTON, nil, frame)
    resizeButton:SetSize(UI.resizeButtonSize, UI.resizeButtonSize)
    resizeButton:SetPoint(FRAME_POINTS.BOTTOMRIGHT, frame, FRAME_POINTS.BOTTOMRIGHT, -4, 4)
    resizeButton:SetNormalTexture(UI_TEXTURES.RESIZE_NORMAL)
    resizeButton:SetHighlightTexture(UI_TEXTURES.RESIZE_HIGHLIGHT)
    resizeButton:SetPushedTexture(UI_TEXTURES.RESIZE_PRESSED)
    resizeButton:SetScript(FRAME_SCRIPTS.ON_MOUSE_DOWN, function(_, button)
        if button == MOUSE_BUTTONS.LEFT then
            frame:StartSizing(FRAME_POINTS.BOTTOMRIGHT)
        end
    end)
    resizeButton:SetScript(FRAME_SCRIPTS.ON_MOUSE_UP, function(_, button)
        if button == MOUSE_BUTTONS.LEFT then
            frame:StopMovingOrSizing()
            saveWindowState(frame)
        end
    end)

    frame:SetScript(FRAME_SCRIPTS.ON_MOUSE_DOWN, function(_, button)
        if button == MOUSE_BUTTONS.LEFT then
            frame:StartMoving()
        end
    end)

    frame:SetScript(FRAME_SCRIPTS.ON_MOUSE_UP, function(_, button)
        if button == MOUSE_BUTTONS.LEFT then
            frame:StopMovingOrSizing()
            saveWindowState(frame)
        end
    end)

    frame:SetScript(FRAME_SCRIPTS.ON_HIDE, function()
        saveWindowState(frame)
    end)

    refreshPlayerInfo(frame)
    return frame
end

local function toggleFrame()
    if AzerothCompanionPanel then
        if AzerothCompanionPanel:IsShown() then
            AzerothCompanionPanel:Hide()
        else
            AzerothCompanionPanel:Show()
        end
    end
end

local function registerSlashCommands()
    SLASH_AZEROTHCOMPANION1 = UI.slashCommand
    SlashCmdList["AZEROTHCOMPANION"] = function()
        toggleFrame()
    end

    SLASH_AZEROTHCOMPANIONDB1 = UI.questieDbSlashCommand
    SlashCmdList["AZEROTHCOMPANIONDB"] = function(message)
        local chatFrame = DEFAULT_CHAT_FRAME
        chatFrame:AddMessage(UI.questieDbOutputPrefix .. UI.questieDbProbeHelp)

        local rawMessage = message or ""
        local cleanedMessage = rawMessage:match("^%s*(.-)%s*$") or rawMessage
        local questID = tonumber(cleanedMessage)

        if not questID or questID < 1 or questID % 1 ~= 0 then
            return
        end

        local quest, reason, detail = QuestieDBAdapter.getQuest(questID)
        if not quest then
            if reason == "not_installed" then
                chatFrame:AddMessage(UI.questieDbOutputPrefix .. UI.questieDbNotInstalled)
            elseif reason == "contract_mismatch" then
                chatFrame:AddMessage(UI.questieDbOutputPrefix .. string.format(UI.questieDbContractMismatch, detail or UI.questieDbUnknownValue))
            elseif reason == "not_found" then
                chatFrame:AddMessage(UI.questieDbOutputPrefix .. string.format(UI.questieDbQuestNotFound, questID))
            elseif reason == "invalid_id" then
                chatFrame:AddMessage(UI.questieDbOutputPrefix .. UI.questieDbInvalidQuestId)
            elseif reason == "api_unavailable" then
                chatFrame:AddMessage(UI.questieDbOutputPrefix .. UI.questieDbApiUnavailable)
            else
                chatFrame:AddMessage(UI.questieDbOutputPrefix .. string.format(UI.questieDbReadFailed, questID, detail or UI.questieDbUnknownValue))
            end
            return
        end

        local function formatField(value)
            if value == nil then
                return UI.questieDbUnknownValue
            end
            return tostring(value)
        end

        local function formatQuestIDs(questIDs)
            if type(questIDs) ~= "table" or #questIDs == 0 then
                return UI.questieDbNoIDs
            end

            local displayedIDs = {}
            for index = 1, math.min(#questIDs, UI.questieDbMaxDisplayedPrerequisites) do
                displayedIDs[index] = tostring(questIDs[index])
            end
            return table.concat(displayedIDs, ", ")
        end

        local objectiveLineCount = type(quest.objectives) == "table" and #quest.objectives or 0
        chatFrame:AddMessage(UI.questieDbOutputPrefix .. UI.questieDbAvailable)
        chatFrame:AddMessage(UI.questieDbOutputPrefix .. string.format(UI.questieDbQuestSummaryFormat, quest.id, quest.title))
        chatFrame:AddMessage(UI.questieDbOutputPrefix .. string.format(
            UI.questieDbQuestFieldsFormat,
            formatField(quest.minLevel),
            formatField(quest.questLevel),
            formatField(quest.zoneOrSort)
        ))
        chatFrame:AddMessage(UI.questieDbOutputPrefix .. string.format(
            UI.questieDbRestrictionFormat,
            formatField(quest.requiredRaces),
            formatField(quest.requiredClasses)
        ))
        chatFrame:AddMessage(UI.questieDbOutputPrefix .. string.format(
            UI.questieDbChainFormat,
            formatQuestIDs(quest.preQuestSingle),
            formatQuestIDs(quest.preQuestGroup),
            formatField(quest.nextQuestInChain)
        ))
        chatFrame:AddMessage(UI.questieDbOutputPrefix .. string.format(
            UI.questieDbObjectivesFormat,
            objectiveLineCount,
            formatField(quest.sourceItemId)
        ))
        chatFrame:AddMessage(UI.questieDbOutputPrefix .. UI.questieDbDataSourceNote)
    end
end

local function onEvent(self, event, ...)
    if event == EVENTS.PLAYER_STARTED_MOVING then
        startCoordinateUpdates()
    elseif event == EVENTS.PLAYER_STOPPED_MOVING then
        stopCoordinateUpdates()
    elseif event == EVENTS.PLAYER_LOGIN or event == EVENTS.PLAYER_ENTERING_WORLD or event == EVENTS.ZONE_CHANGED_NEW_AREA or event == EVENTS.QUEST_LOG_UPDATE then
        if not AzerothCompanionPanel then
            AzerothCompanionPanel = buildFrame()
        end
        refreshPlayerInfo(AzerothCompanionPanel)
        ensureCoordinateDisplay()
    end
end

local function initialize()
    ensureDatabase()
    registerSlashCommands()
    addon:SetScript("OnEvent", onEvent)
    ensureCoordinateDisplay()

    if not AzerothCompanionPanel then
        AzerothCompanionPanel = buildFrame()
    end
    AzerothCompanionPanel:Show()
    refreshPlayerInfo(AzerothCompanionPanel)
end

initialize()
