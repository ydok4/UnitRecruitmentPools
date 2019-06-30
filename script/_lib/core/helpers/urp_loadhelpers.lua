local MAX_NUM_SAVE_TABLE_KEYS = 400;

local cm = nil;
local context = nil;

function URP_InitialiseLoadHelper(cmObject, contextObject)
    out("URP: Initialising load helpers");
    cm = cmObject;
    context = contextObject;
end

function URP_LoadUnitPools(urp)
    out("URP: LoadUnitPools");
    if cm == nil then
        out("URP: Can't access CM");
        return;
    end
    local urp_unit_pools_header = cm:load_named_value("urp_unit_pools_header", {}, context);
    if urp_unit_pools_header == nil or urp_unit_pools_header["TotalCharacters"] == nil then
        out("URP: No characters to load");
        return;
    else
        out("URP: Loading "..urp_unit_pools_header["TotalCharacters"].." other characters");
    end

    local serialised_save_table_units = {};
    urp.FactionUnitData = {};
    local tableCount = math.ceil(urp_unit_pools_header["TotalCharacters"] / MAX_NUM_SAVE_TABLE_KEYS);
    for n = 1, tableCount do
        out("URP: Loading table "..tostring(n));
        local nthTable = cm:load_named_value("urp_unit_pool_units_"..tostring(n), {}, context);
        ConcatTableWithKeys(serialised_save_table_units, nthTable);
    end
    out("URP: Concatted serialised save data");

    for key, factionUnitData in pairs(serialised_save_table_units) do
        --out("URP: Checking key: "..key);
        local subcultureKey = key:match("(.-)/");
        if urp.FactionUnitData[subcultureKey] == nil then
            urp.FactionUnitData[subcultureKey] = {};
        end
        local factionKey = key:match(subcultureKey.."/(.-)/");
        if urp.FactionUnitData[subcultureKey][factionKey] == nil then
            urp.FactionUnitData[subcultureKey][factionKey] = {};
        end
        -- We need to escape anything in the which could be a pattern class
        -- function, current I think it is just - for those goddamn skull-takerz
        local substitutedFactionKey = factionKey:gsub("-", "%%-");
        local unitKey = key:match(subcultureKey.."/"..substitutedFactionKey.."/(.+)");
        --out("URP: Loading unit: "..unitKey.." for faction: "..factionKey);
        urp.FactionUnitData[subcultureKey][factionKey][unitKey] = {
            UnitReserveCap = factionUnitData[1],
            UnitReserves = factionUnitData[2],
            UnitGrowth = factionUnitData[3],
        }
    end

    out("URP: Finished loading unit tables");
end

function URP_LoadFactionBuildingPools(urp)
    out("URP: LoadFactionBuildingPools");
    if cm == nil then
        out("URP: Can't access CM");
        return;
    end
    local urp_faction_building_pools_header = cm:load_named_value("urp_faction_building_pools_header", {}, context);
    if urp_faction_building_pools_header == nil or urp_faction_building_pools_header["TotalFactionBuildings"] == nil then
        out("URP: No faction buildings to load");
        return;
    else
        out("URP: Loading "..urp_faction_building_pools_header["TotalFactionBuildings"].." faction buildings");
    end

    local serialised_save_table_faction_buildings = {};

    urp.FactionBuildingData = {};
    local tableCount = math.ceil(urp_faction_building_pools_header["TotalFactionBuildings"] / MAX_NUM_SAVE_TABLE_KEYS);
    for n = 1, tableCount do
        out("URP: Loading table "..tostring(n));
        local nthTable = cm:load_named_value("urp_unit_pool_faction_buildings_"..tostring(n), {}, context);
        ConcatTableWithKeys(serialised_save_table_faction_buildings, nthTable);
    end
    out("URP: Concatted serialised save data");

    for key, factionbuildingData in pairs(serialised_save_table_faction_buildings) do
        local subcultureKey = key:match("(.-)/");
        if urp.FactionBuildingData[subcultureKey] == nil then
            urp.FactionBuildingData[subcultureKey] = {};
        end
        local factionKey = key:match(subcultureKey.."/(.-)/");
        if urp.FactionBuildingData[subcultureKey][factionKey] == nil then
            urp.FactionBuildingData[subcultureKey][factionKey] = {};
        end
        -- We need to escape anything in the which could be a pattern class
        -- function, current I think it is just - for those goddamn skull-takerz
        local substitutedFactionKey = factionKey:gsub("-", "%%-");
        local buildingKey = key:match(subcultureKey.."/"..substitutedFactionKey.."/(.+)");
        urp.FactionBuildingData[subcultureKey][factionKey][buildingKey] = {
            Amount = factionbuildingData[1],
        }
    end

    out("URP: Finished loading faction building tables");
end

function URP_LoadCharacterBuildingPools(urp)
    out("URP: LoadCharacterBuildingPools");
    if cm == nil then
        out("URP: Can't access CM");
        return;
    end
    local urp_character_building_pools_header = cm:load_named_value("urp_character_building_pools_header", {}, context);
    if urp_character_building_pools_header == nil or urp_character_building_pools_header["TotalCharacterBuildings"] == nil then
        out("URP: No character buildings to load");
        return;
    else
        out("URP: Loading "..urp_character_building_pools_header["TotalCharacterBuildings"].." character buildings");
    end

    local serialised_save_table_character_buildings = {};

    urp.CharacterBuildingData = {};
    local tableCount = math.ceil(urp_character_building_pools_header["TotalCharacterBuildings"] / MAX_NUM_SAVE_TABLE_KEYS);
    for n = 1, tableCount do
        out("URP: Loading table "..tostring(n));
        local nthTable = cm:load_named_value("urp_unit_pool_character_buildings_"..tostring(n), {}, context);
        ConcatTableWithKeys(serialised_save_table_character_buildings, nthTable);
    end
    out("URP: Concatted serialised save data");

    for key, characterbuildingData in pairs(serialised_save_table_character_buildings) do
        local subcultureKey = key:match("(.-)/");
        if urp.CharacterBuildingData[subcultureKey] == nil then
            urp.CharacterBuildingData[subcultureKey] = {};
        end
        local factionKey = key:match(subcultureKey.."/(.-)/");
        if urp.CharacterBuildingData[subcultureKey][factionKey] == nil then
            urp.CharacterBuildingData[subcultureKey][factionKey] = {};
        end
        -- We need to escape anything in the which could be a pattern class
        -- function, current I think it is just - for those goddamn skull-takerz
        local substitutedFactionKey = factionKey:gsub("-", "%%-");
        local characterCQI = key:match(subcultureKey.."/"..substitutedFactionKey.."/(.-)/");
        if urp.CharacterBuildingData[subcultureKey][factionKey][characterCQI] == nil then
            urp.CharacterBuildingData[subcultureKey][factionKey][characterCQI] = {};
        end
        local buildingKey = key:match(subcultureKey.."/"..substitutedFactionKey.."/"..characterCQI.."/(.+)");
        urp.CharacterBuildingData[subcultureKey][factionKey][buildingKey] = {
            Amount = characterbuildingData[1],
        }
    end

    out("URP: Finished loading character building tables");
end