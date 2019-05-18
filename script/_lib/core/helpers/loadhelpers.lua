local MAX_NUM_SAVE_TABLE_KEYS = 400;

local cm = nil;
local context = nil;

function InitialiseLoadHelper(cmObject, contextObject)
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
        local subcultureKey = key:match("(.-)/");
        if urp.FactionUnitData[subcultureKey] == nil then
            urp.FactionUnitData[subcultureKey] = {};
        end
        local factionKey = key:match(subcultureKey.."/(.-)/");
        if urp.FactionUnitData[subcultureKey][factionKey] == nil then
            urp.FactionUnitData[subcultureKey][factionKey] = {};
        end
        local unitKey = key:match(subcultureKey.."/"..factionKey.."/(.+)");
        urp.FactionUnitData[subcultureKey][factionKey][unitKey] = {
            UnitCap = factionUnitData[1],
            AvailableAmount = factionUnitData[2],
            GrowthChance = factionUnitData[3],
        }
    end

    out("URP: Finished loading tables");
end