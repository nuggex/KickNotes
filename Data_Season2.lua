local ADDON_NAME, KN = ...

-- Curated on 2026-09-23 for WoW Midnight 12.1 / Season 2.
-- Dungeon rows are based on current Season 2 guide sections explicitly listing
-- important interrupts, dispels and purges. Additional STOP rows are only added
-- when the guide specifically calls out crowd control as the intended answer.

local function E(action, spell, mob, where, note, priority, dispelType)
    return {
        action = action,
        spell = spell,
        mob = mob,
        where = where,
        note = note,
        priority = priority or 2,
        dispelType = dispelType,
    }
end

local function W(title, note, priority)
    return {
        action = "watch",
        title = title,
        note = note,
        priority = priority or 2,
    }
end

-- MUST STOP is intentionally separate from priority. A mechanic can be Essential
-- without being catastrophic if missed. Use M() only for mechanics where failing
-- the stop can cause deaths, severe group-wide damage, or a major pull failure.
local function M(action, spell, mob, where, note, priority, dispelType)
    local entry = E(action, spell, mob, where, note, priority or 3, dispelType)
    entry.mustStop = true
    return entry
end

KN:RegisterContent({
    id = "midnight-s2-altar-of-fangs",
    name = "Altar of Fangs",
    type = "dungeon",
    season = "Midnight Season 2",
    currentSeason = true,
    entries = {
        E("interrupt", "Piercing Hiss", "Primal Serpent", "T1", "Priority kick."),
        E("interrupt", "Toxic Atrophy", "The Writhing Coil", "B2", "Boss casts it three times in succession.", 3),
        E("interrupt", "Mass Envenom", "Ula'tek's Chosen", "T3", "Priority kick; also dispellable if one gets through.", 3),
        E("dispel", "Paralyzing Shots", "Twinfang Harrower", "T1", "Magic DoT/snare. Remove it with a Magic dispel; personal movement-clears may also help with the snare.", nil, "magic"),
        E("dispel", "Regurgitate", "Rav'i", "B1", "Disease from failing the frontal. Remove it with a Disease dispel.", nil, "disease"),
        E("dispel", "Envenom", "High Evolutionist", "T2", "Poison. Interrupt/CC the source or remove it with a Poison dispel.", nil, "poison"),
        E("purge", "Ravenous Claws", "Ravenous Descendant", "T1", "Remove the enemy buff."),
        M("stop", "Evolve", "High Evolutionist", "T2", "Guide specifically recommends crowd control to stop this cast.", 3),
    },
})

KN:RegisterContent({
    id = "midnight-s2-murder-row",
    name = "Murder Row",
    type = "dungeon",
    season = "Midnight Season 2",
    currentSeason = true,
    entries = {
        E("interrupt", "Fel Missiles", "Felonious Mage", "T1", "Priority kick."),
        E("interrupt", "Seduction", "Seductive Sayaad", "T1", "Stop the control cast."),
        M("interrupt", "Felstorm", "Kystia Manaheart / Mirror Images", "B1", "The mirror images cast this; interrupt the images because the channel pulses damage across the group.", 3),
        E("interrupt", "Fel Rage", "Wrathguard Flayer", "T3", "Prevents a large damage-reduction effect.", 3),
        E("interrupt", "Health Funnel", "Fel Invoker", "T3", "Stop the heal/channel."),
        E("interrupt", "Chaos Bolt", "Lithiel Cinderfury", "B4", "High damage if it completes.", 3),
        E("dispel", "Corroding Spittle", "Massive Felwyrm / Kystia Manaheart", "T1/B1", "Magic DoT. Remove it with a Magic dispel.", nil, "magic"),
        E("dispel", "Heartstop Poison", "Zaen Bladesorrow", "B2", "Poison tank debuff. Remove it with a Poison dispel.", nil, "poison"),
        E("dispel", "Curse of Doom", "Corrupted Warlock", "T3", "Curse. Remove it with a Curse dispel.", nil, "curse"),
        E("purge", "Back to Work!", "Keen Taskmaster", "T2", "Remove the enemy buff."),
    },
})

