require 'script/_lib/pooldata/buildingpooldata/CTTBeastmenBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTBretonniaBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTChaosBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTDarkElfBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTEmpireBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTLizardmenBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTGreenskinBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTHighElfBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTHoboBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTNorscaBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTSavageOrcBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTSkavenBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTTEBBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTTombKingsBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTVampireCountsBuildingPoolData'
require 'script/_lib/pooldata/buildingpooldata/CTTWoodElfBuildingPoolData'

require 'script/_lib/pooldata/unitpooldata/CTTBeastmenUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTBretonniaUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTChaosUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTEmpireUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTLizardmenUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTGreenskinUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTHoboUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTNorscaUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTSavageOrcUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTSkavenUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTTEBUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTTombKingUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTVampireCountsUnitPoolData'
require 'script/_lib/pooldata/unitpooldata/CTTWoodElfUnitPoolData'


out("URP: Loading CTT Patch");
_G.URPResources.AddAdditionalBuildingPoolResources("wh_dlc03_sc_bst_beastmen", CTTBeastmenBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_brt_bretonnia", CTTBretonniaBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_chs_chaos", CTTChaosBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh2_main_sc_def_dark_elves", CTTDarkElfBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_emp_empire", CTTEmpireBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh2_main_sc_lzd_lizardmen", CTTLizardmenBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_grn_greenskins", CTTGreenskinBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh2_main_sc_hef_high_elves", CTTHighElfBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_vmp_vampire_counts", CTTHoboBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_nor_norsca", CTTNorscaBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_grn_savage_orcs", CTTSavageOrcBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh2_main_sc_skv_skaven", CTTSkavenBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_teb_teb", CTTTEBBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh2_dlc09_sc_tmb_tomb_kings", CTTTombKingsBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_main_sc_vmp_vampire_counts", CTTVampireCountsBuildingPoolData);
_G.URPResources.AddAdditionalBuildingPoolResources("wh_dlc05_sc_wef_wood_elves", CTTWoodElfBuildingPoolData);


_G.URPResources.AddAdditionalUnitResources("wh_dlc03_sc_bst_beastmen", CTTBeastmenUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_brt_bretonnia", CTTBretonniaUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_chs_chaos", CTTChaosUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_emp_empire", CTTEmpireUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh2_main_sc_lzd_lizardmen", CTTLizardmenUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_grn_greenskins", CTTGreenskinUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_vmp_vampire_counts", CTTHoboUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_nor_norsca", CTTNorscaUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_grn_savage_orcs", CTTSavageOrcUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh2_main_sc_skv_skaven", CTTSkavenUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_teb_teb", CTTTEBUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh2_dlc09_sc_tmb_tomb_kings", CTTTombKingUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_main_sc_vmp_vampire_counts", CTTVampireCountsUnitPoolData);
_G.URPResources.AddAdditionalUnitResources("wh_dlc05_sc_wef_wood_elves", CTTWoodElfUnitPoolData);

out("URP: Finished loading CTT Patch");