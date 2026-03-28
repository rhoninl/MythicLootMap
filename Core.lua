-- EquipMap Core
-- Main addon initialization, event handling, and slash commands

local ADDON_NAME, ns = ...

-- Global reference for tests and external access
EquipMap = ns

-- Internal data store
ns.db = {
    dungeons = {},
    items = {},
}

-- Event frame
local eventFrame = CreateFrame("Frame")

local EVENTS = {
    "PLAYER_ENTERING_WORLD",
    "CHALLENGE_MODE_MAPS_UPDATE",
    "ITEM_DATA_LOAD_RESULT",
    "PLAYER_EQUIPMENT_CHANGED",
    "TRANSMOG_COLLECTION_UPDATED",
}

for _, event in ipairs(EVENTS) do
    eventFrame:RegisterEvent(event)
end

local dataLoaded = false
local isLoadingData = false

-- Debounce: batch ITEM_DATA_LOAD_RESULT refreshes into a single UI update
local refreshPending = false
local REFRESH_DELAY = 0.3

local function ScheduleRefresh()
    if refreshPending then return end
    refreshPending = true
    C_Timer.After(REFRESH_DELAY, function()
        refreshPending = false
        ns.Data:UpdateComparisons()
        ns.MainFrame:Refresh()
    end)
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        C_MythicPlus.RequestMapInfo()

    elseif event == "CHALLENGE_MODE_MAPS_UPDATE" then
        if not dataLoaded and not isLoadingData then
            isLoadingData = true
            dataLoaded = true
            ns.Data:LoadDungeonData()
            ns.Data:UpdateComparisons()
            ns.MainFrame:InitDungeonDropdown()
            isLoadingData = false
        end

    elseif event == "ITEM_DATA_LOAD_RESULT" then
        local itemID, success = ...
        ns.Data:OnItemDataLoaded(itemID, success)
        if not isLoadingData then
            ScheduleRefresh()
        end

    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if dataLoaded and not isLoadingData then
            ScheduleRefresh()
        end

    elseif event == "TRANSMOG_COLLECTION_UPDATED" then
        if dataLoaded and not isLoadingData then
            for _, item in ipairs(ns.db.items) do
                if C_TransmogCollection and C_TransmogCollection.PlayerHasTransmog then
                    item.owned = C_TransmogCollection.PlayerHasTransmog(item.itemID, 0)
                end
            end
            ScheduleRefresh()
        end
    end
end)

-- Slash command
SLASH_EQUIPMAP1 = "/equipmap"
SLASH_EQUIPMAP2 = "/em"

SlashCmdList["EQUIPMAP"] = function(msg)
    msg = strtrim(msg):lower()

    if msg == "test" then
        if ns.TestRunner then
            ns.TestRunner:RunAll()
        else
            ns:Print("Test suite not loaded.")
        end
        return
    end

    if msg == "reload" then
        isLoadingData = true
        ns.db.dungeons = {}
        ns.db.items = {}
        ns.Data:LoadDungeonData()
        ns.Data:UpdateComparisons()
        ns.MainFrame:InitDungeonDropdown()
        ns.MainFrame:Refresh()
        isLoadingData = false
        ns:Print("Data reloaded.")
        return
    end

    if msg == "help" then
        ns:Print("Commands:")
        print("  /equipmap - Toggle loot browser window")
        print("  /equipmap reload - Reload dungeon data")
        print("  /equipmap test - Run test suite")
        print("  /equipmap help - Show this help")
        return
    end

    -- Default: toggle window
    ns.MainFrame:Toggle()
end

ns:Print("Loaded. Type /equipmap to open.")
