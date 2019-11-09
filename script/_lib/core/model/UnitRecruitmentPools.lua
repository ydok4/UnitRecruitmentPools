UnitRecruitmentPools = {
    -- UI Object which handles UI manipulation
    urpui = {};
    FactionBuildingData = {},
    CharacterBuildingData = {},
    FactionUnitData = {},
    HumanFaction = {},
    -- Cached data
    BuildingUnits = {},
    DiplomacyUnits = {},
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
                RecruitmentArchetypes = {},
            }
        end
        newTable[unitKey].StartingReserveCap = unitResources.StartingReserveCap;
        newTable[unitKey].StartingReserves = unitResources.StartingReserves;
        newTable[unitKey].UnitGrowth = unitResources.UnitGrowth;
        newTable[unitKey].RequiredGrowthForReplenishment = unitResources.RequiredGrowthForReplenishment;
        newTable[unitKey].SharedData = unitResources.SharedData;
        newTable[unitKey].RecruitmentArchetypes = unitResources.RecruitmentArchetypes;
    end
end

function UnitRecruitmentPools:ApplyFactionBuildingUnitPoolModifiers(faction)
    URP_Log("Apply building unit pool modifiers for faction: "..faction:name());
    local buildingResourceData = self:GetBuildingResourceDataForFaction(faction);
    if buildingResourceData == nil then
        URP_Log("ERROR: Faction/Subculture does not have building resource data");
        return;
    end
    URP_Log("Faction has building data");
    local factionBuildingDataList = {};
    local currentFactionBuildingList = {};
    --Then we building a new list for data from this turn
    local regionList = faction:region_list();
    -- For every region the player controls
    for i = 0, regionList:num_items() - 1 do
        local region = regionList:item_at(i);
        URP_Log("Checking region: "..region:name());
        local provinceName = region:province_name();
        if region:is_abandoned() == false and factionBuildingDataList[provinceName] == nil then
            local provinceGrowth = region:faction_province_growth();
            URP_Log("ProvinceGrowth is: "..provinceGrowth);
            local developmentPoints = self:ConvertProvinceGrowthToDevelopmentPoints(provinceGrowth);
            URP_Log("developmentPoints is: "..developmentPoints);
            factionBuildingDataList[provinceName] = {
                ProvinceGrowth = developmentPoints,
                RegionData = {},
            };
            local adjacentRegionList = region:adjacent_region_list();
            -- On a province level
            for i = 0, adjacentRegionList:num_items() - 1 do
                local adjacentRegion = adjacentRegionList:item_at(i);
                URP_Log("Checking adjacent region: "..adjacentRegion:name());
                if adjacentRegion:province_name() == provinceName
                and adjacentRegion:is_abandoned() == false
                and adjacentRegion:owning_faction():name() == faction:name() then
                    self:GetRegionBuildingData(adjacentRegion, factionBuildingDataList, currentFactionBuildingList, buildingResourceData);
                end
            end
            -- Now we add the original region
            self:GetRegionBuildingData(region, factionBuildingDataList, currentFactionBuildingList, buildingResourceData);
            -- Now we distribute the excess province growth
            for i = 1, factionBuildingDataList[provinceName].ProvinceGrowth, 1 do
                local randomProvinceRegion = GetRandomObjectFromList(factionBuildingDataList[provinceName].RegionData);
                if TableHasAnyValue(randomProvinceRegion.RecruitmentBuildings) then
                    local randomMilitaryBuilding = GetRandomObjectFromList(randomProvinceRegion.RecruitmentBuildings);
                    URP_Log("Adding bonus province growth to building: "..randomMilitaryBuilding.BuildingKey);
                    currentFactionBuildingList[randomMilitaryBuilding.BuildingKey].AmountOfUnitGrowths = currentFactionBuildingList[randomMilitaryBuilding.BuildingKey].AmountOfUnitGrowths + 1;
                end
            end
        end
    end
    local oldBuildingData = self:GetBuildingDataForFaction(faction);
    self:ModifyBuildingPoolData(faction, currentFactionBuildingList, oldBuildingData, buildingResourceData);
    self.FactionBuildingData[faction:subculture()][faction:name()] = currentFactionBuildingList;
end

function UnitRecruitmentPools:ConvertProvinceGrowthToDevelopmentPoints(provinceGrowth)
    if provinceGrowth <= 125 then
        return 0;
    elseif provinceGrowth <= 375 then
        return 1;
    elseif provinceGrowth <= 750 then
        return 2;
    elseif provinceGrowth <= 1250 then
        return 3;
    elseif provinceGrowth <= 1750 then
        return 4
    else
        return 5;
    end
end

