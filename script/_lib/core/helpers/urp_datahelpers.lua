out("URP: Loading URP DataHelpers");
local ENABLE_LOGGING = true;
function ConcatTableWithKeys(destinationTable, sourceTable)
    for key, value in pairs(sourceTable) do
        destinationTable[key] = value;
    end
end

function ConcatTable(destinationTable, sourceTable)
    for key, value in pairs(sourceTable) do
        destinationTable[#destinationTable + 1] = value;
    end
end

function Roll100(passValue)
    return Random(99) < passValue;
end

function TableHasAnyValue(table)
    for key, value in pairs(table) do
        return true;
    end
    return false;
end

function URP_TableHasValue(table, valueToCheck)
    for key, value in pairs(table) do
        if value == valueToCheck then
            return true;
        end
    end
    return false;
end

function Random(limit, start)
    if not start then
        start = 1;
    end
    return math.random(start, limit) ;
end

function GetRandomObjectFromList(objectList)
    local tempTable = {}
    for key, value in pairs(objectList) do
      tempTable[#tempTable + 1] = key; --Store keys in another table
    end
    local index = tempTable[Random(#tempTable)];
    return objectList[index];
end

function GetRandomObjectKeyFromList(objectList)
    local tempTable = {}
    for key, value in pairs(objectList) do
      tempTable[#tempTable + 1] = key; --Store keys in another table
    end
    local index = tempTable[Random(#tempTable)];
    return index;
end

function FindTableObjectByKeyPartial(objectList, partialValue)
    for key, value in pairs(objectList) do
        if string.match(key, partialValue) then
            return value;
        end
    end
end

function CreateValidLuaTableKey(value)
    -- This removes any spaces within names, eg the surname "Von Carstein";
    -- Otherwise the key is invalid and the character won't be tracked
    value = value:gsub("%s+", "");
    -- This replaces any apostrophes in names with _
    value = value:gsub("'", "_");
    value = value:gsub("-", "_");
    value = value:gsub("á", "a");
    value = value:gsub("à", "a");
    value = value:gsub("é", "e");
    value = value:gsub("í", "i");
    value = value:gsub("ó", "o");
    value = value:gsub("‘", "_");
    value = value:gsub(",", "_");
    return value;
end

function GetStringifiedUnitList(character)
    if character:has_military_force() == false then
        URP_Log("Replaced character does not have military force");
        return "";
    end
    local unitList = character:military_force():unit_list();

    local unitString = "";
    -- This starts at one so it skips the first unit, which is the general
    for i = 0, unitList:num_items() - 1 do
        -- If this is the last unit we should not add a comma to the end
        local unitKey = unitList:item_at(i):unit_key();
        if i ~= 0 then
            if i == unitList:num_items() - 1 then
                unitString = unitString..unitKey;
            else
                unitString = unitString..unitKey..",";
            end
        end
    end
    URP_Log("Built Unit string: "..unitString);
    return unitString;
end

function GetKeysFromTable(tableWithKeys)
    local tableKeys = {};
    for key, value in pairs(tableWithKeys) do
        tableKeys[#tableKeys + 1] = key;
    end
    return tableKeys;
end

function GetMatchingKeyMatchingLocalisedString(keys, stringToMatch, keyPrefix)
    for index, key in pairs(keys) do
        if stringToMatch == effect.get_localised_string(keyPrefix..key) then
            return key;
        end
    end
    return nil;
end

function URP_Log_Start()
    -- Clears the log file
    if ENABLE_LOGGING == true then
        io.open("Unit_Recruitment_Pools.txt","w"):close();
    end
end

function URP_Log(text)
    if ENABLE_LOGGING == true then
        local logText = tostring(text);
        local logTimeStamp = os.date("%d, %m %Y %X");
        local popLog = io.open("Unit_Recruitment_Pools.txt","a");

        popLog :write("URP:  "..logText .. "   : [".. logTimeStamp .. "]\n");
        popLog :flush();
        popLog :close();
    end
end

function URP_Log_Finished()
    if ENABLE_LOGGING == true then
        local popLog = io.open("Unit_Recruitment_Pools.txt","a");

        popLog :write("URP:  FINISHED\n\n");
        popLog :flush();
        popLog :close();
    end
end