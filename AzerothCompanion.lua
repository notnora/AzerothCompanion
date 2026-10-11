local addonName, namespace = ...
local constants = namespace.Constants
local UI = constants.UI
local questFixtures = namespace.QuestFixtures
local Recommendations = namespace.Recommendations
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

local function keepFieldTogether(value)
    local formattedValue = tostring(value):gsub(" ", UI.nonBreakingSpace)
    return formattedValue
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
end

local updateRecommendationContent

local function updateContentWidths(frame)
    local contentWidth = frame:GetWidth() - UI.contentHorizontalPadding

    if frame.playerText then
        frame.playerText:SetWidth(contentWidth)
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

local function createQuestFontString(parent, fontReference, fontScale)
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
    AzerothCompanionDB.window.height = frame:GetHeight()
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

    local currentButton = CreateFrame(FRAME_TYPES.BUTTON, nil, frame, FRAME_TEMPLATES.PANEL_BUTTON)
    configureActionButton(currentButton, UI.buttonCurrentText)
    currentButton:SetPoint(FRAME_POINTS.TOPLEFT, frame.playerText, FRAME_POINTS.BOTTOMLEFT, 0, -16)
    currentButton:SetScript(FRAME_SCRIPTS.ON_CLICK, function()
        setRecommendationText(frame, MODES.CURRENT)
    end)

    local moveOnButton = CreateFrame(FRAME_TYPES.BUTTON, nil, frame, FRAME_TEMPLATES.PANEL_BUTTON)
    configureActionButton(moveOnButton, UI.buttonMoveOnText)
    moveOnButton:SetPoint(FRAME_POINTS.TOPLEFT, currentButton, FRAME_POINTS.TOPRIGHT, UI.buttonGap, 0)
    moveOnButton:SetScript(FRAME_SCRIPTS.ON_CLICK, function()
        setRecommendationText(frame, MODES.MOVE_ON)
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
