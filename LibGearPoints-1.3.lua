-- A library to compute Gear Points for items as described in

local MAJOR_VERSION = "LibGearPoints-1.3"
local MINOR_VERSION = 10300

local lib, oldMinor = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then return end

local Debug = LibStub("LibDebug-1.0")
local ItemUtils = LibStub("LibItemUtils-1.0")
local LN = LibStub("LibLocalConstant-1.0")

-- Return recommended parameters
function lib:GetRecommendIlvlParams(version, levelCap)
  local standardIlvl
  local standardIlvlLastTier
  local standardIlvlNextTier
  local ilvlDenominator = 26 -- how much ilevel difference from standard affects cost, higher values mean less effect
  local version = version or select(4, GetBuildInfo())
  local levelCap = levelCap or MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()]

  --MagDev: wondering if this is 'vanilla' 
  --/g if version < 11303 then
  --  standardIlvl = 66
  --  standardIlvlLastTier = nil
  --  standardIlvlNextTier = 76
  --  ilvlDenominator = 10
  
  -- MagDev: "Classic" current version is 11304 -- So this would be values we utilize
  --elseif version < 20200 then
    standardIlvl = 76
    standardIlvlLastTier = 66
    standardIlvlNextTier = 86
    ilvlDenominator = 10
  --end

  return standardIlvl, standardIlvlLastTier, standardIlvlNextTier, ilvlDenominator
end

-- Used to display GP values directly on tier tokens; keys are itemIDs,
-- values are:
-- 1. rarity, int, 4 = epic
-- 2. ilvl, int
-- 3. inventory slot, string
-- 4. an optional boolean value indicating heroic/mythic ilvl should be
--    derived from the bonus list rather than the raw ilvl
--    (mainly for T17+ tier gear)
-- 5. faction (Horde/Alliance), string
local CUSTOM_ITEM_DATA = {
  -- Classic P2
  [17204] = { 5, 80, "INVTYPE_2HWEAPON" },
  [18422] = { 4, 74, "INVTYPE_NECK", nil, "Horde" }, -- Head of Onyxia
  [18423] = { 4, 74, "INVTYPE_NECK", nil, "Alliance" }, -- Head of Onyxia
  [18563] = { 5, 80, "INVTYPE_WEAPON" }, -- Legendary Sward
  [18564] = { 5, 80, "INVTYPE_WEAPON" }, -- Legendary Sward
  [18646] = { 4, 75, "INVTYPE_2HWEAPON" }, -- The Eye of Divinity
  [18703] = { 4, 75, "INVTYPE_RANGED" }, -- Ancient Petrified Leaf

  -- Classic P3
  [19002] = { 4, 83, "INVTYPE_NECK", nil, "Horde" },
  [19003] = { 4, 83, "INVTYPE_NECK", nil, "Alliance" },

  -- Classic P5
  [20928] = { 4, 78, "INVTYPE_SHOULDER" }, -- T2.5 shoulder, feet
  [20932] = { 4, 78, "INVTYPE_SHOULDER" }, -- T2.5 shoulder, feet
  [20930] = { 4, 81, "INVTYPE_HEAD" },     -- T2.5 head
  [20926] = { 4, 81, "INVTYPE_HEAD" },     -- T2.5 head
  [20927] = { 4, 81, "INVTYPE_LEGS" },     -- T2.5 legs
  [20931] = { 4, 81, "INVTYPE_LEGS" },     -- T2.5 legs
  [20929] = { 4, 81, "INVTYPE_CHEST" },    -- T2.5 chest
  [20933] = { 4, 81, "INVTYPE_CHEST" },    -- T2.5 chest
  [21221] = { 4, 88, "INVTYPE_NECK" },     -- 克苏恩之眼
  [21232] = { 4, 79, "INVTYPE_WEAPON" },   -- 其拉帝王武器
  [21237] = { 4, 79, "INVTYPE_2HWEAPON" }, -- 其拉帝王徽记

  -- Classic P6
  [22349] = { 4, 88, "INVTYPE_CHEST" },
  [22350] = { 4, 88, "INVTYPE_CHEST" },
  [22351] = { 4, 88, "INVTYPE_CHEST" },
  [22352] = { 4, 88, "INVTYPE_LEGS" },
  [22359] = { 4, 88, "INVTYPE_LEGS" },
  [22366] = { 4, 88, "INVTYPE_LEGS" },
  [22353] = { 4, 88, "INVTYPE_HEAD" },
  [22360] = { 4, 88, "INVTYPE_HEAD" },
  [22367] = { 4, 88, "INVTYPE_HEAD" },
  [22354] = { 4, 88, "INVTYPE_SHOULDER" },
  [22361] = { 4, 88, "INVTYPE_SHOULDER" },
  [22368] = { 4, 88, "INVTYPE_SHOULDER" },
  [22355] = { 4, 88, "INVTYPE_WRIST" },
  [22362] = { 4, 88, "INVTYPE_WRIST" },
  [22369] = { 4, 88, "INVTYPE_WRIST" },
  [22356] = { 4, 88, "INVTYPE_WAIST" },
  [22363] = { 4, 88, "INVTYPE_WAIST" },
  [22370] = { 4, 88, "INVTYPE_WAIST" },
  [22357] = { 4, 88, "INVTYPE_HAND" },
  [22364] = { 4, 88, "INVTYPE_HAND" },
  [22371] = { 4, 88, "INVTYPE_HAND" },
  [22358] = { 4, 88, "INVTYPE_FEET" },
  [22365] = { 4, 88, "INVTYPE_FEET" },
  [22372] = { 4, 88, "INVTYPE_FEET" },
  [22520] = { 4, 90, "INVTYPE_TRINKET" }, -- 克尔苏加德的护符匣
  [22726] = { 5, 90, "INVTYPE_2HWEAPON" }, -- Legendary

}

