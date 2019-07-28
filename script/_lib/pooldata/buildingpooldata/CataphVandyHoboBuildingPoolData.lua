CataphVandyHoboBuildingPoolData = {
	wh2_dlc11_vmp_the_barrow_legion = {
		-- Note: This isn't a real building in the db
		-- Because there are multiple kemmlers due to
		-- the wounding mechanic we need a weaker effect
		-- for Kemmler
		AK_hobo_main_5_kemmler = {
			Units = {
				AK_hobo_skeleton_swords = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "10",
				},
				AK_hobo_skeleton_spears = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "10",
				},
			},
		},
		AK_hobo_main_5 = {
			Units = {
				AK_hobo_skeleton_swords = {
					UnitReserveCapChange = "2",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "20",
				},
				AK_hobo_skeleton_spears = {
					UnitReserveCapChange = "2",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "20",
				},
			},
		},
		AK_hobo_recr1_1 = {
			Units = {
				AK_hobo_skeleton_2h = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "40",
					UnitGrowthChange = "10",
				},
				AK_hobo_skeleton_lobber = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "30",
					UnitGrowthChange = "10",
				},
			},
		},
		AK_hobo_recr1_2 = {
			Units = {
				AK_hobo_skeleton_2h = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
				AK_hobo_skeleton_lobber = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
				AK_hobo_embalmed = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "30",
					UnitGrowthChange = "10",
				},
				AK_hobo_horsemen = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "30",
					UnitGrowthChange = "10",
				},
				AK_hobo_horsemen_lances = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "30",
					UnitGrowthChange = "10",
				},
			},
			PreviousBuilding = "AK_hobo_recr1_1",
		},
		AK_hobo_recr1_3 = {
			Units = {
				AK_hobo_skeleton_2h = {
					UnitReserveCapChange = "0",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
					},
				AK_hobo_skeleton_lobber = {
					UnitReserveCapChange = "0",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
				AK_hobo_embalmed = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "0",
				},
				AK_hobo_horsemen = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "0",
				},
				AK_hobo_horsemen_lances = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "0",
				},
				AK_hobo_barrow_guardians = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "30",
					UnitGrowthChange = "10",
				},
				AK_hobo_barrow_guardians_halb = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "30",
					UnitGrowthChange = "25",
				},
			},
			PreviousBuilding = "AK_hobo_recr1_2",
		},
		AK_hobo_recr2_1 = {
			Units = {
				AK_hobo_glooms = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "40",
					UnitGrowthChange = "10",
				},
			},
		},
		AK_hobo_recr2_2 = {
			Units = {
				AK_hobo_glooms = {
					UnitReserveCapChange = "0",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
				AK_hobo_ghost = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "40",
					UnitGrowthChange = "10",
				},
			},
			PreviousBuilding = "AK_hobo_recr2_1",
		},
		AK_hobo_recr2_3 = {
			Units = {
				AK_hobo_glooms = {
					UnitReserveCapChange = "0",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
				AK_hobo_ghost = {
					UnitReserveCapChange = "0",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
				wh_main_vmp_inf_cairn_wraiths = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "30",
					UnitGrowthChange = "10",
					ApplyToUnit = "AK_hobo_cairn",
				},
			},
			PreviousBuilding = "AK_hobo_recr2_2",
		},
		AK_hobo_recr2_4 = {
			Units = {
				AK_hobo_ghost = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "50",
					UnitGrowthChange = "5",
				},
				wh_main_vmp_cav_hexwraiths = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "30",
					UnitGrowthChange = "10",
					ApplyToUnit = "AK_hobo_hexwr",
				},
				wh_dlc04_vmp_veh_mortis_engine_0 = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "20",
					UnitGrowthChange = "10",
					ApplyToUnit = "AK_hobo_mortis_engine",
				},
			},
			PreviousBuilding = "AK_hobo_recr2_3",
		},
		AK_hobo_anim_1 = {
			Units = {
				AK_hobo_stalker = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "30",
					UnitGrowthChange = "10",
				},
			},
		},
		AK_hobo_anim_2 = {
			Units = {
				AK_hobo_stalker = {
					UnitReserveCapChange = "0",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
				AK_hobo_simulacra = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "20",
					UnitGrowthChange = "10",
				},
			},
			PreviousBuilding = "AK_hobo_anim_1",
		},
		AK_hobo_anim_3 = {
			Units = {
				AK_hobo_simulacra = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "0",
				},
				AK_hobo_stalker = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "0",
					UnitGrowthChange = "5",
				},
				AK_hobo_dragon = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "20",
					UnitGrowthChange = "10",
				},
				wh_main_vmp_mon_terrorgheist = {
					UnitReserveCapChange = "1",
					ImmediateUnitReservesChange = "20",
					UnitGrowthChange = "10",
					ApplyToUnit = "AK_hobo_terrorgheist",
				},
			},
			PreviousBuilding = "AK_hobo_anim_2",
		},
	},
}