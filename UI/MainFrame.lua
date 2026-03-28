-- EquipMap Main UI Frame
-- Uses modern WoW 12.0 APIs: ScrollBox, DropdownButton, MenuUtil

local ADDON_NAME, ns = ...
local EquipMap = ns

local MainFrame = {}
EquipMap.MainFrame = MainFrame

local FRAME_WIDTH = 960
local FRAME_HEIGHT = 560
local ROW_HEIGHT = 28
local HEADER_HEIGHT = 24
local FILTER_BAR_HEIGHT = 36

local frame = nil
local scrollBox = nil
local dataProvider = nil
local statusText = nil

function MainFrame:Create()
    if frame then return frame end

    frame = CreateFrame("Frame", "EquipMapFrame", UIParent, "BackdropTemplate")
    frame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)

    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("EquipMap - Mythic+ Loot Browser")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -6, -6)

    self:CreateFilterBar(frame)
    self:CreateHeaders(frame)
    self:CreateScrollBox(frame)

    -- Status bar
    statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusText:SetPoint("BOTTOMLEFT", 16, 12)
    statusText:SetTextColor(0.7, 0.7, 0.7)

    frame:Hide()
    return frame
end

---------------------------------------------------------------------------
-- Filter Bar (modern DropdownButton API)
---------------------------------------------------------------------------

