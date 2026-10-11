local addonName, namespace = ...
local constants = namespace.Constants
local UI = constants.UI
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
addon:RegisterEvent(EVENTS.PLAYER_LOGIN)
addon:RegisterEvent(EVENTS.PLAYER_ENTERING_WORLD)
addon:RegisterEvent(EVENTS.ZONE_CHANGED_NEW_AREA)
addon:RegisterEvent(EVENTS.QUEST_LOG_UPDATE)

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

local function createSampleRecommendations(mode)
    local suggestions = {
        {
            title = "Rising from the Ashes",
            zone = "Durotar",
            reason = "Dette passer godt for en kort, sammenhengende quest-kjede i samme område.",
        },
        {
            title = "The Missing Tools",
            zone = "The Barrens",
            reason = "God kandidat for å kombinere flere mål i en naturlig ny sone.",
        },
        {
            title = "A New Dawn",
            zone = "Orgrimmar",
            reason = "Nær innlevering og god måte å koble en shorter city-errand til eventyr.",
        },
    }

    if mode == MODES.MOVE_ON then
        return {
            {
                title = "The Barrens route",
                zone = "The Barrens",
                reason = "En meningsfull ny destinasjon når spilleren er klar for å flytte videre fra nåværende sone.",
            },
            {
                title = "Northwatch outpost",
                zone = "Northern Barrens",
                reason = "Godt innhold for langreiser som fortsatt har solid opplevelseverdier.",
            },
            {
                title = "Capital errands",
                zone = "Orgrimmar",
                reason = "Kombinerer turn-ins og relevant bybesøk når reise er nødvendig.",
            },
        }
    end

    return suggestions
end

local function formatRecommendations(mode)
    local entries = createSampleRecommendations(mode)
    local lines = {
        UI.sampleDataText,
        "",
    }

    for index, entry in ipairs(entries) do
        local line = string.format("%d. %s (%s) - %s", index, entry.title, entry.zone, entry.reason)
        table.insert(lines, line)
    end

    return table.concat(lines, "\n")
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
                context.playerName,
                context.playerClass,
                "Lvl " .. context.playerLevel,
                context.playerFaction,
                context.zone
            )
        )
    end
end

local function updateContentWidths(frame)
    local contentWidth = frame:GetWidth() - UI.contentHorizontalPadding

    if frame.playerText then
        frame.playerText:SetWidth(contentWidth)
    end

    if frame.recommendationText then
        frame.recommendationText:SetWidth(contentWidth)
    end
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
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
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
    frame.playerText:SetText(UI.loadingText)

    local currentButton = CreateFrame(FRAME_TYPES.BUTTON, nil, frame, FRAME_TEMPLATES.PANEL_BUTTON)
    configureActionButton(currentButton, UI.buttonCurrentText)
    currentButton:SetPoint(FRAME_POINTS.TOPLEFT, frame.playerText, FRAME_POINTS.BOTTOMLEFT, 0, -16)
    currentButton:SetScript(FRAME_SCRIPTS.ON_CLICK, function()
        frame.recommendationText:SetText(formatRecommendations(MODES.CURRENT))
    end)

    local moveOnButton = CreateFrame(FRAME_TYPES.BUTTON, nil, frame, FRAME_TEMPLATES.PANEL_BUTTON)
    configureActionButton(moveOnButton, UI.buttonMoveOnText)
    moveOnButton:SetPoint(FRAME_POINTS.TOPLEFT, currentButton, FRAME_POINTS.TOPRIGHT, UI.buttonGap, 0)
    moveOnButton:SetScript(FRAME_SCRIPTS.ON_CLICK, function()
        frame.recommendationText:SetText(formatRecommendations(MODES.MOVE_ON))
    end)

    frame.recommendationText = frame:CreateFontString(nil, DRAW_LAYERS.OVERLAY, FONT_OBJECTS.HIGHLIGHT)
    frame.recommendationText:SetPoint(FRAME_POINTS.TOPLEFT, currentButton, FRAME_POINTS.BOTTOMLEFT, 0, -18)
    frame.recommendationText:SetJustifyH("LEFT")
    frame.recommendationText:SetText(UI.emptyRecommendationText)

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
    if event == EVENTS.PLAYER_LOGIN or event == EVENTS.PLAYER_ENTERING_WORLD or event == EVENTS.ZONE_CHANGED_NEW_AREA or event == EVENTS.QUEST_LOG_UPDATE then
        if not AzerothCompanionPanel then
            AzerothCompanionPanel = buildFrame()
        end
        refreshPlayerInfo(AzerothCompanionPanel)
    end
end

local function initialize()
    ensureDatabase()
    registerSlashCommands()
    addon:SetScript("OnEvent", onEvent)

    if not AzerothCompanionPanel then
        AzerothCompanionPanel = buildFrame()
    end
    AzerothCompanionPanel:Show()
    refreshPlayerInfo(AzerothCompanionPanel)
end

initialize()
