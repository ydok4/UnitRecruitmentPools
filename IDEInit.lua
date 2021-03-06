-- Mock Data
testCharacter = {
    cqi = function() return 123 end,
    get_forename = function() return "Direfan"; end,
    get_surname = function() return "Cylostra"; end,
    character_subtype_key = function() return "chs_egrimm_van_horstmann"; end,
    command_queue_index = function() end,
    has_military_force = function() return true end,
    military_force = function() return {
        is_armed_citizenry = function () return false; end,
        unit_list = function() return {
            num_items = function() return 2; end,
            item_at = function(self, index)
                return test_unit;
            end,
        }
        end,
    }
    end,
    faction = function() return humanFaction; end,
    region = function() return get_cm():get_region(); end,
    logical_position_x = function() return 100; end,
    logical_position_y = function() return 110; end,
    command_queue_index = function() return 10; end,
    character_type = function() return false; end,
    is_null_interface = function() return false; end,
    is_wounded = function() return false; end,
}

humanFaction = {
    name = function()
        return "wh2_main_hef_nagarythe";
    end,
    culture = function()
        return "wh2_main_hef_high_elves";
    end,
    subculture = function()
        return "wh_main_sc_emp_empire";
    end,
    character_list = function()
        return {
            num_items = function()
                return 1;
            end,
            item_at = function(self, index)
                return testCharacter;
            end,
        };
    end,
    region_list = function()
        return {
            num_items = function()
                return 1;
            end,
            item_at = function(self, index)
                return cm:get_region(index);
            end,
        };
    end,
    home_region = function ()
        return {
            name = function()
                return "";
            end,
            is_null_interface = function()
                return false;
            end,
        }
    end,
    faction_leader = function() return testCharacter; end,
    is_quest_battle_faction = function() return false; end,
    is_null_interface = function() return false; end,
    is_human = function() return true; end,
    has_effect_bundle = function() return true; end,
    is_horde = function() return false; end,
    can_be_horde = function() return false; end,
    factions_of_same_culture = function() return {
            num_items = function()
                return 1;
            end,
            item_at = function()
                return testFaction;
            end,
        };
    end,
    at_war_with = function() return false; end,
    factions_non_aggression_pact_with = function() return {
            num_items = function()
                return 1;
            end,
            item_at = function()
                return testFaction;
            end,
        };
    end,
    factions_trading_with = function() return {
            num_items = function()
                return 1;
            end,
            item_at = function()
                return testFaction;
            end,
        }
    end,
    diplomatic_standing_with = function() return 10; end,
    diplomatic_attitude_towards = function() return 15; end,
    military_allies_with = function() return true; end,
    defensive_allies_with = function() return true; end,
}

testFaction = {
    name = function()
        return "wh_main_emp_wissenland";
    end,
    culture = function()
        return "wh_main_emp_empire";
    end,
    subculture = function()
        return "wh_main_sc_emp_empire";
    end,
    character_list = function()
        return {
            num_items = function()
                return 1;
            end,
            item_at = function()
                return testCharacter;
            end
        };
    end,
    region_list = function()
        return {
            num_items = function()
                return 0;
            end
        };
    end,
    home_region = function ()
        return {
            name = function()
                return "";
            end,
            is_null_interface = function()
                return false;
            end,
        }
    end,
    faction_leader = function() return testCharacter; end,
    is_quest_battle_faction = function() return false; end,
    is_null_interface = function() return false; end,
    is_human = function() return false; end,
    has_effect_bundle = function() return true; end,
    is_horde = function() return false; end,
    can_be_horde = function() return false; end,
    factions_of_same_culture = function() return {
            num_items = function()
                return 1;
            end,
            item_at = function()
                return testFaction;
            end,
        };
    end,
    at_war_with = function() return false; end,
    factions_non_aggression_pact_with = function() return {
            num_items = function()
                return 1;
            end,
            item_at = function()
                return testFaction;
            end,
        };
    end,
    factions_trading_with = function() return {
            num_items = function()
                return 1;
            end,
            item_at = function()
                return testFaction;
            end,
        }
    end,
    diplomatic_standing_with = function() return 10; end,
    diplomatic_attitude_towards = function() return 15; end,
    military_allies_with = function() return true; end,
    defensive_allies_with = function() return true; end,
}

