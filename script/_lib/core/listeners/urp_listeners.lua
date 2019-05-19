URP_Log("Loading Listeners");
function InitialiseListenerData()
    out("URP: SetupListeners");
    URP_Log("InitialiseListenerData");
    URP_Log_Finished();
end



function SetupPostUIListeners(urp)
    URP_Log("Initialising post UI listeners");

    urp.urpui = URPUI:new({});
    local urpui = urp.urpui;

    if not core then
        URP_Log("Error: core is not defined");
        return;
    end
    -- Applies UI under appropriate circumstances
    URP_Log("ClickedButtonToRecruitUnits");
    core:add_listener(
        "URP_ClickedButtonToRecruitUnits",
        "ComponentLClickUp",
        function(context)
            return urp.urpui:IsValidButtonContext(context.string);
        end,
        function(context)
            URP_Log_Start();
            URP_Log("ClickedButtonRecruitedUnits context is "..context.string);
            local buttonContext = context.string;
            cm:callback(function()
                local uiSuffix = nil;
                local clickedButton = false;
                if buttonContext == "button_mercenaries" then
                    uiSuffix = "_mercenary";
                    clickedButton = true;
                elseif buttonContext == "button_recruitment"
                or urp.urpui:IsGlobalRecruitmentStance(buttonContext) then
                    clickedButton = true;
                end
                local unitData = urp:GetFactionUnitData(urp.HumanFaction);
                urpui:RefreshUI(unitData, uiSuffix, clickedButton);
            end,
            0);
        end,
        true
    );

    -- Applies UI under appropriate circumstances
    URP_Log("ClickedButtonToRecruitUnits");
    core:add_listener(
        "URP_MercenaryPanelClosed",
        "PanelClosedCampaign",
        function(context)
            return context.string == "mercenary_recruitment";
        end,
        function(context)
            URP_Log("MercenaryPanelClosed listener");
            urp:ClearMercenaryCache();
            URP_Log_Finished();
        end,
        true
    );

    -- Recruitment UI should also be applied when a human controlled character is selected
    URP_Log("ClickedCharacterSelected");
    core:add_listener(
        "URP_CharacterSelected",
        "CharacterSelected",
        function(context)
            return context:character():faction():name() == urp.HumanFaction:faction():name();
        end,
        function(context)
            URP_Log_Start();
            URP_Log("ClickedButtonRecruitedUnits context is "..context.string);
            cm:callback(function()
                local unitData = urp:GetFactionUnitData(urp.HumanFaction);
                urpui:RefreshUI(unitData, nil, true);
            end,
            0);
        end,
        true
    );

    -- Modifies the unit pools for the standard recruitment
    core:add_listener(
        "URP_ClickedButtonRecruitedUnits",
        "ComponentLClickUp",
        function(context)
            return string.match(context.string, "_recruitable")
            or string.match(context.string, "QueuedLandUnit");
        end,
        function(context)
            URP_Log_Start();
            URP_Log("ClickedButtonRecruitedUnits context is "..context.string);
            local buttonContext = context.string;
            local uiSuffix = nil;
            -- Cancelling
            if string.match(buttonContext, "QueuedLandUnit") then
                local queuedUnit = find_uicomponent(core:get_ui_root(), "main_units_panel", "units", buttonContext);
                queuedUnit:SimulateMouseOn();
                local unitInfoPopup = find_uicomponent(core:get_ui_root(), "UnitInfoPopup", "tx_unit-type");
                local unitTypeText = unitInfoPopup:GetStateText();
                local unitKey = string.match(unitTypeText, "/unit/(.-)%]%]");
                URP_Log("Cancelling unitKey: "..unitKey);
                urp:ModifyUnitAvailableAmountForFaction(urp.HumanFaction, unitKey, 1);
            -- Adding
            else
                uiSuffix = "_recruitable";
                local unitKey = string.match(buttonContext, "(.*)_recruitable");
                URP_Log("Clicked unit is "..unitKey);
                urp:ModifyUnitAvailableAmountForFaction(urp.HumanFaction, unitKey, -1);
            end
            cm:callback(function()
                local unitData = urp:GetFactionUnitData(urp.HumanFaction);
                urpui:RefreshUI(unitData, uiSuffix);
            end,
            0.15);
        end,
        true
    );

    -- Modifies the unit pools for Mercenary/Raise Dead recruitment
    core:add_listener(
        "URP_ClickedButtonMercenaryUnits",
        "ComponentLClickUp",
        function(context)
            return string.match(context.string, "_mercenary")
            or string.match(context.string, "temp_merc_");
        end,
        function(context)
            URP_Log_Start();
            URP_Log("ClickedButtonMercenaryUnits context is "..context.string);
            local buttonContext = context.string;
            local uiSuffix = nil;
            -- Cancelling
            if string.match(context.string, "temp_merc_") then
                local unitIndex = string.match(buttonContext, "temp_merc_(.*)");
                local unitKey = urp:GetUnitKeyFromCache(unitIndex);
                if unitKey ~= nil then
                    URP_Log("Uncaching mercenary unit: "..unitKey.." at index: "..unitIndex);
                    urp:RemoveUnitFromMercenaryCache(unitIndex);
                    urp:ModifyUnitAvailableAmountForFaction(urp.HumanFaction, unitKey, 1);
                end
            -- Adding
            else
                uiSuffix = "_mercenary";
                local unitKey = string.match(buttonContext, "(.*)_mercenary");
                URP_Log("Caching mercenary unit: "..unitKey);
                urp:AddUnitToMercenaryCache(unitKey);
                urp:ModifyUnitAvailableAmountForFaction(urp.HumanFaction, unitKey, -1);
            end
            cm:callback(function()
                local unitData = urp:GetFactionUnitData(urp.HumanFaction);
                urpui:RefreshUI(unitData, uiSuffix);
            end,
            0.15);
        end,
        true
    );

    -- Clears the mercenary cache without reverting the changes
    core:add_listener(
        "URP_RecruitedMercenaryUnits",
        "ComponentLClickUp",
        function(context)
            return context.string == "button_raise_dead";
        end,
        function(context)
            URP_Log("Commiting mercenary cache data");
            urp:CommitMercenaryCache();
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

    -- This handles the logic for unit pool growth
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
                urp:CommitMercenaryCache();
            end
            urp:RollUnitChances(context:faction());
            URP_Log_Finished();
        end,
        true
    );

    -- This handles pool changes when the AI recruits a unit
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
                urp:ModifyUnitAvailableAmountForFaction(context:unit():faction(), context:unit():unit_key(), -1, false);
            end
            URP_Log_Finished();
        end,
        true
    );

    -- These handle UnitCap changes for when buildings are de/constructred for non horde factions
    core:add_listener(
        "URP_UpdateBuildingPoolData",
        "FactionTurnStart",
        function(context)
            return cm:turn_number() > 1;
        end,
        function(context)
            urp:ApplyFactionBuildingUnitPoolModifiers(context:faction());
            URP_Log_Finished();
        end,
        true
    );
    -- These listener handles horde factions / Ship building characters
    core:add_listener(
        "URP_UpdateBuildingPoolDataHorde",
        "MilitaryForceBuildingCompleteEvent",
        function(context)
            return true;
        end,
        function(context)
            local faction = context:character():faction();
            URP_Log("Horde building: "..context:building().." completed for faction: "..faction:name());
            urp:ApplyCharacterBuildingUnitPoolModifiers(context:character(), context:building());
            URP_Log_Finished();
        end,
        true
    );

    core:add_listener(
        "URP_CharacterKilled",
        "CharacterConvalescedOrKilled",
        function(context)
            local char = context:character();
            return not char:character_type("colonel");
        end,
        function(context)
            local character = context:character();
            local faction = context:character():faction();
            if urp:FactionHasCharacterBuildingData(faction) == true then
                if character:is_null_interface() or character:is_wounded() == false then
                    URP_Log("Character has been killed for faction: "..faction:name());
                    urp:RemoveBuildingDataForCharacter(character);
                else
                    URP_Log("Character has been only been wounded for faction: "..faction:name());
                    -- True horde factions have their horde buildings removed on wounded
                    -- In vanilla this is just Chaos and Beastmen
                    if (faction:is_horde() and not faction:has_home_region())
                    or (faction:can_be_horde() and faction:subculture() == "wh2_main_sc_def_dark_elves") then
                        urp:RemoveBuildingDataForCharacter(character);
                    end
                end
                URP_Log_Finished();
            end
        end,
        true
    );
end