function UnitRecruitmentPools:GetRegionBuildingData(region, factionBuildingDataList, currentFactionBuildingList, buildingResourceData)
    local faction = region:owning_faction();
    local provinceName = region:province_name();
    -- Grab all the military buildings and non-excluded other buildings
    local settlement = region:settlement(region);
    local settlementLevelBonus = settlement:primary_slot():building():building_level();
    URP_Log("Primary slot building level is: "..settlementLevelBonus);
    local factionCapitalBonus = 0;
    if region:name() == faction:home_region():name() then
        URP_Log("Region is faction capital. Adding bonus");
        factionCapitalBonus = 1;
    end
    factionBuildingDataList[provinceName].RegionData[region:name()] = {
        PrimarySettlementChainBonusGrowth = settlementLevelBonus + factionCapitalBonus,
        RecruitmentBuildings = {},
        BuildingsWithRecruitmentPenalty = {},
    };
    local settlementSlotList = settlement:slot_list();
    for j = 0, settlementSlotList:num_items() - 1 do
        local slot = settlementSlotList:item_at(j);
        if slot:has_building() then
            local building = slot:building();
            local buildingKey = building:name();
            URP_Log("Adding building: "..buildingKey);
            if buildingKey ~= settlement:primary_slot():building():name()
            and (settlement:port_slot() == nil or buildingKey ~= settlement:port_slot():building():name()) then
                if buildingResourceData[buildingKey] ~= nil then
                    factionBuildingDataList[provinceName].RegionData[region:name()].RecruitmentBuildings[buildingKey] = {
                        BuildingKey = buildingKey,
                    };
                elseif building:superchain() ~= "wh2_main_sch_infrastructure1_farm" then
                    factionBuildingDataList[provinceName].RegionData[region:name()].BuildingsWithRecruitmentPenalty[buildingKey] = {
                        BuildingKey = buildingKey,
                    };
                    factionBuildingDataList[provinceName].RegionData[region:name()].PrimarySettlementChainBonusGrowth = factionBuildingDataList[provinceName].RegionData[region:name()].PrimarySettlementChainBonusGrowth - 1;
                end
            end
            if currentFactionBuildingList[buildingKey] == nil then
                currentFactionBuildingList[buildingKey] = {
                    Amount = 1,
                    AmountOfUnitGrowths = (building:building_level() + 1),
                }
            else
                currentFactionBuildingList[buildingKey].Amount = currentFactionBuildingList[buildingKey].Amount + 1;
                currentFactionBuildingList[buildingKey].AmountOfUnitGrowths = currentFactionBuildingList[buildingKey].AmountOfUnitGrowths + (building:building_level() + 1);
            end
            URP_Log("Building level is: "..building:building_level());
            URP_Log(buildingKey.." AmountOfUnitGrowths: "..currentFactionBuildingList[buildingKey].AmountOfUnitGrowths);
        end
    end
    -- Now we distribute the main settlement growth (if there is any)
    if TableHasAnyValue(factionBuildingDataList[provinceName].RegionData[region:name()].RecruitmentBuildings) then
        for i = 1, factionBuildingDataList[provinceName].RegionData[region:name()].PrimarySettlementChainBonusGrowth, 1 do
            local randomMilitaryBuilding = GetRandomObjectFromList(factionBuildingDataList[provinceName].RegionData[region:name()].RecruitmentBuildings);
            URP_Log("Adding bonus settlement growth to building: "..randomMilitaryBuilding.BuildingKey);
            currentFactionBuildingList[randomMilitaryBuilding.BuildingKey].AmountOfUnitGrowths = currentFactionBuildingList[randomMilitaryBuilding.BuildingKey].AmountOfUnitGrowths + 1;
        end
    end
end

function UnitRecruitmentPools:ApplyCharacterBuildingUnitPoolModifiers(character, buildingConstructed, shouldRemove)
    local faction = character:faction();
    local buildingResourceData = self:GetBuildingResourceDataForFaction(faction);
    if buildingResourceData == nil then
        URP_Log("ERROR: Faction/Subculture does not have building resource data");
        return;
    end
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
                AmountOfUnitGrowths = 0,
            }
        elseif existingCharacterBuildingData[buildingConstructed] == nil and shouldRemove == true then
            newCharacterBuildingData[buildingConstructed] = {
                Amount = 0,
                AmountOfUnitGrowths = 0,
            }
        else
            URP_Log("Character already has building, not modifying pools");
            return;
        end
    end
    self:ModifyBuildingPoolData(faction, newCharacterBuildingData, existingCharacterBuildingData, buildingResourceData);
    self.CharacterBuildingData[faction:subculture()][faction:name()][character:cqi()] = newCharacterBuildingData;
end

