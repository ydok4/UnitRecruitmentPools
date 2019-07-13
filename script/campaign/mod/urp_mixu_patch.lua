require 'script/_lib/pooldata/buildingpooldata/MixuEmpireBuildingPoolData'

require 'script/_lib/pooldata/unitpooldata/MixuEmpireUnitPoolData'

out("URP: Loading Mixu Patch");
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_emp_empire", MixuEmpireBuildingPoolData);

_G.URPResources.AddAdditionalUnitResources("wh_main_sc_emp_empire", MixuEmpireUnitPoolData);
out("URP: Finished loading Mixu Patch");