KN:RegisterContent({
    id = "midnight-s2-den-of-nalorakk",
    name = "Den of Nalorakk",
    type = "dungeon",
    season = "Midnight Season 2",
    currentSeason = true,
    entries = {
        E("interrupt", "Scavenge", "Keen-Eyed Striker", "T1", "Priority kick."),
        E("interrupt", "Healing Breeze", "Earthwhisper Tender", "T1", "Stop the heal."),
        E("interrupt", "Frigid Roar", "Frigid Mauler", "T2", "Priority kick."),
        E("interrupt", "Winter's Shroud", "Sentinel of Winter", "B2", "Interrupt the add cast.", 3),
        E("interrupt", "Arc Lightning", "Stormbound Mystic", "T3", "Priority kick."),
        E("dispel", "Insatiable Hunger", "Spirit of Hunger", "T1", "Remove the debuff."),
        E("dispel", "Toxic Spores", "The Hoardmonger", "B1", "Poison debuff. Remove it with a Poison dispel.", nil, "poison"),
        E("dispel", "Cryo Surge", "Glacial Revenant", "T2", "Magic debuff. Remove it with a Magic dispel.", nil, "magic"),
        E("dispel", "Glacial Torment", "Sentinel of Winter", "B2", "Magic debuff. Remove it with a Magic dispel.", 3, "magic"),
        E("purge", "Healing Breeze", "Earthwhisper Tender", "T1", "Purge if the cast gets through."),
        E("purge", "Mother's Wrath", "Territorial Matriarch", "T1", "Remove the enemy buff."),
        E("purge", "Bestial Wrath", "Bonded Beasttamer", "T3", "Remove the enemy buff."),
    },
})

KN:RegisterContent({
    id = "midnight-s2-blinding-vale",
    name = "The Blinding Vale",
    type = "dungeon",
    season = "Midnight Season 2",
    currentSeason = true,
    aliases = { "Blinding Vale" },
    entries = {
        E("interrupt", "Light Bolt Volley", "Radiant Spellsower", "T1", "Priority kick.", 3),
        E("interrupt", "Light Bolt", "Kezkitt", "B1", "Priority kick."),
        E("interrupt", "Disorienting Screech", "Lightfeather Petalwing", "T2", "Stop the disorient."),
        E("interrupt", "Warden's Wrath", "Lightwarden Ruia", "B3", "Boss interrupt."),
        E("interrupt", "Lightspore Shot", "Ziekket", "B4", "Boss interrupt."),
        E("dispel", "Bloodthorn Roots", "Ikuzz the Light Hunter", "B2", "Root effect listed as dispellable."),
    },
})

KN:RegisterContent({
    id = "midnight-s2-voidscar-arena",
    name = "Voidscar Arena",
    type = "dungeon",
    season = "Midnight Season 2",
    currentSeason = true,
    entries = {
        E("interrupt", "Demoralizing Shout", "Dominated Brawler", "T1", "Priority kick."),
        M("interrupt", "Shadowbolt Volley", "Voidtouched Magi", "T1", "Group-wide damage cast. Treat this as a must-stop whenever possible.", 3),
        E("interrupt", "Violent Sand", "Angry Krolusk", "T1", "Priority kick."),
        E("interrupt", "Mad Shriek", "Killvore Screamer", "T2", "Priority kick."),
        E("interrupt", "Mending Void", "Voidminder", "T3", "Stop the heal.", 3),
        E("dispel", "Melt Armor", "Sycophantic Tarasek", "T1", "Magic debuff. Remove it with a Magic dispel.", nil, "magic"),
        E("dispel", "Corrosive Essence", "Agitated Voidscythe", "T2", "Poison. Remove it with a Poison dispel.", nil, "poison"),
        E("purge", "Bolster", "Longtooth Tuskarr", "T1", "Remove the enemy buff."),
    },
})

