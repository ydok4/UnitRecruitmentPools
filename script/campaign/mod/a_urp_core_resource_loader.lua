-- Building resources
require 'script/_lib/pooldata/buildingpooldata/BeastmenBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/BretonniaBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/ChaosBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/DarkElfBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/DwarfBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/EmpireBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/GreenskinBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/HighElfBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/KislevBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/LizardmenBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/NorscaBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/SavageOrcBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/SkavenBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/TEBBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/TombKingsBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/VampireCoastBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/VampireCountsBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/WoodElfBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/RogueArmyBuildingPoolData'

-- Character resources
require 'script/_lib/pooldata/characterpooldata/BeastmenCharacterPoolData'
require 'script/_lib/pooldata/characterpooldata/ChaosCharacterPoolData'
require 'script/_lib/pooldata/characterpooldata/DarkElfCharacterPoolData'
require 'script/_lib/pooldata/characterpooldata/MixuEmpireCharacterPoolData'

-- Unit resources
require 'script/_lib/pooldata/unitpooldata/BeastmenUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/BretonniaUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/ChaosUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/DarkElfUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/DwarfUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/EmpireUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/GreenskinUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/HighElfUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/KislevUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/LizardmenUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/NorscaUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/SavageOrcUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/SkavenUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/TEBUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/TombKingUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/VampireCoastUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/VampireCountsUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/WoodElfUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/RogueArmyUnitPoolData'

out("URP: Loading Core Data");