function lib:GetCustomItemsDefault()
  return CUSTOM_ITEM_DATA
end

-- Used to add extra GP if the item contains bonus stats
-- generally considered chargeable. Sockets are very
-- valuable in early BFA.
local ITEM_BONUS_GP = {
  [40]  = 50,  -- avoidance
  [41]  = 50,  -- leech
  [42]  = 50,  -- speed
  [43]  = 0,  -- indestructible, no material value
  [523] = 300, -- extra socket
  [563] = 300, -- extra socket
  [564] = 300, -- extra socket
  [565] = 300, -- extra socket
  [572] = 300, -- extra socket
  [1808] = 300, -- extra socket
}

-- The default quality threshold:
-- 0 - Poor
-- 1 - Uncommon
-- 2 - Common
-- 3 - Rare
-- 4 - Epic
-- 5 - Legendary
-- 6 - Artifact
local quality_threshold = 4

local recent_items_queue = {}
local recent_items_map = {}


-- Given a list of item bonuses, return the ilvl delta it represents
-- (15 for Heroic, 30 for Mythic)
local function GetItemBonusLevelDelta(itemBonuses)
  for _, value in pairs(itemBonuses) do
    -- Item modifiers for heroic are 566 and 570; mythic are 567 and 569
    if value == 566 or value == 570 then return 15 end
    if value == 567 or value == 569 then return 30 end
  end
  return 0
end

local function UpdateRecentLoot(itemLink)
  if recent_items_map[itemLink] then return end

  -- Debug("Adding %s to recent items", itemLink)
  table.insert(recent_items_queue, 1, itemLink)
  recent_items_map[itemLink] = true
  if #recent_items_queue > 15 then
    local itemLink = table.remove(recent_items_queue)
    -- Debug("Removing %s from recent items", itemLink)
    recent_items_map[itemLink] = nil
  end
end

function lib:GetNumRecentItems()
  return #recent_items_queue
end

function lib:GetRecentItemLink(i)
  return recent_items_queue[i]
end

--- Return the currently set quality threshold.
function lib:GetQualityThreshold()
  return quality_threshold
end

--- Set the minimum quality threshold.
-- @param itemQuality Lowest allowed item quality.
function lib:SetQualityThreshold(itemQuality)
  itemQuality = itemQuality and tonumber(itemQuality)
  if not itemQuality or itemQuality > 6 or itemQuality < 0 then
    return error("Usage: SetQualityThreshold(itemQuality): 'itemQuality' - number [0,6].", 3)
  end

  quality_threshold = itemQuality
end

function lib:GetValue(item)
  if not item then return end

  local _, itemLink, rarity, ilvl, _, _, itemSubClass, _, equipLoc = GetItemInfo(item)
  if not itemLink then return end

  -- Get the item ID to check against known token IDs
  local itemID = itemLink:match("item:(%d+)")
  
  -- MAGDEV: if there is no itemID - exit out
  Debug("itemID: %s", itemID)
  if not itemID then return end
  
  itemID = tonumber(itemID)
  
  -- Check to see if there is custom data for this item ID
  local customItem = EPGP.db.profile.customItems[itemID]
  if customItem then
    rarity = customItem.rarity
    ilvl = customItem.ilvl
    equipLoc = customItem.equipLoc
  else
    -- Is the item above our minimum threshold?
    if not rarity or rarity < quality_threshold then
      Debug("%s is below rarity threshold.", itemLink)
      return
    end
  end

  UpdateRecentLoot(itemLink)

  if equipLoc == "CUSTOM_SCALE" then
    local gp1, gp2 = self:CalculateGPFromScale(customItem.s1, customItem.s2, nil, ilvl, rarity)
    return gp1, "", gp2, ""
  elseif equipLoc == "CUSTOM_GP" then
    return customItem.gp1, "", customItem.gp2, ""
  else
    return self:CalculateGPFromEquipLoc(equipLoc, itemSubClass, ilvl, rarity)
  end


