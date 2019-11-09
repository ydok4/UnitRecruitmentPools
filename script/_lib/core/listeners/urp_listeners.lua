URP_Log("Loading Listeners");

function URP_SetupPostUIListeners(urp)
    URP_Log("Initialising post UI listeners");

    urp.urpui = RecruitmentUIManager:new({});
    local urpui = urp.urpui;

    if not core then
        URP_Log("Error: core is not defined");
        return;
    end

    -- Initalisation listeners only need to run on the end of the first turns
    if cm:turn_number() == 1 then
        URP_Log("Initialise faction");
        -- We need to fire this for every faction on turn start
        -- when we start a new game.  We only need to do this once.
        core:add_listener(
            "URP_InitialiseFaction",
            "FactionTurnStart",
            function(context)
                return cm:turn_number() == 1 and context:faction():name() ~= "rebels";
            end,
            function(context)
                URP_Log("Turn 1 initialise faction listener");
                -- There is a chance that the player could save and reload on the first turn
                -- so we want to ensure it can only happen once
                if context:faction():name() == urp.HumanFaction:name() then
                    if cm:is_new_game() then
                        urp:SetupFactionUnitPools(context:faction());
                    end
                else
                    urp:SetupFactionUnitPools(context:faction());
                end
                URP_Log_Finished();
            end,
            true
        );
        -- We use this to initialise the player's faction when the recruit unit
        -- buttons are selected
        core:add_listener(
            "URP_ClickedButtonToRecruitUnits",
            "ComponentLClickUp",
            function(context)
                return context.string == "button_recruitment"
                or context.string == "button_mercenaries";
            end,
            function(context)
                URP_Log("URP_ClickedButtonToRecruitUnits");
                local listenerContext = {
                    ListenerContext = "URP_ClickedButtonToRecruitUnits",
                    Faction = urp.HumanFaction,
                }
                if _G.RM then
                    URP_Log("RM is not nil");
                    _G.RM:UpdateCacheWithFactionCharacterForceData(urp.HumanFaction);
                    urp:UpdateEffectBundles(listenerContext);
                end
            end,
            false
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
        "URP_UpdateUnitReplenishment",
        "FactionTurnEnd",
        function(context)
            return context:faction():name() ~= "rebels";
        end,
        function(context)
            -- We clear the log on the end of the player's turn
            if context:faction():name() == urp.HumanFaction:name() then
                URP_Log_Start();
                urpui:CommitMercenaryCache();
            end
            urp:UpdateUnitGrowth(context:faction());
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
            return context:unit():faction():name() ~= "rebels" and context:unit():faction():name() ~= urp.HumanFaction:name();
        end,
        function(context)
            local faction = context:unit():faction();
            local unitKey = context:unit():unit_key();
            URP_Log("Unit: "..unitKey.." recruited for faction: "..faction:name());
            urp:ModifyUnitUnitReservesForFaction(faction, unitKey, -100, false);
            URP_Log_Finished();
        end,
        true
    );

    core:add_listener(
        "URP_CharacterPerformsSettlementOccupationDecision",
        "CharacterPerformsSettlementOccupationDecision",
        function(context)
            return context:character():faction():name() ~= "rebels";
        end,
        function(context)
            URP_Log("URP_CharacterPerformsSettlementOccupationDecision");
            local faction = context:character():faction();
            local listenerContext = {
                ListenerContext = "URP_CharacterPerformsSettlementOccupationDecision",
                Faction = faction,
            }
            cm:callback(function()
                urp:ApplyFactionBuildingUnitPoolModifiers(faction);
                urp:UpdateEffectBundles(listenerContext);
                URP_Log_Finished();
            end, 0.25);
            URP_Log_Finished();
        end,
        true
    );

    -- These listener handles horde factions / Ship building characters
    core:add_listener(
        "URP_UpdateBuildingPoolDataHorde",
        "MilitaryForceBuildingCompleteEvent",
        function(context)
            return context:character():faction():name() ~= "rebels";
        end,
        function(context)
            local faction = context:character():faction();
            URP_Log("Horde building: "..context:building().." completed for faction: "..faction:name());
            urp:ApplyCharacterBuildingUnitPoolModifiers(context:character(), context:building(), false);
            URP_Log_Finished();
        end,
        true
    );

    core:add_listener(
        "URP_CharacterCreated",
        "CharacterCreated",
        function(context)
            local character = context:character();
            --URP_Log("Checking CreatedCharacter: "..character:character_subtype_key().." in faction: "..character:faction():name().." type: "..character:character_type_key());
            return cm:char_is_agent(character) == false
            and character:character_type("colonel") == false;
        end,
        function(context)
            local character = context:character();
            URP_Log("URP_CharacterCreated: "..character:character_subtype_key().." in faction: "..character:faction():name().." cqi: "..character:command_queue_index());
            urp:ModifyCharacterPoolData(character, false);
            URP_Log_Finished();
        end,
        true
    );

    core:add_listener(
        "URP_CharacterKilled",
        "CharacterConvalescedOrKilled",
        function(context)
            local character = context:character();
            return cm:char_is_agent(character) == false
            and character:character_type("colonel") == false
            and character:faction():name() ~= "rebels";
        end,
        function(context)
            local character = context:character();
            local faction = context:character():faction();
            local subtype = character:character_subtype_key();
            if urp:FactionHasCharacterBuildingData(faction) == true then
                if character:is_null_interface() or character:is_wounded() == false then
                    URP_Log("Character has been killed for faction: "..faction:name().." subtype is: "..subtype.." cqi: "..character:command_queue_index());
                    urp:RemoveBuildingDataForCharacter(character);
                else
                    URP_Log("Character has been only been wounded for faction: "..faction:name());
                    -- True horde factions have their horde buildings removed on wounded
                    -- In vanilla this is just Chaos, Beastmen and Dark Elf Black Arks
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

    -- This sets up the unit recruitment UI in the diplomacy panel
    local unitDiplomacyIndicatorId = "URP_UnitDiplomacyIndicator";
    local selectedDiplomacyFaction = "";
    local startedFromButton = false;
    core:add_listener(
        "URP_ClickedFactionInDiplomacy",
        "ComponentLClickUp",
        function(context)
            return string.match(context.string, "faction_row_entry_")
            or context.string == "button_diplomacy";
        end,
        function(context)
            URP_Log("URP_ClickedFactionInDiplomacy");
            if context.string == "button_diplomacy" then
                startedFromButton = true;
            else
                local factionKey = context.string:match("faction_row_entry_(.*)");
                URP_Log("Selected faction in list is: "..factionKey);
                selectedDiplomacyFaction = factionKey;
                local rightStatusPanel = find_uicomponent(core:get_ui_root(), "diplomacy_dropdown", "faction_right_status_panel");
                local unitDiplomacyIndicator = find_uicomponent(rightStatusPanel, unitDiplomacyIndicatorId);
                cm:callback(function(context)
                    URP_SetupDiplomacyUI(urp, unitDiplomacyIndicator, selectedDiplomacyFaction);
                end,
                0);
            end
            URP_Log_Finished();
        end,
        true
    );

    core:add_listener(
        "URP_CharacterSelectedForDiplomacy",
        "CharacterSelected",
        function(context)
            return true;
        end,
        function(context)
            local character = context:character();
            selectedDiplomacyFaction = character:faction():name();
        end,
        true
    );

    core:add_listener(
		"URP_SettlementSelectedForDiplomacy",
		"SettlementSelected",
		true,
        function(context)
            local factionKey = context:garrison_residence():faction():name();
            selectedDiplomacyFaction = factionKey;
		end,
		true
	);

    core:add_listener(
        "URP_DiplomacyOpened",
        "PanelOpenedCampaign",
        function(context)
            return context.string == "diplomacy_dropdown";
        end,
        function(context)
            URP_Log("Diplomacy panel opened");
            local rightStatusPanel = find_uicomponent(core:get_ui_root(), "diplomacy_dropdown", "faction_right_status_panel");
            local unitDiplomacyIndicator = find_uicomponent(rightStatusPanel, unitDiplomacyIndicatorId);
            if not unitDiplomacyIndicator then
                URP_Log("Cloning attitude frame");
                local attitudeFrame = find_uicomponent(rightStatusPanel, "attitude_frame");
                local attitudeFrameCloneAddress = attitudeFrame:CopyComponent(unitDiplomacyIndicatorId);
                --local rightStatusPanel = find_uicomponent(core:get_ui_root(), "diplomacy_dropdown", "faction_right_status_panel");
                rightStatusPanel:Adopt(attitudeFrameCloneAddress);
                unitDiplomacyIndicator = UIComponent(attitudeFrameCloneAddress);
            else
                URP_Log("Component already exists");
            end
            -- Callback required for positioning
            cm:callback(function(context)
                if startedFromButton == true then
                    local factionListBox = find_uicomponent(core:get_ui_root(), "diplomacy_dropdown", "faction_panel", "sortable_list_factions", "list_clip", "list_box");
                    for i = 0, factionListBox:ChildCount() - 1  do
                        local subcomponent = UIComponent(factionListBox:Find(i));
                        local subcomponentID = subcomponent:Id();
                        if string.match(subcomponentID, "faction_row_entry_") then
                            URP_Log("First faction in faction list panel is: "..subcomponentID);
                            selectedDiplomacyFaction = subcomponent:Id():match("faction_row_entry_(.*)");
                            break;
                        end
                    end
                    startedFromButton = false;
                end
                URP_SetupDiplomacyUI(urp, unitDiplomacyIndicator, selectedDiplomacyFaction);
            end,
            0);
            URP_Log_Finished();
        end,
        true
    );
end

function URP_SetupDiplomacyUI(urp, unitDiplomacyIndicator, selectedFactionKey)
    URP_Log("URP_SetupDiplomacyUI");
    local diplomacyResources = urp:GetDiplomacyResourcesForSubCulture(urp.HumanFaction:subculture());
    local selectedFaction = cm:model():world():faction_by_key(selectedFactionKey);
    if diplomacyResources ~= nil
    and selectedFaction:subculture() == urp.HumanFaction:subculture()
    and (diplomacyResources[selectedFaction:subculture()] or diplomacyResources[selectedFactionKey]) then
        URP_Log("Faction or subculture has diplomacy data");
        local attitudeFrame = find_uicomponent(core:get_ui_root(), "diplomacy_dropdown", "faction_right_status_panel", "attitude_frame");
        local relX, relY = attitudeFrame:Position();
        unitDiplomacyIndicator:MoveTo(relX + 150, relY);
        unitDiplomacyIndicator:SetVisible(true);
        local attitudeTextComponent = find_uicomponent(unitDiplomacyIndicator, "dy_attitude");
        local attitudeNumberComponent = find_uicomponent(unitDiplomacyIndicator, "dy_value");

        local attitudeImageComponent = find_uicomponent(unitDiplomacyIndicator, "attitude");

        local attitudeArrowsComponent = find_uicomponent(unitDiplomacyIndicator, "arrows");

        attitudeTextComponent:SetStateText("Diplomacy units");
        -- Setup tooltips
        local factionDiplomacyTooltip = urp:GetDiplomacyScreenTooltipForFaction(selectedFaction);
        local hasDiplomacyUnitGrowth = (factionDiplomacyTooltip == "");
        attitudeTextComponent:SetTooltipText(factionDiplomacyTooltip);
        attitudeNumberComponent:SetTooltipText(factionDiplomacyTooltip);
        attitudeImageComponent:SetTooltipText(factionDiplomacyTooltip);
        unitDiplomacyIndicator:SetTooltipText(factionDiplomacyTooltip);
        -- Updating visibility
        attitudeNumberComponent:SetVisible(hasDiplomacyUnitGrowth);
        attitudeImageComponent:SetVisible(hasDiplomacyUnitGrowth);
        attitudeArrowsComponent:SetVisible(hasDiplomacyUnitGrowth);
        attitudeImageComponent:SetVisible(hasDiplomacyUnitGrowth);
    else
        URP_Log("Faction does not have diplomacy data");
        unitDiplomacyIndicator:SetVisible(false);
    end
    URP_Log_Finished();
end