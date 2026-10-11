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
        playerLabelFormat = "%s | %s | %s | %s",
        buttonCurrentText = "Hva bør jeg gjøre her?",
        buttonMoveOnText = "Jeg er klar til å gå videre!",
        slashCommand = "/ac",
        frameWidth = 360,
        frameHeight = 260,
        buttonWidth = 150,
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
    FRAME_POINTS = {
        TOPLEFT = "TOPLEFT",
        TOPRIGHT = "TOPRIGHT",
        BOTTOMLEFT = "BOTTOMLEFT",
    },
    DRAW_LAYERS = {
        OVERLAY = "OVERLAY",
    },
    FONT_OBJECTS = {
        TITLE = "GameFontNormalLarge",
        SMALL_HIGHLIGHT = "GameFontHighlightSmall",
        HIGHLIGHT = "GameFontHighlight",
    },
    FRAME_SCRIPTS = {
        ON_CLICK = "OnClick",
        ON_MOUSE_DOWN = "OnMouseDown",
        ON_MOUSE_UP = "OnMouseUp",
        ON_HIDE = "OnHide",
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