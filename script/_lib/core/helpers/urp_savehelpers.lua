local MAX_NUM_SAVE_TABLE_KEYS = 400;

local cm = nil;
local context = nil;

function URP_InitialiseSaveHelper(cmObject, contextObject)
    URP_Log("URP: Initialising save helpers");
    cm = cmObject;
    context = contextObject;
end

function URP_SaveUnitPools(urp)
    URP_Log("Saving unit pools");
    local urp_unit_pools_header = {};

    local numberOfUnits = 0;
    local tableCount = 1;
    local nthTable = {};

    for subcultureKey, subcultureFactions in pairs(urp.FactionUnitData) do
        for factionKey, factionData in pairs(subcultureFactions) do
            for unitKey, unitData in pairs(factionData) do
                nthTable[subcultureKey.."/"..factionKey.."/"..unitKey] = { unitData.UnitReserveCap, unitData.UnitReserves, unitData.UnitGrowth };
                numberOfUnits = numberOfUnits + 1;

                if numberOfUnits % MAX_NUM_SAVE_TABLE_KEYS == 0 then
                    URP_Log("Saving table number "..(tableCount + 1));
                    cm:save_named_value("urp_unit_pool_units_"..tableCount, nthTable, context);
                    tableCount = tableCount + 1;
                    nthTable = {};
                end
            end
        end
    end
    -- Saving the remaining units
    cm:save_named_value("urp_unit_pool_units_"..tableCount, nthTable, context);
    URP_Log("Saving "..numberOfUnits.." unit numbers.");

    urp_unit_pools_header["TotalCharacters"] = numberOfUnits;
    cm:save_named_value("urp_unit_pools_header", urp_unit_pools_header, context);
end

function URP_SaveFactionBuildingPools(urp)
    URP_Log("Saving faction building pools");
    local urp_faction_building_pools_header = {};

    local buildingAmount = 0;
    local tableCount = 1;
    local nthTable = {};

    for subcultureKey, subcultureFactions in pairs(urp.FactionBuildingData) do
        for factionKey, factionData in pairs(subcultureFactions) do
            for buildingKey, buildingData in pairs(factionData) do
                nthTable[subcultureKey.."/"..factionKey.."/"..buildingKey] = { buildingData.Amount };
                buildingAmount = buildingAmount + 1;

                if buildingAmount % MAX_NUM_SAVE_TABLE_KEYS == 0 then
                    URP_Log("Saving table number "..(tableCount + 1));
                    cm:save_named_value("urp_unit_pool_faction_buildings_"..tableCount, nthTable, context);
                    tableCount = tableCount + 1;
                    nthTable = {};
                end
            end
        end
    end
    -- Saving the remaining buildings
    cm:save_named_value("urp_unit_pool_faction_buildings_"..tableCount, nthTable, context);
    URP_Log("Saving "..buildingAmount.." buildings.");

    urp_faction_building_pools_header["TotalFactionBuildings"] = buildingAmount;
    cm:save_named_value("urp_faction_building_pools_header", urp_faction_building_pools_header, context);
end

function URP_SaveCharacterBuildingPools(urp)
    URP_Log("Saving character building pools");
    local urp_character_building_pools_header = {};

    local buildingAmount = 0;
    local tableCount = 1;
    local nthTable = {};

    for subcultureKey, subcultureFactions in pairs(urp.CharacterBuildingData) do
        for factionKey, factionData in pairs(subcultureFactions) do
            for characterCQI, characterData in pairs(factionData) do
                for buildingKey, buildingData in pairs(characterData) do
                    nthTable[subcultureKey.."/"..factionKey.."/"..characterCQI.."/"..buildingKey] = { buildingData.Amount };
                    buildingAmount = buildingAmount + 1;

                    if buildingAmount % MAX_NUM_SAVE_TABLE_KEYS == 0 then
                        URP_Log("Saving table number "..(tableCount + 1));
                        cm:save_named_value("urp_unit_pool_character_buildings_"..tableCount, nthTable, context);
                        tableCount = tableCount + 1;
                        nthTable = {};
                    end
                end
            end
        end
    end
    -- Saving the remainder units
    cm:save_named_value("urp_unit_pool_character_buildings_"..tableCount, nthTable, context);
    URP_Log("Saving "..buildingAmount.." character buildings.");

    urp_character_building_pools_header["TotalCharacterBuildings"] = buildingAmount;
    cm:save_named_value("urp_character_building_pools_header", urp_character_building_pools_header, context);
end