function UnitRecruitmentPools:ModifyBuildingPoolData(faction, currentFactionBuildingList, oldBuildings, buildingResourceData)
    local factionUnitData = self:GetFactionUnitData(faction);
    local factionUnitResources = self:GetFactionUnitResources(faction);
    local unitGroupsData = self:GetUnitGroupDataForSubculture(faction:subculture());
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
                if buildingResourcePoolData.Units ~= nil then
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
            if buildingResourcePoolData ~= nil and buildingResourcePoolData.UnitGroups ~= nil then
                for unitGroupKey, unitGroupBuildingData in pairs(buildingResourcePoolData.UnitGroups) do
                    URP_Log("Amount of growth for units from building: "..buildingKey.." is: "..buildingData.AmountOfUnitGrowths);
                    for i = 0, buildingData.AmountOfUnitGrowths, 1 do
                        if buildingResourcePoolData.UnitGroups ~= nil then
                            local randonUnitGroupKey = GetRandomObjectKeyFromList(buildingResourcePoolData.UnitGroups);
                            local unitGroupData = unitGroupsData[randonUnitGroupKey];
                            local validUnits = {};
                            for unitKey, unitData in pairs(factionUnitData) do
                                local unitResources = factionUnitResources[unitKey];
                                if unitGroupData.Units[unitKey] ~= nil
                                and unitData.UnitReserveCap > 0 then
                                    if URP_TableHasValue(unitResources.RecruitmentArchetypes, "Building") then
                                        validUnits[#validUnits + 1] = {
                                            UnitKey = unitKey,
                                            ApplyToUnit = unitGroupData.Units[unitKey].ApplyToUnit,
                                        };
                                    elseif URP_TableHasValue(unitResources.RecruitmentArchetypes, "Diplomacy") then
                                        self.DiplomacyUnits[unitKey] = {
                                            Growth = buildingData.Amount * unitData.UnitGrowth,
                                        };
                                    end
                                end
                            end
                            if #validUnits > 0 then
                                local unit = GetRandomObjectFromList(validUnits);
                                local applyToUnit = unit.UnitKey;
                                if unit.ApplyToUnit ~= nil then
                                    URP_Log("Unit cap data should be applied to a different unit: "..unit.ApplyToUnit);
                                    applyToUnit = unit.ApplyToUnit;
                                end
                                -- Unit growth chance gets changed
                                local growthChange = buildingData.Amount * tonumber(unitGroupBuildingData.UnitGrowthChange) + factionUnitData[unit.UnitKey].UnitGrowth;
                                self:ModifyUnitGrowthForFaction(faction, applyToUnit, growthChange, true);
                            end
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
                --local growthChanceChange = buildingDifferenceAmount * tonumber(unitCapData.UnitGrowthChange);
                --self:ModifyUnitGrowthForFaction(faction, applyToUnit, growthChanceChange);
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

function UnitRecruitmentPools:GetUnitGroupDataForSubculture(subcultureKey)
    return _G.URPResources.UnitGroupPoolResources[subcultureKey];
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
                UnitGroups = {},
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
            if buildingData.UnitGroups ~= nil then
                for unitGroupKey, unitGroupData in pairs(buildingData.UnitGroups) do
                    newTable[buildingKey].UnitGroups[unitGroupKey] = {
                        UnitReserveCapChange = unitGroupData.UnitReserveCapChange,
                        ImmediateUnitReservesChange = unitGroupData.ImmediateUnitReservesChange,
                        UnitGrowthChange = unitGroupData.UnitGrowthChange,
                        ApplyToUnit = unitGroupData.ApplyToUnit,
                    };
                end
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
        return nil;
    end
    if buildingResources[currentBuildingKey] ~= nil then
        repeat
            if buildingKey == currentBuildingKey then
                self:AddUnitBuildingResources(baseBuildingResources, buildingResources[currentBuildingKey].Units, true, false);
                self:AddUnitBuildingResources(baseBuildingResources, buildingResources[currentBuildingKey].UnitGroups, true, true);
            else
                self:AddUnitBuildingResources(baseBuildingResources, buildingResources[currentBuildingKey].Units, false, false);
                self:AddUnitBuildingResources(baseBuildingResources, buildingResources[currentBuildingKey].UnitGroups, false, true);
            end
            currentBuildingKey = buildingResources[currentBuildingKey].PreviousBuilding;
        until(currentBuildingKey == nil)
    end
    return baseBuildingResources;
end

