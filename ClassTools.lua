local ADDON_NAME, KN = ...

-- Spell IDs are used only to detect which utility the current character actually knows.
-- The addon never watches casts or reacts to combat events.
local CLASS_TOOLS = {
    DEATHKNIGHT = {
        interrupt = { 47528 },                 -- Mind Freeze
        stop = { 108194, 49576 },              -- Asphyxiate, Death Grip
    },
    DEMONHUNTER = {
        interrupt = { 183752 },                -- Disrupt
        stop = { 179057, 202137 },             -- Chaos Nova, Sigil of Silence
        purge = { 278326 },                    -- Consume Magic
    },
    DRUID = {
        interrupt = { 106839, 78675 },         -- Skull Bash, Solar Beam
        stop = { 99, 132469 },                 -- Incapacitating Roar, Typhoon
    },
    EVOKER = {
        interrupt = { 351338 },                -- Quell
        stop = { 368970, 357214 },             -- Tail Swipe, Wing Buffet
    },
    HUNTER = {
        interrupt = { 147362, 187707 },        -- Counter Shot, Muzzle
        stop = { 19577 },                      -- Intimidation
        purge = { 19801 },                     -- Tranquilizing Shot
    },
    MAGE = {
        interrupt = { 2139 },                  -- Counterspell
        stop = { 31661, 157981, 118 },         -- Dragon's Breath, Blast Wave, Polymorph
        purge = { 30449 },                     -- Spellsteal
    },
    MONK = {
        interrupt = { 116705 },                -- Spear Hand Strike
        stop = { 119381, 116844 },             -- Leg Sweep, Ring of Peace
    },
    PALADIN = {
        interrupt = { 96231 },                 -- Rebuke
        stop = { 853, 115750 },                -- Hammer of Justice, Blinding Light
    },
    PRIEST = {
        interrupt = { 15487 },                 -- Silence
        stop = { 8122, 9484 },                 -- Psychic Scream, Shackle Undead
        purge = { 528 },                       -- Dispel Magic
    },
    ROGUE = {
        interrupt = { 1766 },                  -- Kick
        stop = { 408, 2094, 1776 },            -- Kidney Shot, Blind, Gouge
    },
    SHAMAN = {
        interrupt = { 57994 },                 -- Wind Shear
        stop = { 192058, 51490 },              -- Capacitor Totem, Thunderstorm
        purge = { 370 },                       -- Purge
    },
    WARLOCK = {
        interrupt = { 19647 },                 -- Spell Lock
        stop = { 30283, 89766 },               -- Shadowfury, Axe Toss
        purge = { 19505 },                     -- Devour Magic
    },
    WARRIOR = {
        interrupt = { 6552 },                  -- Pummel
        stop = { 107570, 46968, 5246 },        -- Storm Bolt, Shockwave, Intimidating Shout
    },
}

-- Friendly dispels are deliberately type-aware. Knowing *a* dispel spell is
-- not enough: Windwalker Detox handles Poison/Disease, for example, but cannot
-- remove Magic. Candidate lists contain current/alternate spell IDs so we can
-- simply use whichever spell the logged-in character actually knows.
local FRIENDLY_DISPEL_TOOLS = {
    DRUID = {
        magic   = { 88423, 311698 },            -- Nature's Cure (Restoration variants)
        poison  = { 2782, 440015, 88423, 311698 }, -- Remove Corruption / Nature's Cure
        curse   = { 2782, 440015, 88423, 311698 },
    },
    EVOKER = {
        magic   = { 360823 },                   -- Naturalize
        poison  = { 365585, 360823, 374251 },   -- Expunge / Naturalize / Cauterizing Flame
        disease = { 374251 },                   -- Cauterizing Flame
        curse   = { 374251 },
        bleed   = { 374251 },
    },
    MAGE = {
        curse   = { 475 },                      -- Remove Curse
    },
    MONK = {
        magic   = { 115450 },                   -- Mistweaver Detox variant
        poison  = { 218164, 115450 },           -- Detox
        disease = { 218164, 115450 },
    },
    PALADIN = {
        magic   = { 4987, 311715 },             -- Cleanse (Holy variants)
        poison  = { 213644, 440013, 4987, 311715 }, -- Cleanse Toxins / Cleanse
        disease = { 213644, 440013, 4987, 311715 },
    },
    PRIEST = {
        magic   = { 527, 32375 },               -- Purify / Mass Dispel
        disease = { 213634, 527 },              -- Purify Disease / Purify
    },
    SHAMAN = {
        magic   = { 77130, 254420 },            -- Purify Spirit variants
        curse   = { 51886, 440012, 77130, 254420 }, -- Cleanse Spirit / Purify Spirit
        poison  = { 383013 },                   -- Poison Cleansing Totem
    },
}

local function isKnown(spellID)
    if IsPlayerSpell and IsPlayerSpell(spellID) then
        return true
    end

    if C_SpellBook and C_SpellBook.IsSpellKnown then
        local ok, result = pcall(C_SpellBook.IsSpellKnown, spellID)
        if ok and result then
            return true
        end
    end

    return false
end

local function getSpellName(spellID)
    if C_Spell and C_Spell.GetSpellName then
        local ok, result = pcall(C_Spell.GetSpellName, spellID)
        if ok and result then
            return result
        end
    end

    if GetSpellInfo then
        return GetSpellInfo(spellID)
    end

    return nil
end

local function getKnownTool(spellIDs)
    for _, spellID in ipairs(spellIDs or {}) do
        if isKnown(spellID) then
            return getSpellName(spellID) or ("Spell " .. spellID)
        end
    end
    return nil
end

function KN:GetToolForEntry(entry)
    if entry.action == "watch" then
        return nil, true
    end

    -- Friendly dispel compatibility depends on the debuff type. Until a row is
    -- explicitly tagged, do not pretend the current spec can or cannot remove it.
    if entry.action == "dispel" and not entry.dispelType then
        return nil, nil
    end

    local _, classFile = UnitClass("player")

    if entry.action == "dispel" and entry.dispelType then
        local dispelType = string.lower(entry.dispelType)
        local classMap = classFile and FRIENDLY_DISPEL_TOOLS[classFile]
        local candidates = classMap and classMap[dispelType]

        if candidates then
            local toolName = getKnownTool(candidates)
            if toolName then
                return toolName, true
            end
        end

        -- A verified dispel type with no known matching tool is a group job for
        -- this character/spec. We intentionally do not generalize self-immunities
        -- such as Cloak of Shadows into friendly dispels.
        return nil, false
    end

    local classTools = classFile and CLASS_TOOLS[classFile]
    if not classTools then
        return nil, nil
    end

    local tools = classTools[entry.action]
    if not tools then
        return nil, false
    end

    local toolName = getKnownTool(tools)
    if toolName then
        return toolName, true
    end

    return nil, false
end
