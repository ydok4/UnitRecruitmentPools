local coreObject = {};
local urpObject = {};

UnitReplenishmentUIManager = {
    EnableLogging = false,
    UIPathData = {

    },
    UIButtonContexts = {
        button_recruitment = true,
    },
    -- This is where we cache UI element boundary data
    -- This data is not saved and is rebuilt after each load
    CachedUIData = {},
    -- We cache the player's building resources here
    CachedHumanBuildingResources = {},
}

function UnitReplenishmentUIManager:new (o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function UnitReplenishmentUIManager:Log_Start()
    if self.EnableLogging == true then
        io.open("UnitReplenishmentUIManager.txt","w"):close();
    end
end

function UnitReplenishmentUIManager:Log(text)
    if self.EnableLogging == true then
        local logText = tostring(text);
        local logTimeStamp = os.date("%d, %m %Y %X");
        local popLog = io.open("UnitReplenishmentUIManager.txt","a");

        popLog :write("RMUI:  "..logText .. "   : [".. logTimeStamp .. "]\n");
        popLog :flush();
        popLog :close();
    end
end

function UnitReplenishmentUIManager:Log_Finished()
    if self.EnableLogging == true then
        local popLog = io.open("UnitReplenishmentUIManager.txt","a");

        popLog :write("UIPM:  FINISHED\n\n");
        popLog :flush();
        popLog :close();
    end
end

-- Applies UI under appropriate circumstances
function UnitReplenishmentUIManager:SetupPostUIListeners(core, urp)
    self:Log_Start();
    coreObject = core;
    urpObject = urp;
    self:Log("UIPM_UnitInfoPanelReplenishmentOn");
    self.CachedUIData["ResetUnitInfo"] = false;
    self.CachedUIData["DisbandingUnit"] = false;
    self.CachedUIData["ReplenishIconCoordinates"] = {897, 1586};
    self.CachedUIData["IsBuildingPanelOpen"] = false;
    self.CachedUIData["OriginalBuildingBounds"] = {};
    self.CachedHumanBuildingResources = urpObject:GetBuildingResourceDataForFaction(urpObject.HumanFaction);
    self.CachedUnitResources = urpObject:GetFactionUnitResources(urpObject.HumanFaction);

    core:add_listener(
        "UIPM_UnitInfoPanelReplenishmentOn",
        "ComponentMouseOn",
        function(context)
            return (string.match(context.string, "LandUnit")
            or string.match(context.string, "Agent")
            or string.match(context.string, "_recruitable")
            or string.match(context.string, "_mercenary")
            or self.CachedUnitResources[context.string] ~= nil)
            and (self.CachedUIData["SelectedObjectFaction"] == urpObject.HumanFaction:name()
            or self.CachedUIData["IsBuildingPanelOpen"] == true);
        end,
        function(context)
            self:Log("UIPM_UnitInfoPanelReplenishmentOn");
            cm:callback(function()
                self:RefreshUI("UIPM_UnitInfoPanelReplenishmentOn");
                self.CachedUIData["ResetUnitInfo"] = true;
                self:Log_Finished();
            end,
            0);
        end,
        true
    );

    self:Log("UIPM_UnitInfoPanelReplenishmentOff");
    core:add_listener(
        "UIPM_UnitInfoPanelReplenishmentOff",
        "ComponentMouseOn",
        function(context)
            return not (string.match(context.string, "LandUnit") and string.match(context.string, "Agent") and self.CachedUnitResources[context.string] ~= nil)
            and self.CachedUIData["ClickedUnitInfo"] ~= nil
            and self.CachedUIData["ResetUnitInfo"] == true
            and self.CachedUIData["SelectedObjectFaction"] == urp.HumanFaction:name();
        end,
        function(context)
            self:Log("UIPM_UnitInfoPanelReplenishmentOff");
            cm:callback(function()
                self:RefreshUI("UIPM_UnitInfoPanelReplenishmentOff");
                self.CachedUIData["ResetUnitInfo"] = false;
                self:Log_Finished();
            end,
            0);
        end,
        true
    );

    self:Log("UIPM_UnitInfoPanelReplenishmentClick");
    core:add_listener(
        "UIPM_UnitInfoPanelReplenishmentClick",
        "ComponentLClickUp",
        function(context)
            return (string.match(context.string, "LandUnit")
            or string.match(context.string, "Agent"))
            and self.CachedUIData["SelectedObjectFaction"] == urp.HumanFaction:name();
        end,
        function(context)
            self:Log("UIPM_UnitInfoPanelReplenishmentClick");
            cm:callback(function()
                self:RefreshUI("UIPM_UnitInfoPanelReplenishmentClick");
                self.CachedUIData["ResetUnitInfo"] = true;
                self:Log_Finished();
            end,
            0);
        end,
        true
    );

    core:add_listener(
		"UIPM_SettlementSelected",
		"SettlementSelected",
		true,
        function(context)
            self:Log("UIPM_SettlementSelected");
            local factionKey = context:garrison_residence():faction():name();
            self.CachedUIData["SelectedObjectFaction"] = factionKey;
            self:Log_Finished();
		end,
		true
	);

    self:Log("UIPM_ToggleReplenishmentUIForHordes");
    core:add_listener(
        "UIPM_ToggleReplenishmentUIForHordes",
        "ComponentLClickUp",
        function(context)
            return (context.string == "tab_army"
            or context.string == "tab_horde_buildings")
            and self.CachedUIData["SelectedObjectFaction"] == urp.HumanFaction:name();
        end,
        function(context)
            self:Log("UIPM_UnitInfoPanelReplenishmentClick");
            if context.string == "tab_horde_buildings" then
                self:HideReplenishmentIcons();
            elseif self.CachedUIData["SelectedCharacterCQI"] then
                --cm:steal_user_input(false);
                local character = cm:get_character_by_cqi(self.CachedUIData["SelectedCharacterCQI"]);
                cm:callback(function()
                    self:RefreshReplenishmentIcons(character);
                    --cm:steal_user_input(false);
                    self:Log_Finished();
                end,
                0);
            end
        end,
        true
    );

    core:add_listener(
        "UIPM_UnitPanelOpenedCampaign",
        "PanelOpenedCampaign",
        function(context)
            return context.string == "units_panel";
        end,
        function(context)
            self:Log("UIPM_UnitPanelOpenedCampaign listener");
            self.CachedUIData["UnitPanelOpened"] = true;
            if self.CachedUIData["SelectedCharacterCQI"] ~= nil then
                local character = cm:get_character_by_cqi(self.CachedUIData["SelectedCharacterCQI"]);
                self:RefreshReplenishmentIcons(character);
            end
            self:Log_Finished();
        end,
        true
    );

    core:add_listener(
        "UIPM_BuildingBrowserOpenedCampaign",
        "PanelOpenedCampaign",
        function(context)
            return context.string == "building_browser";
        end,
        function(context)
            self:Log("UIPM_BuildingBrowserOpenedCampaign listener");
            self.CachedUIData["IsBuildingPanelOpen"] = true;
            self:Log_Finished();
        end,
        true
    );

    core:add_listener(
        "UIPM_PanelClosedCampaign",
        "PanelClosedCampaign",
        function(context)
            return true;
        end,
        function(context)
            self:Log("UIPM_PanelClosedCampaign listener: "..context.string);
            self.CachedUIData["HighlightedBuilding"] = nil;
            if context.string == "units_panel" then
                self.CachedUIData["UnitPanelOpened"] = false;
            elseif context.string == "building_browser" then
                self.CachedUIData["IsBuildingPanelOpen"] = false;
            else
                if self.CachedUIData["SelectedCharacterCQI"] == nil then
                    return;
                end
                cm:callback(function()
                    local character = cm:get_character_by_cqi(self.CachedUIData["SelectedCharacterCQI"]);
                    self:RefreshReplenishmentIcons(character);
                end,
                0);
            end
            self:Log_Finished();
        end,
        true
    );

    --[[core:add_listener(
        "UIPM_BuildingUnitInfoMouseOff",
        "ComponentMouseOn",
        function(context)
            local contextKey = context.string:match("(.-)"..urpObject.HumanFaction:culture());
            if contextKey == nil then
                contextKey = context.string;
            end
            return self.ActiveBuildingInfo ~= contextKey;
        end,
        function(context)
            self.ActiveBuildingInfo = nil;
            self:Log_Finished();
        end,
        true
    );--]]

    core:add_listener(
        "UIPM_BuildingUnitInfoMouseOn",
        "ComponentMouseOn",
        function(context)
            return self.ActiveBuildingInfo == nil;
        end,
        function(context)
            local buildingKey = context.string:match("(.-)"..urpObject.HumanFaction:culture());
            if buildingKey == nil then
                buildingKey = context.string;
            end
            local unitInfoPopUp = {};
            -- The UI pop up the player can see will vary in path depending on what triggered it
            local iconSuffix = "";
            if self.CachedUIData["IsBuildingPanelOpen"] == true then
                unitInfoPopUp = find_uicomponent(coreObject:get_ui_root(), "building_browser", "info_panel_background", "BuildingInfoPopup");
                iconSuffix = "_building_open";
            else
                unitInfoPopUp = find_uicomponent(coreObject:get_ui_root(), "layout", "info_panel_holder", "secondary_info_panel_holder", "info_panel_background", "BuildingInfoPopup");
                iconSuffix = "_building_closed";
            end
            if self.CachedUIData["SelectedObjectFaction"] == urpObject.HumanFaction:name()
            and (buildingKey ~= nil and self.CachedHumanBuildingResources[buildingKey] ~= nil) then
                self:Log("UIPM_BuildingUnitInfoMouseOn");
                local buildingContext = context.string;
                if buildingContext ~= self.CachedUIData["HighlightedBuilding"] then
                    self:Log("New highlighted building. Resetting cache values.");
                    self.CachedUIData["UnlockTextPosition"] = nil;
                    self.CachedUIData["RecruitableUnitsPosition"] = nil;
                end
                self:Log("Building key is: "..buildingKey);
                self:Log("buildingContext is: "..buildingContext);
                self.CachedUIData["HighlightedBuilding"] = buildingContext;
                -- Normally I would just assign but I specifically want a deep copy of the data,
                -- that way I don't need to recache the data after what I'm doing next.
                local currentBuildingResources = self.CachedHumanBuildingResources[buildingKey];
                if currentBuildingResources ~= nil then
                    currentBuildingResources = currentBuildingResources.Units;
                end
                local buildingChainResources = urpObject:GetAllBuildingResourcesWithinChain(self.CachedHumanBuildingResources, buildingKey);
                cm:callback(function()
                    self:Log("Building is: "..buildingKey);
                    local lastRecruitableUnitXPos = 0;
                    local lastRecruitableUnitYPos = 0;
                    local lastRecruitableUnitXBounds = 0;
                    local lastRecruitableUnitYBounds = 0;
                    local unlockedUnitsYStart = 0;
                    local unlockedUnitsXStart = 0;
                    local numberOfNewUnits = 0;
                    local numberOfRemainingUnits = 0;
                    local recruitableUnits = nil;
                    local effectsList = find_uicomponent(unitInfoPopUp, "effects_list");
                    local numberOfEffects = effectsList:ChildCount() - 1;
                    local lastTextComponent = nil;
                    local alreadyUnlockedUnitsString = "";
                    for i = 0, numberOfEffects do
                        local effectComponent = UIComponent(effectsList:Find(i));
                        local componentId = effectComponent:Id();
                        if componentId == "building_info_recruitment_effects" then
                            recruitableUnits = find_uicomponent(effectComponent, "entry_parent");
                            local recruitableUnitsTextComponents = find_uicomponent(effectComponent, "title_parent", "tx_enables");
                            local recruitableUnitsText = recruitableUnitsTextComponents:GetStateText();
                            self:Log("recruitableUnitsText: "..recruitableUnitsText);
                            if i == numberOfEffects and recruitableUnitsText == "Allows recruitment of:" then
                                local numberOfRecruitmentAllowed = recruitableUnits:ChildCount() - 1;
                                self:Log("numberOfRecruitmentAllowed: "..numberOfRecruitmentAllowed);
                                local recruitableUnit = UIComponent(recruitableUnits:Find(numberOfRecruitmentAllowed));
                                for unitKey, unitBuildingData in pairs(buildingChainResources) do
                                    numberOfRemainingUnits = numberOfRemainingUnits + 1;
                                end
                                recruitableUnit:SetCanResizeHeight(true);
                                recruitableUnit:Resize(lastRecruitableUnitXBounds, 45 + (numberOfRemainingUnits * 45));
                                recruitableUnit:SetCanResizeHeight(false);
                                --[[lastRecruitableUnitXPos, lastRecruitableUnitYPos = recruitableUnit:Position();
                                lastRecruitableUnitXBounds, lastRecruitableUnitYBounds = recruitableUnit:Bounds();
                                unlockedUnitsXStart = lastRecruitableUnitXPos + 60;
                                unlockedUnitsYStart = lastRecruitableUnitYPos + 25;
                                self:Log("lastRecruitableUnitXBounds: "..lastRecruitableUnitXBounds);
                                self:Log("lastRecruitableUnitYPos: "..lastRecruitableUnitYPos);
                                self:Log("lastRecruitableUnitYBounds: "..lastRecruitableUnitYBounds);
                                self:Log("unlockedUnitsXStart: "..unlockedUnitsXStart);
                                self:Log("unlockedUnitsYStart: "..unlockedUnitsYStart);--]]
                                local unitNameComponent = find_uicomponent(recruitableUnit, "unit_name");
                                lastTextComponent = unitNameComponent;
                                self:Log("Unit name: "..unitNameComponent:GetStateText());
                                alreadyUnlockedUnitsString = unitNameComponent:GetStateText().."\n";
                                --[[for j = 0, numberOfRecruitmentAllowed do
                                    alreadyUnlockedUnitsString = alreadyUnlockedUnitsString.."\n";
                                end--]]
                                --lastTextComponent:Resize(lastTextComponent:Width(), 500);
                            elseif i == numberOfEffects and recruitableUnitsText == "Provides garrison:" then
                                local numberOfGarrisonUnits = recruitableUnits:ChildCount() - 1;
                                self:Log("numberOfGarrisonUnits: "..numberOfGarrisonUnits);
                                local recruitableUnit = UIComponent(recruitableUnits:Find(numberOfGarrisonUnits));
                                for unitKey, unitBuildingData in pairs(buildingChainResources) do
                                    numberOfRemainingUnits = numberOfRemainingUnits + 1;
                                end
                                recruitableUnit:SetCanResizeHeight(true);
                                recruitableUnit:Resize(lastRecruitableUnitXBounds, 45 + (numberOfRemainingUnits * 45));
                                recruitableUnit:SetCanResizeHeight(false);
                                --[[lastRecruitableUnitXPos, lastRecruitableUnitYPos = recruitableUnit:Position();
                                lastRecruitableUnitXBounds, lastRecruitableUnitYBounds = recruitableUnit:Bounds();
                                unlockedUnitsXStart = lastRecruitableUnitXPos + 60;
                                unlockedUnitsYStart = lastRecruitableUnitYPos + 25;
                                self:Log("lastRecruitableUnitXBounds: "..lastRecruitableUnitXBounds);
                                self:Log("lastRecruitableUnitYPos: "..lastRecruitableUnitYPos);
                                self:Log("lastRecruitableUnitYBounds: "..lastRecruitableUnitYBounds);
                                self:Log("unlockedUnitsXStart: "..unlockedUnitsXStart);
                                self:Log("unlockedUnitsYStart: "..unlockedUnitsYStart);--]]
                                local unitNameComponent = find_uicomponent(recruitableUnit, "unit_name");
                                lastTextComponent = unitNameComponent;
                                alreadyUnlockedUnitsString = unitNameComponent:GetStateText().."\n";
                                --[[for j = 0, numberOfGarrisonUnits do
                                    alreadyUnlockedUnitsString = alreadyUnlockedUnitsString.."\n";
                                end--]]
                                --lastTextComponent:Resize(lastTextComponent:Width(), 500);
                            elseif recruitableUnitsText == "Unlocks recruitment of:" then
                                numberOfNewUnits = recruitableUnits:ChildCount() - 1;
                                local totalNumberOfTextLines = 0;
                                local newYBounds = 80;
                                for j = 0, numberOfNewUnits do
                                    local recruitableUnit = UIComponent(recruitableUnits:Find(j));
                                    local effectId = recruitableUnit:Id();
                                    --self:Log("recruitableUnit id is: "..effectId);
                                    local unitNameComponent = find_uicomponent(recruitableUnit, "unit_name");
                                    local unitName = unitNameComponent:GetStateText();
                                    if string.match(unitName, "%(Requires building: ") then
                                        unitName = string.match(unitName, "(.-) %(Requires building: ").."\n";
                                    end
                                    self:Log("unitName is: "..unitName);
                                    for unitKey, unitBuildingData in pairs(currentBuildingResources) do
                                        local localisationUnitKey = unitKey;
                                        -- 99% of the main units table keys are the same as the land units
                                        -- This is the exception
                                        if unitKey == "wh_main_emp_veh_steam_tank" then
                                            localisationUnitKey = "wh_main_emp_veh_steam_tank_driver";
                                        end
                                        local localisedUnitName = effect.get_localised_string("land_units_onscreen_name_"..localisationUnitKey);
                                        local testableUnitName = localisedUnitName:gsub("%(", "%%(");
                                        testableUnitName = testableUnitName:gsub("%)", "%%)");
                                        self:Log("localisedUnitName is: "..testableUnitName);
                                        if localisedUnitName == unitName or unitName:match(testableUnitName.."\n") then
                                            self:Log("Doing unitKey: "..unitKey.." at UI index: "..j);
                                            local unitNameText, numberOfLines = self:GetRecruitmentTextData(localisedUnitName, unitBuildingData, false);
                                            self:Log("Got name text: "..unitNameText);
                                            if numberOfLines == 4 then
                                                newYBounds = 95;
                                            end
                                            totalNumberOfTextLines = totalNumberOfTextLines + numberOfLines;
                                            if unitNameComponent ~= nil then
                                                unitNameComponent:SetStateText(unitNameText);
                                            end
                                            -- If we found a match we delete the unit from building chain data, cause we've already covered it.
                                            -- There is also no point in continuing the loop, since there should
                                            -- only be one match (I hope so at least, otherwise ehhhh).
                                            buildingChainResources[unitKey] = nil;
                                            break;
                                        end
                                    end

                                    --self:Log("Resizing height to: "..recruitableUnit:Height() * numberOfLines);
                                    recruitableUnit:SetCanResizeHeight(true);
                                    if j == numberOfNewUnits and i == numberOfEffects then
                                        for unitKey, unitBuildingData in pairs(buildingChainResources) do
                                            numberOfRemainingUnits = numberOfRemainingUnits + 1;
                                        end
                                        local resizeScale = 45;
                                        if iconSuffix == "_building_open" then
                                            resizeScale = 50;
                                        end
                                        local lastYUnitBounds = newYBounds + (resizeScale * numberOfRemainingUnits);
                                        recruitableUnit:Resize(recruitableUnit:Width(), lastYUnitBounds);
                                        numberOfNewUnits = numberOfNewUnits + 1;
                                        --[[lastRecruitableUnitXPos, lastRecruitableUnitYPos = recruitableUnit:Position();
                                        lastRecruitableUnitXBounds, lastRecruitableUnitYBounds = recruitableUnit:Bounds();
                                        unlockedUnitsXStart = lastRecruitableUnitXPos + 40;
                                        unlockedUnitsYStart = lastRecruitableUnitYPos + 80;
                                        self:Log("lastRecruitableUnitYPos: "..lastRecruitableUnitYPos);
                                        self:Log("lastRecruitableUnitYBounds: "..lastRecruitableUnitYBounds);
                                        self:Log("unlockedUnitsXStart: "..unlockedUnitsXStart);
                                        self:Log("unlockedUnitsYStart: "..unlockedUnitsYStart);--]]
                                        lastTextComponent = unitNameComponent;
                                        alreadyUnlockedUnitsString = unitNameComponent:GetStateText().."\n";
                                        --[[for j = 0, totalNumberOfTextLines do
                                            alreadyUnlockedUnitsString = alreadyUnlockedUnitsString.."\n";
                                        end--]]
                                        --lastTextComponent:Resize(lastTextComponent:Width(), 500);
                                    else
                                        recruitableUnit:Resize(recruitableUnit:Width(), newYBounds);
                                    end
                                    recruitableUnit:SetCanResizeHeight(false);
                                end
                            end
                        elseif string.match(componentId, "building_info_generic_entry") then
                            self:Log("Checking generic effect: "..componentId);
                            local stateText = effectComponent:GetStateText();
                            self:Log("stateText: "..stateText);
                            if string.match(stateText, "capacity")
                            or string.match(stateText, "Capacity")
                            or string.match(stateText, "Supports") then
                                effectComponent:SetVisible(false);
                            end
                        end
                        if i == numberOfEffects then
                            -- If there weren't any new units to unlock then we haven't calculated
                            -- how many units are left. See Empire Worship chain.
                            if numberOfRemainingUnits == 0 then
                                for unitKey, unitBuildingData in pairs(buildingChainResources) do
                                    numberOfRemainingUnits = numberOfRemainingUnits + 1;
                                end
                            end
                            --[[if recruitableUnits == nil then
                                self:Log("Recruitable units is nil");
                                recruitableUnits = effectComponent;
                                lastRecruitableUnitXPos, lastRecruitableUnitYPos = effectComponent:Position();
                                lastRecruitableUnitXBounds, lastRecruitableUnitYBounds = effectComponent:Bounds();
                                unlockedUnitsXStart = lastRecruitableUnitXPos + 30;
                                unlockedUnitsYStart = lastRecruitableUnitYPos + 20;
                                self:Log("lastRecruitableUnitYPos: "..lastRecruitableUnitYPos);
                                self:Log("lastRecruitableUnitYBounds: "..lastRecruitableUnitYBounds);
                                self:Log("unlockedUnitsXStart: "..unlockedUnitsXStart);
                                self:Log("unlockedUnitsYStart: "..unlockedUnitsYStart);
                            end--]]
                            if lastTextComponent == nil then
                                lastTextComponent = effectComponent;
                                alreadyUnlockedUnitsString = effectComponent:GetStateText().."\n";
                                --lastTextComponent:Resize(lastTextComponent:Width(), 500);
                            end
                            if string.match(alreadyUnlockedUnitsString, "%[%[col:") then
                                alreadyUnlockedUnitsString = string.match(alreadyUnlockedUnitsString, "(.-)%[%[col:");
                            end
                            lastTextComponent:SetStateText(alreadyUnlockedUnitsString);
                            self:Log("numberOfNewUnits: "..numberOfNewUnits);
                            self:Log("numberOfRemainingUnits: "..numberOfRemainingUnits);
                        end
                    end
                    self:Log("Finished newly unlocked units");
                    self:Log("Number of remainings units: "..numberOfRemainingUnits);
                    if buildingChainResources == nil then
                        self:Log("Missing building chain resources");
                        return;
                    end
                    -- Now we do the already unlocked units
                    --self:Log("unlockedUnitsYStart: "..unlockedUnitsYStart);
                    --local alreadyUnlockedUnitChanges = {};
                    --local alreadyUnlockedUnitChangesParent = find_uicomponent(unitInfoPopUp, "urp_unlocked_unit_effects_parent"..iconSuffix);
                    --if not alreadyUnlockedUnitChangesParent then
                    --    self:Log("Creating alreadyUnlockedUnitChangesParent");
                    --    alreadyUnlockedUnitChangesParent = UIComponent(unitInfoPopUp:CreateComponent("urp_unlocked_unit_effects_parent"..iconSuffix, coreObject.path_to_dummy_component));
                    --    alreadyUnlockedUnitChanges = Text.new("urp_unlocked_unit_effects"..iconSuffix, alreadyUnlockedUnitChangesParent, "NORMAL", "[[col:dark_g]]Already unlocked units[[/col]]");
                    --[[alreadyUnlockedUnitChanges = find_uicomponent(alreadyUnlockedUnitChangesParent, "urp_unlocked_unit_effects"..iconSuffix);
                        alreadyUnlockedUnitChanges:SetCanResizeHeight(true);
                        alreadyUnlockedUnitChanges:SetCanResizeWidth(true);
                        alreadyUnlockedUnitChanges:Resize(lastRecruitableUnitXBounds, 50);
                        alreadyUnlockedUnitChanges:SetCanResizeHeight(false);
                        alreadyUnlockedUnitChanges:SetCanResizeWidth(false);
                        alreadyUnlockedUnitChanges:SetVisible(true);
                        alreadyUnlockedUnitChangesParent:SetVisible(true);
                        alreadyUnlockedUnitChangesParent = find_uicomponent(unitInfoPopUp, "urp_unlocked_unit_effects_parent"..iconSuffix);
                    else
                        self:Log("alreadyUnlockedUnitChangesParent already exists");
                        alreadyUnlockedUnitChanges = find_uicomponent(alreadyUnlockedUnitChangesParent, "urp_unlocked_unit_effects"..iconSuffix);
                    end
                    if numberOfRemainingUnits == 0 then
                        alreadyUnlockedUnitChanges:SetVisible(false);
                    else
                        alreadyUnlockedUnitChanges:SetVisible(false);
                        cm:callback(function()
                            alreadyUnlockedUnitChangesParent:MoveTo(unlockedUnitsXStart + 50, unlockedUnitsYStart);
                            alreadyUnlockedUnitChangesParent:SetVisible(true);
                            alreadyUnlockedUnitChanges:SetVisible(true);
                        end,
                        0.5)
                    end--]]

                    -- Then setup and show the current icons
                    local unlockedUnitIndex = 1;
                    if numberOfRemainingUnits > 0 then
                        alreadyUnlockedUnitsString = alreadyUnlockedUnitsString.."[[col:dark_g]]Already unlocked units[[/col]]\n";
                        self:Log("Doing remaining units");
                        for unitKey, unitBuildingData in pairs(buildingChainResources) do
                            self:Log("Doing unitKey: "..unitKey.." at index: "..unlockedUnitIndex);
                            local localisedUnitName = effect.get_localised_string("land_units_onscreen_name_"..unitKey);
                            local unitNameText, numberOfLines = self:GetRecruitmentTextData(localisedUnitName, unitBuildingData, true);
                            alreadyUnlockedUnitsString = alreadyUnlockedUnitsString.."[[col:dark_g]]"..unitNameText.."[[/col]]\n";
                            --self:Log("UnitNameText is: "..unitNameText);
                            -- statements
                            --[[local unlockedTextAtIndexParent = find_uicomponent(alreadyUnlockedUnitChanges, "urp_unlocked_unit_text_parent_"..unlockedUnitIndex..iconSuffix);
                            local unlockedTextAtIndex = {};
                            if not unlockedTextAtIndexParent then
                                --self:Log("Unit not found at index");
                                unlockedTextAtIndexParent = UIComponent(alreadyUnlockedUnitChanges:CreateComponent("urp_unlocked_unit_text_parent_"..unlockedUnitIndex..iconSuffix, coreObject.path_to_dummy_component));
                                unlockedTextAtIndex = Text.new("urp_unlocked_unit_text_"..unlockedUnitIndex..iconSuffix, unlockedTextAtIndexParent, "NORMAL", unitNameText);
                                unlockedTextAtIndex = find_uicomponent(unlockedTextAtIndexParent, "urp_unlocked_unit_text_"..unlockedUnitIndex..iconSuffix);
                                unlockedTextAtIndex:SetCanResizeHeight(true);
                                unlockedTextAtIndex:SetCanResizeWidth(true);
                                unlockedTextAtIndex:Resize(lastRecruitableUnitXBounds * 1.4, 50);
                                unlockedTextAtIndex:SetCanResizeHeight(false);
                                unlockedTextAtIndex:SetCanResizeWidth(false);
                            else
                                --self:Log("Unit found at index");
                                unlockedTextAtIndex = find_uicomponent(unlockedTextAtIndexParent, "urp_unlocked_unit_text_"..unlockedUnitIndex..iconSuffix);
                                unlockedTextAtIndex:SetStateText(unitNameText);
                            end--]]
                            --[[local yPos = unlockedUnitsYStart - 15 + ((unlockedUnitIndex * 35));
                            cm:callback(function()
                                unlockedTextAtIndexParent:MoveTo(unlockedUnitsXStart + 70, yPos);
                            end,
                            0.3);--]]
                            unlockedUnitIndex = unlockedUnitIndex + 1;
                            --unlockedTextAtIndex:SetVisible(true);
                        end
                        --[[cm:callback(function()
                            self:MoveRemainingUnits(buildingChainResources, alreadyUnlockedUnitChanges, iconSuffix, unlockedUnitsXStart, unlockedUnitsYStart);
                            self:Log_Finished();
                        end,
                        0.5);--]]
                        self:Log("alreadyUnlockedUnitsString: "..alreadyUnlockedUnitsString);
                        lastTextComponent:SetStateText(alreadyUnlockedUnitsString);
                        self:Log_Finished();
                    end
                    --self:HideChildrenFromIndex(unlockedUnitIndex, alreadyUnlockedUnitChanges);
                    self:Log_Finished();
                end,
                0.2);
            else
                local alreadyUnlockedUnitChangesParent = find_uicomponent(unitInfoPopUp, "urp_unlocked_unit_effects_parent"..iconSuffix);
                alreadyUnlockedUnitChangesParent:SetVisible(false);
                local alreadyUnlockedUnitChanges = find_uicomponent(alreadyUnlockedUnitChangesParent, "urp_unlocked_unit_effects"..iconSuffix);
                self:HideChildrenFromIndex(1, alreadyUnlockedUnitChanges);
            end
            self:Log_Finished();
        end,
        true
    );

    -- Recruitment UI should also be applied when a human controlled character is selected
    self:Log("UIPM_CharacterSelected");
    core:add_listener(
        "UIPM_CharacterSelected",
        "CharacterSelected",
        function(context)
            return true;
        end,
        function(context)
            self:Log("UIPM_CharacterSelected");
            local character = context:character();
            local faction = character:faction();
            self.CachedUIData["SelectedObjectFaction"] = faction:name();
            if faction:name() ~= urp.HumanFaction:name() then
                self:Log("Non human character selected");
                self:HideReplenishmentIcons();
            end
            if not self.CachedUIData["UnitPanelOpened"] then
                self.CachedUIData["SelectedCharacterCQI"] = character:command_queue_index();
                self:Log("Panel is not open, closing");
                self:Log_Finished();
                return;
            else
                cm:callback(function()
                    self:RefreshReplenishmentIcons(character);
                    self:Log_Finished();
                end,
                0);
            end
            self:Log_Finished();
        end,
        true
    );

    core:add_listener(
        "UIPM_UnitMerged",
        "UnitMergedAndDestroyed",
        function(context)
            return context:unit():faction():name() == urp.HumanFaction:name()
            and self.CachedUIData["DisbandingUnit"] == false;
        end,
        function(context)
            self.CachedUIData["DisbandingUnit"] = true;
            --cm:steal_user_input(true);
            self:Log("UIPM_UnitMerged");
            local character = context:unit():force_commander();
            cm:callback(function()
                self:RefreshReplenishmentIcons(character);
                self.CachedUIData["DisbandingUnit"] = false;
                --cm:steal_user_input(false);
                self:Log_Finished();
            end,
            0.15);
        end,
        true
    );

    -- Unit disbanded listener
    core:add_listener(
        "UIPM_UnitDisbanded",
        "UnitDisbanded",
        function(context)
            return context:unit():faction():name() == urp.HumanFaction:name()
            and self.CachedUIData["DisbandingUnit"] == false;
        end,
        function(context)
            self.CachedUIData["DisbandingUnit"] = true;
            --cm:steal_user_input(true);
            self:Log("UIPM_UnitDisbanded");
            local character = context:unit():force_commander();
            cm:callback(function()
                self:RefreshReplenishmentIcons(character);
                self.CachedUIData["DisbandingUnit"] = false;
                --cm:steal_user_input(false);
                self:Log_Finished();
            end,
            0.15);
        end,
        true
    );

    core:add_listener(
        "UIPM_CharacterFinishedMovingEvent",
        "CharacterFinishedMovingEvent",
        function(context)
            return context:character():faction():is_human() == true;
        end,
        function(context)
            self:Log("UIPM_CharacterFinishedMovingEvent");
            --cm:steal_user_input(true);
            self:HideReplenishmentIcons();
            local character = context:character();
            cm:callback(function()
                self:RefreshReplenishmentIcons(character);
                --cm:steal_user_input(false);
                self:Log_Finished();
            end,
            0.15);
            self:Log_Finished();
        end,
        true
    );

    core:add_listener(
        "UIPM_ClickedButtonToRecruitUnits",
        "ComponentLClickUp",
        function(context)
            return context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_MUSTER"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SET_CAMP"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SET_CAMP_RAIDING"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SETTLE"
        end,
        function(context)
            self:Log("UIPM_ClickedButtonToRecruitUnits");
            --cm:steal_user_input(true);
            self:HideReplenishmentIcons();
            local character = cm:get_character_by_cqi(self.CachedUIData["SelectedCharacterCQI"]);
            self:Log("Got character");
            cm:callback(function()
                self:RefreshReplenishmentIcons(character);
                --cm:steal_user_input(false);
                self:Log_Finished();
            end,
            0.15);
            self:Log_Finished();
        end,
        true
    );
end

function UnitReplenishmentUIManager:GetUnitPanelCoordinateData(character)
    local unitsPanel = find_uicomponent(coreObject:get_ui_root(), "units_panel");
    local characterUnitList = character:military_force():unit_list();
    local numItems = characterUnitList:num_items() - 1;
    local screenX, screenY = coreObject:get_screen_resolution();
    self:Log("ScreenX: "..screenX.." ScreenY: "..screenY);
    self:Log("Num items is: "..numItems);
    local unitPanelX, unitPanelY = unitsPanel:Position();
    self:Log("unitPanelX: "..unitPanelX.." ScreenY: "..unitPanelY);
    -- (Unit panel x - offset) + card distance for replenishment + 1 units worth of spacing
    if numItems <= 9 then
        self.CachedUIData["ReplenishIconCoordinates"][1] = (unitPanelX  - 35) + 32 + 60;
    else
        self.CachedUIData["ReplenishIconCoordinates"][1] =  (unitPanelX - 26) + 42 - ((numItems - 9) * 30) + 60;
    end
    self.CachedUIData["ReplenishIconCoordinates"][2] = (unitPanelY + 158);
    self:Log("XStart: "..self.CachedUIData["ReplenishIconCoordinates"][1].." YStart: "..self.CachedUIData["ReplenishIconCoordinates"][2]);
end

function UnitReplenishmentUIManager:SetupReplenishmentIconTooltip(character)
    local unitUI = find_uicomponent(coreObject:get_ui_root(), "units_panel", "main_units_panel", "units");
    local faction = character:faction();
    local factionUnitData = urpObject:GetFactionUnitData(faction);
    local factionUnitResources = urpObject:GetFactionUnitResources(faction);
    local characterUnitList = character:military_force():unit_list();
    local characterUnitListNumber = characterUnitList:num_items() - 1;
    local replenishingFactionUnitCounts = _G.RM:GetUnitsReplenishingForFaction(faction);
    local numberOfUnitUI = unitUI:ChildCount() - 1;
    self:Log("Number of units in UI: "..numberOfUnitUI);
    -- We start at because the general is number and we don't care about them
    for i = 1, 20  do
        --self:Log("Checking i: "..i);
        if i > numberOfUnitUI then
            self:SetupReplenishmentIcon(i, 0, "", false);
        elseif i <= characterUnitListNumber then
            local unitComponent = UIComponent(unitUI:Find(i));
            local unitId = unitComponent:Id();
            local unitX, unitY = unitComponent:Position();
            -- subtract one becase the we don't have the general in the military force list
            local unit = characterUnitList:item_at(i);
            local unitKey = unit:unit_key();
            if unitKey ~= nil then
                local unitData = factionUnitData[unitKey];
                if unitData ~= nil then
                    local originalReplenishIcon = find_uicomponent(unitUI, unitId, "campaign", "replenish_icon");
                    if factionUnitResources == nil or not originalReplenishIcon then
                        self:Log("Error: Unit: "..unitKey.." Missing icon or resources");
                    else
                        self:Log("Doing unit: "..unitId.." unitX: "..unitX.." unitY: "..unitY.." Unit key: "..unitKey);
                        local unitResourceData = factionUnitResources[unitKey];
                        local replenishmentText = self:GetTooltipReplenishmentText(faction, unitKey, unitData, unitResourceData);
                        local currentTooltipText = originalReplenishIcon:GetTooltipText();
                        local replenishingUnitReserves = replenishingFactionUnitCounts[unitKey];
                        if replenishingUnitReserves == nil then
                            --self:Log("Unit replenishment is missing, setting to 0");
                            replenishingUnitReserves = 0;
                        end
                        local effectBundleNumber = urpObject:GetReplenishmentEffectBundleNumber(faction, unitKey, replenishingUnitReserves, unitData);
                        local isDisabled = false;
                        if string.match(currentTooltipText, "unit is not replenishing") then
                            self:Log("Replenishment is disabled");
                            isDisabled = true;
                        else
                            self:Log("Replenishment is active");
                        end
                        local tooltipText = "";
                        if effectBundleNumber > 0 then
                            if not string.match(currentTooltipText, "Replenishment is modified by") then
                                tooltipText = currentTooltipText.."\n".."Replenishment is modified by "..(-10 * effectBundleNumber).."%".."\n"..replenishmentText;
                            else
                                tooltipText = currentTooltipText;
                            end
                        else
                            tooltipText = currentTooltipText.."\n"..replenishmentText;
                        end
                        if isDisabled then
                            self:SetupReplenishmentIcon(i, effectBundleNumber, tooltipText, true);
                            originalReplenishIcon:SetVisible(false);
                        else
                            self:SetupReplenishmentIcon(i, effectBundleNumber, tooltipText, false);
                            self:SetReplenishIcon(originalReplenishIcon, effectBundleNumber, false);
                            originalReplenishIcon:SetTooltipText(tooltipText);
                        end
                    end
                else
                    self:Log("No unit data...ignoring");
                end
            end
        end
    end
end

function UnitReplenishmentUIManager:SetupReplenishmentIcon(index, effectBundleNumber, tooltipText, isVisible)
    local unitsPanel = find_uicomponent(coreObject:get_ui_root(), "units_panel", "main_units_panel");
    local baseReplenishIconCoordinates = self.CachedUIData["ReplenishIconCoordinates"];
    --self:Log("Checking replenish icon: "..i);
    local newReplenishIcon = find_uicomponent(unitsPanel, "replenish_icon_custom_"..index);
    if not newReplenishIcon then
        --self:Log("Custom replenish icon not found");
        local uimfImage = Image.new("replenish_icon_custom_"..index, unitsPanel, "ui/urp/icon_replenish.png");
        uimfImage:Scale(0.75);
        uimfImage:SetOpacity(155);
        newReplenishIcon = find_uicomponent(unitsPanel, "replenish_icon_custom_"..index);
        --newReplenishIcon:RegisterTopMost();
    else
        --self:Log("Found existing icon");
    end
    newReplenishIcon:MoveTo(baseReplenishIconCoordinates[1] + (index * 60), self.CachedUIData["ReplenishIconCoordinates"][2]);

    if isVisible then
        --self:Log("Unit: "..index.." key: "..unitKey.." Xpos: "..xPos.. " Ypos: "..yPos);
        self:SetReplenishIcon(newReplenishIcon, effectBundleNumber, true);
        newReplenishIcon:SetTooltipText(tooltipText);
        newReplenishIcon:SetVisible(true);
    else
        self:Log("Hiding icon number: "..index);
        newReplenishIcon:SetVisible(false);
    end
end

function UnitReplenishmentUIManager:SetReplenishIcon(replenishComponent, replenishPenaltyLevel, isDisabled)
    if replenishPenaltyLevel > 0 and replenishPenaltyLevel < 5 then
        if isDisabled == true then
            replenishComponent:SetImage("ui/urp/icon_replenish_disabled_yellow.png");
        else
            replenishComponent:SetImage("ui/urp/icon_replenish_yellow.png");
        end
        --self:Log("Replenish icon is yellow");
    elseif replenishPenaltyLevel > 4 and replenishPenaltyLevel < 9 then
        if isDisabled == true then
            replenishComponent:SetImage("ui/urp/icon_replenish_disabled_orange.png");
        else
            replenishComponent:SetImage("ui/urp/icon_replenish_orange.png");
        end
        --self:Log("Replenish icon is orange");
    elseif replenishPenaltyLevel > 8 then
        if isDisabled == true then
            replenishComponent:SetImage("ui/urp/icon_replenish_disabled_red.png");
        else
            replenishComponent:SetImage("ui/urp/icon_replenish_red.png");
        end
        --self:Log("Replenish icon is red");
    else
        if isDisabled == true then
            replenishComponent:SetImage("ui/urp/icon_replenish_disabled.png");
        else
            replenishComponent:SetImage("ui/urp/icon_replenish.png");
        end
        --self:Log("Replenish icon is green");
    end
end

function UnitReplenishmentUIManager:IsValidButtonContext(buttonContext)
    return self.UIButtonContexts[buttonContext] == true;
end

function UnitReplenishmentUIManager:RefreshUI(listenerKey)
    --self:Log("Refreshing UnitInfoPanelUI");
    local ui_root = coreObject:get_ui_root();
    if not Text then
        URP_Log("ERROR: UIMF is missing.");
        return;
    end

    local buildingPanelUnitInfo = find_uicomponent(ui_root, "building_browser", "info_panel_background", "UnitInfoPopup", "details", "top_bar");
    local mainScreenUnitInfo = find_uicomponent(ui_root, "layout", "info_panel_holder", "secondary_info_panel_holder", "info_panel_background", "UnitInfoPopup", "details", "top_bar");
    local unitInfoTopBar = {};
    local replenishmentSuffix = "";
    if self.CachedUIData["IsBuildingPanelOpen"] == true then
        --self:Log("Building panel is open");
        unitInfoTopBar = buildingPanelUnitInfo;
        replenishmentSuffix = "_building_open";
    else
        --self:Log("Building panel is not open");
        unitInfoTopBar = mainScreenUnitInfo;
        replenishmentSuffix = "_building_closed";
    end

    if unitInfoTopBar == nil then
        URP_Log("Wrong unit info path");
        return;
    end

    local unitReplenishment = find_uicomponent(unitInfoTopBar,  "urp_unit_replenishment");
    local unitReplenishmentValue = {};
    local unitReplenishmentIcon = {};
    if not unitReplenishment then
        local upKeepCost = find_uicomponent(unitInfoTopBar,  "upkeep_cost");
        local upkeepCostX, upkeepCostY = upKeepCost:Position();
        if self.CachedUIData["upkeep_cost"] == nil then
            upKeepCost:MoveTo(upkeepCostX - 5, upkeepCostY);
            self.CachedUIData["upkeep_cost"] = {upkeepCostX - 5, upkeepCostY};
        end
        --self:Log("Replenishment icon was not found. Initialising...");
        unitReplenishment = UIComponent(unitInfoTopBar:CreateComponent("urp_unit_replenishment", coreObject.path_to_dummy_component));
        unitReplenishment:MoveTo(upkeepCostX + 60, upkeepCostY);
        unitReplenishmentIcon = Image.new("urp_icon_replenishment"..replenishmentSuffix, unitReplenishment, "ui/urp/icon_replenish.png");
        local unitReplenishmentValueParent = UIComponent(unitInfoTopBar:CreateComponent("urp_replenishment_value_parent", coreObject.path_to_dummy_component));
        unitReplenishmentValueParent:MoveTo(upkeepCostX + 135, upkeepCostY - 20);
        unitReplenishmentValue = Text.new("urp_replenishment_value"..replenishmentSuffix, unitReplenishmentValueParent, "NORMAL", "");
        unitReplenishmentValue:PositionRelativeTo(unitReplenishmentIcon, 26, 6);
        self:Log("Initialised urp_replenishment_value");
    else
        self:Log("Replenishment already exists");
        unitReplenishmentIcon = Util.getComponentWithName("urp_icon_replenishment"..replenishmentSuffix);
        unitReplenishmentIcon:SetVisible(true);
        unitReplenishmentValue = Util.getComponentWithName("urp_replenishment_value"..replenishmentSuffix);
    end

    local factionUnitResources = urpObject:GetFactionUnitResources(urpObject.HumanFaction);
    local highlightedUnitKey = _G.RMUI:GetUnitKeyFromInfoPopup(coreObject);
    local unitResourceData = nil;
    if highlightedUnitKey ~= nil then
        self:Log("Highlighted unit is: "..highlightedUnitKey);
        unitResourceData = factionUnitResources[highlightedUnitKey];
    end
    if unitResourceData == nil
    or unitResourceData.RequiredGrowthForReplenishment == 0 then
        --self:Log("Unit does not have any growth requirement. Hiding...");
        unitReplenishment:SetVisible(false);
        unitReplenishmentValue:SetVisible(false);
    else
        unitReplenishment:SetVisible(true);
        unitReplenishmentValue:SetVisible(true);
        if listenerKey == "UIPM_UnitInfoPanelReplenishmentClick" then
            --self:Log("Unit was clicked");
            self.CachedUIData["ClickedUnitInfo"] = highlightedUnitKey;
        elseif self.CachedUIData["ClickedUnitInfo"] ~= nil
        and listenerKey == "UIPM_UnitInfoPanelReplenishmentOff" then
            --self:Log("Set unit data from previously clicked");
            highlightedUnitKey = self.CachedUIData["ClickedUnitInfo"];
            unitResourceData = factionUnitResources[highlightedUnitKey];
        end
        -- This sets the right image icon depending on replenishment level
        local factionUnitData = urpObject:GetFactionUnitData(urpObject.HumanFaction);
        local unitData = factionUnitData[highlightedUnitKey];
        local replenishingFactionUnitCounts = _G.RM:GetUnitsReplenishingForFaction(urpObject.HumanFaction);
        local replenishingUnitReserves = replenishingFactionUnitCounts[highlightedUnitKey];
        if replenishingUnitReserves == nil then
            replenishingUnitReserves = 0;
        end
        local effectBundleNumber = urpObject:GetReplenishmentEffectBundleNumber(urpObject.HumanFaction, highlightedUnitKey, replenishingUnitReserves, unitData);
        --self:Log("EffectBundleNumber is: "..effectBundleNumber);
        self:SetReplenishIcon(unitReplenishmentIcon, effectBundleNumber, false);
        if unitResourceData ~= nil then
            unitReplenishmentValue:SetText(unitResourceData.RequiredGrowthForReplenishment);
            local replenishmentText = self:GetTooltipReplenishmentText(urpObject.HumanFaction, highlightedUnitKey, unitData, unitResourceData);
            local replenishVanillaUICValue = find_uicomponent(unitInfoTopBar,  "urp_replenishment_value_parent", "urp_replenishment_value"..replenishmentSuffix);
            replenishVanillaUICValue:SetTooltipText(replenishmentText);
            local replenishVanillaUICIcon = find_uicomponent(unitReplenishment,  "urp_icon_replenishment"..replenishmentSuffix);
            replenishVanillaUICIcon:SetTooltipText(replenishmentText);
        end
    end
    self:Log_Finished();
end

function UnitReplenishmentUIManager:GetTooltipReplenishmentText(faction, unitKey, unitData, unitResourceData)
    local replenishingUnits = _G.RM:GetUnitsReplenishingForFaction(faction);
    local unitCount = replenishingUnits[unitKey];
    if unitCount == nil then
        unitCount = 0;
    end
    local growthGeneration = unitData.UnitGrowth;
    --self:Log("growthGeneration is: "..growthGeneration);
    local growthConsumption = unitResourceData.RequiredGrowthForReplenishment * unitCount;
    --self:Log("growthConsumption is: "..growthConsumption);
    local reserveGrowth = unitData.UnitReserves;
    --self:Log("reserveGrowth is: "..reserveGrowth);
    return (growthConsumption.." unit growth is consumed per turn.\n"..growthGeneration.." unit growth is generated per turn.\n"..reserveGrowth.." unit reserves are available.");
end

function UnitReplenishmentUIManager:HideReplenishmentIcons()
    local unitsPanel = find_uicomponent(coreObject:get_ui_root(), "units_panel", "main_units_panel");
    for i = 1, 20  do
        local newReplenishIcon = find_uicomponent(unitsPanel, "replenish_icon_custom_"..i);
        if newReplenishIcon then
            newReplenishIcon:SetVisible(false);
        end
    end
end

function UnitReplenishmentUIManager:GetRecruitmentTextData(localisedUnitName, unitBuildingData, isAlreadyUnlocked)
    local numberOfLines = 0;
    local newUnitNameText = "";
    if isAlreadyUnlocked == true then
        self:Log("Is already unlocked");
        --local headingPadding = "                    ";
        local headingPadding = "";
        -- 9 Spaces to (hopefully) centre the name
        newUnitNameText = headingPadding:sub(1, math.floor(headingPadding:len() - (localisedUnitName:len()/2 - 1)))..localisedUnitName..headingPadding:sub(1, math.floor(headingPadding:len() - (localisedUnitName:len()/2 - 1)))..": ";
        self:Log("Centred name text");
        if tonumber(unitBuildingData.UnitReserveCapChange) > 0 then
            newUnitNameText = newUnitNameText.."+"..unitBuildingData.UnitReserveCapChange.." Reserve cap ";
        end
        self:Log("UnitReserveCapChange");
        if tonumber(unitBuildingData.ImmediateUnitReservesChange) > 0 then
            newUnitNameText = newUnitNameText.."+"..unitBuildingData.ImmediateUnitReservesChange.." Reserves ";
        end
        self:Log("ImmediateUnitReservesChange");
        if tonumber(unitBuildingData.UnitGrowthChange) > 0 then
            newUnitNameText = newUnitNameText.."+"..unitBuildingData.UnitGrowthChange.." Unit Growth";
        end
        self:Log("UnitGrowthChange");
        numberOfLines = 2;
    else
        self:Log("Is unlocked at level");
        newUnitNameText = localisedUnitName.."\n";
        if string.len(localisedUnitName) > 20 then
            numberOfLines = numberOfLines + 1;
        end
        if tonumber(unitBuildingData.UnitReserveCapChange) > 0 then
            newUnitNameText = newUnitNameText.."+"..unitBuildingData.UnitReserveCapChange.." Reserve cap\n";
            numberOfLines = numberOfLines + 1;
        end
        if tonumber(unitBuildingData.ImmediateUnitReservesChange) > 0 then
            newUnitNameText = newUnitNameText.."+"..unitBuildingData.ImmediateUnitReservesChange.." Immediate reserves\n";
            numberOfLines = numberOfLines + 1;
        end
        if tonumber(unitBuildingData.UnitGrowthChange) > 0 then
            newUnitNameText = newUnitNameText.."+"..unitBuildingData.UnitGrowthChange.." Growth Change\n";
            numberOfLines = numberOfLines + 1;
        end
        if numberOfLines == 0 then
            numberOfLines = 1;
        end
    end
    return newUnitNameText, numberOfLines;
end

function UnitReplenishmentUIManager:RefreshReplenishmentIcons(character)
    local faction = character:faction();
    if (faction:is_horde() and not faction:has_home_region())
        or (faction:can_be_horde() and faction:subculture() == "wh2_main_sc_def_dark_elves" and character:character_subtype() == "wh2_main_def_black_ark") then
        local buildingPanel = find_uicomponent(coreObject:get_ui_root(), "units_panel", "main_units_panel", "horde_building_frame");
        if buildingPanel:Visible() then
            self:Log("Horde buildings are visible...hiding replenishment");
            self:HideReplenishmentIcons()
        else
            self:Log("Horde buildings are not visible...showing replenishment");
            self:GetUnitPanelCoordinateData(character);
        self:SetupReplenishmentIconTooltip(character);
        end
    else
        self:GetUnitPanelCoordinateData(character);
        self:SetupReplenishmentIconTooltip(character);
    end
end

function UnitReplenishmentUIManager:RMUIWrapper(context)
    if context.Type ~= "RMUI_CharacterSelected"
    and context.Type ~= "RMUI_CharacterFinishedMovingEvent"
    and context.Type ~= "RMUI_UnitDisbanded"
    and context.Type ~= "RMUI_UnitMerged"
    and context.Type ~= "RMUI_ClickedButtonToRecruitUnits"
    and context.CachedUIData["SelectedCharacterCQI"] ~= nil
    and not self.CachedUIData["RMUIWrapperCallback"]
    then
        self:Log("Trigger RMUIWrapper");
        self:HideReplenishmentIcons();
        self.CachedUIData["RMUIWrapperCallback"] = true;
        local character = cm:get_character_by_cqi(context.CachedUIData["SelectedCharacterCQI"]);
        self:RefreshReplenishmentIcons(character);
        cm:callback(function()
            self.CachedUIData["RMUIWrapperCallback"] = false;
        end,
        0);
        self:Log_Finished();
    end
end

function UnitReplenishmentUIManager:HideChildrenFromIndex(index, componentParent)
    -- Hide all the remaining components
    for i = index - 1, componentParent:ChildCount() - 1 do
        local alreadyUnlockedUnit = UIComponent(componentParent:Find(i));
        --self:Log("Hiding i: "..tostring(i + 1).." id: "..alreadyUnlockedUnit:Id());
        alreadyUnlockedUnit:SetVisible(false);
    end
end

function UnitReplenishmentUIManager:MoveRemainingUnits(buildingChainResources, alreadyUnlockedUnitChanges, iconSuffix, unlockedUnitsXStart, unlockedUnitsYStart)
    local unlockedUnitIndex = 1;
    for unitKey, unitBuildingData in pairs(buildingChainResources) do
        local unlockedTextAtIndexParent = find_uicomponent(alreadyUnlockedUnitChanges, "urp_unlocked_unit_text_parent_"..unlockedUnitIndex..iconSuffix);
        local yPos = unlockedUnitsYStart - 15 + ((unlockedUnitIndex * 35));
        self:Log("Setting Unit: "..unitKey.. " YPos as: "..yPos);
        unlockedTextAtIndexParent:MoveTo(unlockedUnitsXStart + 70, yPos);
        unlockedUnitIndex = unlockedUnitIndex + 1;
        unlockedTextAtIndexParent:SetVisible(true);
    end
end