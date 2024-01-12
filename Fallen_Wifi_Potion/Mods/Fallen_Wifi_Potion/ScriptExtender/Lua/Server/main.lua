--- @alias PotionType string |"small"|"greater"|"superior"|"supreme"


Ext.Require("Server/_ModInfos.lua")
Ext.Require("Shared/_Globals.lua")
Ext.Require("Shared/_Utils.lua")

local healingPotionTag = "1879a93d-2edf-4f54-85dd-81a3724d677f"
--local stupidFuckingIteratingPieceOfShitFunctionIsDone = false
local potions = {}
-- local drinkerQueue = {}
-- --Actually not a queue.
-- local initQueue = {}

local healingPotionTypes = {
    ["small"] = {
        stat = "OBJ_Potion_Healing",
        status = "POTION_OF_HEALING",
        template = "1119ee77-9048-427b-bd09-69911270dd01",
        nameHandle = "ha248915ag9249g4fafg8924g12bb3e56c426",
        descriptionPartHandle = "h80012058gcbd4g4d3ag9035gcb7c190f929c",
        descriptionHandle = "h5b4a5cffg1852g4c2cga49ag6badba0e1ee8"
    },
    ["greater"] = {
        stat = "OBJ_Potion_Healing_Greater",
        status = "POTION_OF_HEALING_GREATER",
        template = "2f630ddb-ccea-489b-a392-95be277cd589",
        nameHandle = "h224d31e1g4c6eg4c37gaac5gbd7871bebc92",
        descriptionPartHandle = "hff823f08g801bg467cg9f22g39bff9cbd8f6",
        descriptionHandle = "h8e1da616g1237g42cbga4bfgb92af9049c6b"
    },
    ["superior"] = {
        stat = "OBJ_Potion_Healing_Superior",
        status = "POTION_OF_HEALING_SUPERIOR",
        template = "d0da8204-73a7-4684-99bd-9733986a9f56",
        nameHandle = "hfaf12441g485bg4d9dgbb32gb44fa8f62f78",
        descriptionPartHandle = "h5267e52eg6250g40d5ga24fg32e6868dc59a",
        descriptionHandle = "hcf6020a2gdfdag43fdg9e75g02e1739cbca8"
    },
    ["supreme"] = {
        stat = "OBJ_Potion_Healing_Supreme",
        status = "POTION_OF_HEALING_SUPREME",
        template = "7c2ef1ca-8b5a-4520-a31b-39c9d603fcb3",
        nameHandle = "ha693f065gd71eg4108g9888g754c4e4aa7c1",
        descriptionPartHandle = "h66a6a882g8715g4c4fg9c6fg02bf264d591e",
        descriptionHandle = "h35bcaeb6ge7eeg4853ga884g03be6d2b8d0c"
    },
}
---Get potion count for a potion type
---@param potionType PotionType type of potion to count the amount of
---@return integer potionCount amount of the specified potion type
local function getPotionCount(potionType)
    if type(potionType) ~= "table" then return 0 end
    local potionCount = 0
    for uuid, potionData in pairs(potions) do
        if potionType.stat == potionData.statsId then
            potionCount = potionCount + potionData.amount
        end
    end
    return potionCount
end

---Function to populate our potions table by iterating over the inventory&sub inventories of each party member
local function getPartyPotions()
    potions={}
    for _, player in pairs(SQUADIES) do
        potions = Table.MergeSets(potions,DeepIterateInventory(Ext.Entity.Get(player), { healingPotionTag }))
    end
end

local function updatePotionDescription(potionType)
    UpdateTranslatedString(potionType.descriptionHandle,
        tostring(GetTranslatedString(potionType.nameHandle) .. " : " .. tostring(getPotionCount(potionType))))
end
local function updateDescriptionForAllPotionTypes()
    for k, v in pairs(healingPotionTypes) do
        updatePotionDescription(v)
    end
end
local function drinkHealingPotion(drinker, potion)
    getPartyPotions()
    local potionStat = potion.stat
    for uuid, data in pairs(potions) do
        if data.statsId == potionStat then
            if drinker then
                Osi.ApplyStatus(drinker, potion.status, 1, 1)
                if data.amount > 1 then
                    Osi.SetStackAmount(uuid, data.amount - 1)
                    data.amount = data.amount - 1
                else
                    Osi.RequestDelete(uuid)
                    data.amount = data.amount - 1
                    potions[uuid] = nil
                end
                updatePotionDescription(potion)
                return
            end
        end
    end
    updatePotionDescription(potion)
end

-- -------------------------------------------------------------------------- --
--                                   EVENTS                                   --
-- -------------------------------------------------------------------------- --

Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", function(level, iseditor)
    if level == "SYS_CC_I" then return end
    GetSquadies()
    getPartyPotions()
    for _, player in pairs(SQUADIES) do
        for _, item in pairs(healingPotionTypes) do
            if not HasItemTemplate(player, item.template) then
                Osi.TemplateAddTo(item.template, player, 1, 1)
            end
        end
    end
    updateDescriptionForAllPotionTypes()
end)

Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "after", function(root, item, inventoryHolder, addType)
    if Osi.IsPartyMember(inventoryHolder,0) == 1 and Osi.IsTagged(GUID(item), healingPotionTag) == 1 then
        getPartyPotions()
        updateDescriptionForAllPotionTypes()
    end
end)


Ext.Osiris.RegisterListener("TemplateUseStarted", 3, "after", function(character, template, item)
    if GUID(template) == healingPotionTypes["small"].template then
        drinkHealingPotion(GUID(character), healingPotionTypes["small"])
    elseif GUID(template) == healingPotionTypes["greater"].template then
        drinkHealingPotion(GUID(character), healingPotionTypes["greater"])
    elseif GUID(template) == healingPotionTypes["superior"].template then
        drinkHealingPotion(GUID(character), healingPotionTypes["superior"])
    elseif GUID(template) == healingPotionTypes["supreme"].template then
        drinkHealingPotion(GUID(character), healingPotionTypes["supreme"])
    end
end)

Ext.Osiris.RegisterListener("CharacterJoinedParty", 1, "after", function()
    GetSquadies()
    for _, player in pairs(SQUADIES) do
        for _, item in pairs(healingPotionTypes) do
            if not HasItemTemplate(player, item.template) then
                Osi.TemplateAddTo(item.template, player, 1, 1)
            end
        end
    end
end)

Ext.Osiris.RegisterListener("CharacterLeftParty", 1, "after", GetSquadies)
