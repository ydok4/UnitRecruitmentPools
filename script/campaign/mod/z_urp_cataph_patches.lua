require 'script/_lib/pooldata/buildingpooldata/CataphHoboBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CataphTEBBuildingPoolData'

require 'script/_lib/pooldata/unitpooldata/CataphHoboUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CataphTEBUnitPoolData'

out("URP: Loading Cataph Patches");
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_vmp_vampire_counts", CataphHoboBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_teb_teb", CataphTEBBuildingPoolData);

_G.URPResources.AddAdditionalUnitResources("wh_main_sc_vmp_vampire_counts", CataphHoboUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_teb_teb", CataphTEBUnitPoolData);
out("URP: Finished loading Cataph TEB Patch");