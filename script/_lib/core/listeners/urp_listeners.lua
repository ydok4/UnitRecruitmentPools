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
        -- We use this to initialise the player's faction on
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
        --[[core:add_listener(
            "URP_CharacterSelectedStartup",
            "CharacterSelected",
            function(context)
                return context:character():faction():is_human() == true and cm:turn_number() == 1;
            end,
            function(context)
                URP_Log("Initialising player faction");
                local listenerContext = {
                    ListenerContext = "URP_CharacterSelectedStartup",
                    Faction = context:character():faction(),
                }
                _G.RM:UpdateCacheWithFactionCharacterForceData(urp.HumanFaction);
                cm:callback(function() urp:UpdateEffectBundles(listenerContext); end, 0);
                URP_Log_Finished();
            end,
            false
        );--]]
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
            cm:callback(function() urp:ModifyUnitUnitReservesForFaction(faction, unitKey, -100, false); end, 0);
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
            end, 0);
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
            return not char:character_type("colonel") and char:faction():name() ~= "rebels";
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
end