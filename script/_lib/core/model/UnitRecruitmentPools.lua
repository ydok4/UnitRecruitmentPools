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
    ConcatTableWithKeys(resources, subcultureResources.Units);
    local factionKey = faction:name();
    local factionResources = _G.URPResources.UnitPoolResources[subcultureKey][factionKey];
    if factionResources ~= nil then
        for unitKey, unitResources in pairs(factionResources.Units) do
            if resources[unitKey] == nil then
                resources[unitKey] = {
                    StartingReserveCap = 0,
                    StartingReserves = 0,
                    UnitGrowth = 0,
                    RequiredGrowthForReplenishment = 0,
                }
            end
            resources[unitKey].StartingReserveCap = unitResources.StartingReserveCap;
            resources[unitKey].StartingReserves = unitResources.StartingReserves;
            resources[unitKey].UnitGrowth = unitResources.UnitGrowth;
            resources[unitKey].RequiredGrowthForReplenishment = unitResources.RequiredGrowthForReplenishment;
        end
    end
    return resources;
end

function UnitRecruitmentPools:ApplyFactionBuildingUnitPoolModifiers(faction)
    local currentFactionBuildingList = {};
    URP_Log("Apply building unit pool modifiers for faction: "..faction:name());
    -- Then we building a new list for data from this turn
    local regionList = faction:region_list();
    for i = 0, regionList:num_items() - 1 do
        local region = regionList:item_at(i);
        --URP_Log("Checking region: "..region:name());
        local settlementSlotList = region:settlement():slot_list();
        for j = 0, settlementSlotList:num_items() - 1 do
            local slot = settlementSlotList:item_at(j);
            if slot:has_building() then
                local building = slot:building();
                local buildingKey = building:name();
                --URP_Log("Found building: "..buildingKey.." in settlement region "..region:name());
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
        ConcatTableWithKeys(characterBuildingData, characterBuildingData);
        if characterBuildingData[buildingConstructed] == nil then
            currentFactionBuildingList[buildingConstructed] = {
                Amount = 1,
            }
        else
            characterBuildingData[buildingConstructed].Amount = characterBuildingData[buildingConstructed].Amount + 1;
        end
    end
    self:ModifyPoolData(faction, currentFactionBuildingList, characterBuildingData);
    self.CharacterBuildingData[faction:subculture()][faction:name()][character:cqi()] = currentFactionBuildingList;
end

function UnitRecruitmentPools:ModifyPoolData(faction, currentFactionBuildingList, oldBuildings)
    local buildingResourceData = self:GetBuildingResourceDataForFaction(faction);
    if buildingResourceData == nil then
        URP_Log("ERROR: Faction/Subculture does not have building resource data");
        return;
    end
    --URP_Log("Faction has building data");
    for buildingKey, buildingData in pairs(currentFactionBuildingList) do
        --URP_Log("Checking building key: "..buildingKey);
        if oldBuildings[buildingKey] == nil or oldBuildings[buildingKey].Amount ~= buildingData.Amount then
            --URP_Log("Building amount is changed or was constructed/initialised");
            local buildingDifferenceAmount = 0;
            if oldBuildings[buildingKey] == nil then
                buildingDifferenceAmount = buildingData.Amount;
            else
                buildingDifferenceAmount = oldBuildings[buildingKey].Amount - buildingData.Amount;
            end
            local buildingResourcePoolData = self:GetAllBuildingResourcesWithinChain(buildingResourceData, buildingKey);
            if buildingResourcePoolData ~= nil and buildingDifferenceAmount ~= 0 then
                URP_Log("Building amount has changed for building: "..buildingKey.." Amount: "..buildingDifferenceAmount);
                -- We need to update every unit pool in this faction by the pool data
                for unitKey, unitCapData in pairs(buildingResourcePoolData) do
                    -- We change the unit pool data
                    -- Unit cap gets changed
                    local capChange = buildingDifferenceAmount * tonumber(unitCapData.UnitReserveCapChange);
                    self:ModifyUnitReserveCapForFaction(faction, unitKey, capChange);
                    -- Unit growth chance gets changed
                    local growthChanceChange = buildingDifferenceAmount * tonumber(unitCapData.UnitGrowthChange);
                    self:ModifyUnitGrowthForFaction(faction, unitKey, growthChanceChange);
                    -- Now we modify the current available unit amount.
                    if unitCapData.ImmediateUnitReservesChange ~= nil then
                        if buildingDifferenceAmount > 0 then
                            self:ModifyUnitUnitReservesForFaction(faction, unitKey, unitCapData.ImmediateUnitReservesChange, unitCapData.OverrideCap);
                        else
                            -- If it is less than, then that means a building has been lost
                            -- We reduce that units available amount by 1 per building lost
                            -- 0 is still the minimum
                            self:ModifyUnitUnitReservesForFaction(faction, unitKey, buildingDifferenceAmount * 100, false);
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
                -- We change the unit pool data
                -- Unit cap gets changed
                local capChange = buildingDifferenceAmount * tonumber(unitCapData.UnitReserveCapChange);
                self:ModifyUnitReserveCapForFaction(faction, unitKey, capChange);
                -- Unit growth chance gets changed
                local growthChanceChange = buildingDifferenceAmount * tonumber(unitCapData.UnitGrowthChange);
                self:ModifyUnitGrowthForFaction(faction, unitKey, growthChanceChange);
                -- Now we modify the current available unit amount.
                -- We reduce that units available amount by 1 per building lost
                -- 0 is still the minimum
                self:ModifyUnitUnitReservesForFaction(faction, unitKey, buildingDifferenceAmount * 100, false);
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
    local subcultureResources = _G.URPResources.BuildingPoolResources[subcultureKey];
    if subcultureResources == nil then
        return;
    end
    local resources = {};
    ConcatTableWithKeys(resources, subcultureResources);
    return resources;
