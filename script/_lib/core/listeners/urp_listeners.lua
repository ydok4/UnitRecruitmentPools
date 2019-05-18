URP_Log("Loading Listeners");
function InitialiseListenerData()
    out("URP: SetupListeners");
    URP_Log("InitialiseListenerData");
    URP_Log_Finished();
end



function SetupPostUIListeners(urp)
    URP_Log("Initialising post UI listeners");

    urp.urpui = URPUI:new({
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
            RecruitmentOptionsGlobalUnitList = {},
            -- Mercenary / Raise Dead
            MercenaryUnitList = {},
        },
    });
    local urpui = urp.urpui;

    if not core then
        URP_Log("Error: core is not defined");
        return;
    end
    -- UI Listeners
    URP_Log("ClickedButtonToRecruitUnits");
    core:add_listener(
        "URP_ClickedButtonToRecruitUnits",
        "ComponentLClickUp",
        function(context)
            return context.string == "button_recruitment"
            or context.string == "button_mercenaries"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_MUSTER"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SET_CAMP"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SET_CAMP_RAIDING"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_DEFAULT"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_SETTLE"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_TUNNELING"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_CHANNELING"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_LAND_RAID"
            or context.string == "button_MILITARY_FORCE_ACTIVE_STANCE_TYPE_MARCH";
        end,
        function(context)
            URP_Log_Start();
            URP_Log("ClickedButtonRecruitedUnits context is "..context.string);
            local buttonContext = context.string;
            cm:callback(function()
                local uiSuffix = nil;
                if buttonContext == "button_mercenaries" then
                    uiSuffix = "_mercenary";
                end

                local unitData = urp:GetFactionUnitData(urp.HumanFaction);
                urpui:RefreshUI(unitData, uiSuffix);
            end,
            0);
        end,
        true
    );

    core:add_listener(
        "URP_ClickedButtonRecruitedUnits",
        "ComponentLClickUp",
        function(context)
            return string.match(context.string, "_recruitable")
            or string.match(context.string, "_mercenary")
            or string.match(context.string, "QueuedLandUnit");
        end,
        function(context)
            URP_Log_Start();
            URP_Log("ClickedButtonRecruitedUnits context is "..context.string);
            local buttonContext = context.string;
            local uiSuffix = nil;
            if string.match(buttonContext, "QueuedLandUnit") then
                local queuedUnit = find_uicomponent(core:get_ui_root(), "main_units_panel", "units", buttonContext);
                queuedUnit:SimulateMouseOn();
                local unitInfoPopup = find_uicomponent(core:get_ui_root(), "UnitInfoPopup", "tx_unit-type");
                local unitTypeText = unitInfoPopup:GetStateText();
                local unitKey = string.match(unitTypeText, "/unit/(.-)%]%]");
                URP_Log("Cancelling unitKey: "..unitKey);
                urp:ModifyUnitCurrentPopForFaction(urp.HumanFaction, unitKey, 1);
            else
                local unitKey = "";
                if string.match(buttonContext, "_mercenary") then
                    uiSuffix = "_mercenary";
                    unitKey = string.match(buttonContext, "(.*)_mercenary");
                elseif string.match(buttonContext, "_recruitable") then
                    uiSuffix = "_recruitable";
                    unitKey = string.match(buttonContext, "(.*)_recruitable");
                end
                URP_Log("Clicked unit is "..unitKey);
                urp:ModifyUnitCurrentPopForFaction(urp.HumanFaction, unitKey, -1);
            end
            cm:callback(function()
                local unitData = urp:GetFactionUnitData(urp.HumanFaction);
                urpui:RefreshUI(unitData, uiSuffix);
            end,
            0.15);
        end,
        true
    );

    -- Initalisation listeners only need to run on the end of the first turns
    if cm:turn_number() == 1 then
        URP_Log("Initialise faction");
        -- We need to fire this for every faction on turn start
        -- when we start a new game.  We only need to do this once.
        core:add_listener(
            "URP_InitialiseFaction",
            "FactionTurnStart",
            function(context)
                return cm:turn_number() == 1;
            end,
            function(context)
                urp:SetupFactionUnitPools(context:faction());
                URP_Log_Finished();
            end,
            true
        );
        -- This listener exists to remove the previous listener
        -- It should only fire once
        core:add_listener(
            "URP_RemoveInitialiseFactionListener",
            "FactionTurnStart",
            function(context)
                return cm:turn_number() == 2;
            end,
            function(context)
                URP_Log("Removing URP_InitialiseFaction listener");
                core:remove_listener("URP_InitialiseFaction");
                URP_Log_Finished();
            end,
            false
        );

    end

    URP_Log("UpdateRecruitmentPool");
    core:add_listener(
        "URP_RollUnitReplenishment",
        "FactionTurnEnd",
        function(context)
            return true;
        end,
        function(context)
            -- We clear the log on the end of the player's turn
            if context:faction():name() == urp.HumanFaction:name() then
                URP_Log_Start();
            end
            urp:RollUnitChances(context:faction());
            URP_Log_Finished();
        end,
        true
    );

    URP_Log("UnitRecruited");
    core:add_listener(
        "URP_UnitCreated",
        "UnitTrained",
        function(context)
            return true;
        end,
        function(context)
            URP_Log("Unit recruited for faction: "..context:unit():faction():name());
            if context:unit():faction():name() ~= urp.HumanFaction:name() then
                urp:ModifyUnitCurrentPopForFaction(context:unit():faction(), context:unit():unit_key(), -1, false);
            end
            URP_Log_Finished();
        end,
        true
    );
end