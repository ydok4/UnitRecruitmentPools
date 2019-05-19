-- Building resources
require 'script/_lib/pooldata/buildingpooldata/EmpireBuildingPoolData'

-- Unit resources
require 'script/_lib/pooldata/unitpooldata/BeastmenUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/BretonniaUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/ChaosUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/DarkElfUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/DwarfUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/EmpireUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/GreenskinUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/HighElfUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/LizardmenUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/NorscaUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/SavageOrcUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/SkavenUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/TombKingUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/VampireCoastUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/VampireCountsUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/WoodElfUnitPoolData'

URP_Log("Loading core data");
out("URP: Loading Core Data");

_G.URPResources = {
    BuildingPoolResources = {
        -- Empire
        wh_main_sc_emp_empire = EmpireBuildingPoolData,
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
        -- Lizardmen
        wh2_main_sc_lzd_lizardmen = LizardmenUnitPoolData,
        -- Norsca
        wh_main_sc_nor_norsca = NorscaUnitPoolData,
        -- Savage Orc
        wh_main_sc_grn_savage_orcs = SavageOrcUnitPoolData,
        -- Tomb Kings
        wh2_dlc09_sc_tmb_tomb_kings = TombKingUnitPoolData,
        -- Vampire Coast
        wh2_dlc11_sc_cst_vampire_coast = VampireCoastUnitPoolData,
        -- Vampire Counts
        wh_main_sc_vmp_vampire_counts = VampireCountsUnitPoolData,
        -- Wood Elf
        wh_dlc05_sc_wef_wood_elves = WoodElfUnitPoolData,
    },
}