testFaction2 = {
    name = function()
        return "wh2_dlc11_cst_rogue_grey_point_scuttlers";
    end,
    subculture = function()
        return "wh_main_sc_nor_norsca";
    end,
    character_list = function()
        return {
            num_items = function()
                return 0;
            end
        };
    end,
    region_list = function()
        return {
            num_items = function()
                return 0;
            end
        };
    end,
    home_region = function ()
        return {
            name = function()
                return "";
            end,
            is_null_interface = function()
                return false;
            end,
        }
    end,
    faction_leader = function() return testCharacter; end,
    is_quest_battle_faction = function() return false; end,
    is_null_interface = function() return false; end,
    is_human = function() return false; end,
    has_effect_bundle = function() return true; end,
}

test_unit = {
    unit_key = function() return "wh2_main_hef_inf_archers_1"; end,
    force_commander = function() return testCharacter; end,
    faction = function() return testFaction; end,
    percentage_proportion_of_full_strength = function() return 80; end,
}

effect = {
    get_localised_string = function()
        return "Murdredesa";
    end,
}

-- This can be modified in the testing driver
-- so we can simulate turns changing easily
local turn_number = 1;

-- Mock functions
mock_listeners = {
    listeners = {},
    trigger_listener = function(self, mockListenerObject)
        local listener = self.listeners[mockListenerObject.Key];
        if listener and listener.Condition(mockListenerObject.Context) then
            listener.Callback(mockListenerObject.Context);
        end
    end,
}

-- Mock save structures
mockSaveData = {

}

-- slot (building) data
slot_1 = {
    has_building = function() return true; end,
    building = function() return {
        name = function() return "wh_main_emp_barracks_1"; end,
        superchain = function()
            return "wh2_main_sch_re1_farm";
        end,
        building_level = function()
            return 2;
        end,
    }
    end,
}

slot_2 = {
    has_building = function() return true; end,
    building = function() return {
        name = function() return "wh_main_emp_stables_1"; end,
        superchain = function()
            return "wh2_main_sch_e1_farm";
        end,
        building_level = function()
            return 2;
        end,
    }
    end,
}

function get_cm()
    return   {
        is_new_game = function() return true; end,
        create_agent = function()
            return;
        end,
        get_human_factions = function()
            return {humanFaction};
        end,
        disable_event_feed_events = function() end,
        turn_number = function() return turn_number; end,
        model = function ()
            return {
                turn_number = function() return turn_number; end,
                world = function()
                    return {
                        faction_by_key = function ()
                            return humanFaction;
                        end,
                        faction_list = function ()
                            return {
                                item_at = function(self, i)
                                    if i == 0 then
                                        return testFaction;
                                    elseif i == 1 then
                                        return humanFaction;
                                    elseif i == 2 then
                                        return testFaction2;
                                    elseif i == 3 then
                                        return testFaction2
                                    else
                                        return nil;
                                    end
                                end,
                                num_items = function()
                                    return 3;
                                end,
                            }
                        end
                    }
                end
            }
        end,
        first_tick_callbacks = {},
        add_saving_game_callback = function() end,
        add_loading_game_callback = function() end,
        spawn_character_to_pool = function() end,
        callback = function(self, callbackFunction, delay) callbackFunction() end,
        transfer_region_to_faction = function() end,
        get_faction = function() return testFaction2; end,
        lift_all_shroud = function() end,
        kill_all_armies_for_faction = function() end,
        create_new_custom_effect_bundle = function()
            return {
                set_duration = function() end,
                add_effect = function() end,
            };
        end,
        apply_custom_effect_bundle_to_region = function() end,
        apply_custom_effect_bundle_to_faction = function() end,
        get_region = function()
            return {
                cqi = function() return 123; end,
                province_name = function() return "wh_main_death_pass"; end,
                faction_province_growth = function() return 3; end,
                religion_proportion = function() return 0; end,
                public_order = function() return -99; end,
                owning_faction = function() return humanFaction; end,
                name = function() return "wh2_main_vor_heart_of_the_jungle_oreons_camp"; end,
                is_province_capital = function() return false; end,
                is_abandoned = function() return false; end,
                command_queue_index = function() return 10; end,
                adjacent_region_list = function()
                    return {
                        item_at = function(self, i)
                            if i == 0 then
                                return get_cm():get_region();
                            elseif i == 1 then
                                return get_cm():get_region();
                            elseif i == 2 then
                                return get_cm():get_region();
                            elseif i == 3 then
                                return get_cm():get_region();
                            else
                                return nil;
                            end
                        end,
                        num_items = function()
                            return 3;
                        end,
                    }
                end,
                is_null_interface = function() return false; end,
                garrison_residence = function() return {
                    army = function() return {
                        strength = function() return 50; end,
                    } end ,
                } end,
                settlement = function() return {
                    primary_slot = function() return {
                        is_null_interface = function() return false; end,
                        has_building = function() return true; end,
                        building = function() return {
                            name = function() return
                                "main_settlement";
                            end,
                            superchain = function()
                                return "wh2_main_sch_infrastructure1_farm";
                            end,
                            building_level = function()
                                return 2;
                            end,
                        };
                    end
                    };
                    end,
                    port_slot = function() return {
                        is_null_interface = function() return false; end,
                        has_building = function() return true; end,
                        building = function() return {
                            name = function() return
                                "port";
                            end,
                            superchain = function()
                                return "wh2_main_sch_infrastructure1_farm";
                            end,
                            building_level = function()
                                return 2;
                            end,
                            };
                        end
                        };
                    end,
                    is_port = function()
                        return true;
                    end,
                    slot_list = function() return {
                        num_items = function () return 2; end,
                        item_at = function(index)
                            if index == 1 then
                                return slot_1;
                            else
                                return slot_2;
                            end
                        end
                    }
                    end,
                }
                end
            }
        end,
        set_character_immortality = function() end,
        get_campaign_name = function() return "main_warhammer"; end,
        apply_effect_bundle_to_characters_force = function() end,
        kill_character = function() end,
        trigger_incident = function() end,
        trigger_dilemma = function() end,
        trigger_mission = function() end,
        create_force_with_general = function() end,
        force_add_trait = function() end,
        force_remove_trait = function() end,
        get_character_by_cqi = function() end,
        char_is_mobile_general_with_army = function() return true; end,
        restrict_units_for_faction = function() end,
        save_named_value = function(self, saveKey, data, context)
            mockSaveData[saveKey] = data;
        end,
        load_named_value = function(self, saveKey, datastructure, context)
            if mockSaveData[saveKey] == nil then
                return nil;
            end
            return mockSaveData[saveKey];
        end,
        remove_effect_bundle = function() end,
        apply_effect_bundle = function() end,
        char_is_agent = function() return false end,
        steal_user_input = function() end,
    };
