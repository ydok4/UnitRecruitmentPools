UnitInfoPanelManager = {
    EnableLogging = false,
    UIPathData = {

    },
    UIButtonContexts = {
        button_recruitment = true,
    },
    -- This is where we cache UI element boundary data
    -- This data is not saved and is rebuilt after each load
    CachedUIData = {},
    -- If we need to simulate mouse over events we should set this as true first
    -- to not trigger other UI listeners
    IgnoreMouseOnUnit = false,
}

function UnitInfoPanelManager:new (o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function UnitInfoPanelManager:Log_Start()
    if self.EnableLogging == true then
        io.open("UnitInfoPanelManager.txt","w"):close();
    end
end

function UnitInfoPanelManager:Log(text)
    if self.EnableLogging == true then
        local logText = tostring(text);
        local logTimeStamp = os.date("%d, %m %Y %X");
        local popLog = io.open("UnitInfoPanelManager.txt","a");

        popLog :write("RMUI:  "..logText .. "   : [".. logTimeStamp .. "]\n");
        popLog :flush();
        popLog :close();
    end
end

function UnitInfoPanelManager:Log_Finished()
    if self.EnableLogging == true then
        local popLog = io.open("UnitInfoPanelManager.txt","a");

        popLog :write("UIPM:  FINISHED\n\n");
        popLog :flush();
        popLog :close();
    end
end

-- Applies UI under appropriate circumstances
function UnitInfoPanelManager:SetupPostUIListeners(core, urp)
    self:Log_Start();
    self:Log("UIPM_UnitInfoPanelReplenishmentOn");
    self.CachedUIData["ResetUnitInfo"] = false;
    self.CachedUIData["DisbandingUnit"] = false;
    self.CachedUIData["ReplenishIconCoordinates"] = {897, 1586};

    core:add_listener(
        "UIPM_UnitInfoPanelReplenishmentOn",
        "ComponentMouseOn",
        function(context)
            return self.IgnoreMouseOnUnit == false
            and (string.match(context.string, "LandUnit")
            or string.match(context.string, "Agent"))
            and self.CachedUIData["SelectedCharacterFaction"] == urp.HumanFaction:name();
        end,
        function(context)
            self:Log("UIPM_UnitInfoPanelReplenishmentOn");
            cm:callback(function()
                self:RefreshUI(core, urp, "UIPM_UnitInfoPanelReplenishmentOn");
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
            --self:Log("Context is: "..context.string.." ClickedUnitInfo: "..self.CachedUIData["ClickedUnitInfo"].." ResetUnitInfo: "..self.CachedUIData["ResetUnitInfo"].." SelectedCharacterFaction: "..self.CachedUIData["SelectedCharacterFaction"]);
            return not (string.match(context.string, "LandUnit") and string.match(context.string, "Agent"))
            and self.CachedUIData["ClickedUnitInfo"] ~= nil
            and self.CachedUIData["ResetUnitInfo"] == true
            and self.CachedUIData["SelectedCharacterFaction"] == urp.HumanFaction:name();
        end,
        function(context)
            self:Log("UIPM_UnitInfoPanelReplenishmentOff");
            local ui_root = core:get_ui_root();
            local unitInfoPanel = find_uicomponent(ui_root, "layout", "info_panel_holder", "secondary_info_panel_holder", "info_panel_background", "UnitInfoPopup");
            --unitInfoPanel:SetVisible(false);
            cm:callback(function()
                self:RefreshUI(core, urp, "UIPM_UnitInfoPanelReplenishmentOff");
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
            and self.CachedUIData["SelectedCharacterFaction"] == urp.HumanFaction:name();
        end,
        function(context)
            self:Log("UIPM_UnitInfoPanelReplenishmentClick");
            local ui_root = core:get_ui_root();
            local unitInfoPanel = find_uicomponent(ui_root, "layout", "info_panel_holder", "secondary_info_panel_holder", "info_panel_background", "UnitInfoPopup");
            --unitInfoPanel:SetVisible(false);
            cm:callback(function()
                self:RefreshUI(core, urp, "UIPM_UnitInfoPanelReplenishmentClick");
                self.CachedUIData["ResetUnitInfo"] = true;
            end,
            0);
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
            and self.CachedUIData["SelectedCharacterFaction"] == urp.HumanFaction:name();
        end,
        function(context)
            self:Log("UIPM_UnitInfoPanelReplenishmentClick");
            if context.string == "tab_horde_buildings" then
                self:HideReplenishmentIcons(core);
            elseif self.CachedUIData["SelectedCharacterCQI"] then
                cm:steal_user_input(false);
                local character = cm:get_character_by_cqi(self.CachedUIData["SelectedCharacterCQI"]);
                cm:callback(function()
                    self:RefreshReplenishmentIcons(core, urp, character);
                    cm:steal_user_input(false);
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
            if self.CachedUIData["SelectedCharacterCQI"] then
                local character = cm:get_character_by_cqi(self.CachedUIData["SelectedCharacterCQI"]);
                self:RefreshReplenishmentIcons(core, urp, character);
            end
            self:Log_Finished();
        end,
        true
    );

    core:add_listener(
        "UIPM_UnitPanelClosedCampaign",
        "PanelClosedCampaign",
        function(context)
            return context.string == "units_panel";
        end,
        function(context)
            self:Log("UIPM_UnitPanelClosedCampaign listener");
            self.CachedUIData["UnitPanelOpened"] = false;
            self.CachedUIData["SelectedCharacterCQI"] = nil;
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
            self.CachedUIData["SelectedCharacterFaction"] = faction:name();
            if faction:name() ~= urp.HumanFaction:name() then
                self:Log("Non human character selected");
                self:HideReplenishmentIcons(core);
            end
            if not self.CachedUIData["UnitPanelOpened"] then
                self.CachedUIData["SelectedCharacterCQI"] = character:command_queue_index();
                self:Log("Panel is not open, closing");
                self:Log_Finished();
                return;
            else
                cm:callback(function()
                    self:RefreshReplenishmentIcons(core, urp, character);
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
            cm:steal_user_input(true);
            self:Log("UIPM_UnitMerged");
            local character = context:unit():force_commander();
            cm:callback(function()
                self:RefreshReplenishmentIcons(core, urp, character);
                self.CachedUIData["DisbandingUnit"] = false;
                cm:steal_user_input(false);
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
            cm:steal_user_input(true);
            self:Log("UIPM_UnitDisbanded");
            local character = context:unit():force_commander();
            cm:callback(function()
                self:RefreshReplenishmentIcons(core, urp, character);
                self.CachedUIData["DisbandingUnit"] = false;
                cm:steal_user_input(false);
                self:Log_Finished();
            end,
            0.15);
        end,
        true
    );
end

function UnitInfoPanelManager:GetUnitPanelCoordinateData(core, character)
    local unitsPanel = find_uicomponent(core:get_ui_root(), "units_panel");
    local characterUnitList = character:military_force():unit_list();
    local numItems = characterUnitList:num_items() - 1;
    local screenX, screenY = core:get_screen_resolution();
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

function UnitInfoPanelManager:SetupReplenishmentIconTooltip(core, urp, character)
    local unitUI = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "units");
    local faction = character:faction();
    local factionUnitData = urp:GetFactionUnitData(faction);
    local factionUnitResources = urp:GetFactionUnitResources(faction);
    local characterUnitList = character:military_force():unit_list();
    local replenishingFactionUnitCounts = _G.RM:GetUnitsReplenishingForFaction(faction);
    local numberOfUnitUI = unitUI:ChildCount() - 1;
    self:Log("Number of units in UI: "..numberOfUnitUI);
    -- We start at because the general is number and we don't care about them
    for i = 1, 20  do
        if i > numberOfUnitUI then
            self:SetupReplenishmentIcon(core, i, 0, "", false);
        else
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
                        local replenishingUnitAmount = replenishingFactionUnitCounts[unitKey];
                        if replenishingUnitAmount == nil then
                            --self:Log("Unit replenishment is missing, setting to 0");
                            replenishingUnitAmount = 0;
                        end
                        local effectBundleNumber = urp:GetReplenishmentEffectBundleNumber(faction, unitKey, replenishingUnitAmount, unitData);
                        local isDisabled = false;
                        if string.match(currentTooltipText, "unit is not replenishing") then
                            self:Log("Replenishment is disabled");
                            isDisabled = true;
                        else
                            self:Log("Replenishment is active");
                        end
                        local tooltipText = currentTooltipText.."\n"..replenishmentText;
                        if isDisabled then
                            self:SetupReplenishmentIcon(core, i, effectBundleNumber, tooltipText, true);
                            originalReplenishIcon:SetVisible(false);
                        else
                            self:SetupReplenishmentIcon(core, i, effectBundleNumber, tooltipText, false);
                            self:SetReplenishIcon(originalReplenishIcon, effectBundleNumber, false);
                            originalReplenishIcon:SetTooltipText(tooltipText);
                        end
                    end
                end
            else
                self:Log("No unit data...ignoring");
            end
        end
    end
end

function UnitInfoPanelManager:SetupReplenishmentIcon(core, index, effectBundleNumber, tooltipText, isVisible)
    local unitsPanel = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel");
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

function UnitInfoPanelManager:SetReplenishIcon(replenishComponent, replenishPenaltyLevel, isDisabled)
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

function UnitInfoPanelManager:IsValidButtonContext(buttonContext)
    return self.UIButtonContexts[buttonContext] == true;
end

function UnitInfoPanelManager:RefreshUI(core, urp, listenerKey)
    --self:Log("Refreshing UnitInfoPanelUI");
    local ui_root = core:get_ui_root();
    if not Text then
        URP_Log("ERROR: UIMF is missing.");
        return;
    end

    local unitInfoTopBar = find_uicomponent(ui_root, "layout", "info_panel_holder", "secondary_info_panel_holder", "info_panel_background", "UnitInfoPopup", "details", "top_bar");
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
        unitReplenishment = UIComponent(unitInfoTopBar:CreateComponent("urp_unit_replenishment", core.path_to_dummy_component));
        unitReplenishment:MoveTo(upkeepCostX + 60, upkeepCostY);
        --self:Log("Initialised urp_unit_replenishment");
        unitReplenishmentIcon = Image.new("urp_icon_replenishment", unitReplenishment, "ui/urp/icon_replenish.png");
        --self:Log("Initialised urp_icon_replenishment");
        local unitReplenishmentValueParent = UIComponent(unitInfoTopBar:CreateComponent("urp_replenishment_value_parent", core.path_to_dummy_component));
        unitReplenishmentValueParent:MoveTo(upkeepCostX + 135, upkeepCostY - 20);
        unitReplenishmentValue = Text.new("urp_replenishment_value", unitReplenishmentValueParent, "NORMAL", "");
        unitReplenishmentValue:PositionRelativeTo(unitReplenishmentIcon, 26, 6);
        --self:Log("Initialised urp_replenishment_value");
    else
        --self:Log("Replenishment already exists");
        unitReplenishmentIcon = Util.getComponentWithName("urp_icon_replenishment");
        unitReplenishmentValue = Util.getComponentWithName("urp_replenishment_value");
    end


    local factionUnitResources = urp:GetFactionUnitResources(urp.HumanFaction);
    local highlightedUnitKey = _G.RMUI:GetUnitKeyFromInfoPopup(core);
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
        local factionUnitData = urp:GetFactionUnitData(urp.HumanFaction);
        local unitData = factionUnitData[highlightedUnitKey];
        local replenishingFactionUnitCounts = _G.RM:GetUnitsReplenishingForFaction(urp.HumanFaction);
        local replenishingUnitAmount = replenishingFactionUnitCounts[highlightedUnitKey];
        if replenishingUnitAmount == nil then
            replenishingUnitAmount = 0;
        end
        local effectBundleNumber = urp:GetReplenishmentEffectBundleNumber(urp.HumanFaction, highlightedUnitKey, replenishingUnitAmount, unitData);
        --self:Log("EffectBundleNumber is: "..effectBundleNumber);
        self:SetReplenishIcon(unitReplenishmentIcon, effectBundleNumber, false);
        if unitResourceData ~= nil then
            unitReplenishmentValue:SetText(unitResourceData.RequiredGrowthForReplenishment);
            --unitReplenishmentValue:PositionRelativeTo(unitReplenishment, 25, 3);
            local replenishmentText = self:GetTooltipReplenishmentText(urp.HumanFaction, highlightedUnitKey, unitData, unitResourceData);
            local replenishVanillaUICValue = find_uicomponent(unitInfoTopBar,  "urp_replenishment_value_parent", "urp_replenishment_value");
            replenishVanillaUICValue:SetTooltipText(replenishmentText);
            local replenishVanillaUICIcon = find_uicomponent(unitReplenishment,  "urp_icon_replenishment");
            replenishVanillaUICIcon:SetTooltipText(replenishmentText);
        end
    end
    --local unitInfoPanel = find_uicomponent(ui_root, "layout", "info_panel_holder", "secondary_info_panel_holder", "info_panel_background", "UnitInfoPopup");
    --unitInfoPanel:SetVisible(true);
    self:Log_Finished();
end

function UnitInfoPanelManager:GetTooltipReplenishmentText(faction, unitKey, unitData, unitResourceData)
    local unitCount = _G.RM:GetUnitCountForFaction(faction, unitKey);
    if unitCount == nil then
        unitCount = 0;
    end
    local growthGeneration = unitData.UnitGrowth;
    --self:Log("growthGeneration is: "..growthGeneration);
    local growthConsumption = unitResourceData.RequiredGrowthForReplenishment * unitCount;
    --self:Log("growthConsumption is: "..growthConsumption);
    local reserveGrowth = unitData.UnitAmount;
    --self:Log("reserveGrowth is: "..reserveGrowth);
    return (growthConsumption.." unit growth is consumed per turn.\n"..growthGeneration.." unit growth is generated per turn.\n"..reserveGrowth.." unit growth is available in reserve.");
end

function UnitInfoPanelManager:HideReplenishmentIcons(core)
    local unitsPanel = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel");
    for i = 1, 20  do
        local newReplenishIcon = find_uicomponent(unitsPanel, "replenish_icon_custom_"..i);
        if newReplenishIcon then
            newReplenishIcon:SetVisible(false);
        end
    end
end

function UnitInfoPanelManager:RefreshReplenishmentIcons(core, urp, character)
    self:GetUnitPanelCoordinateData(core, character);
    self:SetupReplenishmentIconTooltip(core, urp, character);
end