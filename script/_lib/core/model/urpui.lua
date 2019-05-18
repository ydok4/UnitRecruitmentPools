URPUI = {
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
    -- This is where we cache UI element position/boundary data
    -- This data is not saved and is rebuilt after each load
    CachedUIData = {},
}

function URPUI:new (o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function URPUI:RefreshUI(unitData, uiSuffix)
    self:RefreshUnitUIData();
    local uipUIPathData = self.UIPathData;
    if uiSuffix == nil then
        uiSuffix = self:GetPanelUIUnitExtension();
        if uiSuffix == nil then
            URP_Log("No recruitment panels present. Existing...");
            return;
        end
    end

    if uiSuffix == "_mercenary" then
        URP_Log("Mercenary units:");
        if self:AreUnitsInUIList(uipUIPathData.MercenaryUnitList) then
            URP_Log("Printing out mercenary units");
            self:ApplyUnitUI(uipUIPathData.MercenaryUnitList, unitData, uiSuffix, "mercenary");
        else
            URP_Log("No units");
            URP_Log_Finished();
        end
        return;
    end
    URP_Log("Local1 units:");
    if self:AreUnitsInUIList(uipUIPathData.RecruitmentOptionsLocal1UnitList) then
        self:ApplyUnitUI(uipUIPathData.RecruitmentOptionsLocal1UnitList, unitData, uiSuffix, "local1_option");
    elseif self:AreUnitsInUIList(uipUIPathData.RecruitmentPoolListLocalUnitList) then
        self:ApplyUnitUI(uipUIPathData.RecruitmentPoolListLocalUnitList, unitData, uiSuffix, "local1_list");
    else
        URP_Log("No units");
        URP_Log_Finished();
    end
    URP_Log("Local2 units:");
    if self:AreUnitsInUIList(uipUIPathData.RecruitmentOptionsLocal2UnitList) then
        self:ApplyUnitUI(uipUIPathData.RecruitmentOptionsLocal2UnitList, unitData, uiSuffix, "local2_option");
    elseif self:AreUnitsInUIList(uipUIPathData.RecruitmentPoolListLocal2UnitList) then
            self:ApplyUnitUI(uipUIPathData.RecruitmentPoolListLocal2UnitList, unitData, uiSuffix, "local2_list");
    else
        URP_Log("No units");
        URP_Log_Finished();
    end
    URP_Log("Global units:");
    if self:AreUnitsInUIList(uipUIPathData.RecruitmentOptionsGlobalUnitList) then
        self:ApplyUnitUI(uipUIPathData.RecruitmentOptionsGlobalUnitList, unitData, uiSuffix, "global_option");
    elseif self:AreUnitsInUIList(uipUIPathData.RecruitmentPoolListGlobalUnitList) then
        self:ApplyUnitUI(uipUIPathData.RecruitmentPoolListGlobalUnitList, unitData, uiSuffix, "global_list");
    else
        URP_Log("No units");
        URP_Log_Finished();
    end

    URP_Log_Finished();
end

function URPUI:GetPanelUIUnitExtension()
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

function URPUI:RefreshUnitUIData()
    URP_Log("Refreshing unit ui");
    local pathData = self.UIPathData;
    -- Mercenary Panel
    pathData.MercenaryPanel = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "mercenary_display");
    -- Mercenary Panel and recruitment panel are mutually exclusive, so we can have a small optimisation by
    -- ignoring the normal recruitment panel or mercenary panel in some cases.
    if pathData.MercenaryPanel and pathData.MercenaryPanel.Visible and pathData.MercenaryPanel:Visible() then
        URP_Log("Mercenary panel is visible");
        -- Mercenary / Raise Dead
        pathData.MercenaryUnitList = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker", "recruitment_options", "mercenary_display", "listview", "list_clip", "list_box");
        self:ResetRecruitmentPanelData();
        URP_Log("Recruitment panel is not visible");
    else
        self:ResetMercenaryPanelData();
        URP_Log("Mercenary panel is not visible");
        -- Recruitment Panel
        pathData.RecruitmentPanel = find_uicomponent(core:get_ui_root(), "units_panel", "main_units_panel", "recruitment_docker");
        if pathData.RecruitmentPanel and pathData.RecruitmentPanel.Visible and pathData.RecruitmentPanel:Visible() then
            URP_Log("Recruitment panel is visible");
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
            URP_Log("Recruitment panel is not visible");
            self:ResetRecruitmentPanelData();
        end
    end
    URP_Log_Finished();
