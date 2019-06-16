RecruitmentUIManager = {
    EnableLogging = false,
    UIPathData = {
        -- Recruitment Panel
        RecruitmentPanel = {},
        -- Mercenary Panel
        MercenaryPanel = {},
        -- Faction with shipbuilding recruitment
        RecruitmentPoolListLocal1UnitList = {},
        RecruitmentPoolListLocal2UnitList = {},
        RecruitmentPoolListGlobalUnitList = {},
        -- Standard recruitment
        RecruitmentOptionsLocal1UnitList = {},
        RecruitmentOptionsLocal2UnitList = {},
        RecruitmentOptionsGlobalUnitList = {},
        -- Mercenary / Raise Dead
        MercenaryUnitList = {},
    },
    UIButtonContexts = {
        button_recruitment = true,
        button_mercenaries = true,
        button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_MUSTER = true,
        button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SET_CAMP = true,
        button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SET_CAMP_RAIDING = true,
        button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_DEFAULT = true,
        button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SETTLE = true,
        button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_TUNNELING = true,
        button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_CHANNELING = true,
        button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_LAND_RAID = true,
        button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_MARCH = true,
        button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_AMBUSH = true,
    },
    -- This is where we cache UI element boundary data
    -- This data is not saved and is rebuilt after each load
    CachedUIData = {},
    -- This stores the keys and the amount of units the player has queued
    -- from the mercenary/raise dead pools
    CachedMercenaryRecruitment = {},
    -- This stores the amount of units the player has queued
    CachedStandardRecruitmentCount = {},
    -- This is a stack of functions which gets called every time
    -- an action should trigger a refresh for the recruitment UI
    RefreshUICallbacks = {},
    -- These callbacks are triggered before the UI should refresh
    -- They should be used to perform any data updates that need to
    -- be done before the UI should refresh
    UIEventCallbacks = {},
}

