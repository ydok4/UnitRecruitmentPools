require 'script/_lib/pooldata/unitpooldata/EmpireUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/VampireCoastUnitPoolData'


URP_Log("Loading core data");
out("URP: Loading Core Data");

_G.URPResources = {
    BuildingPoolResources = {

    },
    UnitPoolResources = {
        -- Empire
        wh_main_sc_emp_empire = EmpireUnitPoolData,
        -- Vampire Coast
        wh2_dlc11_sc_cst_vampire_coast = VampireCoastUnitPoolData,
    },
}