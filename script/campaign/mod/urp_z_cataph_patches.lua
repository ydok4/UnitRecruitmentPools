require 'script/_lib/pooldata/buildingpooldata/CataphVandyHoboBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CataphKrakaDrakBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CataphSeaHelmBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CataphTEBBuildingPoolData'

require 'script/_lib/pooldata/characterpooldata/CataphSeaHelmCharacterPoolData'

require 'script/_lib/pooldata/unitpooldata/CataphVandyHoboUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CataphKrakaDrakUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CataphSeaHelmsUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CataphTEBUnitPoolData'

out("URP: Loading Cataph Patches");
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_vmp_vampire_counts", CataphVandyHoboBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_dwf_dwarfs", CataphKrakaDrakBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh2_main_sc_hef_high_elves", CataphSeaHelmBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_teb_teb", CataphTEBBuildingPoolData);

_G.URPResources.AddAdditionalCharacterResources("wh2_main_sc_hef_high_elves", CataphSeaHelmCharacterPoolData);

_G.URPResources.AddAdditionalUnitResources("wh_main_sc_vmp_vampire_counts", CataphVandyHoboUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_dwf_dwarfs", CataphKrakaDrakUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh2_main_sc_hef_high_elves", CataphSeaHelmsUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_teb_teb", CataphTEBUnitPoolData);
out("URP: Finished loading Cataph Patches");