function RecruitmentUIManager:new (o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function RecruitmentUIManager:Log_Start()
    if self.EnableLogging == true then
        io.open("RecruitmentUIManager.txt","w"):close();
    end
end

function RecruitmentUIManager:Log(text)
    if self.EnableLogging == true then
        local logText = tostring(text);
        local logTimeStamp = os.date("%d, %m %Y %X");
        local popLog = io.open("RecruitmentUIManager.txt","a");

        popLog :write("RMUI:  "..logText .. "   : [".. logTimeStamp .. "]\n");
        popLog :flush();
        popLog :close();
    end
end

function RecruitmentUIManager:RegisterRefreshUICallback(key, callbackFunction)
    self.RefreshUICallbacks[key] = callbackFunction;
end

function RecruitmentUIManager:RegisterUIEventCallback(key, callbackFunction)
    self.UIEventCallbacks[key] = callbackFunction;
end

function RecruitmentUIManager:Log_Finished()
    if self.EnableLogging == true then
        local popLog = io.open("RecruitmentUIManager.txt","a");

        popLog :write("RMUI:  FINISHED\n\n");
        popLog :flush();
        popLog :close();
    end
end

-- Applies UI under appropriate circumstances
function RecruitmentUIManager:SetupPostUIListeners(core)
    self.CachedUIData["DisbandingUnit"] = false;
    self:Log("RMUI_ClickedButtonToRecruitUnits");
    core:add_listener(
        "RMUI_ClickedButtonToRecruitUnits",
        "ComponentLClickUp",
        function(context)
            return self:IsValidButtonContext(context.string);
        end,
        function(context)
            cm:steal_user_input(true);
            self:Log_Start();
            self:Log("ClickedButtonRecruitedUnits context is "..context.string);
            local buttonContext = context.string;
            cm:callback(function()
                local uiSuffix = nil;
                local clickedButton = false;
                if buttonContext == "button_mercenaries" then
                    uiSuffix = "_mercenary";
                    clickedButton = true;
                elseif buttonContext == "button_recruitment"
                or self:IsGlobalRecruitmentStance(buttonContext) then
                    clickedButton = true;
                end
                self:RefreshUI(uiSuffix, clickedButton);
                cm:steal_user_input(false);
            end,
            0);
        end,
        true
    );

    -- Applies UI under appropriate circumstances
    self:Log("RMUI_MercenaryPanelClosed");
    core:add_listener(
        "RMUI_MercenaryPanelClosed",
        "PanelClosedCampaign",
        function(context)
            return context.string == "mercenary_recruitment";
        end,
        function(context)
            self:Log("MercenaryPanelClosed listener");
            self:ClearMercenaryCache();
            self:Log_Finished();
        end,
        true
    );

    -- Recruitment UI should also be applied when a human controlled character is selected
    self:Log("RMUI_CharacterSelected");
    core:add_listener(
        "RMUI_CharacterSelected",
        "CharacterSelected",
        function(context)
            return context:character():faction():is_human() == true;
        end,
        function(context)
            cm:steal_user_input(true);
            self:Log_Start();
            self:Log("CharacterSelected context is "..context.string);
            local character = context:character();
            self.CachedUIData["SelectedCharacterCQI"] = character:command_queue_index();
            self:ClearMercenaryCache();
            cm:callback(function()
                self:RefreshUI(nil, true);
                self.CachedStandardRecruitmentCount = self:GetQueuedUnitCount(core);
                cm:steal_user_input(false);
            end,
            0);
        end,
        true
    );

    self:Log("RMUI_ClickedButtonRecruitedUnits");
    -- Modifies the unit pools for the standard recruitment
    core:add_listener(
        "RMUI_ClickedButtonRecruitedUnits",
        "ComponentLClickUp",
        function(context)
            return string.match(context.string, "_recruitable")
            or string.match(context.string, "QueuedLandUnit");
        end,
        function(context)
            self:Log_Start();
            cm:steal_user_input(true);
            local buttonContext = context.string;
            self:Log("ClickedButtonRecruitedUnits context is "..buttonContext);
            -- Cancelling
            if string.match(buttonContext, "QueuedLandUnit") then
                local queuedUnit = find_uicomponent(core:get_ui_root(), "main_units_panel", "units", buttonContext);
                queuedUnit:SimulateMouseOn();
                local unitKey = self:GetUnitKeyFromInfoPopup(core);
                self:Log("Cancelling unitKey: "..unitKey);
                self:TriggerUIEventCallbacks(unitKey, true, "RMUI_ClickedButtonRecruitedUnits");
            end
            cm:callback(function()
                local currentQueuedUnitCount =  self:GetQueuedUnitCount(core);
                self:Log("currentQueuedUnitCount: "..currentQueuedUnitCount.." CachedStandardRecruitmentCount: "..self.CachedStandardRecruitmentCount);
                local uiSuffix = nil;
                if currentQueuedUnitCount ~= self.CachedStandardRecruitmentCount then
                    -- Adding
                    if string.match(buttonContext, "_recruitable") then
                        uiSuffix = "_recruitable";
                        local unitKey = string.match(buttonContext, "(.*)_recruitable");
                        self:Log("Clicked unit is "..unitKey);
                        self:TriggerUIEventCallbacks(unitKey, false, "RMUI_ClickedButtonRecruitedUnits");
                    end
                    self:RefreshUI(uiSuffix);
                    self.CachedStandardRecruitmentCount = currentQueuedUnitCount;
                end
                cm:steal_user_input(false);
            end,
            0.15);
        end,
        true
    );

    self:Log("RMUI_ClickedButtonMercenaryUnits");
    -- Modifies the unit pools for Mercenary/Raise Dead recruitment
    core:add_listener(
        "RMUI_ClickedButtonMercenaryUnits",
        "ComponentLClickUp",
        function(context)
            return string.match(context.string, "_mercenary")
            or string.match(context.string, "temp_merc_");
        end,
        function(context)
            cm:steal_user_input(true);
            self:Log_Start();
            self:Log("ClickedButtonMercenaryUnits context is "..context.string);
            local buttonContext = context.string;
            local uiSuffix = nil;
            -- Cancelling
            if string.match(context.string, "temp_merc_") then
                local unitIndex = string.match(buttonContext, "temp_merc_(.*)");
                local unitKey = self:GetUnitKeyFromCache(unitIndex);
                if unitKey ~= nil then
                    self:Log("Uncaching mercenary unit: "..unitKey.." at index: "..unitIndex);
                    self:RemoveUnitFromMercenaryCache(unitIndex);
                    self:TriggerUIEventCallbacks(unitKey, true, "RMUI_ClickedButtonMercenaryUnits");
                end
            -- Adding
            else
                uiSuffix = "_mercenary";
                local unitKey = string.match(buttonContext, "(.*)_mercenary");
                self:Log("Caching mercenary unit: "..unitKey);
                self:AddUnitToMercenaryCache(unitKey);
                self:TriggerUIEventCallbacks(unitKey, false, "RMUI_ClickedButtonMercenaryUnits");
            end
            cm:callback(function()
                self:RefreshUI(uiSuffix);
                cm:steal_user_input(false);
            end,
            0.15);
        end,
        true
    );

    self:Log("RMUI_RecruitedMercenaryUnits");
    -- Clears the mercenary cache without reverting the changes
    core:add_listener(
        "RMUI_RecruitedMercenaryUnits",
        "ComponentLClickUp",
        function(context)
            return context.string == "button_raise_dead";
        end,
        function(context)
            self:Log("Commiting mercenary cache data");
            self:CommitMercenaryCache();
        end,
        true
    );

    -- Unit merged listener
    core:add_listener(
        "RMUI_UnitMerged",
        "UnitMergedAndDestroyed",
        function(context)
            return context:unit():faction():name() ~= "rebels";
        end,
        function(context)
            cm:steal_user_input(true);
            local faction = context:unit():faction();
            local unitKey = context:unit():unit_key();
            self:Log("Unit:"..unitKey.." merged/destroyed for faction: "..faction:name());
            self:TriggerUIEventCallbacks(unitKey, true, "RMUI_UnitMerged");
            if self.CachedUIData["DisbandingUnit"] == false then
                self.CachedUIData["DisbandingUnit"] = true;
                cm:callback(function()
                    self:RefreshUI();
                    self.CachedUIData["DisbandingUnit"] = false;
                end,
                0.15);
            end
            cm:steal_user_input(false);
            self:Log_Finished();
        end,
        true
    );

    -- Unit disbanded listener
    core:add_listener(
        "RMUI_UnitDisbanded",
        "UnitDisbanded",
        function(context)
            return context:unit():faction():name() ~= "rebels";
        end,
        function(context)
            cm:steal_user_input(true);
            local faction = context:unit():faction();
            local unitKey = context:unit():unit_key();
            self:Log("Unit: "..unitKey.." disbanded for faction: "..faction:name());
            self:TriggerUIEventCallbacks(unitKey, true, "RMUI__UnitDisbanded");
            if self.CachedUIData["DisbandingUnit"] == false then
                self.CachedUIData["DisbandingUnit"] = true;
                cm:callback(function()
                    self:RefreshUI();
                    self.CachedUIData["DisbandingUnit"] = false;
                end,
                0.15);
            end
            cm:steal_user_input(false);
            self:Log_Finished();
        end,
        true
    );

    self:Log_Finished();
end

function RecruitmentUIManager:IsValidButtonContext(buttonContext)
    return self.UIButtonContexts[buttonContext] == true;
end

function RecruitmentUIManager:IsGlobalRecruitmentStance(buttonContext)
    local isglobalRecruitmentStance = false;
    if buttonContext == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_MUSTER"
    or buttonContext == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SET_CAMP"
    or buttonContext == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SET_CAMP_RAIDING"
    or buttonContext == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SETTLE" then
        isglobalRecruitmentStance = true;
    end
    return isglobalRecruitmentStance;
end

function RecruitmentUIManager:TriggerUIEventCallbacks(unitKey, isCancelled, listenerContext)
    local character = nil;
    if self.CachedUIData["SelectedCharacterCQI"] ~= nil then
        character = cm:get_character_by_cqi(self.CachedUIData["SelectedCharacterCQI"]);
    end
    local context = {
        UnitKey = unitKey,
        IsCancelled = isCancelled,
        ListenerContext = listenerContext,
        RecruitingCharacter = character,
    }
    for callbackKey, callback in pairs(self.UIEventCallbacks) do
        self:Log("Triggering UIEventCallback: "..callbackKey.." for listenerContext: "..listenerContext);
        callback(context);
    end
end

function RecruitmentUIManager:RefreshUI(uiSuffix, buttonClicked)
    if buttonClicked == true then
        self:RefreshUnitUIData();
    end
    local uipUIPathData = self.UIPathData;
    if uiSuffix == nil then
        uiSuffix = self:GetPanelUIUnitExtension();
        if uiSuffix == nil then
            self:Log("No recruitment panels present. Exiting...");
            return;
        end
    end

    if uiSuffix == "_mercenary" then
        if self:AreUnitsInUIList(uipUIPathData.MercenaryUnitList) then
            self:Log("Printing out mercenary units");
            self:ApplyUnitUI(uipUIPathData.MercenaryUnitList, uiSuffix, "mercenary");
        else
            self:Log("No mercenary units");
            self:Log_Finished();
        end
        return;
    end
    self:Log("Local1 units:");
    if self:AreUnitsInUIList(uipUIPathData.RecruitmentOptionsLocal1UnitList) then
        self:ApplyUnitUI(uipUIPathData.RecruitmentOptionsLocal1UnitList, uiSuffix, "local1_option");
    elseif self:AreUnitsInUIList(uipUIPathData.RecruitmentPoolListLocalUnitList) then
        self:ApplyUnitUI(uipUIPathData.RecruitmentPoolListLocalUnitList, uiSuffix, "local1_list");
    else
        self:Log("No units");
        self:Log_Finished();
    end
    self:Log("Local2 units:");
    if self:AreUnitsInUIList(uipUIPathData.RecruitmentOptionsLocal2UnitList) then
        self:ApplyUnitUI(uipUIPathData.RecruitmentOptionsLocal2UnitList, uiSuffix, "local2_option");
    elseif self:AreUnitsInUIList(uipUIPathData.RecruitmentPoolListLocal2UnitList) then
            self:ApplyUnitUI(uipUIPathData.RecruitmentPoolListLocal2UnitList, uiSuffix, "local2_list");
    else
        self:Log("No units");
        self:Log_Finished();
    end
    self:Log("Global units:");
    if self:AreUnitsInUIList(uipUIPathData.RecruitmentOptionsGlobalUnitList) then
        self:ApplyUnitUI(uipUIPathData.RecruitmentOptionsGlobalUnitList, uiSuffix, "global_option");
    elseif self:AreUnitsInUIList(uipUIPathData.RecruitmentPoolListGlobalUnitList) then
        self:ApplyUnitUI(uipUIPathData.RecruitmentPoolListGlobalUnitList, uiSuffix, "global_list");
    else
        self:Log("No units");
        self:Log_Finished();
    end

    self:Log_Finished();
end

function RecruitmentUIManager:GetPanelUIUnitExtension()
    local pathData = self.UIPathData;
    -- Mercenary Panel
    pathData.MercenaryPanel = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "mercenary_display");
    if pathData.MercenaryPanel and pathData.MercenaryPanel.Visible and pathData.MercenaryPanel:Visible() then
        return "_mercenary";
    else
        pathData.RecruitmentPanel = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker");
        if pathData.RecruitmentPanel and pathData.RecruitmentPanel.Visible and pathData.RecruitmentPanel:Visible() then
            return "_recruitable";
        end
    end
    return nil;
