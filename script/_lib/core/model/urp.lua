UnitRecruitmentPools = {
    -- UI Object which handles UI manipulation
    urpui = {};
    FactionUnitData = {},
    HumanFaction = {},
}

function UnitRecruitmentPools:new (o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

function UnitRecruitmentPools:Initialise()
    out("CRP: Setting default values");
    URP_Log("Setting default values");
    self.HumanFaction = self:GetHumanFaction();
    URP_Log("Finished default values");
    out("CRP: Finished default values");
end

function UnitRecruitmentPools:NewGameStartUp()
    URP_Log("New game startup");
    -- Initialise the human player
    self:SetupFactionUnitPools(self.HumanFaction);
    URP_Log("New game startup completed");
    URP_Log_Finished();
end

-- This exists to convert the human faction list to just an object.
-- This also means it will only work for one player.
function UnitRecruitmentPools:GetHumanFaction()
    local allHumanFactions = cm:get_human_factions();
    if allHumanFactions == nil then
        return allHumanFactions;
    end
    for key, humanFaction in pairs(allHumanFactions) do
        return cm:model():world():faction_by_key(humanFaction);
    end
end

function UnitRecruitmentPools:SetupFactionUnitPools(faction)
    local factionKey = faction:name();
    URP_Log("Setting up unit pools for faction: "..factionKey);
    -- Initialise tables
    if self.FactionUnitData[faction:subculture()] == nil then
        self.FactionUnitData[faction:subculture()] = {};
    end
    self.FactionUnitData[faction:subculture()][factionKey] = {};
    local factionData = self.FactionUnitData[faction:subculture()][factionKey];
    local factionUnitDefaultData = self:GetFactionUnitResources(faction);

    if factionUnitDefaultData == nil then
        return;
    end

    for unitKey, unitData in pairs(factionUnitDefaultData) do
        local unitCap = Random(unitData.StartingCap[2], unitData.StartingCap[1]);
        local availableAmount = Random(unitData.StartingAmount[2], unitData.StartingAmount[1]);
        local growthChance = Random(unitData.GrowthChance[2], unitData.GrowthChance[1]);
        if factionData[unitKey] == nil then
            URP_Log("Initialising unit "..unitKey.." UnitCap: "..unitCap.." AvailableAmount: "..availableAmount.." GrowthChance: "..growthChance);
            factionData[unitKey] = {
                UnitCap = unitCap,
                AvailableAmount = availableAmount,
                GrowthChance = growthChance,
            }
        else
            URP_Log("Unit: "..unitKey.." has already been initialised");
        end
    end

    self.FactionUnitData[faction:subculture()][factionKey] = factionData;
end

function UnitRecruitmentPools:GetFactionUnitResources(faction)
    local subcultureResources = _G.URPResources.UnitPoolResources[faction:subculture()][faction:subculture()];
    if subcultureResources == nil then
        return;
    end
    local factionResources = _G.URPResources.UnitPoolResources[faction:subculture()][faction:name()];
    if factionResources ~= nil then
        ConcatTableWithKeys(subcultureResources.Units, factionResources.Units);
    end
    return subcultureResources.Units;
end

function UnitRecruitmentPools:ModifyUnitCurrentPopForFaction(faction, unitKey, amount, overrideCap)
    local factionUnitData = self:GetFactionUnitData(faction);
    if factionUnitData[unitKey] == nil then
        URP_Log("Unit "..unitKey.." does not have any data...Initialising");
        factionUnitData[unitKey] = {
            UnitCap = 0,
            AvailableAmount = 0,
            GrowthChance = 0,
        }
    elseif factionUnitData[unitKey].AvailableAmount + amount <= 0 then
        URP_Log("Modifying AvailableAmount for unit "..unitKey.." would take value below 0 or 0. Setting to 0.");
        factionUnitData[unitKey].AvailableAmount = 0;
        URP_Log("Restricting unit "..unitKey.." for faction "..faction:name());
        cm:restrict_units_for_faction(faction:name(), unitKey, true);
    elseif factionUnitData[unitKey].AvailableAmount + amount > factionUnitData[unitKey].UnitCap and overrideCap ~= true then
        URP_Log("Can't set unit: "..unitKey.." above cap");
    else
        URP_Log("Changing AvailableAmount for unit "..unitKey.." from "..factionUnitData[unitKey].AvailableAmount.." to "..(factionUnitData[unitKey].AvailableAmount + amount));
        factionUnitData[unitKey].AvailableAmount = factionUnitData[unitKey].AvailableAmount + amount;
        cm:restrict_units_for_faction(faction:name(), unitKey, false);
    end
end

function UnitRecruitmentPools:GetFactionUnitData(faction)
    local factionKey = faction:name();
    local subcultureFactions = self.FactionUnitData[faction:subculture()];
    if subcultureFactions == nil then
        subcultureFactions = {};
    end
    local factionUnitData = subcultureFactions[factionKey];
    if factionUnitData == nil then
        self:SetupFactionUnitPools(faction);
    end
    return factionUnitData;
end

function UnitRecruitmentPools:RollUnitChances(faction)
    URP_Log("Rolling unit chances for faction: "..faction:name());
    local factionUnitData = self:GetFactionUnitData(faction);
    for unitKey, unitData in pairs(factionUnitData) do
        if Roll100(unitData.GrowthChance) then
            self:ModifyUnitCurrentPopForFaction(faction, unitKey, 1, false);
        end
    end
end