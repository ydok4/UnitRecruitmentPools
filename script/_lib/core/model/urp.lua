UnitRecruitmentPools = {
    -- UI Object which handles UI manipulation
    urpui = {};
    FactionBuildingData = {},
    CharacterBuildingData = {},
    FactionUnitData = {},
    -- This stores the keys and the amount of units the player has queued
    -- from the mercenary/raise dead pools
    CachedMercenaryRecruitment = {},
    HumanFaction = {},
}

function UnitRecruitmentPools:new (o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function UnitRecruitmentPools:Initialise()
    out("URP: Setting default values");
    URP_Log("Setting default values");
    self.HumanFaction = self:GetHumanFaction();
    URP_Log("Finished default values");
    out("URP: Finished default values");
end

function UnitRecruitmentPools:NewGameStartUp()
    URP_Log("New game startup");
    -- Startup requirements TBD
    URP_Log("New game startup completed");
    URP_Log_Finished();
end

-- This exists to convert the human faction list to just an object.
-- This also means it will only work for one player.
function UnitRecruitmentPools:GetHumanFaction()
    local allHumanFactions = cm:get_human_factions();
    if allHumanFactions == nil then
        return allHumanFactions;
    end
    for key, humanFaction in pairs(allHumanFactions) do
        local faction = cm:model():world():faction_by_key(humanFaction);
        return faction;
    end
end

function UnitRecruitmentPools:SetupFactionUnitPools(faction)
    local factionKey = faction:name();
    URP_Log("Setting up unit pools for faction: "..factionKey);
    -- Initialise tables
    if self.FactionUnitData[faction:subculture()] == nil then
        self.FactionUnitData[faction:subculture()] = {};
    end
    self.FactionUnitData[faction:subculture()][factionKey] = {};
    local factionData = self.FactionUnitData[faction:subculture()][factionKey];
    local factionUnitDefaultData = self:GetFactionUnitResources(faction);

    if factionUnitDefaultData == nil then
        return;
    end

    for unitKey, unitData in pairs(factionUnitDefaultData) do
        local unitCap = Random(unitData.StartingCap[2], unitData.StartingCap[1]);
        local availableAmount = Random(unitData.StartingAmount[2], unitData.StartingAmount[1]);
        local growthChance = Random(unitData.GrowthChance[2], unitData.GrowthChance[1]);
        if factionData[unitKey] == nil then
            URP_Log("Initialising unit "..unitKey.." UnitCap: "..unitCap.." AvailableAmount: "..availableAmount.." GrowthChance: "..growthChance);
            factionData[unitKey] = {
                UnitCap = unitCap,
                AvailableAmount = availableAmount,
                GrowthChance = growthChance,
            }
        else
            URP_Log("Unit: "..unitKey.." has already been initialised");
        end
    end

    self.FactionUnitData[faction:subculture()][factionKey] = factionData;
    -- Once the baseline starting data has been setup, then we check for any starting buildings
    self:ApplyFactionBuildingUnitPoolModifiers(faction);
end

function UnitRecruitmentPools:GetFactionUnitResources(faction)
    local subcultureKey = faction:subculture();
    if _G.URPResources.UnitPoolResources[subcultureKey] == nil then
        return;
    end
    local subcultureResources = _G.URPResources.UnitPoolResources[subcultureKey][subcultureKey];
    if subcultureResources == nil then
        return;
    end
    local factionKey = faction:name();
    local factionResources = _G.URPResources.UnitPoolResources[subcultureKey][factionKey];
    if factionResources ~= nil then
        ConcatTableWithKeys(subcultureResources.Units, factionResources.Units);
    end
    return subcultureResources.Units;
end

function UnitRecruitmentPools:ApplyFactionBuildingUnitPoolModifiers(faction)
    local currentFactionBuildingList = {};
    URP_Log("Apply building unit pool modifiers for faction: "..faction:name());
    -- Then we building a new list for data from this turn
    local regionList = faction:region_list();
    for i = 0, regionList:num_items() - 1 do
        local region = regionList:item_at(i);
        URP_Log("Checking region: "..region:name());
        local settlementSlotList = region:settlement():slot_list();
        for j = 0, settlementSlotList:num_items() - 1 do
            local slot = settlementSlotList:item_at(j);
            if slot:has_building() then
                local building = slot:building();
                local buildingKey = building:name();
                URP_Log("Found building: "..buildingKey.." in settlement region "..region:name());
                if currentFactionBuildingList[buildingKey] == nil then
                    currentFactionBuildingList[buildingKey] = {
                        Amount = 1,
                    }
                else
                    currentFactionBuildingList[buildingKey].Amount = currentFactionBuildingList[buildingKey].Amount + 1;
                end
            end
        end
    end
    local oldBuildingData = self:GetBuildingDataForFaction(faction);
    self:ModifyPoolData(faction, currentFactionBuildingList, oldBuildingData);
    self.FactionBuildingData[faction:subculture()][faction:name()] = currentFactionBuildingList;
end

function UnitRecruitmentPools:ApplyCharacterBuildingUnitPoolModifiers(character, buildingConstructed)
    local faction = character:faction();
    local currentFactionBuildingList = {};
    -- Since we are just adding a building to the data we get the old tracked data and add to it
    local characterBuildingData = self:GetCharacterDataForCharacter(character);
    if characterBuildingData ~= nil then
        currentFactionBuildingList = characterBuildingData;
        if characterBuildingData[buildingConstructed] == nil then
            currentFactionBuildingList[buildingConstructed] = {
                Amount = 1,
            }
        end
    end
    self:ModifyPoolData(faction, currentFactionBuildingList, characterBuildingData);
    self.CharacterBuildingData[faction:subculture()][faction:name()][character:cqi()] = currentFactionBuildingList;
end

function UnitRecruitmentPools:ModifyPoolData(faction, currentFactionBuildingList, oldBuildingData)
    local buildingResourceData = self:GetBuildingResourceDataForFaction(faction);
    if buildingResourceData == nil then
        URP_Log("ERROR: Faction/Subculture does not have building resource data");
        return;
    end
    for buildingKey, buildingData in pairs(currentFactionBuildingList) do
        if oldBuildingData[buildingKey] == nil or oldBuildingData[buildingKey].Amount ~= buildingData.Amount then
            local buildingDifferenceAmount = 0;
            if oldBuildingData[buildingKey] == nil then
                buildingDifferenceAmount = buildingData.Amount;
            else
                buildingDifferenceAmount = oldBuildingData[buildingKey].Amount - buildingData.Amount;
            end
            local buildingResourcePoolData = buildingResourceData[buildingKey];
            if buildingResourcePoolData ~= nil and buildingDifferenceAmount > 0 then
                -- We need to update every unit pool in this faction by the pool data
                for unitKey, unitCapData in pairs(buildingResourcePoolData) do
                    -- We change the unit pool data
                    -- Unit cap gets changed
                    local capChange = buildingDifferenceAmount * buildingResourcePoolData[unitKey].UnitCapChange;
                    self:ModifyUnitCapForFaction(faction, unitKey, capChange);
                    -- Unit growth chance gets changed
                    local growthChanceChange = buildingDifferenceAmount * buildingResourcePoolData[unitKey].UnitGrowthChange;
                    self:ModifyGrowthChanceForFaction(faction, unitKey, growthChanceChange);
                    -- Now we modify the current available unit amount.
                    if buildingDifferenceAmount > 0 then
                        self:ModifyUnitAvailableAmountForFaction(faction, unitKey, buildingResourcePoolData[unitKey].ImmediateAvailableAmount, buildingResourcePoolData[unitKey].OverrideCap);
                    else
                        -- If it is less than, then that means a building has been lost
                        -- We reduce that units available amount by 1 per building lost
                        -- 0 is still the minimum
                        self:ModifyUnitAvailableAmountForFaction(faction, unitKey, buildingDifferenceAmount, false);
                    end
                end
            end
        end
    end
end

function UnitRecruitmentPools:GetBuildingDataForFaction(faction)
    local factionKey = faction:name();
    local subcultureFactions = self.FactionBuildingData[faction:subculture()];
    if subcultureFactions == nil then
        self.FactionBuildingData[faction:subculture()] = {};
    end
    local factionBuildingData = self.FactionBuildingData[faction:subculture()][factionKey];
    if factionBuildingData == nil then
        self.FactionBuildingData[faction:subculture()][factionKey] = {};
    end
    return self.FactionBuildingData[faction:subculture()][factionKey];
end

function UnitRecruitmentPools:GetCharacterDataForCharacter(character)
    local faction = character:faction();
    local factionKey = faction:name();
    local subcultureFactions = self.CharacterBuildingData[faction:subculture()];
    if subcultureFactions == nil then
        self.CharacterBuildingData[faction:subculture()] = {};
    end
    local factionCharacterBuildingData = self.CharacterBuildingData[faction:subculture()][factionKey];
    if factionCharacterBuildingData == nil then
        self.CharacterBuildingData[faction:subculture()][factionKey] = {};
    end
    local characterBuildingData = self.CharacterBuildingData[faction:subculture()][factionKey][character:cqi()];
    if characterBuildingData == nil then
        self.CharacterBuildingData[faction:subculture()][factionKey][character:cqi()] = {};
    end
    return self.CharacterBuildingData[faction:subculture()][factionKey][character:cqi()];
end

function UnitRecruitmentPools:GetBuildingResourceDataForFaction(faction)
    local subcultureKey = faction:subculture();
    if _G.URPResources.BuildingPoolResources[subcultureKey] == nil then
        return nil;
    end
    local subcultureResources = _G.URPResources.BuildingPoolResources[subcultureKey][subcultureKey];
    if subcultureResources == nil then
        return;
    end
    local factionKey = faction:name();
    local factionResources = _G.URPResources.BuildingPoolResources[subcultureKey][factionKey];
    if factionResources ~= nil then
        ConcatTableWithKeys(subcultureResources.Units, factionResources.Units);
    end
    return subcultureResources;
end

function UnitRecruitmentPools:ModifyUnitCapForFaction(faction, unitKey, capChange)
    local factionUnitData = self:GetFactionUnitData(faction);
    if factionUnitData[unitKey] == nil then
        URP_Log("Unit "..unitKey.." does not have any data...Initialising");
        factionUnitData[unitKey] = {
            UnitCap = 0,
            AvailableAmount = 0,
            GrowthChance = 0,
        }
    elseif factionUnitData[unitKey].UnitCap ~= 0 and
    factionUnitData[unitKey].UnitCap + capChange <= 0 then
        URP_Log("Modifying UnitCap for unit "..unitKey.." would take value below 0 or 0. Setting to 0.");
        factionUnitData[unitKey].UnitCap = 0;
    else
        local capIncrease = factionUnitData[unitKey].UnitCap + capChange;
        URP_Log("Changing UnitCap for unit "..unitKey.." from "..factionUnitData[unitKey].UnitCap.." to "..capIncrease);
        factionUnitData[unitKey].UnitCap = capIncrease;
    end
end

function UnitRecruitmentPools:ModifyUnitAvailableAmountForFaction(faction, unitKey, amountChange, overrideCap)
    local factionUnitData = self:GetFactionUnitData(faction);
    if factionUnitData[unitKey] == nil then
        URP_Log("Unit "..unitKey.." does not have any data...Initialising");
        factionUnitData[unitKey] = {
            UnitCap = 0,
            AvailableAmount = 0,
            GrowthChance = 0,
        }
    elseif factionUnitData[unitKey].AvailableAmount ~= 0
    and factionUnitData[unitKey].AvailableAmount + amountChange <= 0 then
        URP_Log("Modifying AvailableAmount for unit "..unitKey.." would take value below 0 or 0. Setting to 0.");
        factionUnitData[unitKey].AvailableAmount = 0;
        URP_Log("Restricting unit "..unitKey.." for faction "..faction:name());
        if faction:name() ~= self.HumanFaction:name() then
            -- We allow the ai to recruit more units than what they have because
            -- we can't actually restrict the AI from going over their available units
            -- if they recruit several at once.
            -- Their caps will be restricted until they go positive again though.
            local amountIncrease = factionUnitData[unitKey].AvailableAmount + amountChange;
            URP_Log("Changing AvailableAmount for unit "..unitKey.." from "..factionUnitData[unitKey].AvailableAmount.." to "..amountIncrease);
            factionUnitData[unitKey].AvailableAmount = amountIncrease;
            cm:restrict_units_for_faction(faction:name(), {unitKey}, true);
        end
    elseif factionUnitData[unitKey].AvailableAmount + amountChange > factionUnitData[unitKey].UnitCap
    and overrideCap ~= true then
        URP_Log("Can't set unit: "..unitKey.." above cap");
    else
        local amountIncrease = factionUnitData[unitKey].AvailableAmount + amountChange;
        URP_Log("Changing AvailableAmount for unit "..unitKey.." from "..factionUnitData[unitKey].AvailableAmount.." to "..amountIncrease);
        factionUnitData[unitKey].AvailableAmount = amountIncrease;
        if faction:name() ~= self.HumanFaction:name() then
            cm:restrict_units_for_faction(faction:name(), {unitKey}, false);
        end
    end
end

function UnitRecruitmentPools:ModifyGrowthChanceForFaction(faction, unitKey, growthChanceChange)
    local factionUnitData = self:GetFactionUnitData(faction);
    if factionUnitData[unitKey] == nil then
        URP_Log("Unit "..unitKey.." does not have any data...Initialising");
        factionUnitData[unitKey] = {
            UnitCap = 0,
            AvailableAmount = 0,
            GrowthChance = 0,
        }
    elseif factionUnitData[unitKey].GrowthChance
    and factionUnitData[unitKey].GrowthChance + growthChanceChange <= 0 then
        URP_Log("Modifying GrowthChance for unit "..unitKey.." would take value below 0 or 0. Setting to 0.");
        factionUnitData[unitKey].GrowthChance = 0;
    else
        local growthChanceIncrease = factionUnitData[unitKey].GrowthChance + growthChanceChange;
        URP_Log("Changing GrowthChance for unit "..unitKey.." from "..factionUnitData[unitKey].GrowthChance.." to "..growthChanceIncrease);
        factionUnitData[unitKey].GrowthChance = growthChanceIncrease;
    end
end

function UnitRecruitmentPools:GetFactionUnitData(faction)
    local factionKey = faction:name();
    local subcultureFactions = self.FactionUnitData[faction:subculture()];
    if subcultureFactions == nil then
        subcultureFactions = {};
    end
    local factionUnitData = subcultureFactions[factionKey];
    if factionUnitData == nil then
        self:SetupFactionUnitPools(faction);
        factionUnitData = self.FactionUnitData[faction:subculture()][factionKey];
    end
    return factionUnitData;
end

function UnitRecruitmentPools:RollUnitChances(faction)
    URP_Log("Rolling unit chances for faction: "..faction:name());
    local factionUnitData = self:GetFactionUnitData(faction);
    for unitKey, unitData in pairs(factionUnitData) do
        if Roll100(unitData.GrowthChance) then
            self:ModifyUnitAvailableAmountForFaction(faction, unitKey, 1, false);
        end
    end
end

function UnitRecruitmentPools:FactionHasCharacterBuildingData(faction)
    if self.CharacterBuildingData[faction:subculture()] ~= nil
    and self.CharacterBuildingData[faction:subculture()][faction:name()] ~= nil then
        return true;
    end
    return false;
end

function UnitRecruitmentPools:RemoveBuildingDataForCharacter(character)
    local faction = character:faction();
    if self.CharacterBuildingData[faction:subculture()][faction:name()][character:cqi()] == nil then
        URP_Log("Character was killed but has no building data")''
    else
        self.CharacterBuildingData[faction:subculture()][faction:name()][character:cqi()] = nil;
    end
end


function UnitRecruitmentPools:ClearMercenaryCache()
    URP_Log("Clearing Mercenary cache");
    self:RevertMercenaryCache();
    self.CachedMercenaryRecruitment = {};
end

function UnitRecruitmentPools:AddUnitToMercenaryCache(unitKey)
    self.CachedMercenaryRecruitment[#self.CachedMercenaryRecruitment + 1] = unitKey;
end

function UnitRecruitmentPools:GetUnitKeyFromCache(uiIndex)
    return self.CachedMercenaryRecruitment[uiIndex + 1];
end

function UnitRecruitmentPools:RemoveUnitFromMercenaryCache(uiIndex)
    self.CachedMercenaryRecruitment[uiIndex + 1] = nil;
end

function UnitRecruitmentPools:CommitMercenaryCache()
    self.CachedMercenaryRecruitment = {};
end

function UnitRecruitmentPools:RevertMercenaryCache()
    URP_Log("UndoMercenaryCache");
    for index, unitKey in pairs(self.CachedMercenaryRecruitment) do
        self:ModifyUnitAvailableAmountForFaction(self.HumanFaction, unitKey, 1);
    end
end