end

function RecruitmentUIManager:RefreshUnitUIData()
    self:Log("Refreshing unit ui");
    local pathData = self.UIPathData;
    -- Mercenary Panel
    pathData.MercenaryPanel = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "mercenary_display");
    -- Mercenary Panel and recruitment panel are mutually exclusive, so we can have a small optimisation by
    -- ignoring the normal recruitment panel or mercenary panel in some cases.
    if pathData.MercenaryPanel and pathData.MercenaryPanel.Visible and pathData.MercenaryPanel:Visible() then
        self:Log("Mercenary panel is visible");
        -- Mercenary / Raise Dead
        pathData.MercenaryUnitList = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "mercenary_display", "listview", "list_clip", "list_box");
        self:ResetRecruitmentPanelData();
        self:Log("Recruitment panel is not visible");
    else
        self:ResetMercenaryPanelData();
        self:Log("Mercenary panel is not visible");
        -- Recruitment Panel
        pathData.RecruitmentPanel = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker");
        if pathData.RecruitmentPanel and pathData.RecruitmentPanel.Visible and pathData.RecruitmentPanel:Visible() then
            self:Log("Recruitment panel is visible");
            -- Faction with shipbuilding recruitment
            pathData.RecruitmentPoolListLocal1UnitList = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "local1", "unit_list", "listview", "list_clip", "list_box");
            pathData.RecruitmentPoolListLocal2UnitList = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "local2", "unit_list", "listview", "list_clip", "list_box");
            -- Shipbuilding and Standard global recruitment requires a check to see if Global recruitment is blocked/enabled due to stances
            local globalRecruitmentOptionsBlocker = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "global_min");
            if globalRecruitmentOptionsBlocker and globalRecruitmentOptionsBlocker.Visible and globalRecruitmentOptionsBlocker:Visible() == true then
                pathData.RecruitmentPoolListGlobalUnitList = {};
                pathData.RecruitmentOptionsGlobalUnitList = {};
            else
                pathData.RecruitmentOptionsGlobalUnitList = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "global", "unit_list", "listview", "list_clip", "list_box");
                pathData.RecruitmentPoolListGlobalUnitList = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_listbox", "recruitment_pool_list", "list_clip", "list_box", "global", "unit_list", "listview", "list_clip", "list_box");
            end
            -- Local recruitment / Black Ark recruitment (Only if local2 is NOT available)
            pathData.RecruitmentOptionsLocal1UnitList = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "local1", "unit_list", "listview", "list_clip", "list_box");
            -- Black Ark recruitment (Only if local1 is also available)
            pathData.RecruitmentOptionsLocal2UnitList = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "recruitment_listbox", "local2", "unit_list", "listview", "list_clip", "list_box");
        else
            self:Log("Recruitment panel is not visible");
            self:ResetRecruitmentPanelData();
        end
    end
    self:Log_Finished();