function UnitRecruitmentPools:AddUnitBuildingResources(targetBuildingData, sourceBuildingData, includeReserveChange, isGroup)
    local buildingResourcesType = "Units";
    if isGroup == true then
        buildingResourcesType = "UnitGroups";
    end
    if targetBuildingData[buildingResourcesType] == nil then
        targetBuildingData[buildingResourcesType] = {};
    end
    for unitKey, unitData in pairs(sourceBuildingData) do
        if targetBuildingData[buildingResourcesType][unitKey] == nil then
            targetBuildingData[buildingResourcesType][unitKey] = {
                UnitReserveCapChange = 0,
                ImmediateUnitReservesChange = 0,
                UnitGrowthChange = 0,
            };
        end
        targetBuildingData[buildingResourcesType][unitKey].UnitReserveCapChange = targetBuildingData[buildingResourcesType][unitKey].UnitReserveCapChange + unitData.UnitReserveCapChange;
        if includeReserveChange == true and unitData.ImmediateUnitReservesChange ~= nil then
            targetBuildingData[buildingResourcesType][unitKey].ImmediateUnitReservesChange = targetBuildingData[buildingResourcesType][unitKey].ImmediateUnitReservesChange + unitData.ImmediateUnitReservesChange;
        end
        targetBuildingData[buildingResourcesType][unitKey].UnitGrowthChange = targetBuildingData[buildingResourcesType][unitKey].UnitGrowthChange + unitData.UnitGrowthChange;
        if unitData.ApplyToUnit ~= nil then
            targetBuildingData[buildingResourcesType][unitKey].ApplyToUnit = unitData.ApplyToUnit;
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

function UnitRecruitmentPools:ModifyUnitGrowthForFaction(faction, unitKey, growthChanceChange, setToValue)
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
        local growthChanceIncrease = 0;
        if setToValue == true then
            growthChanceIncrease = growthChanceChange;
        else
            growthChanceIncrease = unitData.UnitGrowth + growthChanceChange;
        end
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
    local buildingResourceData = self:GetBuildingResourceDataForFaction(faction);
    if buildingResourceData == nil then
        URP_Log("ERROR: Faction/Subculture does not have building resource data");
        return;
    end
    if self.CharacterBuildingData[faction:subculture()][faction:name()][character:cqi()] == nil then
        URP_Log("Character was killed but has no building data");
    else
        local existingCharacterBuildingData = self.CharacterBuildingData[faction:subculture()][faction:name()][character:cqi()];
        self:ModifyBuildingPoolData(faction, {}, existingCharacterBuildingData, buildingResourceData);
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
    local customEffectBundle = cm:create_new_custom_effect_bundle("urp_effect_bundle_unit_template");
    -- As this is applying on turn end when this event ends that counts as 1 turn, so we need 2
    customEffectBundle:set_duration(2);
    for unitKey, unitMasterData in pairs(factionUnitData) do
        self:UpdateUnitEffectBundle(faction, factionUnitResources, factionUnitData, unitKey, unitMasterData, customEffectBundle);
    end
    -- Finally we apply the custom effect bundle
    cm:apply_custom_effect_bundle_to_faction(customEffectBundle, faction);
    URP_Log("Finished UpdateEffectBundles for faction: "..faction:name());
    URP_Log_Finished();
end

function UnitRecruitmentPools:UpdateUnitEffectBundle(faction, factionUnitResources, factionUnitData, unitKey, unitMasterData, customEffectBundle)
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
        -- Calculate which cap bundle we need
        URP_Log("Unit count for unit: "..unitKey.." in faction: "..factionKey.." is: "..currentUnitCount.." UnitReserves: "..unitData.UnitReserves);
        local allowedTotal = currentUnitCount + math.floor(unitData.UnitReserves / 100);
        -- This is to stop the AI from recruiting certain unit types and tanking their replenishment
        if factionKey ~= self.HumanFaction:name() and allowedTotal > unitData.UnitReserveCap + 3 then
            allowedTotal = unitData.UnitReserveCap + 3;
        end
        URP_Log("Maximum amount allowed is: "..allowedTotal);
        -- Add new cap effect bundle
        URP_Log("Setting duration");
        customEffectBundle:add_effect(unitKey.."_unit_cap", "faction_to_faction_own_unseen", allowedTotal);
        URP_Log("Added cap effect");
        -- Now we calculate which replenishment bundle we need
        local replenishingFactionUnitCounts = _G.RM:GetUnitsReplenishingForFaction(faction);
        local replenishingUnitReserves = replenishingFactionUnitCounts[unitKey];
        if replenishingUnitReserves == nil then
            replenishingUnitReserves = 0;
        end
        URP_Log("Got replenishing unit reserves");
        local replenishmentModifierNumber = self:GetReplenishmentEffectBundleNumber(faction, unitKey, replenishingUnitReserves, unitData);
        customEffectBundle:add_effect(unitKey.."_replenishment_modifier", "faction_to_faction_own_unseen", replenishmentModifierNumber * 10);
        --URP_Log("Applying replenishment effect bundle: "..replenishmentModifierNumber);
        URP_Log_Finished();
    end
