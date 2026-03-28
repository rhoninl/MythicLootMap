-- EquipMap Filter Logic

local ADDON_NAME, ns = ...
local EquipMap = ns

local Filters = {}
EquipMap.Filters = Filters

-- Current active filter state
Filters.current = {
    slotID = nil,        -- nil = all slots
    instanceID = nil,    -- nil = all dungeons
    upgradesOnly = false,
    notCollected = false,
    specFilter = false,  -- use EJ class/spec filter
}

function Filters:Apply(items, filterOverrides)
    local filters = filterOverrides or self.current
    local result = {}

    for _, item in ipairs(items) do
        if self:MatchesFilters(item, filters) then
            result[#result + 1] = item
        end
    end

    return result
end

function Filters:MatchesFilters(item, filters)
    -- Slot filter
    if filters.slotID and filters.slotID > 0 then
        if not self:MatchesSlot(item, filters.slotID) then
            return false
        end
    end

    -- Dungeon filter
    if filters.instanceID and filters.instanceID > 0 then
        if item.instanceID ~= filters.instanceID then
            return false
        end
    end

    -- Upgrades only
    if filters.upgradesOnly then
        if not item.ilvlDelta or item.ilvlDelta <= 0 then
            return false
        end
    end

    -- Not collected (transmog not owned)
    if filters.notCollected then
        if item.owned then
            return false
        end
    end

    return true
end

function Filters:MatchesSlot(item, filterSlotID)
    if item.slotID == filterSlotID then
        return true
    end

    -- Ring: slotID 11 or 12 should match filter for either
    if filterSlotID == 11 and item.slotID == 12 then return true end
    if filterSlotID == 12 and item.slotID == 11 then return true end

    -- Trinket: slotID 13 or 14 should match filter for either
    if filterSlotID == 13 and item.slotID == 14 then return true end
    if filterSlotID == 14 and item.slotID == 13 then return true end

    return false
end

function Filters:Reset()
    self.current.slotID = nil
    self.current.instanceID = nil
    self.current.upgradesOnly = false
    self.current.notCollected = false
    self.current.specFilter = false
end

function Filters:SetSlot(slotID)
    self.current.slotID = (slotID and slotID > 0) and slotID or nil
end

function Filters:SetDungeon(instanceID)
    self.current.instanceID = (instanceID and instanceID > 0) and instanceID or nil
end

function Filters:SetUpgradesOnly(enabled)
    self.current.upgradesOnly = enabled
end

function Filters:SetNotCollected(enabled)
    self.current.notCollected = enabled
end

function Filters:SetSpecFilter(enabled)
    self.current.specFilter = enabled
end

function Filters:GetFilteredItems()
    return self:Apply(EquipMap.db.items, self.current)
end