end

function RecruitmentUIManager:ResetRecruitmentPanelData()
    local pathData = self.UIPathData;
    pathData.RecruitmentPoolListLocal1UnitList = {};
    pathData.RecruitmentPoolListLocalUnitList = {};
    pathData.RecruitmentPoolListGlobalUnitList = {};
    pathData.RecruitmentOptionsLocal1UnitList = {};
    pathData.RecruitmentOptionsLocal2UnitList = {};
    pathData.RecruitmentOptionsGlobalUnitList = {};
end

function RecruitmentUIManager:ResetMercenaryPanelData()
    local pathData = self.UIPathData;
    pathData.MercenaryUnitList = {};
end

function RecruitmentUIManager:AreUnitsInUIList(uiToUnits)
    if uiToUnits and uiToUnits.ChildCount and uiToUnits:ChildCount() > 0 then
        return true;
    else
        return false;
    end
end

function RecruitmentUIManager:ApplyUnitUI(uiToUnits, uiSuffix, type)
    self:Log("ApplyUnitUI");
    if uiToUnits and uiToUnits:ChildCount() > 0 then
        local context = {
            UiToUnits = uiToUnits,
            UiSuffix = uiSuffix,
            Type = type,
            CachedUIData = self.CachedUIData,
        }
        for callbackKey, callback in pairs(self.RefreshUICallbacks) do
            self:Log("Triggering callback: "..callbackKey);
            callback(context);
        end
    else
        self:Log("Recruitment uiToUnits is empty");
    end
    self:Log_Finished();