end

function UnitRecruitmentPools:UpdateDiplomacyUnitPools(faction)
    local factionKey = faction:name();
    local subcultureKey = faction:subculture();
    local diplomacyResources = self:GetDiplomacyResourcesForSubCulture(subcultureKey);
    if diplomacyResources == nil then
        return;
    end
    local sameCultureFactions = faction:factions_of_same_culture();
    URP_Log("Performing diplomacy updates with faction: "..factionKey);
    local diplomacyUnitGrowthChanges = {};
    for i = 0, sameCultureFactions:num_items() - 1 do
        local sameCultureFaction = sameCultureFactions:item_at(i);
        diplomacyUnitGrowthChanges = self:GetDiplomacyGrowthChangesBetweenFactions(faction, sameCultureFaction, diplomacyResources, diplomacyUnitGrowthChanges);
    end
    for unitKey, unitData in pairs(diplomacyUnitGrowthChanges) do
        self:ModifyUnitGrowthForFaction(faction, unitKey, unitData.Growth, true);
    end
    -- Clear the diplomacy units cache
    self.DiplomacyUnits = {};
    URP_Log_Finished();
end

function UnitRecruitmentPools:GetDiplomacyGrowthChangesBetweenFactions(sourceFaction, targetFaction, diplomacyResources, diplomacyUnitGrowthChanges)
    local sourceFactionKey = sourceFaction:name();
    local subcultureKey = sourceFaction:subculture();
    if diplomacyUnitGrowthChanges == nil then
        diplomacyUnitGrowthChanges = {};
    end
    local factionUnitData = self:GetFactionUnitData(sourceFaction);
    local targetFactionKey = targetFaction:name();
    if targetFaction:at_war_with(sourceFaction) == false then
        --URP_Log("Not at war with faction: "..targetFactionKey);
        local diplomaticStanding = targetFaction:diplomatic_standing_with(sourceFactionKey);
        --URP_Log("Diplomatic standing with faction: "..diplomaticStanding);
        if diplomaticStanding > 0
        and (diplomacyResources[subcultureKey] ~= nil
        or diplomacyResources[targetFactionKey] ~= nil) then
            local hasNonAggressionPact = false;
            local napFactions = sourceFaction:factions_non_aggression_pact_with();
            for j = 0, napFactions:num_items() - 1 do
                local napFaction = napFactions:item_at(j);
                if napFaction:name() == targetFactionKey then
                    hasNonAggressionPact = true;
                    break;
                end
            end
            --URP_Log("Checked NAP");
            local hasTradeAgreement = false;
            local tradingFactions = sourceFaction:factions_trading_with();
            for j = 0, tradingFactions:num_items() - 1 do
                local tradingFaction = tradingFactions:item_at(j);
                if tradingFaction:name() == targetFactionKey then
                    hasTradeAgreement = true;
                    break;
                end
            end
            --URP_Log("Checked Trading");
            local hasDefensiveAlliance = targetFaction:military_allies_with(sourceFaction);
            --URP_Log("Checked Defensive");
            local hasMilitaryAlliance = targetFaction:defensive_allies_with(sourceFaction);
            --URP_Log("Checked Military");
            if diplomacyResources[subcultureKey] ~= nil then
                for unitKey, unitDiplomacyData in pairs(diplomacyResources[subcultureKey]) do
                    if diplomacyUnitGrowthChanges[unitKey] == nil then
                        diplomacyUnitGrowthChanges[unitKey] = {
                            Growth = 0,
                        }
                    end
                    if factionUnitData[unitKey].UnitReserveCap > 0 then
                        local growthChange = self:GetDiplomacyGrowthChange(sourceFaction, unitKey, unitDiplomacyData, diplomaticStanding);
                        if hasNonAggressionPact == true then
                            URP_Log("Has NAP with: "..targetFactionKey);
                        end
                        if unitDiplomacyData.RequiredTreaty == "NonAggressionPact"
                        and hasNonAggressionPact == true then
                            diplomacyUnitGrowthChanges[unitKey].Growth = diplomacyUnitGrowthChanges[unitKey].Growth + growthChange;
                        elseif unitDiplomacyData.RequiredTreaty == "TradeAgreement"
                        and hasTradeAgreement == true then
                            diplomacyUnitGrowthChanges[unitKey].Growth = diplomacyUnitGrowthChanges[unitKey].Growth + growthChange;
                        elseif unitDiplomacyData.RequiredTreaty == "DefensiveAlliance"
                        and hasDefensiveAlliance == true then
                            diplomacyUnitGrowthChanges[unitKey].Growth = diplomacyUnitGrowthChanges[unitKey].Growth + growthChange;
                        elseif unitDiplomacyData.RequiredTreaty == "MilitaryAlliance"
                        and hasMilitaryAlliance == true then
                            diplomacyUnitGrowthChanges[unitKey].Growth = diplomacyUnitGrowthChanges[unitKey].Growth + growthChange;
                        elseif unitDiplomacyData.RequiredTreaty == "" then
                            diplomacyUnitGrowthChanges[unitKey].Growth = diplomacyUnitGrowthChanges[unitKey].Growth + growthChange;
                        end
                    end
                end
            end
            --URP_Log("Checked subculture resources");
            if diplomacyResources[targetFactionKey] ~= nil then
                for unitKey, unitDiplomacyData in pairs(diplomacyResources[targetFactionKey]) do
                    if diplomacyUnitGrowthChanges[unitKey] == nil then
                        diplomacyUnitGrowthChanges[unitKey] = {
                            Growth = 0,
                        }
                    end
                    if factionUnitData[unitKey].UnitReserveCap > 0 then
                        local growthChange = self:GetDiplomacyGrowthChange(sourceFaction, unitKey, unitDiplomacyData, diplomaticStanding);
                        if unitDiplomacyData.RequiredTreaty == "NonAggressionPact"
                        and hasNonAggressionPact == true then
                            diplomacyUnitGrowthChanges[unitKey].Growth = diplomacyUnitGrowthChanges[unitKey].Growth + growthChange;
                        elseif unitDiplomacyData.RequiredTreaty == "TradeAgreement"
                        and hasTradeAgreement == true then
                            diplomacyUnitGrowthChanges[unitKey].Growth = diplomacyUnitGrowthChanges[unitKey].Growth + growthChange;
                        elseif unitDiplomacyData.RequiredTreaty == "DefensiveAlliance"
                        and hasDefensiveAlliance == true then
                            diplomacyUnitGrowthChanges[unitKey].Growth = diplomacyUnitGrowthChanges[unitKey].Growth + growthChange;
                        elseif unitDiplomacyData.RequiredTreaty == "MilitaryAlliance"
                        and hasMilitaryAlliance == true then
                            diplomacyUnitGrowthChanges[unitKey].Growth = diplomacyUnitGrowthChanges[unitKey].Growth + growthChange;
                        elseif unitDiplomacyData.RequiredTreaty == "" then
                            diplomacyUnitGrowthChanges[unitKey].Growth = diplomacyUnitGrowthChanges[unitKey].Growth + growthChange;
                        end
                    end
                end
            end
            --URP_Log("Checked faction resources");
        else
            URP_Log("Not enough standing or missing resources");
        end
    end
    return diplomacyUnitGrowthChanges;