end

function UnitRecruitmentPools:GetAllBuildingResourcesWithinChain(buildingResources, buildingKey)
    local currentBuildingKey = buildingKey;
    local baseBuildingResources = {};
    if buildingResources[currentBuildingKey] == nil then
        URP_Log("Error: Missing building resources");
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
        until(currentBuildingKey == nil or buildingResources[currentBuildingKey].PreviousBuilding == nil)
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
    end
end

function UnitRecruitmentPools:ModifyUnitReserveCapForFaction(faction, unitKey, capChange)
    local factionUnitData = self:GetFactionUnitData(faction);
    if factionUnitData[unitKey] == nil then
        URP_Log("Unit "..unitKey.." does not have any data...Initialising");
        factionUnitData[unitKey] = {
            UnitReserveCap = 0,
            UnitReserves = 0,
            UnitGrowth = 0,
        }
    end
    local unitData = factionUnitData[unitKey];
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
    if factionUnitData[unitKey] == nil then
        URP_Log("Unit "..unitKey.." does not have any data...Initialising");
        factionUnitData[unitKey] = {
            UnitReserveCap = 0,
            UnitReserves = 0,
            UnitGrowth = 0,
        }
    end
    local unitData = factionUnitData[unitKey];
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
        URP_Log("Can't set unit: "..unitKey.." above cap");
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
    if factionUnitData[unitKey] == nil then
        URP_Log("Unit "..unitKey.." does not have any data...Initialising");
        factionUnitData[unitKey] = {
            UnitReserveCap = 0,
            UnitReserves = 0,
            UnitGrowth = 0,
        }
    end
    local unitData = factionUnitData[unitKey];
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
    local replenishingFactionUnitCounts = _G.RM:GetUnitsReplenishingForFaction(faction);
    for unitKey, unitData in pairs(factionUnitData) do
        -- First we add the current UnitGrowth for the unit's UnitReserves
        self:ModifyUnitUnitReservesForFaction(faction, unitKey, unitData.UnitGrowth, false);
        if replenishingFactionUnitCounts[unitKey] ~= nil then
            -- Then we subtract the replenishment penalties for that Unit
            local replenishmentPenalty = -1 * replenishingFactionUnitCounts[unitKey] * factionUnitResources[unitKey].RequiredGrowthForReplenishment;
            URP_Log("ReplenishmentPenalty is: "..replenishmentPenalty);
            self:ModifyUnitUnitReservesForFaction(faction, unitKey, replenishmentPenalty);
        end
    end
end

function UnitRecruitmentPools:GetReplenishmentPenalty(replenishingFactionUnitCounts, factionUnitResources, unitKey)
    local replenishmentPenalty = -1 * replenishingFactionUnitCounts[unitKey] * factionUnitResources[unitKey].RequiredGrowthForReplenishment;
    return replenishmentPenalty;
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
        self.CharacterBuildingData[faction:subculture()][faction:name()][character:cqi()] = nil;
    end
end