end

function RecruitmentUIManager:ClearMercenaryCache()
    self:Log("Clearing Mercenary cache");
    self:RevertMercenaryCache();
    self.CachedMercenaryRecruitment = {};
end

function RecruitmentUIManager:AddUnitToMercenaryCache(unitKey)
    self.CachedMercenaryRecruitment[#self.CachedMercenaryRecruitment + 1] = unitKey;
end

function RecruitmentUIManager:GetUnitKeyFromCache(uiIndex)
    return self.CachedMercenaryRecruitment[uiIndex + 1];
end

function RecruitmentUIManager:RemoveUnitFromMercenaryCache(uiIndex)
    self.CachedMercenaryRecruitment[uiIndex + 1] = nil;
end

function RecruitmentUIManager:CommitMercenaryCache()
    self.CachedMercenaryRecruitment = {};
end

function RecruitmentUIManager:RevertMercenaryCache()
    self:Log("RevertMercenaryCache");
    for index, unitKey in pairs(self.CachedMercenaryRecruitment) do
        self:TriggerUIEventCallbacks(unitKey, true, "RevertMercenaryCache");
    end
end

function RecruitmentUIManager:GetUnitKeyFromInfoPopup(core)
    local unitInfoPopup = find_uicomponent(core:get_ui_root(), "UnitInfoPopup", "tx_unit-type");
    local unitTypeText = unitInfoPopup:GetStateText();
    --self:Log("Popup state text: "..unitTypeText);
    local unitKey = string.match(unitTypeText, "/unit/(.-)%]%]");
    if unitKey == nil then
        return;
    end
    return unitKey;
end

function RecruitmentUIManager:GetQueuedUnitCount(core)
    local count = 0;
    local unitUI = find_uicomponent(core:get_ui_root(), "main_units_panel", "units");
    for i = 1, unitUI:ChildCount() - 1 do
        local unitComponent = UIComponent(unitUI:Find(i));
        local unitId = unitComponent:Id();
        if string.match(unitId, "QueuedLandUnit") then
            count = count + 1;
        end
    end
    return count;
end