end

function UnitRecruitmentPools:GetDiplomacyGrowthChange(faction, unitKey, unitDiplomacyData, diplomaticStanding)
    URP_Log("Getting growth change for: "..unitKey);
    local growthHits = 0;
    -- Growth hits are based on the level of treaty required and have a cap
    if unitDiplomacyData.RequiredTreaty == "NonAggressionPact" then
        growthHits = math.ceil(diplomaticStanding / 50);
    elseif unitDiplomacyData.RequiredTreaty == "TradeAgreement" then
        growthHits = math.ceil(diplomaticStanding / 75);
    elseif unitDiplomacyData.RequiredTreaty == "DefensiveAlliance" then
        growthHits = math.ceil(diplomaticStanding / 100);
    elseif unitDiplomacyData.RequiredTreaty == "MilitaryAlliance" then
        growthHits = math.ceil(diplomaticStanding / 150);
    end
    local unitBuildingGrowth = 0;
    if TableHasAnyValue(self.DiplomacyUnits) == false then
        URP_Log("Diplomacy cache is empty");
        self:RecreateDiplomacyUnitCache(faction);
    end
    if self.DiplomacyUnits[unitKey] ~= nil then
        unitBuildingGrowth = self.DiplomacyUnits[unitKey].Growth;
    end
    return unitBuildingGrowth * growthHits;
end

function UnitRecruitmentPools:RecreateDiplomacyUnitCache(faction)
    local factionUnitResources = self:GetFactionUnitResources(faction);
    local factionBuildingResources = self:GetBuildingResourceDataForFaction(faction);
    local factionBuildingData = self:GetBuildingDataForFaction(faction);
    for buildingKey, buildingData in pairs(factionBuildingData) do
        local buildingResources = factionBuildingResources[buildingKey];
        if buildingResources ~= nil then
            for unitKey, unitData in pairs(buildingResources.Units) do
                local unitResources = factionUnitResources[unitKey];
                if URP_TableHasValue(unitResources.RecruitmentArchetypes, "Diplomacy") then
                    URP_Log("Adding diplomacy unit to cache: "..unitKey);
                    URP_Log("Growth is: "..(buildingData.Amount * unitResources.UnitGrowth));
                    self.DiplomacyUnits[unitKey] = {
                        Growth = buildingData.Amount * unitResources.UnitGrowth,
                    };
                end
            end
        end
    end