end

function URPUI:ResetRecruitmentPanelData()
    local pathData = self.UIPathData;
    pathData.RecruitmentPoolListLocal1UnitList = {};
    pathData.RecruitmentPoolListLocalUnitList = {};
    pathData.RecruitmentPoolListGlobalUnitList = {};
    pathData.RecruitmentOptionsLocal1UnitList = {};
    pathData.RecruitmentOptionsLocal2UnitList = {};
    pathData.RecruitmentOptionsGlobalUnitList = {};
end

function URPUI:ResetMercenaryPanelData()
    local pathData = self.UIPathData;
    pathData.MercenaryUnitList = {};
end

function URPUI:AreUnitsInUIList(uiToUnits)
    if uiToUnits and uiToUnits.ChildCount and uiToUnits:ChildCount() > 0 then
        return true;
    else
        return false;
    end
end

function URPUI:ApplyUnitUI(uiToUnits, unitData, uiSuffix, type)
    if uiToUnits and uiToUnits:ChildCount() > 0 then
        for i = 0, uiToUnits:ChildCount() - 1  do
            local unit = UIComponent(uiToUnits:Find(i));
            local unitId = unit:Id();
            local unitKey = string.match(unitId, "(.*)"..uiSuffix);
            URP_Log("Unit ID: "..unitId);
            for j = 0, unit:ChildCount() - 1  do
                local subcomponent = UIComponent(unit:Find(j));
                local subcomponentId = subcomponent:Id();
                --URP_Log(unitId.." Subcomponent ID: "..subcomponentId);
                local xPos, yPos = subcomponent:Position();
                local subcomponentDefaultData = self.CachedUIData[type..unitId..subcomponentId];
                if subcomponentDefaultData == nil then
                    --URP_Log("No found cache data, initalising");
                    self.CachedUIData[type..unitId..subcomponentId] = {
                        yPos = 0,
                        xBounds = 0,
                        yBounds = 0,
                    }
                    subcomponentDefaultData = self.CachedUIData[type..unitId..subcomponentId];
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
                    if unitData[unitKey] ~= nil then
                        --URP_Log("AvailableAmount is "..unitData[unitKey].AvailableAmount);
                        --URP_Log("StartingCap is "..unitData[unitKey].UnitCap);
                        subcomponent:SetStateText(unitData[unitKey].AvailableAmount.." / "..unitData[unitKey].UnitCap);
                    else
                        URP_Log("Unit "..unitKey.." does not have data");
                        subcomponent:SetStateText("N/A");
                    end
                elseif subcomponentId == "RecruitmentCost"
                or subcomponentId == "UpkeepCost"
                or subcomponentId == "unit_cat_frame"
                or subcomponentId == "FoodCost" then
                    subcomponent:MoveTo(xPos, yPos + 12);
                elseif subcomponentId == "Turns" then
                    subcomponentDefaultData.yPos = yPos + 23;
                    subcomponent:MoveTo(xPos, yPos + 23);
                else
                    subcomponentDefaultData.yPos = yPos + 20;
                    subcomponent:MoveTo(xPos, yPos + 18);
                end
            end

            if unitData[unitKey] and unitData[unitKey].AvailableAmount <= 0 then
                unit:SetInteractive(false);
                URP_Log("Stopping recruitment of "..unitKey);
            else
                unit:SetInteractive(true);
            end
        end
    else
        URP_Log("Recruitment uiToUnits is empty");
    end
    URP_Log_Finished();
end