end

cm = get_cm();
mock_max_unit_ui_component = {
    Id = function() return "CTT_emp_halberdiers_reg_recruitable" end,
    ChildCount = function() return 1; end,
    Find = function() return mock_unit_ui_component; end,
    SetVisible = function() end,
    MoveTo = function() end,
    SetStateText = function() end,
    SetInteractive = function() end,
    Visible = function() return true; end,
    Position = function() return 0, 1 end,
    Bounds = function() return 0, 1 end,
    Width = function() return 1; end,
    Resize = function() return; end,
    SimulateMouseOn = function() return; end,
    GetStateText = function() return "/unit/wh_main_vmp_inf_zombie]]"; end,
    --GetStateText = function() return "Unlocks recruitment of:"; end,
    SetTooltipText = function() return nil; end,
    SetCanResizeHeight = function() end;
    SetCanResizeWidth = function() end;
}

mock_unit_ui_component = {
    Id = function() return "wh_main_vmp_inf_zombie_mercenary" end,
    --Id = function() return "building_info_recruitment_effects" end,
    ChildCount = function() return 1; end,
    Find = function() return mock_max_unit_ui_component; end,
    SetVisible = function() end,
    MoveTo = function() end,
    SetStateText = function() end,
    SetInteractive = function() end,
    Visible = function() return true; end,
    Position = function() return 0, 1 end,
    Bounds = function() return 0, 1 end,
    Width = function() return 1; end,
    Resize = function() return; end,
    SimulateMouseOn = function() return; end,
    GetStateText = function() return "/unit/wh_main_vmp_inf_zombie]]"; end,
    SetTooltipText = function() return nil; end,
    SetCanResizeHeight = function() end;
    SetCanResizeWidth = function() end;
}

mock_unit_ui_list_component = {
    Id = function() return "mock_list" end,
    ChildCount = function() return 1; end,
    Find = function() return mock_unit_ui_component; end,
    SetVisible = function() end,
    MoveTo = function() end,
    SetStateText = function() end,
    SetInteractive = function() end,
    Visible = function() return true; end,
    Position = function() return 0, 1 end,
    Bounds = function() return 0, 1 end,
    Width = function() return 1; end,
    Resize = function() return; end,
    SimulateMouseOn = function() return; end,
    GetStateText = function() return "/unit/wh_main_vmp_inf_zombie]]"; end,
    SetTooltipText = function() return nil; end,
    SetCanResizeHeight = function() end;
    SetCanResizeWidth = function() end;
}