end

function UnitRecruitmentPools:GetDiplomacyResourcesForSubCulture(subcultureKey)
    return _G.URPResources.UnitDiplomacyPoolResources[subcultureKey];
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
        --URP_Log("currentUnitCount: "..currentUnitCount);
        local requiredGrowth = currentUnitResources.RequiredGrowthForReplenishment * currentUnitCount;
        --URP_Log("UnitGrowth: "..unitData.UnitGrowth);
        --URP_Log("requiredGrowth: "..requiredGrowth);
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
function UnitRecruitmentPools:SetupMaxCountUI(factionData, unitUIData, uiSuffix, cachedUIData)
    URP_Log("SetupMaxCountUI");
    local newSubcomponentId = unitUIData.UnitKey.."_max_units_"..uiSuffix;
    local maxUnitUIClone = find_uicomponent(unitUIData.UnitComponent, newSubcomponentId);
    if not maxUnitUIClone then
        -- Clone the max units component
        local maxUnits = find_uicomponent(unitUIData.UnitComponent, "max_units");
        local maxUnitUICloneAddress = maxUnits:CopyComponent(newSubcomponentId);
        unitUIData.UnitComponent:Adopt(maxUnitUICloneAddress);
        maxUnitUIClone = UIComponent(maxUnitUICloneAddress);

        maxUnitUIClone:SetCanResizeWidth(true);
        local xBounds, yBounds = maxUnitUIClone:Bounds();
        maxUnitUIClone:Resize(xBounds + 15, yBounds - 10);
        maxUnitUIClone:SetCanResizeWidth(false);
        local uiFileName = "urp_recruitment_default.png";
        local unitResources = factionData.UnitResources[unitUIData.UnitKey];
        if unitResources ~= nil and unitResources.RecruitmentArchetypes ~= nil then
            if URP_TableHasValue(unitResources.RecruitmentArchetypes, "Building") then
                uiFileName = "urp_recruitment_buildings.png";
            elseif URP_TableHasValue(unitResources.RecruitmentArchetypes, "Diplomacy") then
                uiFileName = "urp_recruitment_diplomacy.png";
            end
        end
        maxUnitUIClone:SetImagePath("ui/urp/recruitment/"..uiFileName);
        maxUnitUIClone:SetVisible(true);
    else
        URP_Log("Component already exists");
    end
    local turnTimes = find_uicomponent(unitUIData.UnitComponent, "Turns");
    local turnTimesText = turnTimes:GetStateText();
    if uiSuffix == "_mercenary" then
        local originalMaxUnits = find_uicomponent(unitUIData.UnitComponent, "max_units");
        local currentAmount = originalMaxUnits:GetStateText();
        if not string.match(currentAmount, "/") then
            if unitUIData.UnitData
            and unitUIData.UnitReserves < tonumber(currentAmount) then
                currentAmount = unitUIData.UnitReserves;
                maxUnitUIClone:SetStateText(turnTimesText.." - "..unitUIData.UnitReserves.."/"..unitUIData.UnitURPData.UnitReserveCap);
            else
                maxUnitUIClone:SetStateText(currentAmount.."/"..unitUIData.UnitURPData.UnitReserveCap);
            end
            --URP_Log("currentAmount is "..currentAmount);
            if tonumber(currentAmount) == 0 then
                URP_Log("Stopping recruitment of "..unitUIData.UnitKey);
                unitUIData.UnitComponent:SetInteractive(false);
            else
                unitUIData.UnitComponent:SetInteractive(true);
            end
        else
            URP_Log("Stopping recruitment of "..unitUIData.UnitKey);
            unitUIData.UnitComponent:SetInteractive(false);
        end
    else
        maxUnitUIClone:SetStateText(turnTimesText.." - "..unitUIData.UnitReserves.."/"..unitUIData.UnitURPData.UnitReserveCap);
    end
    -- Setup tooltip
    local unitTooltipText = self:GetUnitToolTipText(unitUIData.UnitKey, unitUIData.UnitURPData, factionData.UnitResources[unitUIData.UnitKey], factionData);
    maxUnitUIClone:SetTooltipText(unitTooltipText);
    -- Disable UI if there is no reserves
    if uiSuffix ~= "_mercenary" then
        if unitUIData.UnitURPData == nil
        or unitUIData.UnitReserves <= 0 then
            URP_Log("Stopping recruitment of "..unitUIData.UnitKey);
            unitUIData.UnitComponent:SetInteractive(false);
        else
            unitUIData.UnitComponent:SetInteractive(true);
        end
    end
