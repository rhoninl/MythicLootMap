-- EquipMap Utilities and Constants

local ADDON_NAME, ns = ...
local EquipMap = ns

-- Equipment location -> inventory slot ID (single slot items)
EquipMap.EQUIPLOC_TO_SLOT = {
    INVTYPE_HEAD = 1,
    INVTYPE_NECK = 2,
    INVTYPE_SHOULDER = 3,
    INVTYPE_CHEST = 5,
    INVTYPE_ROBE = 5,
    INVTYPE_WAIST = 6,
    INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8,
    INVTYPE_WRIST = 9,
    INVTYPE_HAND = 10,
    INVTYPE_CLOAK = 15,
    INVTYPE_2HWEAPON = 16,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_WEAPONOFFHAND = 17,
    INVTYPE_SHIELD = 17,
    INVTYPE_HOLDABLE = 17,
    INVTYPE_RANGED = 16,
    INVTYPE_RANGEDRIGHT = 16,
}

-- Equipment locations that map to multiple slots
EquipMap.MULTI_SLOT_EQUIPLOCS = {
    INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 },
    INVTYPE_WEAPON = { 16, 17 },
}

-- Armor type constants
EquipMap.ARMOR_TYPES = {
    Cloth = 1,
    Leather = 2,
    Mail = 3,
    Plate = 4,
}

-- Slot ID -> display name
EquipMap.SLOT_NAMES = {
    [1] = "Head",
    [2] = "Neck",
    [3] = "Shoulder",
    [5] = "Chest",
    [6] = "Waist",
    [7] = "Legs",
    [8] = "Feet",
    [9] = "Wrist",
    [10] = "Hands",
    [11] = "Ring",
    [12] = "Ring",
    [13] = "Trinket",
    [14] = "Trinket",
    [15] = "Back",
    [16] = "Main Hand",
    [17] = "Off Hand",
}

-- Unique slot IDs for filter dropdown (no duplicates)
EquipMap.FILTER_SLOTS = {
    { id = 0, name = "All Slots" },
    { id = 1, name = "Head" },
    { id = 2, name = "Neck" },
    { id = 3, name = "Shoulder" },
    { id = 15, name = "Back" },
    { id = 5, name = "Chest" },
    { id = 9, name = "Wrist" },
    { id = 10, name = "Hands" },
    { id = 6, name = "Waist" },
    { id = 7, name = "Legs" },
    { id = 8, name = "Feet" },
    { id = 11, name = "Ring" },
    { id = 13, name = "Trinket" },
    { id = 16, name = "Main Hand" },
    { id = 17, name = "Off Hand" },
}

-- M+ difficulty ID for Encounter Journal
EquipMap.MYTHIC_KEYSTONE_DIFFICULTY = 8

-- Midnight Season 1: M+ end-of-dungeon ilvl by key level
-- Key levels beyond +10 still drop +10 ilvl gear
EquipMap.MPLUS_ILVL_TABLE = {
    [0]  = 246, -- M0: Champion 1/6
    [2]  = 250, -- Champion 2/6
    [3]  = 250, -- Champion 2/6
    [4]  = 253, -- Champion 3/6
    [5]  = 256, -- Champion 4/6
    [6]  = 259, -- Hero 1/6
    [7]  = 259, -- Hero 1/6
    [8]  = 263, -- Hero 2/6
    [9]  = 263, -- Hero 2/6
    [10] = 266, -- Hero 3/6 (cap)
}

-- Midnight Season 1: Great Vault ilvl by key level
EquipMap.MPLUS_VAULT_ILVL_TABLE = {
    [0]  = 256, -- Champion 4/6
    [2]  = 259, -- Hero 1/6
    [3]  = 259, -- Hero 1/6
    [4]  = 263, -- Hero 2/6
    [5]  = 263, -- Hero 2/6
    [6]  = 266, -- Hero 3/6
    [7]  = 269, -- Hero 4/6
    [8]  = 269, -- Hero 4/6
    [9]  = 269, -- Hero 4/6
    [10] = 272, -- Myth 1/6
}

-- Default key level for ilvl display
EquipMap.selectedKeyLevel = 10

function EquipMap:GetMPlusIlvl(keyLevel)
    keyLevel = keyLevel or self.selectedKeyLevel
    if keyLevel > 10 then keyLevel = 10 end
    if keyLevel < 2 and keyLevel ~= 0 then keyLevel = 0 end
    return self.MPLUS_ILVL_TABLE[keyLevel] or self.MPLUS_ILVL_TABLE[10]
end

function EquipMap:GetVaultIlvl(keyLevel)
    keyLevel = keyLevel or self.selectedKeyLevel
    if keyLevel > 10 then keyLevel = 10 end
    if keyLevel < 2 and keyLevel ~= 0 then keyLevel = 0 end
    return self.MPLUS_VAULT_ILVL_TABLE[keyLevel] or self.MPLUS_VAULT_ILVL_TABLE[10]
end

-- Color codes
EquipMap.COLORS = {
    UPGRADE = "|cFF00FF00",    -- green
    DOWNGRADE = "|cFFFF0000",  -- red
    NEUTRAL = "|cFFFFFFFF",    -- white
    OWNED = "|cFF888888",      -- gray
    HEADER = "|cFFFFD100",     -- gold
    RESET = "|r",
}

function EquipMap:Print(msg)
    print(EquipMap.COLORS.HEADER .. "EquipMap:|r " .. msg)
end

function EquipMap:GetSlotName(slotID)
    return self.SLOT_NAMES[slotID] or "Unknown"
end

function EquipMap:ResolveSlotID(equipLoc)
    if not equipLoc then return nil end

    local multi = self.MULTI_SLOT_EQUIPLOCS[equipLoc]
    if multi then
        return multi[1]
    end

    return self.EQUIPLOC_TO_SLOT[equipLoc]
end