find_uicomponent = function()
    return mock_unit_ui_list_component;
end

UIComponent = function(mock_ui_find) return mock_ui_find; end

core = {
    add_listener = function (self, key, eventKey, condition, callback)
        mock_listeners.listeners[key] = {
            Condition = condition,
            Callback = callback,
        }
    end,
    get_ui_root = function() end,
    get_screen_resolution = function() return 0, 1 end;
}

random_army_manager = {
    new_force = function() end,
    add_mandatory_unit = function() end,
    add_unit = function() end,
    generate_force = function() return ""; end,
}

invasion_manager = {
    new_invasion = function()
        return {
            set_target = function() end,
            apply_effect = function() end,
            add_character_experience = function() end,
            start_invasion = function() end,
            assign_general = function() end,
            create_general = function() end,
        }
    end,
    get_invasion = function() return {
        release = function() return end,
    }; end,
}
out = function(text)
  print(text);
end

require 'script/campaign/mod/a_urp_core_resource_loader';
require 'script/campaign/mod/urp_enchanted_arrow_expansion_patch'
require 'script/campaign/mod/urp_mixu_patch'
require 'script/campaign/mod/urp_wez_speshul_patch'
require 'script/campaign/mod/urp_x_ctt_patch'
require 'script/campaign/mod/urp_z_cataph_patches'
require 'script/campaign/mod/z_unit_recruitment_pools'

math.randomseed(os.time())

-- This is used in game by Warhammer but we have it here so it won't throw errors when running
-- in ZeroBrane IDE
function URP_Log(text)
  print(text);
end

z_unit_recruitment_pools();

urp = _G.urp;

local unitName = "Lothern Sea Guard (Shields)\n+1 Reserve cap\n+50 Immediate reserves\n+25 Growth Change";
local localisedUnitName = "Lothern Sea Guard (Shields)\n";
localisedUnitName = localisedUnitName:gsub("%(", "%%(");
localisedUnitName = localisedUnitName:gsub("%)", "%%)");
local value = unitName:match(localisedUnitName);

turn_number = 1;
-- This is a mockContext to simulate a click on a unit
local MockContext_URP_CharacterCreated = {
    Key = "URP_CharacterCreated",
    Context = {
        character = function() return testCharacter; end,
    },
}
mock_listeners:trigger_listener(MockContext_URP_CharacterCreated);


local MockContext_URP_InitialiseFaction = {
    Key = "URP_InitialiseFaction",
    Context = {
        faction = function() return humanFaction; end,
    },
}
mock_listeners:trigger_listener(MockContext_URP_InitialiseFaction);



local URP_UpdateUnitReplenishment1 = {
    Key = "URP_UpdateUnitReplenishment",
    Context = {
        faction = function() return humanFaction; end,
    },
}
mock_listeners:trigger_listener(URP_UpdateUnitReplenishment1);

local URP_UpdateUnitReplenishment2 = {
    Key = "URP_UpdateUnitReplenishment",
    Context = {
        faction = function() return testFaction; end,
    },
}
mock_listeners:trigger_listener(URP_UpdateUnitReplenishment2);

local URP_UpdateUnitReplenishment3 = {
    Key = "URP_UpdateUnitReplenishment",
    Context = {
        faction = function() return humanFaction; end,
    },
}
mock_listeners:trigger_listener(URP_UpdateUnitReplenishment3);

_G.UIPM.CachedUIData["UnitPanelOpened"] = true;
local UIPM_CharacterSelected = {
    Key = "UIPM_CharacterSelected",
    Context = {
        character = function() return testCharacter; end,
    },
}
mock_listeners:trigger_listener(UIPM_CharacterSelected);

-- This is a mockContext to simulate a click on a unit
local MockContext_RMUI_ClickedButtonRecruitedUnits = {
    Key = "RMUI_ClickedButtonRecruitedUnits",
    Context = {
        string = "QueuedLandUnit"
    },
}
mock_listeners:trigger_listener(MockContext_RMUI_ClickedButtonRecruitedUnits);

local context = {
    UiToUnits = mock_unit_ui_component,
    UiSuffix = "_recruitable",
    Type = "",
    CachedUIData = {},
}
urp:RefreshUICallback(context);

local MockContext_RMUI_ClickedButtonMercenaryUnits = {
    Key = "RMUI_ClickedButtonMercenaryUnits",
    Context = {
        string = "wh_main_vmp_inf_skeleton_warriors_0_mercenary"
    },
}
mock_listeners:trigger_listener(MockContext_RMUI_ClickedButtonMercenaryUnits);
mock_listeners:trigger_listener(MockContext_RMUI_ClickedButtonMercenaryUnits);

