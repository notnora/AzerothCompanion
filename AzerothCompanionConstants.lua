local addonName, namespace = ...

namespace.Constants = {
    UI = {
        frameName = addonName .. "Panel",
        defaultWindowX = 120,
        defaultWindowY = -120,
        titleText = "Azeroth Companion",
        loadingText = "Laster spillerstatus...",
        emptyRecommendationText = "Velg en handling for å se forslag.",
        sampleDataText = "Eksempeldata: dette er demonstrasjonsanbefalinger.",
        playerLabelFormat = "%s | %s | %s | Faction:\194\160%s | Sone:\194\160%s",
        nonBreakingSpace = "\194\160",
        buttonCurrentText = "Hva bør jeg gjøre her?",
        buttonMoveOnText = "Jeg er klar til å gå videre!",
        slashCommand = "/ac",
        frameWidth = 360,
        frameHeight = 260,
        minimumFrameWidth = 360,
        minimumFrameHeight = 240,
        maximumFrameWidth = 720,
        maximumFrameHeight = 600,
        contentHorizontalPadding = 32,
        resizeButtonSize = 16,
        buttonTextHorizontalPadding = 10,
        buttonGap = 12,
        buttonHeight = 26,
    },
    FRAME_TYPES = {
        FRAME = "Frame",
        BUTTON = "Button",
    },
    FRAME_TEMPLATES = {
        BACKDROP = "BackdropTemplate",
        CLOSE_BUTTON = "UIPanelCloseButton",
        PANEL_BUTTON = "UIPanelButtonTemplate",
    },
    UI_TEXTURES = {
        RESIZE_NORMAL = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up",
        RESIZE_HIGHLIGHT = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight",
        RESIZE_PRESSED = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down",
    },
    FRAME_POINTS = {
        TOPLEFT = "TOPLEFT",
        TOPRIGHT = "TOPRIGHT",
        BOTTOMLEFT = "BOTTOMLEFT",
        BOTTOMRIGHT = "BOTTOMRIGHT",
    },
    DRAW_LAYERS = {
        OVERLAY = "OVERLAY",
    },
    FONT_OBJECTS = {
        TITLE = "GameFontNormalLarge",
        SMALL_HIGHLIGHT = "GameFontHighlightSmall",
        HIGHLIGHT = "GameFontHighlight",
    },
    TEXT_JUSTIFICATION = {
        LEFT = "LEFT",
        CENTER = "CENTER",
    },
    FRAME_SCRIPTS = {
        ON_CLICK = "OnClick",
        ON_MOUSE_DOWN = "OnMouseDown",
        ON_MOUSE_UP = "OnMouseUp",
        ON_HIDE = "OnHide",
        ON_SIZE_CHANGED = "OnSizeChanged",
    },
    MOUSE_BUTTONS = {
        LEFT = "LeftButton",
    },
    PLAYER_UNIT = "player",
    MODES = {
        CURRENT = "current",
        MOVE_ON = "moveon",
    },
    EVENTS = {
        PLAYER_LOGIN = "PLAYER_LOGIN",
        PLAYER_ENTERING_WORLD = "PLAYER_ENTERING_WORLD",
        ZONE_CHANGED_NEW_AREA = "ZONE_CHANGED_NEW_AREA",
        QUEST_LOG_UPDATE = "QUEST_LOG_UPDATE",
    },
}