KN:RegisterContent({
    id = "midnight-s2-ruby-life-pools",
    name = "Ruby Life Pools",
    type = "dungeon",
    season = "Midnight Season 2",
    currentSeason = true,
    entries = {
        E("interrupt", "Ice Shield", "Flashfrost Chillweaver", "T1", "Priority kick; the Chillweaver is a key caster.", 3),
        E("interrupt", "Frigid Shard", "Melidrussa Chillworn", "B1", "Interruptible tank hit."),
        E("interrupt", "Fiery Blast", "Blazebound Destroyer", "T2", "Priority kick."),
        M("interrupt", "Blaze Volley", "Kokia Blazehoof encounter add", "B2", "The summoned add blasts the whole group if this completes. Interrupt it.", 3),
        E("dispel", "Cold Claws", "Infused Whelp", "T1/B1", "Magic debuff on the tank. Remove it with a Magic dispel.", nil, "magic"),
        E("dispel", "Rolling Thunder", "Thunderhead", "T2", "Magic debuff. Coordinate dispels because removal triggers Electrical Discharge.", nil, "magic"),
        E("dispel", "Stormslam", "Erkhart Stormvein", "B3", "Magic vulnerability on the tank. Remove it with a Magic dispel.", nil, "magic"),
        E("purge", "Blaze of Glory", "Ashseer Flamelasher", "T2", "Remove the enemy buff."),
        E("purge", "Stormcloud Barrier", "Primal Thundercloud", "T3", "Remove the enemy shield."),
    },
})

KN:RegisterContent({
    id = "midnight-s2-temple-of-sethraliss",
    name = "Temple of Sethraliss",
    type = "dungeon",
    season = "Midnight Season 2",
    currentSeason = true,
    entries = {
        E("interrupt", "Poisoned Cheap Shot", "Shrouded Fang", "T1", "Priority kick."),
        E("interrupt", "Addle Mind", "Faithless Subjugator", "T2", "Priority kick."),
        E("interrupt", "Poison Spit", "Merektha", "B2", "Boss interrupt."),
        E("interrupt", "Essence Disruption", "Temple Disruptor", "T4", "Priority kick or stop."),
        E("interrupt", "Flame Shock", "Twisted Hexxer", "T4/B4", "Priority kick."),
        E("dispel", "Cytotoxin", "Poisonous Viper", "T2", "Poison debuff. Remove it with a Poison dispel.", nil, "poison"),
        E("dispel", "Imbued Conduction", "Imbued Stormcaller", "T3", "Magic debuff. Dispel it before it expires and stuns the target.", nil, "magic"),
        E("purge", "Accumulate Charge", "Agitated Nimbus", "T3", "Remove the enemy buff.", 3),
        M("stop", "Essence Disruption", "Temple Disruptor", "T4", "Crowd control this channel so the Eye can keep gaining energy and the gauntlet can progress.", 3),
    },
})

KN:RegisterContent({
    id = "midnight-s2-kings-rest",
    name = "Kings' Rest",
    type = "dungeon",
    season = "Midnight Season 2",
    currentSeason = true,
    aliases = { "King's Rest", "Kings Rest" },
    entries = {
        E("interrupt", "Hex Volley", "Risen Hexer", "T1", "Priority kick.", 3),
        E("interrupt", "Bind Soul", "Queen Wasi", "T2", "Priority kick."),
        E("interrupt", "Unholy Mending", "Seneschal M'bara", "T2", "Stop the heal.", 3),
        E("interrupt", "Wretched Discharge", "Half-Finished Mummy", "T2", "Priority kick."),
        E("interrupt", "Hex", "Phantom Hex Priest", "T3", "Stop the control cast."),
        M("interrupt", "Poison Nova", "Zanazal the Wise", "B3", "Large group-wide AoE. Treat this as a must-stop.", 3),
        E("interrupt", "Deathly Roar", "Reban", "B4", "AoE fear; interrupt.", 3),
        E("dispel", "Lingering Fluid", "Embalming Fluid", "T2", "Poison. Remove it with a Poison dispel.", nil, "poison"),
        E("dispel", "Putrid Seekers", "Embalming Fluid", "T2", "Poison. Remove it with a Poison dispel.", nil, "poison"),
        E("purge", "Bound by Shadow", "Minion of Zul", "T1", "Purge can instantly deal with the protected add.", 3),
        E("purge", "Ancestral Fury", "Shadow-Borne Champion", "T1", "Remove the enemy buff."),
        E("purge", "Bestial Berserk", "Queen Patlaa", "T2", "Remove the enemy buff."),
        E("purge", "Captain's Bulwark", "Guard Captain Atu", "T2", "Remove the enemy defensive."),
    },
})