_G.URPResources = {
    BuildingPoolResources = {
        -- Beastmen
        wh_dlc03_sc_bst_beastmen = BeastmenBuildingPoolData,
        -- Bretonnia
        wh_main_sc_brt_bretonnia = BretonniaBuildingPoolData,
        -- Chaos
        wh_main_sc_chs_chaos = ChaosBuildingPoolData,
        -- Dark Elves
        wh2_main_sc_def_dark_elves = DarkElfBuildingPoolData,
        -- Dwarfs
        wh_main_sc_dwf_dwarfs = DwarfBuildingPoolData,
        -- Empire
        wh_main_sc_emp_empire = EmpireBuildingPoolData,
        -- Greenskin
        wh_main_sc_grn_greenskins = GreenskinBuildingPoolData,
        -- High Elves
        wh2_main_sc_hef_high_elves = HighElfBuildingPoolData,
        -- Kislev
        wh_main_sc_ksl_kislev = KislevBuildingPoolData,
        -- Lizardmen
        wh2_main_sc_lzd_lizardmen = LizardmenBuildingPoolData,
        -- Norsca
        wh_main_sc_nor_norsca = NorscaBuildingPoolData,
        -- Savage Orc
        wh_main_sc_grn_savage_orcs = SavageOrcBuildingPoolData,
        -- Skaven
        wh2_main_sc_skv_skaven = SkavenBuildingPoolData,
        -- TEB
        wh_main_sc_teb_teb = TEBBuildingPoolData,
        -- Tomb Kings
        wh2_dlc09_sc_tmb_tomb_kings = TombKingsBuildingPoolData,
        -- Vampire Coast
        wh2_dlc11_sc_cst_vampire_coast = VampireCoastBuildingPoolData,
        -- Vampire Counts
        wh_main_sc_vmp_vampire_counts = VampireCountsBuildingPoolData,
        -- Wood Elf
        wh_dlc05_sc_wef_wood_elves = WoodElfBuildingPoolData,

        -- Rogue Armies
        wh_rogue_armies = RogueArmyBuildingPoolData,
    },
    CharacterPoolResources = {
        -- Beastmen
        wh_dlc03_sc_bst_beastmen = BeastmenCharacterPoolData,
        -- Chaos
        wh_main_sc_chs_chaos = ChaosCharacterPoolData,
        -- Dark Elves
        wh2_main_sc_def_dark_elves = DarkElfCharacterPoolData,
        -- Empire
        wh_main_sc_emp_empire = MixuEmpireCharacterPoolData,
    },
    UnitPoolResources = {
        -- Beastmen
        wh_dlc03_sc_bst_beastmen = BeastmenUnitPoolData,
        -- Bretonnia
        wh_main_sc_brt_bretonnia = BretonniaUnitPoolData,
        -- Chaos
        wh_main_sc_chs_chaos = ChaosUnitPoolData,
        -- Dark Elves
        wh2_main_sc_def_dark_elves = DarkElfUnitPoolData,
        -- Dwarfs
        wh_main_sc_dwf_dwarfs = DwarfUnitPoolData,
        -- Empire
        wh_main_sc_emp_empire = EmpireUnitPoolData,
        -- Greenskin
        wh_main_sc_grn_greenskins = GreenskinUnitPoolData,
        -- High Elves
        wh2_main_sc_hef_high_elves = HighElfUnitPoolData,
        -- Kislev
        wh_main_sc_ksl_kislev = KislevUnitPoolData,
        -- Lizardmen
        wh2_main_sc_lzd_lizardmen = LizardmenUnitPoolData,
        -- Norsca
        wh_main_sc_nor_norsca = NorscaUnitPoolData,
        -- Savage Orc
        wh_main_sc_grn_savage_orcs = SavageOrcUnitPoolData,
        -- Skaven
        wh2_main_sc_skv_skaven = SkavenUnitPoolData,
        -- TEB
        wh_main_sc_teb_teb = TEBUnitPoolData,
        -- Tomb Kings
        wh2_dlc09_sc_tmb_tomb_kings = TombKingUnitPoolData,
        -- Vampire Coast
        wh2_dlc11_sc_cst_vampire_coast = VampireCoastUnitPoolData,
        -- Vampire Counts
        wh_main_sc_vmp_vampire_counts = VampireCountsUnitPoolData,
        -- Wood Elf
        wh_dlc05_sc_wef_wood_elves = WoodElfUnitPoolData,

        -- Rogue Armies
        wh_rogue_armies = RogueArmyUnitPoolData,
    },
    AddAdditionalBuildingPoolResources = function(subculture, data)
        local cultureResources = _G.URPResources.BuildingPoolResources[subculture];
        for factionOrSubcultureKey, factionOrSubcultureData in pairs(data) do
            if cultureResources[factionOrSubcultureKey] == nil then
                cultureResources[factionOrSubcultureKey] = {
                }
            end
            local factionOrSubcultureResources = cultureResources[factionOrSubcultureKey];
            for buildingKey, buildingData in pairs(factionOrSubcultureData) do
                if factionOrSubcultureResources[buildingKey] == nil then
                    factionOrSubcultureResources[buildingKey] = buildingData;
                elseif buildingData == false then
                    factionOrSubcultureResources[buildingKey] = nil;
                else
                    for unitKey, unitData in pairs(buildingData.Units) do
                        if not unitData then
                            factionOrSubcultureResources[buildingKey].Units[unitKey] = nil;
                        else
                            if factionOrSubcultureResources[buildingKey].Units[unitKey] == nil then
                                factionOrSubcultureResources[buildingKey].Units[unitKey] = {};
                            end
                            if unitData.UnitReserveCapChange ~= nil then
                                factionOrSubcultureResources[buildingKey].Units[unitKey].UnitReserveCapChange = unitData.UnitReserveCapChange;
                            end
                            if unitData.ImmediateUnitReservesChange ~= nil then
                                factionOrSubcultureResources[buildingKey].Units[unitKey].ImmediateUnitReservesChange = unitData.ImmediateUnitReservesChange;
                            end
                            if unitData.UnitGrowthChange ~= nil then
                                factionOrSubcultureResources[buildingKey].Units[unitKey].UnitGrowthChange = unitData.UnitGrowthChange;
                            end
                            if unitData.ApplyToUnit ~= nil then
                                factionOrSubcultureResources[buildingKey].Units[unitKey].ApplyToUnit = unitData.ApplyToUnit;
                            end
                        end
                    end
                end
            end
        end
    end,
    AddAdditionalCharacterResources = function(subculture, data)
        local cultureResources = _G.URPResources.CharacterPoolResources[subculture];
        if cultureResources == nil then
            _G.URPResources.CharacterPoolResources[subculture] = {};
            cultureResources = _G.URPResources.CharacterPoolResources[subculture];
        end
        for agentSubTypeKey, agentSubTypeData in pairs(data) do
            if cultureResources[agentSubTypeKey] == nil then
                cultureResources[agentSubTypeKey] = {};
            end
            if agentSubTypeData.Units ~= nil then
                cultureResources[agentSubTypeKey].Units = agentSubTypeData.Units;
            end
            if agentSubTypeData.Buildings ~= nil then
                cultureResources[agentSubTypeKey].Buildings = agentSubTypeData.Buildings;
            end
        end
    end,
    AddAdditionalUnitResources = function(subculture, data)
        local cultureResources = _G.URPResources.UnitPoolResources[subculture];
        for factionOrSubcultureKey, factionOrSubcultureData in pairs(data) do
            if cultureResources[factionOrSubcultureKey] == nil then
                cultureResources[factionOrSubcultureKey] = {
                    Units = {},
                }
            end
            local factionOrSubcultureResources = cultureResources[factionOrSubcultureKey].Units;
            for unitKey, unitData in pairs(factionOrSubcultureData.Units) do
                if factionOrSubcultureResources[unitKey] == nil then
                    factionOrSubcultureResources[unitKey] = unitData;
                elseif data[unitKey] == false then
                    factionOrSubcultureResources[unitKey] = nil;
                else
                    if unitData.StartingReserveCap ~= nil then
                        factionOrSubcultureResources[unitKey].StartingReserveCap = unitData.StartingReserveCap;
                    end
                    if unitData.StartingReserves ~= nil then
                        factionOrSubcultureResources[unitKey].StartingReserves = unitData.StartingReserves;
                    end
                    if unitData.UnitGrowth ~= nil then
                        factionOrSubcultureResources[unitKey].UnitGrowth = unitData.UnitGrowth;
                    end
                    if unitData.RequiredGrowthForReplenishment ~= nil then
                        factionOrSubcultureResources[unitKey].RequiredGrowthForReplenishment = unitData.RequiredGrowthForReplenishment;
                    end
                end
            end
        end
    end,
}