function MainFrame:CreateFilterBar(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetPoint("TOPLEFT", 12, -42)
    bar:SetPoint("TOPRIGHT", -12, -42)
    bar:SetHeight(FILTER_BAR_HEIGHT)

    -- Slot dropdown
    local slotDropdown = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
    slotDropdown:SetPoint("LEFT", 4, 0)
    slotDropdown:SetDefaultText("All Slots")
    self.slotDropdown = slotDropdown

    local selectedSlot = 0
    slotDropdown:SetupMenu(function(dropdown, rootDescription)
        for _, slot in ipairs(EquipMap.FILTER_SLOTS) do
            rootDescription:CreateRadio(
                slot.name,
                function() return selectedSlot == slot.id end,
                function()
                    selectedSlot = slot.id
                    EquipMap.Filters:SetSlot(slot.id)
                    MainFrame:Refresh()
                end
            )
        end
    end)

    -- Dungeon dropdown
    local dungeonDropdown = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
    dungeonDropdown:SetPoint("LEFT", slotDropdown, "RIGHT", 10, 0)
    dungeonDropdown:SetDefaultText("All Dungeons")
    self.dungeonDropdown = dungeonDropdown

    -- Stat filter dropdown
    local statDropdown = CreateFrame("DropdownButton", nil, bar, "WowStyle1DropdownTemplate")
    statDropdown:SetPoint("LEFT", dungeonDropdown, "RIGHT", 10, 0)
    statDropdown:SetDefaultText("All Stats")
    self.statDropdown = statDropdown

    local selectedStat = nil
    statDropdown:SetupMenu(function(dropdown, rootDescription)
        local statOptions = {
            { key = nil,       name = "All Stats" },
            { key = "crit",    name = "Crit" },
            { key = "haste",   name = "Haste" },
            { key = "mastery", name = "Mastery" },
            { key = "vers",    name = "Versatility" },
        }
        for _, opt in ipairs(statOptions) do
            rootDescription:CreateRadio(
                opt.name,
                function() return selectedStat == opt.key end,
                function()
                    selectedStat = opt.key
                    EquipMap.Filters:SetStat(opt.key)
                    MainFrame:Refresh()
                end
            )
        end
    end)

    -- Spec filter checkbox
    local specCheck = self:CreateCheckbox(bar, "My Spec", function(checked)
        EquipMap.Filters:SetSpecFilter(checked)
        if checked then
            local _, _, classID = UnitClass("player")
            local specIndex = GetSpecialization()
            if specIndex then
                local specID = GetSpecializationInfo(specIndex)
                EJ_SetLootFilter(classID, specID)
            end
        else
            EJ_ResetLootFilter()
        end
        EquipMap.Data:LoadDungeonData()
        EquipMap.Data:UpdateComparisons()
        MainFrame:Refresh()
    end)
    specCheck:SetPoint("LEFT", statDropdown, "RIGHT", 10, 0)
    self.specCheck = specCheck

    -- Upgrades only checkbox
    local upgradeCheck = self:CreateCheckbox(bar, "Upgrades", function(checked)
        EquipMap.Filters:SetUpgradesOnly(checked)
        MainFrame:Refresh()
    end)
    upgradeCheck:SetPoint("LEFT", specCheck, "RIGHT", 80, 0)
    self.upgradeCheck = upgradeCheck

    -- Not collected checkbox
    local collectCheck = self:CreateCheckbox(bar, "Not Collected", function(checked)
        EquipMap.Filters:SetNotCollected(checked)
        MainFrame:Refresh()
    end)
    collectCheck:SetPoint("LEFT", upgradeCheck, "RIGHT", 80, 0)
    self.collectCheck = collectCheck
end

function MainFrame:CreateCheckbox(parent, label, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check.text = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    check.text:SetPoint("LEFT", check, "RIGHT", 2, 0)
    check.text:SetText(label)
    check:SetScript("OnClick", function(self)
        onClick(self:GetChecked())
    end)
    return check
end

---------------------------------------------------------------------------
-- Column headers
---------------------------------------------------------------------------

function MainFrame:CreateHeaders(parent)
    local headerRow = CreateFrame("Frame", nil, parent)
    headerRow:SetPoint("TOPLEFT", 12, -(42 + FILTER_BAR_HEIGHT + 4))
    headerRow:SetPoint("TOPRIGHT", -28, -(42 + FILTER_BAR_HEIGHT + 4))
    headerRow:SetHeight(HEADER_HEIGHT)

    local headers = {
        { text = "", width = 30 },
        { text = "Item", width = 180 },
        { text = "iLvl", width = 45 },
        { text = "Slot", width = 75 },
        { text = "Stats", width = 110 },
        { text = "Dungeon", width = 150 },
        { text = "Boss", width = 140 },
        { text = "+/-", width = 50 },
        { text = "Owned", width = 50 },
    }

    local xOffset = 0
    for _, h in ipairs(headers) do
        local text = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", xOffset, 0)
        text:SetWidth(h.width)
        text:SetText(EquipMap.COLORS.HEADER .. h.text .. EquipMap.COLORS.RESET)
        text:SetJustifyH("LEFT")
        xOffset = xOffset + h.width
    end

    local sep = headerRow:CreateTexture(nil, "ARTWORK")
    sep:SetPoint("BOTTOMLEFT", 0, 0)
    sep:SetPoint("BOTTOMRIGHT", 0, 0)
    sep:SetHeight(1)
    sep:SetColorTexture(0.5, 0.5, 0.5, 0.5)
end

---------------------------------------------------------------------------
-- ScrollBox (modern WoW 10.1+ / 12.0 API)
---------------------------------------------------------------------------

function MainFrame:CreateScrollBox(parent)
    local topOffset = 42 + FILTER_BAR_HEIGHT + 4 + HEADER_HEIGHT + 4

    scrollBox = CreateFrame("Frame", nil, parent, "WowScrollBoxList")
    scrollBox:SetPoint("TOPLEFT", 12, -topOffset)
    scrollBox:SetPoint("BOTTOMRIGHT", -28, 30)

    local scrollBar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 4, 0)

    local scrollView = CreateScrollBoxListLinearView()
    scrollView:SetElementExtent(ROW_HEIGHT)

    scrollView:SetElementInitializer("Frame", function(row, data)
        self:InitRow(row, data)
    end)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, scrollView)

    dataProvider = CreateDataProvider()
    scrollBox:SetDataProvider(dataProvider)
end

---------------------------------------------------------------------------
-- Row initialization (called by ScrollBox for each visible row)
---------------------------------------------------------------------------

function MainFrame:InitRow(row, data)
    if not row.initialized then
        self:SetupRowWidgets(row)
        row.initialized = true
    end

    self:SetRowData(row, data)
end

