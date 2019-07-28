UnitRecruitmentPools = {
    -- UI Object which handles UI manipulation
    urpui = {};
    FactionBuildingData = {},
    CharacterBuildingData = {},
    FactionUnitData = {},
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
        local unitCap = unitData.StartingReserveCap;
        local UnitReserves = unitData.StartingReserves;
        local unitGrowth = unitData.UnitGrowth;
        if factionData[unitKey] == nil then
            --URP_Log("Initialising unit "..unitKey.." UnitReserveCap: "..unitCap.." UnitReserves: "..UnitReserves.." UnitGrowth: "..unitGrowth);
            factionData[unitKey] = {
                UnitReserveCap = unitCap,
                UnitReserves = UnitReserves,
                UnitGrowth = unitGrowth,
            }
        else
            --URP_Log("Unit: "..unitKey.." has already been initialised");
        end
    end

    self.FactionUnitData[faction:subculture()][factionKey] = factionData;
    -- Once the baseline starting data has been setup, then we check for any starting buildings
    self:ApplyFactionBuildingUnitPoolModifiers(faction);
    -- Then we check for any characters which need additional data,
    -- typically this is just hordes
    local characters = faction:character_list();
    for i = 0, characters:num_items() - 1 do
        local character = characters:item_at(i);
        URP_Log("Checking character: "..character:command_queue_index());
        if character:has_military_force() == true and character:military_force():is_armed_citizenry() == false and cm:char_is_agent(character) == false then
            self:ModifyCharacterPoolData(character, false);
        end
    end
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
    local resources = {};
    if subcultureResources ~= nil then
        self:RemapUnitResources(resources, subcultureResources);
    end
    local factionKey = faction:name();
    local factionResources = _G.URPResources.UnitPoolResources[subcultureKey][factionKey];
    if factionResources ~= nil then
        self:RemapUnitResources(resources, factionResources);
    end
    return resources;
end

function UnitRecruitmentPools:RemapUnitResources(newTable, resources)
    for unitKey, unitResources in pairs(resources.Units) do
        if newTable[unitKey] == nil then
            newTable[unitKey] = {
                StartingReserveCap = 0,
                StartingReserves = 0,
                UnitGrowth = 0,
                RequiredGrowthForReplenishment = 0,
            }
        end
        newTable[unitKey].StartingReserveCap = unitResources.StartingReserveCap;
        newTable[unitKey].StartingReserves = unitResources.StartingReserves;
        newTable[unitKey].UnitGrowth = unitResources.UnitGrowth;
        newTable[unitKey].RequiredGrowthForReplenishment = unitResources.RequiredGrowthForReplenishment;
        newTable[unitKey].SharedData = unitResources.SharedData;
    end
end

function UnitRecruitmentPools:ApplyFactionBuildingUnitPoolModifiers(faction)
    local currentFactionBuildingList = {};
    URP_Log("Apply building unit pool modifiers for faction: "..faction:name());
    --Then we building a new list for data from this turn
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
    self:ModifyBuildingPoolData(faction, currentFactionBuildingList, oldBuildingData);
    self.FactionBuildingData[faction:subculture()][faction:name()] = currentFactionBuildingList;
end

function UnitRecruitmentPools:ApplyCharacterBuildingUnitPoolModifiers(character, buildingConstructed, shouldRemove)
    local faction = character:faction();
    local increment = 0;
    if shouldRemove == true then
        increment = -1;
    else
        increment = 1;
    end
    -- Since we are adding a building to the data we get the old tracked data and add to it
    local existingCharacterBuildingData = self:GetCharacterBuildingDataForCharacter(character);
    local newCharacterBuildingData = {};
    ConcatTableWithKeys(newCharacterBuildingData, existingCharacterBuildingData);
    -- This shouldn't ever be nil be eh, check anyway
    if existingCharacterBuildingData ~= nil then
        if existingCharacterBuildingData[buildingConstructed] == nil and shouldRemove == false then
            newCharacterBuildingData[buildingConstructed] = {
                Amount = 1,
            }
        elseif existingCharacterBuildingData[buildingConstructed] == nil and shouldRemove == true then
            newCharacterBuildingData[buildingConstructed] = {
                Amount = 0,
            }
        else
            URP_Log("Character already has building, not modifying pools");
            return;
        end
    end
    self:ModifyBuildingPoolData(faction, newCharacterBuildingData, existingCharacterBuildingData);
    self.CharacterBuildingData[faction:subculture()][faction:name()][character:cqi()] = newCharacterBuildingData;
end

function UnitRecruitmentPools:ModifyBuildingPoolData(faction, currentFactionBuildingList, oldBuildings)
    local buildingResourceData = self:GetBuildingResourceDataForFaction(faction);
    if buildingResourceData == nil then
        URP_Log("ERROR: Faction/Subculture does not have building resource data");
        return;
    end
    URP_Log("Faction has building data");
    for buildingKey, buildingData in pairs(currentFactionBuildingList) do
        URP_Log("Checking building key: "..buildingKey);
        if oldBuildings[buildingKey] == nil or oldBuildings[buildingKey].Amount ~= buildingData.Amount then
            URP_Log("Building amount is changed or was constructed/initialised");
            local buildingDifferenceAmount = 0;
            if oldBuildings[buildingKey] == nil then
                buildingDifferenceAmount = buildingData.Amount;
            else
                buildingDifferenceAmount = buildingData.Amount - oldBuildings[buildingKey].Amount;
            end
            local buildingResourcePoolData = self:GetAllBuildingResourcesWithinChain(buildingResourceData, buildingKey);
            if buildingResourcePoolData ~= nil and buildingDifferenceAmount ~= 0 then
                URP_Log("Building amount has changed for building: "..buildingKey.." Amount: "..buildingDifferenceAmount);
                -- We need to update every unit pool in this faction by the pool data
                for unitKey, unitCapData in pairs(buildingResourcePoolData) do
                    local applyToUnit = unitKey;
                    if unitCapData.ApplyToUnit ~= nil then
                        URP_Log("Unit cap data should be applied to a different unit: "..unitCapData.ApplyToUnit);
                        applyToUnit = unitCapData.ApplyToUnit;
                    end
                    -- We change the unit pool data
                    -- Unit cap gets changed
                    local capChange = buildingDifferenceAmount * tonumber(unitCapData.UnitReserveCapChange);
                    self:ModifyUnitReserveCapForFaction(faction, applyToUnit, capChange);
                    -- Unit growth chance gets changed
                    local growthChanceChange = buildingDifferenceAmount * tonumber(unitCapData.UnitGrowthChange);
                    self:ModifyUnitGrowthForFaction(faction, applyToUnit, growthChanceChange);
                    -- Now we modify the current available unit amount.
                    if unitCapData.ImmediateUnitReservesChange ~= nil then
                        if buildingDifferenceAmount > 0 then
                            self:ModifyUnitUnitReservesForFaction(faction, applyToUnit, unitCapData.ImmediateUnitReservesChange, unitCapData.OverrideCap);
                        else
                            -- If it is less than, then that means a building has been lost
                            -- We reduce that units available amount by 1 per building lost
                            -- 0 is still the minimum
                            self:ModifyUnitUnitReservesForFaction(faction, applyToUnit, buildingDifferenceAmount * 100, false);
                        end
                    end
                end
            end
        end
        -- We remove this from the old building data because we've checked it now
        oldBuildings[buildingKey] = nil;
    end
    -- If there are any old buildings left, then that means all copies
    -- of that building were removed in the last turn
    for oldBuildingKey, oldBuildingData in pairs(oldBuildings) do
        local buildingResourcePoolData = buildingResourceData[oldBuildingKey];
        if buildingResourcePoolData ~= nil then
            local buildingDifferenceAmount = oldBuildingData.Amount * -1;
            URP_Log("All buildings of: "..oldBuildingKey.." has been removed. Amount was: "..buildingDifferenceAmount);
            -- We need to update every unit pool in this faction by the pool data
            for unitKey, unitCapData in pairs(buildingResourcePoolData.Units) do
                local applyToUnit = unitKey;
                if unitCapData.ApplyToUnit ~= nil then
                    URP_Log("Unit cap data should be applied to a different unit: "..unitCapData.ApplyToUnit);
                    applyToUnit = unitCapData.ApplyToUnit;
                end
                -- We change the unit pool data
                -- Unit cap gets changed
                local capChange = buildingDifferenceAmount * tonumber(unitCapData.UnitReserveCapChange);
                self:ModifyUnitReserveCapForFaction(faction, applyToUnit, capChange);
                -- Unit growth chance gets changed
                local growthChanceChange = buildingDifferenceAmount * tonumber(unitCapData.UnitGrowthChange);
                self:ModifyUnitGrowthForFaction(faction, applyToUnit, growthChanceChange);
                -- Now we modify the current available unit amount.
                -- We reduce that units available amount by 1 per building lost
                -- 0 is still the minimum
                self:ModifyUnitUnitReservesForFaction(faction, applyToUnit, buildingDifferenceAmount * 100, false);
            end
        end
    end
    URP_Log_Finished();
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

function UnitRecruitmentPools:GetCharacterBuildingDataForFaction(faction)
    local factionKey = faction:name();
    local subcultureFactions = self.CharacterBuildingData[faction:subculture()];
    if subcultureFactions == nil then
        self.CharacterBuildingData[faction:subculture()] = {};
    end
    return self.CharacterBuildingData[faction:subculture()][factionKey];
end

function UnitRecruitmentPools:GetCharacterBuildingDataForCharacter(character)
    local faction = character:faction();
    local factionKey = faction:name();
    local factionCharacterBuildingData = self:GetCharacterBuildingDataForFaction(faction);
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
    local factionKey = faction:name();
    if _G.URPResources.BuildingPoolResources[subcultureKey] == nil then
        return nil;
    end
    local subcultureResources = {};
    if _G.URPResources.BuildingPoolResources[subcultureKey][subcultureKey] ~= nil then
        subcultureResources = _G.URPResources.BuildingPoolResources[subcultureKey][subcultureKey];
    end
    if subcultureResources == nil then
        return;
    end
    local resources = {};
    self:RemapBuildingPoolData(resources, subcultureResources);
    local factionResources = {};
    if _G.URPResources.BuildingPoolResources[subcultureKey][factionKey] ~= nil then
        factionResources = _G.URPResources.BuildingPoolResources[subcultureKey][factionKey];
    end
    self:RemapBuildingPoolData(resources, factionResources);
    return resources;
end

function UnitRecruitmentPools:RemapBuildingPoolData(newTable, resources)
    for buildingKey, buildingData in pairs(resources) do
        if not buildingData then
            newTable[buildingKey] = nil;
        elseif newTable[buildingKey] == nil then
            newTable[buildingKey] = {
                Units = {},
                PreviousBuilding = buildingData.PreviousBuilding,
            }
            for unitKey, unitData in pairs(buildingData.Units) do
                newTable[buildingKey].Units[unitKey] = {
                    UnitReserveCapChange = unitData.UnitReserveCapChange,
					ImmediateUnitReservesChange = unitData.ImmediateUnitReservesChange,
                    UnitGrowthChange = unitData.UnitGrowthChange,
                    ApplyToUnit = unitData.ApplyToUnit,
                }
            end
        else
            for unitKey, unitData in pairs(buildingData.Units) do
                if not unitData then
                    newTable[buildingKey].Units[unitKey] = nil;
                else
                    newTable[buildingKey].Units[unitKey] = unitData;
                end
            end
        end
    end
end

function UnitRecruitmentPools:GetAllBuildingResourcesWithinChain(buildingResources, buildingKey)
    local currentBuildingKey = buildingKey;
    local baseBuildingResources = {};
    if buildingResources[currentBuildingKey] == nil then
        URP_Log("Building is unsupported");
        return baseBuildingResources;
    end
    if buildingResources[currentBuildingKey] ~= nil then
        repeat
            if buildingKey == currentBuildingKey then
                self:AddUnitBuildingResources(baseBuildingResources, buildingResources[currentBuildingKey].Units, true);
            else
                self:AddUnitBuildingResources(baseBuildingResources, buildingResources[currentBuildingKey].Units, false);
            end
            currentBuildingKey = buildingResources[currentBuildingKey].PreviousBuilding;
        until(currentBuildingKey == nil)
    end
    return baseBuildingResources;
end

function UnitRecruitmentPools:AddUnitBuildingResources(targetBuildingData, sourceBuildingData, includeReserveChange)
    for unitKey, unitData in pairs(sourceBuildingData) do
        if targetBuildingData[unitKey] == nil then
            targetBuildingData[unitKey] = {
                UnitReserveCapChange = 0,
                ImmediateUnitReservesChange = 0,
                UnitGrowthChange = 0,
            };
        end
        targetBuildingData[unitKey].UnitReserveCapChange = targetBuildingData[unitKey].UnitReserveCapChange + unitData.UnitReserveCapChange;
        if includeReserveChange == true and unitData.ImmediateUnitReservesChange ~= nil then
            targetBuildingData[unitKey].ImmediateUnitReservesChange = targetBuildingData[unitKey].ImmediateUnitReservesChange + unitData.ImmediateUnitReservesChange;
        end
        targetBuildingData[unitKey].UnitGrowthChange = targetBuildingData[unitKey].UnitGrowthChange + unitData.UnitGrowthChange;
        if unitData.ApplyToUnit ~= nil then
            targetBuildingData[unitKey].ApplyToUnit = unitData.ApplyToUnit;
        end
    end
end

function UnitRecruitmentPools:ModifyUnitReserveCapForFaction(faction, unitKey, capChange)
    local factionUnitData = self:GetFactionUnitData(faction);
    local factionUnitResources = self:GetFactionUnitResources(faction);
    if factionUnitData[unitKey] == nil then
        URP_Log("Unit "..unitKey.." does not have any data...Initialising");
        factionUnitData[unitKey] = {
            UnitReserveCap = 0,
            UnitReserves = 0,
            UnitGrowth = 0,
        }
    end
    local unitData = {};
    if factionUnitResources[unitKey].SharedData ~= nil then
        unitData = self:GetSharedUnitData(unitKey, factionUnitResources, factionUnitData);
    else
        unitData = factionUnitData[unitKey];
    end
    if unitData.UnitReserveCap ~= 0 and
    unitData.UnitReserveCap + capChange <= 0 then
        URP_Log("Modifying UnitReserveCap for unit "..unitKey.." would take value below 0 or 0. Setting to 0.");
        unitData.UnitReserveCap = 0;
    else
        local capIncrease = unitData.UnitReserveCap + capChange;
        URP_Log("Changing UnitReserveCap for unit "..unitKey.." from "..unitData.UnitReserveCap.." to "..capIncrease);
        unitData.UnitReserveCap = capIncrease;
    end
end

function UnitRecruitmentPools:ModifyUnitUnitReservesForFaction(faction, unitKey, amountChange, overrideCap)
    local factionUnitData = self:GetFactionUnitData(faction);
    local factionUnitResources = self:GetFactionUnitResources(faction);
    if factionUnitData[unitKey] == nil then
        URP_Log("Unit "..unitKey.." does not have any data...Initialising");
        factionUnitData[unitKey] = {
            UnitReserveCap = 0,
            UnitReserves = 0,
            UnitGrowth = 0,
        }
    end
    local unitData = {};
    if factionUnitResources[unitKey].SharedData ~= nil then
        unitData = self:GetSharedUnitData(unitKey, factionUnitResources, factionUnitData);
    else
        unitData = factionUnitData[unitKey];
    end
    if unitData.UnitReserves + amountChange <= 0 then
        URP_Log("Modifying UnitReserves for unit "..unitKey.." would take value below 0 or 0. Setting to 0.");
        unitData.UnitReserves = 0;
        URP_Log("Restricting unit "..unitKey.." for faction "..faction:name());
        --[[if faction:name() ~= self.HumanFaction:name() then
            -- We allow the ai to recruit more units than what they have because
            -- we can't actually restrict the AI from going over their available units
            -- if they recruit several at once.
            -- Their caps will be restricted until they go positive again though.
            local amountIncrease = unitData.UnitReserves + amountChange;
            URP_Log("Changing UnitReserves for unit "..unitKey.." from "..unitData.UnitReserves.." to "..amountIncrease);
            unitData.UnitReserves = amountIncrease;
            cm:restrict_units_for_faction(faction:name(), {unitKey}, true);
        end--]]
    elseif unitData.UnitReserves + amountChange > (unitData.UnitReserveCap * 100)
    and overrideCap ~= true then
        URP_Log("Can't set unit: "..unitKey.." above cap. Setting to max.");
        unitData.UnitReserves = unitData.UnitReserveCap * 100;
    else
        local amountIncrease = unitData.UnitReserves + amountChange;
        URP_Log("Changing UnitReserves for unit "..unitKey.." from "..unitData.UnitReserves.." to "..amountIncrease);
        unitData.UnitReserves = amountIncrease;
        --[[if faction:name() ~= self.HumanFaction:name() then
            cm:restrict_units_for_faction(faction:name(), {unitKey}, false);
        end--]]
    end
end

function UnitRecruitmentPools:ModifyUnitGrowthForFaction(faction, unitKey, growthChanceChange)
    local factionUnitData = self:GetFactionUnitData(faction);
    local factionUnitResources = self:GetFactionUnitResources(faction);
    if factionUnitData[unitKey] == nil then
        URP_Log("Unit "..unitKey.." does not have any data...Initialising");
        factionUnitData[unitKey] = {
            UnitReserveCap = 0,
            UnitReserves = 0,
            UnitGrowth = 0,
        }
    end
    local unitData = {};
    if factionUnitResources[unitKey].SharedData ~= nil then
        unitData = self:GetSharedUnitData(unitKey, factionUnitResources, factionUnitData);
    else
        unitData = factionUnitData[unitKey];
    end
    if unitData.UnitGrowth
    and unitData.UnitGrowth + growthChanceChange <= 0 then
        URP_Log("Modifying UnitGrowth for unit "..unitKey.." would take value below 0 or 0. Setting to 0.");
        unitData.UnitGrowth = 0;
    else
        local growthChanceIncrease = unitData.UnitGrowth + growthChanceChange;
        URP_Log("Changing UnitGrowth for unit "..unitKey.." from "..unitData.UnitGrowth.." to "..growthChanceIncrease);
        unitData.UnitGrowth = growthChanceIncrease;
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

function UnitRecruitmentPools:UpdateUnitGrowth(faction)
    local factionKey = faction:name();
    URP_Log("Updating unit growth for faction: "..factionKey);
    local factionUnitData = self:GetFactionUnitData(faction);
    local factionUnitResources = self:GetFactionUnitResources(faction);
    local factionUnitCounts = _G.RM:GetUnitCountsForFaction(faction);
    local replenishingFactionUnitCounts = _G.RM:GetUnitsReplenishingForFaction(faction);
    for unitKey, unitMasterData in pairs(factionUnitData) do
        local unitResourceData = {};
        local unitData = {};
        if factionUnitResources[unitKey].SharedData ~= nil then
            unitData = self:GetSharedUnitData(unitKey, factionUnitResources, factionUnitData);
            unitResourceData = self:GetSharedUnitResources(unitKey, factionUnitResources);
        else
            unitData = unitMasterData;
            unitResourceData = factionUnitResources[unitKey];
        end
        -- First we add the current UnitGrowth for the unit's UnitReserves
        self:ModifyUnitUnitReservesForFaction(faction, unitKey, unitData.UnitGrowth, false);
        local totalPenalty = 0;
        if replenishingFactionUnitCounts[unitKey] ~= nil then
            -- Then we subtract the replenishment penalties for that Unit
            local replenishmentPenalty = -1 * replenishingFactionUnitCounts[unitKey] * unitResourceData.RequiredGrowthForReplenishment;
            URP_Log("ReplenishmentPenalty is: "..replenishmentPenalty);
            totalPenalty = replenishmentPenalty;
        end
        -- If we have more units than the reserve cap, then we start to inflict
        -- growth penalties
        if factionUnitCounts[unitKey] ~= nil then
            if factionUnitCounts[unitKey] > unitData.UnitReserveCap then
                local amountAboveReserveCap = factionUnitCounts[unitKey] - unitData.UnitReserveCap;
                local excessReservePenalty = -1 * amountAboveReserveCap * unitResourceData.RequiredGrowthForReplenishment;
                totalPenalty = totalPenalty + excessReservePenalty;
            end
            -- Add penalty for units which have a growth cost
            if unitResourceData.IgnoreReplenishmentPenalties == true then
                totalPenalty = totalPenalty + factionUnitCounts[unitKey] * unitResourceData.RequiredGrowthForReplenishment;
            end
        end
        if totalPenalty > 0 then
            self:ModifyUnitUnitReservesForFaction(faction, unitKey, totalPenalty);
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
        URP_Log("Character was killed but has no building data");
    else
        local existingCharacterBuildingData = self.CharacterBuildingData[faction:subculture()][faction:name()][character:cqi()];
        self:ModifyBuildingPoolData(faction, {}, existingCharacterBuildingData);
        existingCharacterBuildingData = nil;
    end
end

function UnitRecruitmentPools:UpdateEffectBundles(context)
    local faction = context.Faction;
    URP_Log("ListenerContext: "..context.ListenerContext);
    URP_Log("UpdateEffectBundles for faction: "..faction:name());
    local factionUnitData = self:GetFactionUnitData(faction);
    local factionUnitResources = self:GetFactionUnitResources(faction);
    local factionKey = faction:name();
    URP_Log("Updating effect bundles for faction: "..factionKey);
    for unitKey, unitMasterData in pairs(factionUnitData) do
        self:UpdateUnitEffectBundle(faction, factionUnitResources, factionUnitData, unitKey, unitMasterData);
    end
    URP_Log("Finished UpdateEffectBundles for faction: "..faction:name());
    URP_Log_Finished();
end

function UnitRecruitmentPools:UpdateUnitEffectBundle(faction, factionUnitResources, factionUnitData, unitKey, unitMasterData, cachedData)
    local factionKey = faction:name();
    local currentUnitCount = _G.RM:GetUnitCountForFaction(faction, unitKey);
    local unitData = {};
    if factionUnitResources[unitKey] ~= nil
    and factionUnitResources[unitKey].SharedData ~= nil then
        unitData = self:GetSharedUnitData(unitKey, factionUnitResources, factionUnitData);
    else
        unitData = unitMasterData;
    end
    if (unitData.UnitReserveCap ~= 0) then
        -- Remove previous cap effect bundle
        local oldCapEffectBundleKey = self:GetActiveUnitReserveCapEffectBundle(faction, unitKey);
        if oldCapEffectBundleKey ~= nil then
            cm:remove_effect_bundle(oldCapEffectBundleKey, faction:name());
        end
        -- Calculate which cap bundle we need
        URP_Log("Unit count for unit: "..unitKey.." in faction: "..factionKey.." is: "..currentUnitCount.." UnitReserves: "..unitData.UnitReserves);
        local allowedTotal = currentUnitCount + math.floor(unitData.UnitReserves / 100);
        -- This is to stop the AI from recruiting certain unit types and tanking their replenishment
        if factionKey ~= self.HumanFaction:name() and allowedTotal > unitData.UnitReserveCap + 2 then
            allowedTotal = unitData.UnitReserveCap + 2;
        end
        URP_Log("Maximum amount allowed is: "..allowedTotal);
        -- Add new cap effect bundle
        local effectBundleForAmount = "urp_effect_bundle_"..unitKey.."_unit_cap_"..allowedTotal;
        URP_Log("Applying cap effect bundle: "..effectBundleForAmount);
        cm:apply_effect_bundle(effectBundleForAmount, factionKey, 0);
        local replenishingFactionUnitCounts = _G.RM:GetUnitsReplenishingForFaction(faction);
        local replenishingUnitReserves = replenishingFactionUnitCounts[unitKey];
        if replenishingUnitReserves == nil then
            replenishingUnitReserves = 0;
        end
        local replenishmentModifierNumber = self:GetReplenishmentEffectBundleNumber(faction, unitKey, replenishingUnitReserves, unitData);
        local effectBundleForReplenishment = "urp_effect_bundle_"..unitKey.."_replenishment_modifier_"..replenishmentModifierNumber;
        -- Add new replenishment effect bundle
        URP_Log("Applying replenishment effect bundle: "..effectBundleForReplenishment);
        cm:apply_effect_bundle(effectBundleForReplenishment, factionKey, 0);
        URP_Log_Finished();
    else
        -- Remove previous cap effect bundle
        local oldCapEffectBundleKey = self:GetActiveUnitReserveCapEffectBundle(faction, unitKey);
        if oldCapEffectBundleKey ~= nil then
            cm:remove_effect_bundle(oldCapEffectBundleKey, faction:name());
        end
    end
end

function UnitRecruitmentPools:GetSharedUnitData(unitKey, factionUnitResources, factionUnitData)
    local unitData = {};
    local sharedUnitResources = factionUnitResources[unitKey].SharedData;
    local sharedUnitKey = sharedUnitResources.UnitKey;
    local sharedUnitData = factionUnitData[sharedUnitKey];
    local reserveCap = unitData.UnitReserveCap;
    if sharedUnitResources.ShareCap == true then
        reserveCap = sharedUnitData.UnitReserveCap;
    end
    local reserves = unitData.UnitReserves;
    if sharedUnitResources.ShareReserves == true then
        reserves = sharedUnitData.UnitReserves;
    end
    local growth = unitData.UnitGrowth;
    if sharedUnitResources.ShareGrowth == true then
        growth = sharedUnitData.UnitGrowth;
    end
    unitData = {
        UnitReserveCap = reserveCap,
        UnitReserves = reserves,
        UnitGrowth = growth,
    }
    return unitData;
end

function UnitRecruitmentPools:GetSharedUnitResources(unitKey, factionUnitResources)
    local unitResourceData = {};
    local unitResources = factionUnitResources[unitKey].SharedData;
    local sharedUnitKey = unitResources.UnitKey;
    local sharedUnitResources = factionUnitResources[sharedUnitKey];

    local startingReserveCap = unitResources.StartingReserveCap;
    if unitResources.ShareCap == true then
        startingReserveCap = sharedUnitResources.StartingReserveCap;
    end
    local startingReserves = unitResources.StartingReserves;
    if unitResources.ShareReserves == true then
        startingReserves = sharedUnitResources.StartingReserves;
    end
    local growth = unitResources.UnitGrowth;
    if unitResources.ShareGrowth == true then
        growth = sharedUnitResources.UnitGrowth;
    end
    local requiredGrowthForReplenishment = unitResources.RequiredGrowthForReplenishment;
    if unitResources.ShareRequiredGrowthForReplenishment == true then
        requiredGrowthForReplenishment = sharedUnitResources.RequiredGrowthForReplenishment;
    end

    unitResourceData = {
        StartingReserveCap = startingReserveCap,
        StartingReserves = startingReserves,
        UnitGrowth = growth,
        RequiredGrowthForReplenishment = requiredGrowthForReplenishment,
    }
    return unitResourceData;
end

function UnitRecruitmentPools:GetActiveUnitReserveCapEffectBundle(faction, unitKey)
	for i = 1, 30 do
		local effect_key = "urp_effect_bundle_"..unitKey.."_unit_cap_"..i;
		if faction:has_effect_bundle(effect_key) then
			return effect_key;
		end
    end
    return nil;
end

function UnitRecruitmentPools:GetActiveUnitReplenishmentEffectBundle(faction, unitKey)
    --URP_Log("GetActiveUnitReplenishmentEffectBundle");
	for i = 1, 10 do
		local effect_key = "urp_effect_bundle_"..unitKey.."_replenishment_modifier_"..i;
        if faction:has_effect_bundle(effect_key) then
            URP_Log("Found effect bundle key");
			return effect_key;
		end
    end
    return nil;
end

function UnitRecruitmentPools:GetReplenishmentEffectBundleNumber(faction, unitKey, currentUnitCount, unitData)
    local factionUnitResources = self:GetFactionUnitResources(faction);
    local currentUnitResources = {};
    if factionUnitResources[unitKey] ~= nil
    and factionUnitResources[unitKey].SharedData ~= nil then
        currentUnitResources = self:GetSharedUnitResources(unitKey, factionUnitResources);
    else
        currentUnitResources = factionUnitResources[unitKey];
    end

    local effectBundleLevel = 0;
    -- Calculate which replenishment bundle we need
    URP_Log("Calculating replenishment effect bundle for faction: "..faction:name().." unit: "..unitKey);
    if currentUnitResources ~= nil
    and currentUnitResources.RequiredGrowthForReplenishment > 0
    and not currentUnitResources.IgnoreReplenishmentPenalties then
        -- Remove previous replenishment bundle
        local oldReplenishmentEffectBundleKey = self:GetActiveUnitReplenishmentEffectBundle(faction, unitKey);
        if oldReplenishmentEffectBundleKey ~= nil then
            cm:remove_effect_bundle(oldReplenishmentEffectBundleKey, faction:name());
        end
        URP_Log("currentUnitCount: "..currentUnitCount);
        local requiredGrowth = currentUnitResources.RequiredGrowthForReplenishment * currentUnitCount;
        URP_Log("UnitGrowth: "..unitData.UnitGrowth);
        URP_Log("requiredGrowth: "..requiredGrowth);
        local isGrowthAmountEnough = (unitData.UnitGrowth - requiredGrowth) > 0;
        if currentUnitCount > 0
        and isGrowthAmountEnough == false then
            URP_Log("Required growth: "..requiredGrowth.." unitgrowth: "..unitData.UnitGrowth);
            -- Even though we don't have enough UnitGrowth for full replenishment
            -- we can draw replenishment from the UnitReserves, albeit slightly slower than full
            effectBundleLevel = math.floor(((requiredGrowth - unitData.UnitGrowth) / 10));
            if effectBundleLevel < 1 then
                effectBundleLevel = 1;
            elseif effectBundleLevel > 10 then
                effectBundleLevel = 10;
            end
        else
            URP_Log("No units present for unit: "..unitKey);
        end
    else
        URP_Log("Unit growth resources are not greater than 0 or missing");
    end
    URP_Log("EffectBundleLevel is "..effectBundleLevel);
    URP_Log_Finished();
    return effectBundleLevel;
end

function UnitRecruitmentPools:RefreshUICallback(context)
    local uiToUnits = context.UiToUnits;
    local uiSuffix = context.UiSuffix;
    local type = context.Type;
    local cachedUIData = context.CachedUIData;
    URP_Log("RefreshUICallback");
    local factionUnitData = self:GetFactionUnitData(self.HumanFaction);
    local factionUnitResources = self:GetFactionUnitResources(self.HumanFaction);
    local factionCountData = {
        ReplenishingUnits = _G.RM:GetUnitsReplenishingForFaction(self.HumanFaction),
        UnitCounts = _G.RM:GetUnitCountsForFaction(self.HumanFaction),
    }
    for i = 0, uiToUnits:ChildCount() - 1  do
        local unit = UIComponent(uiToUnits:Find(i));
        local unitId = unit:Id();
        URP_Log("Unit ID: "..unitId);
        local unitKey = string.match(unitId, "(.*)"..uiSuffix);
        if unitKey == nil or
        factionUnitData[unitKey] == nil or
        factionUnitResources[unitKey] == nil then
            URP_Log("Missing required unit data, skipping unit.");
        else
            --URP_Log("UnitKey: "..unitKey);
            if self.HumanFaction:subculture() == "wh2_dlc09_sc_tmb_tomb_kings" then
                local unitCapComponent = find_uicomponent(unit, "unit_cap");
                unitCapComponent:SetVisible(false);
            end
            local unitData = {};
            if factionUnitResources[unitKey].SharedData ~= nil then
                --URP_Log("Unit has shared data");
                unitData = self:GetSharedUnitData(unitKey, factionUnitResources, factionUnitData);
            else
                --URP_Log("Unit does not share data");
                unitData = factionUnitData[unitKey];
            end
            local unitReserves = math.floor(unitData.UnitReserves / 100);
            --URP_Log("unitReserves: "..unitReserves);
            for j = 0, unit:ChildCount() - 1  do
                local subcomponent = UIComponent(unit:Find(j));
                local subcomponentId = subcomponent:Id();
                --URP_Log(unitId.." Subcomponent ID: "..subcomponentId);
                local xPos, yPos = subcomponent:Position();
                local subcomponentDefaultData = cachedUIData[type..unitId..subcomponentId];
                if subcomponentDefaultData == nil then
                    --URP_Log("No found cache data, initalising");
                    cachedUIData[type..unitId..subcomponentId] = {
                        yPos = 0,
                        xBounds = 0,
                        yBounds = 0,
                    }
                    subcomponentDefaultData = cachedUIData[type..unitId..subcomponentId];
                end
                if subcomponentId == "max_units" then
                    subcomponent:SetVisible(true);
                    local xBounds, yBounds = subcomponent:Bounds();
                    if subcomponentDefaultData.xBounds == 0
                    or subcomponentDefaultData.yBounds == 0
                    or subcomponentDefaultData.yPos == 0 then
                        subcomponentDefaultData.xBounds = xBounds + 17;
                        subcomponentDefaultData.yBounds = yBounds;
                        subcomponentDefaultData.yPos = yPos - 5;
                    end
                    subcomponent:MoveTo(xPos, yPos - 5);
                    subcomponent:SetCanResizeWidth(true);
                    subcomponent:Resize(subcomponentDefaultData.xBounds, subcomponentDefaultData.yBounds);
                    subcomponent:SetCanResizeWidth(false);
                    if unitData ~= nil
                    and unitReserves >= 0 then
                        --URP_Log("UnitReserves is "..unitData.UnitReserves);
                        --URP_Log("UnitReserveCap is "..unitData.UnitReserveCap);
                        if uiSuffix == "_mercenary" then
                            local currentAmount = subcomponent:GetStateText();
                            if not string.match(currentAmount, "/") then
                                if unitData
                                and unitReserves < tonumber(currentAmount) then
                                    currentAmount = unitReserves;
                                    subcomponent:SetStateText(unitReserves.." / "..unitData.UnitReserveCap);
                                else
                                    subcomponent:SetStateText(currentAmount.." / "..unitData.UnitReserveCap);
                                end
                                --URP_Log("currentAmount is "..currentAmount);
                                if tonumber(currentAmount) == 0 then
                                    URP_Log("Stopping recruitment of "..unitKey);
                                    unit:SetInteractive(false);
                                else
                                    unit:SetInteractive(true);
                                end
                            else
                                URP_Log("Stopping recruitment of "..unitKey);
                                unit:SetInteractive(false);
                            end
                        else
                            subcomponent:SetStateText(unitReserves.." / "..unitData.UnitReserveCap);
                        end
                        local unitResourceData = {};
                        if factionUnitResources[unitKey].SharedData ~= nil then
                            --URP_Log("Unit has shared resource data");
                            unitResourceData = self:GetSharedUnitResources(unitKey, factionUnitResources);
                        else
                            URP_Log("Unit does not share resource data");
                            unitResourceData = factionUnitResources[unitKey];
                        end
                        local replenishmentText = self:GetTooltipReplenishmentText(unitKey, unitData, unitResourceData, factionCountData);
                        URP_Log("Got tooltip");
                        local tooltipText = "Number of available units\n"..replenishmentText;
                        subcomponent:SetTooltipText(tooltipText);
                        URP_Log("Set tooltip");
                    else
                        --URP_Log("Stopping recruitment of "..unitKey);
                        --unit:SetInteractive(false);
                        --subcomponent:SetStateText("0");
                        subcomponent:SetVisible(false);
                    end
                elseif uiSuffix ~= "_mercenary" then
                    if subcomponentId == "RecruitmentCost"
                    or subcomponentId == "UpkeepCost"
                    or subcomponentId == "unit_cat_frame"
                    or subcomponentId == "FoodCost"
                    or subcomponentId == "experience" then
                        subcomponent:MoveTo(xPos, yPos + 1);
                    elseif subcomponentId == "Turns" then
                        subcomponentDefaultData.yPos = yPos + 23;
                        subcomponent:MoveTo(xPos, yPos + 23);
                    else
                        subcomponentDefaultData.yPos = yPos + 20;
                        subcomponent:MoveTo(xPos, yPos + 18);
                    end
                end
            end
            if uiSuffix ~= "_mercenary" then
                if unitData == nil
                or unitReserves <= 0 then
                    URP_Log("Stopping recruitment of "..unitKey);
                    unit:SetInteractive(false);
                else
                    unit:SetInteractive(true);
                end
            end
        end
    end
    URP_Log_Finished();
end

function UnitRecruitmentPools:UIEventCallback(context)
    URP_Log("In UIEventCallback");
    local listenerContext = context.ListenerContext;
    local unitKey = context.UnitKey;
    local isCancelled = context.IsCancelled;
    if unitKey == nil then
        return;
    end
    -- For these two contexts we don't add the units back into the recruitment pool
    if listenerContext == "RMUI_UnitDisbanded"
    or listenerContext == "RMUI_UnitMerged" then
        URP_Log("Invalid context: "..listenerContext);
        URP_Log_Finished();
        return;
    end
    local factionUnitResources = self:GetFactionUnitResources(self.HumanFaction);
    if factionUnitResources[unitKey] == nil then
        URP_Log("Unit: "..unitKey.." is not supported");
        return;
    end
    local sharedUnitKey = nil;
    if factionUnitResources[unitKey] ~= nil
    and factionUnitResources[unitKey].SharedData ~= nil then
        URP_Log("Unit has shared data");
        sharedUnitKey = unitKey;
        unitKey = factionUnitResources[unitKey].SharedData.UnitKey;
    end
    if isCancelled == true then
        self:ModifyUnitUnitReservesForFaction(self.HumanFaction, unitKey, 100);
    else
        self:ModifyUnitUnitReservesForFaction(self.HumanFaction, unitKey, -100);
    end
    URP_Log_Finished();
end

function UnitRecruitmentPools:GetTooltipReplenishmentText(unitKey, unitData, unitResourceData, factionCountData)
    local factionUnitCounts = factionCountData.UnitCounts;
    local unitCount = factionUnitCounts[unitKey];
    if unitCount == nil then
        unitCount = 0;
    end
    local replenishingUnits = factionCountData.ReplenishingUnits;
    local replenishingUnitCount = replenishingUnits[unitKey];
    if replenishingUnitCount == nil then
        replenishingUnitCount = 0;
    end
    local growthGeneration = unitData.UnitGrowth;
    --URP_Log("growthGeneration is: "..growthGeneration);
    local growthConsumption = unitResourceData.RequiredGrowthForReplenishment * replenishingUnitCount;
    --URP_Log("growthConsumption is: "..growthConsumption);
    local reserveGrowth = unitData.UnitReserves;
    --URP_Log("reserveGrowth is: "..reserveGrowth);
    local formattedString = "There are "..unitCount.." of unit in faction.\n";
    formattedString = formattedString.."There are "..reserveGrowth.." Reserves available.\n";
    --URP_Log("formattedString is: "..formattedString);
    formattedString = formattedString..growthGeneration.." Reserves are being generated.\n";
    --URP_Log("formattedString is: "..formattedString);
    if replenishingUnitCount > 0 then
        formattedString = formattedString..growthConsumption.." Reserves are being consumed by "..replenishingUnitCount.." replenishing unit(s).\n";
    end
    --URP_Log("formattedString is: "..formattedString);
    local totalPenalty = (reserveGrowth) + (growthGeneration) + (-1 * growthConsumption);
    --URP_Log("totalPenalty is: "..totalPenalty);
    if unitCount > unitData.UnitReserveCap then
        local amountAboveReserveCap = unitCount - unitData.UnitReserveCap;
        --URP_Log("amountAboveReserveCap is: "..amountAboveReserveCap);
        formattedString = formattedString.."Reserve Capacity exceeded by "..amountAboveReserveCap.." unit(s).\n";
        --URP_Log("formattedString is: "..formattedString);
        local excessReservePenalty = amountAboveReserveCap * unitResourceData.RequiredGrowthForReplenishment;
        --URP_Log("excessReservePenalty is: "..excessReservePenalty);
        totalPenalty = totalPenalty + -1 * excessReservePenalty;
        --URP_Log("totalPenalty is: "..totalPenalty);
        formattedString = formattedString.."Excess units are consuming "..excessReservePenalty.." Reserves.\n";
        --URP_Log("formattedString is: "..formattedString);
    end
    if totalPenalty < 0 then
        totalPenalty = 0;
    end
    if totalPenalty >= (unitData.UnitReserveCap * 100) then
        formattedString = formattedString.."Reserves will change to "..(unitData.UnitReserveCap * 100).." next turn.";
    else
        formattedString = formattedString.."Reserves will change to "..totalPenalty.." next turn.";
    end
    return formattedString;
end

function UnitRecruitmentPools:ModifyCharacterPoolData(character, shouldRemove)
    local subcultureKey = character:faction():subculture();
    if _G.URPResources.CharacterPoolResources[subcultureKey] ~= nil then
        local characterSubTypeKey = character:character_subtype_key();
        if _G.URPResources.CharacterPoolResources[subcultureKey][characterSubTypeKey] ~= nil then
            URP_Log("Found resources for character: "..characterSubTypeKey);
            local agentSubTypeResources = _G.URPResources.CharacterPoolResources[subcultureKey][characterSubTypeKey];
            if agentSubTypeResources.Units ~= nil then
                --self:ModifyUnitUnitReservesForFaction(faction, unitKey, amountChange, overrideCap);
            end
            if agentSubTypeResources.Buildings ~= nil then
                URP_Log("Adding buildings for character: "..characterSubTypeKey);
                for index, buildingKey in pairs(agentSubTypeResources.Buildings) do
                    self:ApplyCharacterBuildingUnitPoolModifiers(character, buildingKey, shouldRemove);
                end
            end
        end
        if _G.URPResources.CharacterPoolResources[subcultureKey][subcultureKey] ~= nil then
            URP_Log("Found resources for subculture: "..subcultureKey);
            local subcultureResources = _G.URPResources.CharacterPoolResources[subcultureKey][subcultureKey];
            if subcultureResources.Units ~= nil then
                --self:ModifyUnitUnitReservesForFaction(faction, unitKey, amountChange, overrideCap);
            end
            if subcultureResources.Buildings ~= nil then
                URP_Log("Adding buildings for subculture: "..subcultureKey);
                for index, buildingKey in pairs(subcultureResources.Buildings) do
                   self:ApplyCharacterBuildingUnitPoolModifiers(character, buildingKey, shouldRemove);
                end
            end
        end
    end
end