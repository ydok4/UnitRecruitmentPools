-- Mock Data
testCharacter = {
    cqi = function() return 123 end,
    get_forename = function() return "Direfan"; end,
    get_surname = function() return "Cylostra"; end,
    character_subtype_key = function() return "grn_orc_warboss"; end,
    command_queue_index = function() end,
    has_military_force = function() return false end,
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
        return "wh_main_vmp_vampire_counts";
    end,
    subculture = function()
        return "wh_main_sc_vmp_vampire_counts";
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
}

testFaction = {
    name = function()
        return "wh2_dlc11_cst_the_drowned";
    end,
    subculture = function()
        return "wh_main_sc_grn_greenskins";
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
        name = function() return "wh2_main_hef_barracks_1"; end,
    }
    end,
}

slot_2 = {
    has_building = function() return true; end,
    building = function() return {
        name = function() return "wh2_main_hef_barracks_1"; end,
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
        get_region = function()
            return {
                owning_faction = function() return testFaction; end,
                name = function() return "region_name"; end,
                is_province_capital = function() return false; end,
                adjacent_region_list = function()
                    return {
                        item_at = function(self, i)
                            if i == 0 then
                                return get_cm():f();
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
                settlement = function() return {
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
    };
end

cm = get_cm();
mock_max_unit_ui_component = {
    Id = function() return "max_units" end,
    ChildCount = function() return 1; end,
    Find = function() return mock_unit_ui_component; end,
    SetVisible = function() end,
    MoveTo = function() end,
    SetStateText = function() end,
    SetInteractive = function() end,
    Visible = function() return true; end,
    Position = function() return 0, 1 end,
    Bounds = function() return 0, 1 end,
    Resize = function() return; end,
    SetCanResizeWidth = function() return; end,
    SimulateMouseOn = function() return; end,
    GetStateText = function() return "/unit/wh_dlc04_emp_inf_free_company_militia_0]]"; end,
}

mock_unit_ui_component = {
    Id = function() return "wh_dlc04_emp_inf_free_company_militia_0_mercenary" end,
    ChildCount = function() return 1; end,
    Find = function() return mock_max_unit_ui_component; end,
    SetVisible = function() end,
    MoveTo = function() end,
    SetStateText = function() end,
    SetInteractive = function() end,
    Visible = function() return true; end,
    Position = function() return 0, 1 end,
    Bounds = function() return 0, 1 end,
    Resize = function() return; end,
    SetCanResizeWidth = function() return; end,
    SimulateMouseOn = function() return; end,
    GetStateText = function() return "/unit/wh_dlc04_emp_inf_free_company_militia_0]]"; end,
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
    Resize = function() return; end,
    SetCanResizeWidth = function() return; end,
    SimulateMouseOn = function() return; end,
    GetStateText = function() return "/unit/wh_dlc04_emp_inf_free_company_militia_0]]"; end,
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

require 'script/campaign/mod/unit_recruitment_pools'

math.randomseed(os.time())

-- This is used in game by Warhammer but we have it here so it won't throw errors when running
-- in ZeroBrane IDE
function URP_Log(text)
  print(text);
end

unit_recruitment_pools();

urp = _G.urp;

-- This is a mockContext to simulate a click on a unit
local MockContext_URP_ClickedButtonRecruitedUnits = {
    Key = "URP_ClickedButtonRecruitedUnits",
    Context = {
        string = "QueuedLandUnit"
    },
}
mock_listeners:trigger_listener(MockContext_URP_ClickedButtonRecruitedUnits);
local MockContext_ClickedButtonMercenaryUnits = {
    Key = "URP_ClickedButtonMercenaryUnits",
    Context = {
        string = "wh_main_vmp_inf_zombie_mercenary"
    },
}
mock_listeners:trigger_listener(MockContext_ClickedButtonMercenaryUnits);
mock_listeners:trigger_listener(MockContext_ClickedButtonMercenaryUnits);

local MockContext_URP_RollUnitReplenishment = {
    Key = "URP_RollUnitReplenishment",
    Context = {
        faction = function() return humanFaction end,
    },
}
mock_listeners:trigger_listener(MockContext_URP_RollUnitReplenishment);

turn_number = 2;
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


InitialiseSaveHelper(cm, context);
URP_SaveUnitPools(urp);
URP_SaveFactionBuildingPools(urp);
URP_SaveCharacterBuildingPools(urp);

urp.FactionUnitData = nil;
urp.FactionBuildingData = nil;
urp.CharacterBuildingData = nil;

InitialiseLoadHelper(cm, context);
URP_LoadUnitPools(urp);
URP_LoadFactionBuildingPools(urp);
URP_LoadCharacterBuildingPools(urp);