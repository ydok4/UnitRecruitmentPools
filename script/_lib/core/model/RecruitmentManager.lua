RecruitmentManager = {
    EnableLogging = false,
    FactionCharacterUnits = {},
    RecruitmentManagerCallbacks = {},
}

function RecruitmentManager:new (o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function RecruitmentManager:Initialise(core)
    if self.EnableLogging == true then
        self:Log_Start();
    end
    self:InitialiseListeners(core);
end

function RecruitmentManager:Log_Start()
    if self.EnableLogging == true then
        io.open("RecruitmentManager.txt","w"):close();
    end
end

function RecruitmentManager:Log(text)
    if self.EnableLogging == true then
        local logText = tostring(text);
        local logTimeStamp = os.date("%d, %m %Y %X");
        local popLog = io.open("RecruitmentManager.txt","a");

        popLog :write("RM:  "..logText .. "   : [".. logTimeStamp .. "]\n");
        popLog :flush();
        popLog :close();
    end
end

function RecruitmentManager:Log_Finished()
    if self.EnableLogging == true then
        local popLog = io.open("RecruitmentManager.txt","a");

        popLog :write("RM:  FINISHED\n\n");
        popLog :flush();
        popLog :close();
    end
end

function RecruitmentManager:InitialiseListeners(core)
    -- Standard recruitment listener
    core:add_listener(
        "RM_UnitCreated",
        "UnitTrained",
        function(context)
            local character = context:unit():force_commander();
            return context:unit():faction():name() ~= "rebels"
            and character:has_military_force() == true
            and character:military_force():is_armed_citizenry() == false
            and cm:char_is_agent(character) == false;
        end,
        function(context)
            local faction = context:unit():faction();
            local unitKey = context:unit():unit_key();
            self:Log("Unit: "..unitKey.." recruited for faction: "..faction:name());
            self:ModifyAmountInFactionCharacterUnitCache(context:unit(), context:unit():force_commander(), 1);
            self:TriggerRMEventCallbacks(faction, context:unit():force_commander(), "RM_UnitCreated");
            self:Log_Finished();
        end,
        true
    );

    -- Unit merged listener
    core:add_listener(
        "RM_UnitMerged",
        "UnitMergedAndDestroyed",
        function(context)
            return context:unit():faction():name() ~= "rebels";
        end,
        function(context)
            local faction = context:unit():faction();
            self:Log("Unit merged/destroyed for faction: "..faction:name());
            self:ModifyAmountInFactionCharacterUnitCache(context:unit(), context:unit():force_commander(), -1);
            self:TriggerRMEventCallbacks(faction, context:unit():force_commander(), "RM_UnitMerged");
            self:Log_Finished();
        end,
        true
    );

    -- Unit disbanded listener
    core:add_listener(
        "RM_UnitDisbanded",
        "UnitDisbanded",
        function(context)
            return context:unit():faction():name() ~= "rebels";
        end,
        function(context)
            local faction = context:unit():faction();
            self:Log("Unit disbanded for faction: "..faction:name());
            self:ModifyAmountInFactionCharacterUnitCache(context:unit(), context:unit():force_commander(), -1);
            self:TriggerRMEventCallbacks(faction, context:unit():force_commander(), "RM_UnitDisbanded");
            self:Log_Finished();
        end,
        true
    );

    -- Battle completed listener
    core:add_listener(
        "RM_CharacterCompletedBattle",
        "CharacterCompletedBattle",
        function(context)
            local character = context:character();
            return character:faction():name() ~= "rebels"
            and character:has_military_force() == true
            and character:military_force():is_armed_citizenry() == false
            and cm:char_is_agent(character) == false;
        end,
        function(context)
            local character = context:character();
            self:Log("Character: "..character:command_queue_index().." in faction: "..character:faction():name().." has completed a battle.");
            self:UpdateCacheWithCharacterForceData(character);
            self:TriggerRMEventCallbacks(character:faction(), character, "RM_CharacterCompletedBattle");
            self:Log_Finished();
        end,
        true
    );

    -- Character Killed Listeners
    core:add_listener(
        "RM_CharacterKilled",
        "CharacterConvalescedOrKilled",
        function(context)
            local character = context:character();
            return character:has_military_force() == true
            and character:military_force():is_armed_citizenry() == false
            and cm:char_is_agent(character) == false;
        end,
        function(context)
            local character = context:character();
            self:Log("Character: "..character:command_queue_index().." in faction: "..character:faction():name().." has been killed or wounded.");
            self:UpdateCacheWithFactionCharacterForceData(context:faction());
            self:TriggerRMEventCallbacks(character:faction(), character, "RM_CharacterKilled");
            self:Log_Finished();
        end,
        true
    );

    -- Faction Turn start listeners
    core:add_listener(
        "RM_FactionTurnStart",
        "FactionTurnStart",
        function(context)
            return context:faction():name() ~= "rebels";
        end,
        function(context)
            if context:faction():is_human() == true then
                self:Log_Start();
            end
            self:UpdateCacheWithFactionCharacterForceData(context:faction());
            self:TriggerRMEventCallbacks(context:faction(), nil, "RM_FactionTurnStart");
            self:Log_Finished();
        end,
        true
    );
end

function RecruitmentManager:RegisterRecruitmentCallback(key, callbackFunction)
    self.RecruitmentManagerCallbacks[key] = callbackFunction;
end

function RecruitmentManager:TriggerRMEventCallbacks(faction, character, listenerContext)
    local context = {
        Faction = faction,
        Character = character,
        ListenerContext = listenerContext,
    }
    for callbackKey, callback in pairs(self.RecruitmentManagerCallbacks) do
        self:Log("Triggering RMEventCallback: "..callbackKey.." for listenerContext: "..listenerContext);
        callback(context);
    end
end

function RecruitmentManager:UpdateCacheWithFactionCharacterForceData(faction)
    local characters = faction:character_list();
    local factionKey = faction:name();
    self:Log("Updating faction character unit cache for faction: "..factionKey);
    for i = 0, characters:num_items() - 1 do
        local character = characters:item_at(i);
        if character:has_military_force() == true and character:military_force():is_armed_citizenry() == false and cm:char_is_agent(character) == false then
            self:InitialiseCacheForCharacterUnit(factionKey, character:command_queue_index());
            self:UpdateCacheWithCharacterForceData(character);
        end
    end
end

function RecruitmentManager:UpdateCacheWithCharacterForceData(character)
    local factionKey = character:faction():name();
    local characterCQI = character:command_queue_index();
    if character:is_null_interface() or character:is_wounded() == true then
        self:RemoveCharacterFromCache(factionKey, characterCQI);
    else
        self:RemoveCharacterFromCache(factionKey, characterCQI);
        local currentUnitList = character:military_force():unit_list();
        for i = 1, currentUnitList:num_items() - 1 do
            local unit = currentUnitList:item_at(i);
            local unitKey = unit:unit_key();
            self:InitialiseCacheForCharacterUnit(factionKey, characterCQI, unitKey);
            self:ModifyAmountInFactionCharacterUnitCache(unit, character, 1);
            self:GetUnitCountForCharacter(characterCQI, factionKey, unitKey);
        end
    end
end

function RecruitmentManager:InitialiseCacheForCharacterUnit(factionKey, characterCQI, unitKey)
    if self.FactionCharacterUnits[factionKey] == nil then
        self.FactionCharacterUnits[factionKey] = {};
        self:Log("Faction: "..factionKey.." is not cached. Initialising");
        local faction = cm:get_faction(factionKey);
        self:UpdateCacheWithFactionCharacterForceData(faction);
        return;
    end
    if characterCQI ~= nil and self.FactionCharacterUnits[factionKey][characterCQI] == nil then
        self.FactionCharacterUnits[factionKey][characterCQI] = {};
    end
    if unitKey ~= nil and self.FactionCharacterUnits[factionKey][characterCQI][unitKey] == nil then
        self.FactionCharacterUnits[factionKey][characterCQI][unitKey] = 0;
    end
end

function RecruitmentManager:ModifyAmountInFactionCharacterUnitCache(unit, character, amount)
    local factionKey = character:faction():name();
    local characterCQI = character:command_queue_index();
    local unitKey = unit:unit_key();

    self:InitialiseCacheForCharacterUnit(factionKey, characterCQI, unitKey);

    if self.FactionCharacterUnits[factionKey] == nil
    or self.FactionCharacterUnits[factionKey][characterCQI] == nil then
        return;
    end
    local unitAmount = self.FactionCharacterUnits[factionKey][characterCQI][unitKey];
    --self:Log("Adding character: "..characterCQI.." in faction: "..factionKey.." to cache with unit: "..unitKey);
    self.FactionCharacterUnits[factionKey][characterCQI][unitKey] = unitAmount + amount;
end

function RecruitmentManager:RemoveCharacterFromCache(factionKey, characterCQI)
    if self.FactionCharacterUnits[factionKey] ~= nil
    and self.FactionCharacterUnits[factionKey][characterCQI] ~= nil then
        --self:Log("Removing character: "..characterCQI.." in faction: "..factionKey.." from cache");
        self.FactionCharacterUnits[factionKey][characterCQI] = nil;
    end
end

function RecruitmentManager:GetUnitCountForFaction(factionKey, unitKey)
    local factionCharacters = self.FactionCharacterUnits[factionKey];
    local amountOfUnit = 0;
    if factionCharacters ~= nil then
        for characterCQI, characterUnits in pairs(factionCharacters) do
            if characterUnits[unitKey] ~= nil then
                --self:Log("Character: "..characterCQI.." in faction: "..factionKey.." has "..characterUnits[unitKey].." of unit: "..unitKey);
                amountOfUnit = amountOfUnit + characterUnits[unitKey];
            end
        end
    end
    return amountOfUnit;
end

function RecruitmentManager:GetUnitCountForCharacter(characterCQI, factionKey, unitKey)
    local factionCharacters = self.FactionCharacterUnits[factionKey];
    if factionCharacters == nil then
        self:Log("Faction has no characters or units");
        return;
    end
    local characterUnits = factionCharacters[characterCQI];
    if characterUnits == nil then
        self:Log("Character has no data or is missing");
        return;
    end
    local amountOfUnit = characterUnits[unitKey];
    return amountOfUnit;
end