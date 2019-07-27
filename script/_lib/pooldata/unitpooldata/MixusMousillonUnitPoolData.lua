MixusMousillonUnitPoolData = {
    wh_main_sc_vmp_vampire_counts = {
		Units = {
			wh2_mixu_vmp_inf_bowmen = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 20,
				RequiredGrowthForReplenishment = 30,
			},
			wh2_mixu_vmp_inf_bowmen_fire = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 10,
				RequiredGrowthForReplenishment = 35,
			},
			wh2_mixu_vmp_inf_bowmen_poison = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 10,
				RequiredGrowthForReplenishment = 35,
			},
			wh2_mixu_vmp_inf_men_at_arms_sword = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 30,
				RequiredGrowthForReplenishment = 30,
			},
			wh2_mixu_vmp_inf_men_at_arms_polearms = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 20,
				RequiredGrowthForReplenishment = 35,
			},
			wh2_mixu_vmp_cav_mounted_yeomen = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 30,
				RequiredGrowthForReplenishment = 35,
			},
			wh2_mixu_vmp_art_trebuchet = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 20,
				RequiredGrowthForReplenishment = 40,
			},
			wh2_mixu_vmp_art_cursed_trebuchet = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 10,
				RequiredGrowthForReplenishment = 50,
			},
			wh2_mixu_vmp_inf_wailing_hags = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 20,
				RequiredGrowthForReplenishment = 50,
			},
			wh2_mixu_vmp_cav_knights_errant = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 20,
				RequiredGrowthForReplenishment = 35,
			},
			wh2_mixu_vmp_cav_knights_of_the_realm = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 10,
				RequiredGrowthForReplenishment = 50,
			},
			wh2_mixu_vmp_cav_questing_knights = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 10,
				RequiredGrowthForReplenishment = 50,
			},
			wh2_mixu_vmp_cav_black_knights_sword = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 30,
				RequiredGrowthForReplenishment = 35,
			},
			wh2_mixu_vmp_cav_black_knights_lance = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 20,
				RequiredGrowthForReplenishment = 35,
			},
			wh2_mixu_vmp_cav_black_grail_knights = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 10,
				RequiredGrowthForReplenishment = 50,
			},
			mixu_vmp_inf_crypt_ghouls = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 40,
				RequiredGrowthForReplenishment = 25,
			},
			mixu_vmp_inf_skeleton_warriors_0 = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 40,
				RequiredGrowthForReplenishment = 20,
			},
			mixu_vmp_inf_skeleton_warriors_1 = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 35,
				RequiredGrowthForReplenishment = 20,
			},
			mixu_vmp_inf_zombie = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 50,
				RequiredGrowthForReplenishment = 20,
			},
			mixu_vmp_mon_fell_bats = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 30,
				RequiredGrowthForReplenishment = 35,
			},
		},
	},

	-- Mousillon specific changes
	wh_main_vmp_mousillon = {
		Units = {
			mixu_vmp_inf_skeleton_warriors_0 = {
				StartingReserveCap = 1,
				StartingReserves = 100,
				UnitGrowth = 40,
				RequiredGrowthForReplenishment = 20,
			},
			mixu_vmp_inf_skeleton_warriors_1 = {
				StartingReserveCap = 0,
				StartingReserves = 0,
				UnitGrowth = 35,
				RequiredGrowthForReplenishment = 20,
			},
			mixu_vmp_inf_zombie = {
				StartingReserveCap = 2,
				StartingReserves = 200,
				UnitGrowth = 50,
				RequiredGrowthForReplenishment = 20,
			},
			mixu_vmp_mon_fell_bats = {
				StartingReserveCap = 1,
				StartingReserves = 0,
				UnitGrowth = 30,
				RequiredGrowthForReplenishment = 35,
			},
			wh2_mixu_vmp_inf_bowmen = {
				StartingReserveCap = 1,
				StartingReserves = 100,
				UnitGrowth = 20,
				RequiredGrowthForReplenishment = 30,
			},
			wh2_mixu_vmp_inf_men_at_arms_sword = {
				StartingReserveCap = 1,
				StartingReserves = 100,
				UnitGrowth = 30,
				RequiredGrowthForReplenishment = 30,
			},
			mixu_vmp_inf_crypt_ghouls = {
				StartingReserveCap = 1,
				StartingReserves = 100,
				UnitGrowth = 40,
				RequiredGrowthForReplenishment = 25,
			},
			wh_main_vmp_inf_zombie = {
				SharedData = {
					UnitKey = "mixu_vmp_inf_zombie",
					ShareCap = true,
					ShareReserves = true,
					ShareGrowth = true,
					ShareRequiredGrowthForReplenishment = true,
				},
			},
			wh_main_vmp_inf_skeleton_warriors_0 = {
				SharedData = {
					UnitKey = "mixu_vmp_inf_skeleton_warriors_0",
					ShareCap = true,
					ShareReserves = true,
					ShareGrowth = true,
					ShareRequiredGrowthForReplenishment = true,
				},
			},
			wh_main_vmp_inf_skeleton_warriors_1 = {
				SharedData = {
					UnitKey = "mixu_vmp_inf_skeleton_warriors_1",
					ShareCap = true,
					ShareReserves = true,
					ShareGrowth = true,
					ShareRequiredGrowthForReplenishment = true,
				},
			},
			wh_main_vmp_inf_crypt_ghouls = {
				SharedData = {
					UnitKey = "mixu_vmp_inf_crypt_ghouls",
					ShareCap = true,
					ShareReserves = true,
					ShareGrowth = true,
					ShareRequiredGrowthForReplenishment = true,
				},
			},
			wh_main_vmp_mon_fell_bats = {
				SharedData = {
					UnitKey = "mixu_vmp_mon_fell_bats",
					ShareCap = true,
					ShareReserves = true,
					ShareGrowth = true,
					ShareRequiredGrowthForReplenishment = true,
				},
			},
		},
	},
}