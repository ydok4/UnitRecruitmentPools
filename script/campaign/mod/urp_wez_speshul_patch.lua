require 'script/_lib/pooldata/buildingpooldata/WezSpeshulGreenskinBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/WezSpeshulSavageOrcBuildingPoolData'

require 'script/_lib/pooldata/unitpooldata/WezSpeshulGreenskinUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/WezSpeshulSavageOrcUnitPoolData'

out("URP: Loading Wez Speshul Patch");
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_grn_greenskins", WezSpeshulGreenskinBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_grn_savage_orcs", WezSpeshulSavageOrcBuildingPoolData);

_G.URPResources.AddAdditionalUnitResources("wh_main_sc_grn_greenskins", WezSpeshulGreenskinUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_grn_savage_orcs", WezSpeshulSavageOrcUnitPoolData);
out("URP: Finished loading Wez Speshul Patch");