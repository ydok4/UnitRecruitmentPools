CTTEmpireBuildingPoolData = {
	wh_main_sc_emp_empire = {
		wh_main_emp_barracks_1 = {
			Units = {
				CTT_emp_archers = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "10",
				},
				wh_main_emp_inf_halberdiers = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "10",
				},
				wh_main_emp_inf_swordsmen = false,
			},
		},
		wh_main_emp_barracks_2 = {
			Units = {
				wh_main_emp_inf_halberdiers = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "10",
				},
				wh_main_emp_inf_swordsmen = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "30",
					UnitGrowthChange = "5",
				},
			},
			PreviousBuilding = "wh_main_emp_barracks_1",
		},
		wh_main_emp_barracks_3 = {
			Units = {
				wh_main_emp_inf_halberdiers = false,
				wh_main_emp_inf_swordsmen = {
					UnitReserveCapChange = "0",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
			},
			PreviousBuilding = "wh_main_emp_barracks_2",
		},
		wh_main_emp_resource_timber_2 = {
			Units = {
				CTT_emp_huntsmen = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "5",
				},
			},
		},
		wh_main_emp_resource_timber_3 = {
			Units = {
				CTT_emp_huntsmen = {
					UnitReserveCapChange = "0",
					UnitGrowthChange = "5",
				},
			},
			PreviousBuilding = "wh_main_emp_resource_timber_2",
		},
		wh_main_emp_resource_furs_2 = {
			Units = {
				CTT_emp_huntsmen = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "5",
				},
			},
		},
		wh_main_emp_resource_furs_3 = {
			Units = {
				CTT_emp_huntsmen = {
					UnitReserveCapChange = "0",
					UnitGrowthChange = "5",
				},
			},
			PreviousBuilding = "wh_main_emp_resource_timber_2",
		},
		wh_main_special_great_temple_of_ulric = {
			Units = {
				CTT_emp_whitewolf = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "20",
					UnitGrowthChange = "10",
				},
				CTT_emp_teutogen = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "20",
					UnitGrowthChange = "10",
				},
			},
		},
		wh_main_middenheim_worship_1 = {
			Units = {
				CTT_emp_whitewolf = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "20",
					UnitGrowthChange = "5",
				},
				CTT_emp_teutogen = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "20",
					UnitGrowthChange = "5",
				},
			},
		},
		wh_main_middenheim_worship_2 = {
			Units = {
				CTT_emp_whitewolf = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
				CTT_emp_teutogen = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
			},
			PreviousBuilding = "wh_main_middenheim_worship_1",
		},
		wh_main_emp_smiths_2 = {
			Units = {
				CTT_emp_spearmen_reg = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "20",
				},
				CTT_emp_halberdiers_reg = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "20",
				},
				CTT_emp_swordsmen_reg = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "20",
				},
				CTT_emp_crossbowmen_reg = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "20",
				},
				CTT_emp_handgunners_reg = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "20",
				},
				CTT_emp_archers_horde = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "20",
				},
			},
		},
		wh_main_emp_worship_3 = {
			Units = {
				CTT_emp_flagellants = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "20",
				},
			},
			PreviousBuilding = "wh_main_emp_worship_2",
		},
		wh2_main_special_altdorf_castle_reikguard = {
			Units = {
				CTT_emp_reiksfoot = {
					UnitReserveCapChange = "2",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "35",
				},
			},
		},
		wh_main_special_reiksfort = {
			Units = {
				CTT_emp_reiksfoot = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "10",
				},
			},
		},
	},
}