end

local LOCAL_NAME = LN:LocalName()

local switchRanged = {}
switchRanged[LOCAL_NAME.Bow]      = "ranged"
switchRanged[LOCAL_NAME.Gun]      = "ranged"
switchRanged[LOCAL_NAME.Crossbow] = "ranged"
switchRanged[LOCAL_NAME.Wand]     = "wand"
switchRanged[LOCAL_NAME.Thrown]   = "thrown"

local switchEquipLoc = {
  ["INVTYPE_HEAD"]            = "head",
  ["INVTYPE_NECK"]            = "neck",
  ["INVTYPE_SHOULDER"]        = "shoulder",
  ["INVTYPE_CHEST"]           = "chest",
  ["INVTYPE_ROBE"]            = "chest",
  ["INVTYPE_WAIST"]           = "waist",
  ["INVTYPE_LEGS"]            = "legs",
  ["INVTYPE_FEET"]            = "feet",
  ["INVTYPE_WRIST"]           = "wrist",
  ["INVTYPE_HAND"]            = "hand",
  ["INVTYPE_FINGER"]          = "finger",
  ["INVTYPE_TRINKET"]         = "trinket",
  ["INVTYPE_CLOAK"]           = "cloak",
  ["INVTYPE_WEAPON"]          = "weapon",
  ["INVTYPE_SHIELD"]          = "shield",
  ["INVTYPE_2HWEAPON"]        = "weapon2H",
  ["INVTYPE_WEAPONMAINHAND"]  = "weaponMainH",
  ["INVTYPE_WEAPONOFFHAND"]   = "weaponOffH",
  ["INVTYPE_HOLDABLE"]        = "holdable",
  ["INVTYPE_RANGED"]          = "ranged", 
  ["INVTYPE_THROWN"]          = "ranged",
  ["INVTYPE_RELIC"]           = "relic",
  ["INVTYPE_WAND"]            = "wand", 
}

function lib:GetScale(equipLoc, subClass)
  local name = switchEquipLoc[equipLoc] or switchRanged[subClass]
  if name then
    local vars = EPGP:GetModule("points").db.profile
    local s1 = vars[name .. "Scale1"] or 0; local c1 = vars[name .. "Comment1"] or ""
    local s2 = vars[name .. "Scale2"] or 0; local c2 = vars[name .. "Comment2"] or ""
    local s3 = vars[name .. "Scale3"] or 0; local c3 = vars[name .. "Comment3"] or ""
    if s1 == 0 and c1 == "" then s1 = nil; c1 = nil; end
    if s2 == 0 and c2 == "" then s2 = nil; c2 = nil; end
    if s3 == 0 and c3 == "" then s3 = nil; c3 = nil; end
    return s1, c1, s2, c2, s3, c3
  end
end

function lib:CalculateGPFromScale(s1, s2, s3, ilvl, rarity)
  local vars = EPGP:GetModule("points").db.profile

  local baseGP = vars.baseGP
  local standardIlvl = vars.standardIlvl
  local ilvlDenominator = vars.ilvlDenominator
  local multiplier = baseGP * 2 ^ (-standardIlvl / ilvlDenominator)
  if rarity == 5 then multiplier = multiplier * vars.legendaryScale end
  local gpBase = multiplier * 2 ^ (ilvl / ilvlDenominator)

  local gp1 = (s1 and math.floor(0.5 + gpBase * s1)) or nil
  local gp2 = (s2 and math.floor(0.5 + gpBase * s2)) or nil
  local gp3 = (s3 and math.floor(0.5 + gpBase * s3)) or nil

  return gp1, gp2, gp3
end

function lib:CalculateGPFromEquipLoc(equipLoc, subClass, ilvl, rarity)
  local s1, c1, s2, c2, s3, c3 = self:GetScale(equipLoc, subClass)
  local gp1, gp2, gp3 = self:CalculateGPFromScale(s1, s2, s3, ilvl, rarity)
  return gp1, c1, gp2, c2, gp3, c3, s1, s2, s3
end
