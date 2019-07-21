require 'script/_lib/pooldata/buildingpooldata/ColinWoodElfEnchantedArrowExpansionBuildingPoolData'

require 'script/_lib/pooldata/unitpooldata/ColinWoodElfEnchantedArrowExpansionUnitPoolData'

out("URP: Loading Wood Elf Enchanted Arrow Patch");
_G.URPResources.AddAdditionalBuildingPoolResources("wh_dlc05_sc_wef_wood_elves", ColinWoodElfEnchantedArrowExpansionBuildingPoolData);

_G.URPResources.AddAdditionalUnitResources("wh_dlc05_sc_wef_wood_elves", ColinWoodElfEnchantedArrowExpansionUnitPoolData);
out("URP: Finished loading Wood Elf Enchanted Arrow Patch");