local MAX_NUM_SAVE_TABLE_KEYS = 400;

local cm = nil;
local context = nil;

function InitialiseSaveHelper(cmObject, contextObject)
    URP_Log("URP: Initialising save helpers");
    cm = cmObject;
    context = contextObject;
end

function URP_SaveUnitPools(urp)
    URP_Log("Saving unit pools");
    local urp_unit_pools_header = {};

    local unitAmount = 0;
    local tableCount = 1;
    local nthTable = {};

    for subcultureKey, subcultureFactions in pairs(urp.FactionUnitData) do
        for factionKey, factionData in pairs(subcultureFactions) do
            for unitKey, unitData in pairs(factionData) do
                nthTable[subcultureKey.."/"..factionKey.."/"..unitKey] = { unitData.UnitCap, unitData.AvailableAmount, unitData.GrowthChance };
                unitAmount = unitAmount + 1;

                if unitAmount % MAX_NUM_SAVE_TABLE_KEYS == 0 then
                    URP_Log("Saving table number "..(tableCount + 1));
                    cm:save_named_value("urp_unit_pool_units_"..tableCount, nthTable, context);
                    tableCount = tableCount + 1;
                    nthTable = {};
                end
            end
        end
    end
    -- Saving the remainder units
    cm:save_named_value("urp_unit_pool_units_"..tableCount, nthTable, context);
    URP_Log("Saving "..unitAmount.." unit numbers.");

    urp_unit_pools_header["TotalCharacters"] = unitAmount;
    cm:save_named_value("urp_unit_pools_header", urp_unit_pools_header, context);
end