-- Raid: intentionally static, pre-authored reminders. No combat-log analysis.
local RAID_ID = "midnight-s2-venomous-abyss"
KN:RegisterContent({
    id = RAID_ID,
    name = "The Venomous Abyss",
    type = "raid",
    season = "Midnight Season 2",
    currentSeason = true,
    entries = {
        W("Nek'zali", "Keep deaths and Restless Amani away from the Soulcoil Well. Move Essence Rend to the edge before dispel."),
        W("Entombed Sentinels", "Keep the bosses separated; dispel Blighted Blood and handle the numbered toxin pairing correctly."),
        W("The Lost Explorers", "Feed Disgusting Fish before Final Ascension completes; keep the soak assignments straight."),
        W("Vashnik", "Track which two fountains are consumed by Imbibe so one venom type is not over-empowered."),
        W("Sszorak", "Respect the pushbacks and tornado lanes; Dig In is the big damage window."),
        W("The Twin Fangs", "Manage Eternal Venom stacks and use Ravenous Feast soaks to remove stacks."),
        W("The Coiled Altar", "Control Coalesced Venom and be ready for the Zul'jan / Malacrass phase transitions."),
        W("Ula'tek", "Break eggs before they hatch empowered adds; keep venom away from eggs."),
    },
    encounters = {
        [KN.NormalizeName("Nek'zali the Soulcoiler")] = {
            W("Soulcoil Well", "Do not die in the well and do not let Restless Amani reach it.", 3),
            W("Essence Rend", "Move to the edge, then call for the dispel so the puddle lands safely.", 3),
        },
        [KN.NormalizeName("Entombed Sentinels")] = {
            W("Boss spacing", "Keep the two Sentinels separated so their dominance aura does not protect them.", 3),
            W("Blighted Blood", "Dispel quickly."),
            W("Helical Toxins", "Pair with the player whose orb count combines with yours to the required total."),
        },
        [KN.NormalizeName("The Lost Explorers")] = {
            W("Final Ascension", "Feed a Disgusting Fish to a possessed tortollan before the cast completes.", 3),
            W("Soaks", "Remember your assigned soak group."),
        },
        [KN.NormalizeName("Vashnik the Malignant")] = {
            W("Imbibe", "Watch which two fountains are consumed; repeated Infusion stacks amplify matching mechanics.", 3),
            W("Adds", "The fight includes priority adds, so avoid tunneling the boss."),
        },
        [KN.NormalizeName("Sszorak")] = {
            W("The Winds", "Read the tornado sections and be ready for repeated forced movement.", 3),
            W("Dig In", "This is the major boss damage window; save damage cooldowns for it."),
        },
        [KN.NormalizeName("The Twin Fangs")] = {
            W("Eternal Venom", "Do not let your stacks reach the lethal threshold.", 3),
            W("Ravenous Feast", "Use the assigned soak to remove Venom stacks."),
            W("Venomous Emergence", "Kill the adds before they add more Venom pressure."),
        },
        [KN.NormalizeName("The Coiled Altar")] = {
            W("Coalesced Venom", "Collect and place venom deliberately instead of letting the room fill randomly."),
            W("Phase 3", "The final phase brings Zul'jan and Malacrass together; be ready for the combined mechanics.", 3),
        },
        [KN.NormalizeName("Ula'tek")] = {
            W("Eggs", "Break eggs before they hatch empowered adds. Venom touching an egg is bad.", 3),
            W("Area denial", "Keep lanes usable through Caustic Waves and Circling Prey."),
        },
    },
})