local MockContext_URP_RollUnitReplenishment = {
    Key = "URP_RollUnitReplenishment",
    Context = {
        faction = function() return humanFaction end,
    },
}
mock_listeners:trigger_listener(MockContext_URP_RollUnitReplenishment);

turn_number = 2;
local RM_FactionTurnStart = {
    Key = "RM_FactionTurnStart",
    Context = {
        faction = function() return humanFaction; end,
    },
}
mock_listeners:trigger_listener(RM_FactionTurnStart);
local MockContext_URP_UpdateBuildingPoolData = {
    Key = "URP_UpdateBuildingPoolData",
    Context = {
        faction = function() return humanFaction end,
    },
}
mock_listeners:trigger_listener(MockContext_URP_UpdateBuildingPoolData);

turn_number = 3;

local MockContext_URP_UpdateBuildingPoolDataHorde = {
    Key = "URP_UpdateBuildingPoolDataHorde",
    Context = {
        building = function() return "wh_main_emp_barracks_2"; end,
        character = function() return testCharacter; end,
    },
}
mock_listeners:trigger_listener(MockContext_URP_UpdateBuildingPoolDataHorde);


local URP_CharacterKilled = {
    Key = "URP_CharacterKilled",
    Context = {
        character = function() return testCharacter; end,
    },
}
mock_listeners:trigger_listener(URP_CharacterKilled);

local RMUI_ClickedButtonRecruitedUnits = {
    Key = "RMUI_ClickedButtonRecruitedUnits",
    Context = {
        string = "QueuedLandUnit"
    },
}
mock_listeners:trigger_listener(RMUI_ClickedButtonRecruitedUnits);

local RM_CharacterCompletedBattle = {
    Key = "RM_CharacterCompletedBattle",
    Context = {
        character = function() return testCharacter; end,
    },
}
mock_listeners:trigger_listener(RM_CharacterCompletedBattle);

local RM_UnitCreated = {
    Key = "RM_UnitCreated",
    Context = {
        unit = function() return test_unit; end,
    },
}
mock_listeners:trigger_listener(RM_UnitCreated);

local URP_UpdateUnitReplenishment = {
    Key = "URP_UpdateUnitReplenishment",
    Context = {
        faction = function() return humanFaction; end,
    },
}
mock_listeners:trigger_listener(URP_UpdateUnitReplenishment);

local UIPM_CharacterSelected = {
    Key = "UIPM_CharacterSelected",
    Context = {
        character = function() return testCharacter; end,
    },
}
mock_listeners:trigger_listener(UIPM_CharacterSelected);

local UIPM_UnitInfoPanelReplenishmentOn = {
    Key = "UIPM_UnitInfoPanelReplenishmentOn",
    Context = {
        string = "wh_main_emp_art_mortar_recruitable",
    },
}
mock_listeners:trigger_listener(UIPM_UnitInfoPanelReplenishmentOn);

local UIPM_BuildingUnitInfoMouseOn = {
    Key = "UIPM_BuildingUnitInfoMouseOn",
    Context = {
        string = "wh_main_dwf_barracks_2",
    },
}
mock_listeners:trigger_listener(UIPM_BuildingUnitInfoMouseOn);

local URP_DiplomacyOpened = {
    Key = "URP_DiplomacyOpened",
    Context = {
        string = "diplomacy_dropdown",
    },
}
mock_listeners:trigger_listener(URP_DiplomacyOpened);

URP_InitialiseSaveHelper(cm, context);
URP_SaveUnitPools(urp);
URP_SaveFactionBuildingPools(urp);
URP_SaveCharacterBuildingPools(urp);

urp.FactionUnitData = nil;
urp.FactionBuildingData = nil;
urp.CharacterBuildingData = nil;

URP_InitialiseLoadHelper(cm, context);
URP_LoadUnitPools(urp);
URP_LoadFactionBuildingPools(urp);
URP_LoadCharacterBuildingPools(urp);

urp:SetupFactionUnitPools(testFaction);
urp:SetupFactionUnitPools(humanFaction);

local testString1 = "Pavise Crossbowmen";
local testString2 = "test Pavise Crossbowmen\nUnit Growth";

local test = testString2:match("(.-)"..testString1.."\n");

local result = true;

local testKey = "faction_row_entry_avelorn";
local factionKey = string.match(testKey, "faction_row_entry_(.*)");
local test2 = "";