function MainFrame:SetupRowWidgets(row)
    row:SetHeight(ROW_HEIGHT)

    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.1)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("LEFT", 4, 0)
    row.icon:SetSize(24, 24)

    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.nameText:SetPoint("LEFT", 34, 0)
    row.nameText:SetWidth(176)
    row.nameText:SetJustifyH("LEFT")

    row.ilvlText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.ilvlText:SetPoint("LEFT", 210, 0)
    row.ilvlText:SetWidth(45)
    row.ilvlText:SetJustifyH("LEFT")

    row.slotText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.slotText:SetPoint("LEFT", 255, 0)
    row.slotText:SetWidth(75)
    row.slotText:SetJustifyH("LEFT")

    row.statsText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.statsText:SetPoint("LEFT", 330, 0)
    row.statsText:SetWidth(110)
    row.statsText:SetJustifyH("LEFT")

    row.dungeonText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.dungeonText:SetPoint("LEFT", 440, 0)
    row.dungeonText:SetWidth(150)
    row.dungeonText:SetJustifyH("LEFT")

    row.bossText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.bossText:SetPoint("LEFT", 590, 0)
    row.bossText:SetWidth(140)
    row.bossText:SetJustifyH("LEFT")

    row.deltaText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.deltaText:SetPoint("LEFT", 730, 0)
    row.deltaText:SetWidth(50)
    row.deltaText:SetJustifyH("LEFT")

    row.ownedText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.ownedText:SetPoint("LEFT", 780, 0)
    row.ownedText:SetWidth(50)
    row.ownedText:SetJustifyH("LEFT")

    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        if self.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local ok = pcall(GameTooltip.SetHyperlink, GameTooltip, self.itemLink)
            if ok then
                GameTooltip:Show()
            end
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    row:SetScript("OnMouseUp", function(self, button)
        if IsModifiedClick("CHATLINK") and self.itemLink then
            ChatEdit_InsertLink(self.itemLink)
        end
    end)
end

function MainFrame:SetRowData(row, item)
    row.itemLink = item.itemLink

    if item.icon then
        row.icon:SetTexture(item.icon)
        row.icon:Show()
    else
        row.icon:Hide()
    end

    row.nameText:SetText(item.itemLink or item.name or "Loading...")
    row.ilvlText:SetText(item.ilvl > 0 and tostring(item.ilvl) or "?")
    row.slotText:SetText(EquipMap:GetSlotName(item.slotID))
    row.statsText:SetText(EquipMap:FormatStatNames(item))
    row.dungeonText:SetText(item.dungeonName or "")
    row.bossText:SetText(item.encounterName or "")
    row.deltaText:SetText(EquipMap.Compare:FormatDelta(item.ilvlDelta))

    if item.owned then
        row.ownedText:SetText(EquipMap.COLORS.OWNED .. "Yes" .. EquipMap.COLORS.RESET)
    else
        row.ownedText:SetText("")
    end
end

---------------------------------------------------------------------------
-- Dungeon dropdown (initialized after data load)
---------------------------------------------------------------------------

function MainFrame:InitDungeonDropdown()
    local dropdown = self.dungeonDropdown
    if not dropdown then return end

    local selectedDungeon = 0

    dropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:CreateRadio(
            "All Dungeons",
            function() return selectedDungeon == 0 end,
            function()
                selectedDungeon = 0
                EquipMap.Filters:SetDungeon(nil)
                MainFrame:Refresh()
            end
        )

        local dungeons = EquipMap.Data:GetDungeonList()
        for _, d in ipairs(dungeons) do
            rootDescription:CreateRadio(
                d.name,
                function() return selectedDungeon == d.instanceID end,
                function()
                    selectedDungeon = d.instanceID
                    EquipMap.Filters:SetDungeon(d.instanceID)
                    MainFrame:Refresh()
                end
            )
        end
    end)
end

---------------------------------------------------------------------------
-- Refresh / Toggle
---------------------------------------------------------------------------

function MainFrame:Refresh()
    if not frame or not frame:IsShown() then return end

    local filteredItems = EquipMap.Filters:GetFilteredItems()

    -- Replace DataProvider in one shot instead of Flush + Insert loop
    dataProvider = CreateDataProvider(filteredItems)
    scrollBox:SetDataProvider(dataProvider)

    local totalItems = #EquipMap.db.items
    statusText:SetText(string.format("Showing %d / %d items", #filteredItems, totalItems))
end

function MainFrame:Toggle()
    if not frame then
        self:Create()
    end

    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        self:Refresh()
    end
end

function MainFrame:Show()
    if not frame then
        self:Create()
    end
    frame:Show()
    self:Refresh()
end

function MainFrame:Hide()
    if frame then
        frame:Hide()
    end
end

function MainFrame:IsShown()
    return frame and frame:IsShown()
end
