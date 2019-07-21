require 'script/_lib/pooldata/buildingpooldata/MixuEmpireBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/MixuChaosBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/MixusMousillonBuildingPoolData'

require 'script/_lib/pooldata/characterpooldata/MixuChaosCharacterPoolData'
require 'script/_lib/pooldata/characterpooldata/MixuEmpireCharacterPoolData'

require 'script/_lib/pooldata/unitpooldata/MixuEmpireUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/MixusMousillonUnitPoolData'

out("URP: Loading Mixu Patches");
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_chs_chaos", MixuChaosBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_emp_empire", MixuEmpireBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_vmp_vampire_counts", MixusMousillonBuildingPoolData);

_G.URPResources.AddAdditionalCharacterResources("wh_main_sc_chs_chaos", MixuChaosCharacterPoolData);
_G.URPResources.AddAdditionalCharacterResources("wh_main_sc_emp_empire", MixuEmpireCharacterPoolData);

_G.URPResources.AddAdditionalUnitResources("wh_main_sc_emp_empire", MixuEmpireUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_vmp_vampire_counts", MixusMousillonUnitPoolData);
out("URP: Finished loading Mixu Patches");