function UnitRecruitmentPools:UpdateEffectBundles(context)
    local turnNumber = cm:turn_number();
    local faction = context.Faction;
    URP_Log("ListenerContext: "..context.ListenerContext);
    URP_Log("UpdateEffectBundles for faction: "..faction:name());
    local listenerContext = context.ListenerContext;
    if listenerContext == "RM_UnitDisbanded"
    or listenerContext == "RM_UnitMerged" then
        URP_Log("Invalid listener context: "..context.ListenerContext);
        URP_Log_Finished();
        return;
    end
    local factionUnitData = self:GetFactionUnitData(faction);
    local factionUnitResources = self:GetFactionUnitResources(faction);
    local factionKey = faction:name();
    URP_Log("Updating effect bundles for faction: "..factionKey);
    for unitKey, unitData in pairs(factionUnitData) do
        local currentUnitCount = _G.RM:GetUnitCountForFaction(faction, unitKey);
        if (unitData.UnitReserveCap ~= 0) then
            local currentUnitResources = factionUnitResources[unitKey];
            -- Remove previous cap effect bundle
            local oldCapEffectBundleKey = self:GetActiveUnitReserveCapEffectBundle(faction, unitKey);
            if oldCapEffectBundleKey ~= nil then
                cm:remove_effect_bundle(oldCapEffectBundleKey, faction:name());
            end
            -- Calculate which cap bundle we need
            URP_Log("Unit count for unit: "..unitKey.." in faction: "..factionKey.." is: "..currentUnitCount.." UnitReserves: "..unitData.UnitReserves);
            local allowedTotal = currentUnitCount + math.floor(unitData.UnitReserves / 100);
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
    URP_Log("Finished UpdateEffectBundles for faction: "..faction:name());
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
    local currentUnitResources = factionUnitResources[unitKey];
    local effectBundleLevel = 0;
    -- Calculate which replenishment bundle we need
    URP_Log("Calculating replenishment effect bundle for faction: "..faction:name().." unit: "..unitKey);
    if currentUnitResources ~= nil
    and currentUnitResources.RequiredGrowthForReplenishment > 0 then
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
            effectBundleLevel = math.ceil(((requiredGrowth - unitData.UnitGrowth) / currentUnitResources.RequiredGrowthForReplenishment)) - math.ceil(unitData.UnitReserves / 100);
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
    local unitData = self:GetFactionUnitData(self.HumanFaction);
    for i = 0, uiToUnits:ChildCount() - 1  do
        local unit = UIComponent(uiToUnits:Find(i));
        local unitId = unit:Id();
        local unitKey = string.match(unitId, "(.*)"..uiSuffix);
        URP_Log("Unit ID: "..unitId.." UnitKey: "..unitKey);
        if unitData[unitKey] == nil then
            URP_Log("Unit data is nil");
        end
        if unitData[unitKey].UnitReserves == nil then
            URP_Log("Unit amount is nil");
        end
        local UnitReserves = math.floor( unitData[unitKey].UnitReserves / 100 );
        URP_Log("UnitReserves: "..UnitReserves);
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
                if unitData[unitKey] ~= nil
                and UnitReserves >= 0 then
                    --URP_Log("UnitReserves is "..unitData[unitKey].UnitReserves);
                    --URP_Log("StartingReserveCap is "..unitData[unitKey].UnitReserveCap);
                    if uiSuffix == "_mercenary" then
                        local currentAmount = subcomponent:GetStateText();
                        if not string.match(currentAmount, "/") then
                            if unitData[unitKey]
                            and UnitReserves < tonumber(currentAmount) then
                                currentAmount = UnitReserves;
                                subcomponent:SetStateText(UnitReserves.." / "..unitData[unitKey].UnitReserveCap);
                            else
                                subcomponent:SetStateText(currentAmount.." / "..unitData[unitKey].UnitReserveCap);
                            end
                            URP_Log("currentAmount is "..currentAmount);
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

                        subcomponent:SetStateText(UnitReserves.." / "..unitData[unitKey].UnitReserveCap);
                    end
                else
                    URP_Log("Stopping recruitment of "..unitKey);
                    unit:SetInteractive(false);
                    subcomponent:SetStateText("0");
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
            if unitData[unitKey] == nil
            or UnitReserves <= 0 then
                URP_Log("Stopping recruitment of "..unitKey);
                unit:SetInteractive(false);
            else
                unit:SetInteractive(true);
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
    if isCancelled == true then
        self:ModifyUnitUnitReservesForFaction(self.HumanFaction, unitKey, 100);
    else
        self:ModifyUnitUnitReservesForFaction(self.HumanFaction, unitKey, -100);
    end
    URP_Log_Finished();
end