end

function UnitRecruitmentPools:RefreshUICallback(context)
    local uiToUnits = context.UiToUnits;
    local uiSuffix = context.UiSuffix;
    local type = context.Type;
    local cachedUIData = context.CachedUIData;
    URP_Log("RefreshUICallback");
    local factionData = {
        -- Current unit data
        UnitData = self:GetFactionUnitData(self.HumanFaction),
        -- Vanilla Resources
        -- Unit Counts
        UnitResources = self:GetFactionUnitResources(self.HumanFaction),
        ReplenishingUnits = _G.RM:GetUnitsReplenishingForFaction(self.HumanFaction),
        UnitCounts = _G.RM:GetUnitCountsForFaction(self.HumanFaction),
    }
    for i = 0, uiToUnits:ChildCount() - 1  do
        local unit = UIComponent(uiToUnits:Find(i));
        local unitId = unit:Id();
        URP_Log("Unit ID: "..unitId);
        local unitKey = string.match(unitId, "(.*)"..uiSuffix);
        if unitKey == nil or
        factionData.UnitData[unitKey] == nil or
        factionData.UnitResources[unitKey] == nil then
            URP_Log("Missing required unit data, skipping unit.");
        else
            URP_Log("UnitKey: "..unitKey);
            if self.HumanFaction:subculture() == "wh2_dlc09_sc_tmb_tomb_kings" then
                local unitCapComponent = find_uicomponent(unit, "unit_cap");
                unitCapComponent:SetVisible(false);
            end
            local unitURPData = {};
            if factionData.UnitResources[unitKey].SharedData ~= nil then
                URP_Log("Unit has shared data");
                unitURPData = self:GetSharedUnitData(unitKey, factionData.UnitResources, factionData.UnitData);
            else
                URP_Log("Unit does not share data");
                unitURPData = factionData.UnitData[unitKey];
            end
            local unitReserves = math.floor(unitURPData.UnitReserves / 100);
            local unitUIData = {
                UnitComponent = unit,
                UnitComponentId = unitId,
                UnitKey = unitKey,
                UnitURPData = unitURPData,
                UnitReserves = unitReserves,
            }
            self:SetupMaxCountUI(factionData, unitUIData, uiSuffix, cachedUIData);
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

function UnitRecruitmentPools:GetDiplomacyScreenTooltipForFaction(selectedFaction)
    local humanSubcultureKey = self.HumanFaction:subculture();
    local diplomacyResources = self:GetDiplomacyResourcesForSubCulture(humanSubcultureKey);
    if diplomacyResources == nil then
        return "";
    end
    local diplomacyUnitGrowthChanges = self:GetDiplomacyGrowthChangesBetweenFactions(self.HumanFaction, selectedFaction, diplomacyResources, nil);
    --URP_Log("Got diplomacyUnitGrowthChanges");
    local tooltipText = "";
    for unitKey, unitDiplomacyData in pairs(diplomacyUnitGrowthChanges) do
        URP_Log("Checking tooltip for unit: "..unitKey);
        if unitDiplomacyData.Growth > 0 then
            local unitLocalisedName = effect.get_localised_string("land_units_onscreen_name_"..unitKey);
            tooltipText = tooltipText..unitLocalisedName.." next turn growth "..unitDiplomacyData.Growth.."\n";
        end
    end
    if tooltipText == "" then
        tooltipText = "You are currently not receiving any growth from this faction.";
    end
    return tooltipText;
end

function UnitRecruitmentPools:GetUnitToolTipText(unitKey, unitData, unitResourceData, factionCountData)
    local replenishmentTypeText = "";
    if URP_TableHasValue(unitResourceData.RecruitmentArchetypes, "Building") then
        replenishmentTypeText = "Unit is receiving growth from buildings.";
    elseif URP_TableHasValue(unitResourceData.RecruitmentArchetypes, "Diplomacy") then
        local diplomacyResources = self:GetDiplomacyResourcesForSubCulture(self.HumanFaction:subculture());
        local subcultureOnlyDiplomacyResources = diplomacyResources[self.HumanFaction:subculture()];
        local treatyType = subcultureOnlyDiplomacyResources[unitKey].RequiredTreaty;
        replenishmentTypeText = "Unit is receiving growth from "..treatyType.." type treaties through diplomacy.";
    end
    local replenishmentText = self:GetTooltipReplenishmentText(unitKey, unitData, unitResourceData, factionCountData);
    return replenishmentTypeText.."\nNumber of available units\n"..replenishmentText;
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