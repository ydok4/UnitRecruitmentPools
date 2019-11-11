EmpireDiplomacyUnitPoolData = {
    nobility = {
        Regions = {
            main_warhammer = {
                -- The Wasteland
                "wh_main_the_wasteland_marienburg",
                "wh_main_the_wasteland_gorssel",
                "wh_main_the_wasteland_aarnau",
                -- Reikland
                "wh_main_reikland_altdorf",
                "wh_main_reikland_grunburg",
                "wh_main_riv_reik",
                "wh_main_reikland_eilhart",
                -- Nordland
                "wh_main_nordland_salzenmund",
                "wh_main_nordland_dietershafen",
                -- Middenland
                "wh_main_middenland_middenheim",
                "wh_main_middenland_carroburg",
                "wh_main_middenland_middenstag",
                "wh_main_middenland_weismund",
                -- Hochland
                "wh_main_hochland_hergig",
                "wh_main_hochland_brass_keep",
                -- Ostland
                "wh_main_ostland_castle_von_rauken",
                "wh_main_ostland_norden",
                "wh_main_ostland_wolfenburg",
                -- Talabecland
                "wh_main_talabecland_talabheim",
                "wh_main_talabecland_krugenheim",
                "wh_main_talabecland_kemperbad",
                "wh_main_talabecland_kappelburg",
                -- Ostermark
                "wh_main_ostermark_bechafen",
                "wh_main_ostermark_essen",
                "wh_main_ostermark_mordheim",
                "wh_main_ostermark_nagenhof",
                -- Eastern Sylvania
                "wh_main_eastern_sylvania_castle_drakenhof",
                "wh_main_eastern_sylvania_eschen",
                "wh_main_eastern_sylvania_waldenhof",
                -- Western Sylvania
                "wh_main_western_sylvania_castle_templehof",
                "wh_main_western_sylvania_fort_oberstyre",
                "wh_main_western_sylvania_schwartzhafen",
                -- The Moot
                "wh_main_stirland_the_moot",
                -- Averland
                "wh_main_averland_averheim",
                "wh_main_averland_grenzstadt",
                -- Solland
                "wh2_main_solland_pfeildorf",
                "wh2_main_solland_steingart",
                -- Wissenland
                "wh_main_wissenland_nuln",
                "wh_main_wissenland_pfeildorf",
                "wh_main_wissenland_wissenburg",
                -- Stirland
                "wh_main_stirland_wurtbad",
                "wh_main_stirland_flensburg",
                "wh_main_stirland_niedling",
            },
            wh2_main_great_vortex = {

            },
        },
        Factions = nil,
        Units = {
            wh_main_emp_cav_pistoliers_1 = {
                RequiredTreaty = "NonAggressionPact",
                ExcludedFactions = {},
            },
            wh_main_emp_cav_empire_knights = {
                RequiredTreaty = "TradeAgreement",
                ExcludedFactions = {},
            },
            wh_main_emp_inf_greatswords = {
                RequiredTreaty = "DefensiveAlliance",
                ExcludedFactions = {},
            },
            wh_main_emp_cav_demigryph_knights_0 = {
                RequiredTreaty = "MilitaryAlliance",
                ExcludedFactions = {},
            },
            wh_main_emp_cav_demigryph_knights_1 = {
                RequiredTreaty = "MilitaryAlliance",
                ExcludedFactions = {},
            },
        },
    },

    reikland_reiksguard = {
        Regions = {
        },
        Factions = {
            "wh_main_emp_empire",
        },
        Units = {
            wh_main_emp_cav_reiksguard = {
                RequiredTreaty = "DefensiveAlliance",
            },
        },
    },

    --[[wh2_dlc13_emp_golden_order = {

    },

    wh2_dlc13_emp_the_huntmarshals_expedition = {

    },

    wh_main_emp_middenland = {

    },--]]

    talabecland_knights = {
        Regions = {
            main_warhammer = {
                "wh_main_talabecland_talabheim",
            },
        },
        Factions = {
            "wh_main_emp_talabecland",
        },
        Units = {
            wh_dlc04_emp_cav_knights_blazing_sun_0 = {
                RequiredTreaty = "TradeAgreement",
            },
        },
    },

    wissenland_artillery = {
        Regions = {
            main_warhammer = {
                "wh_main_wissenland_nuln",
            },
        },
        Factions = {
            "wh_main_emp_wissenland",
        },
        Units = {
            wh_main_emp_art_mortar = {
                RequiredTreaty = "TradeAgreement",
            },
            wh_main_emp_art_great_cannon = {
                RequiredTreaty = "DefensiveAlliance",
            },
            wh_main_emp_art_helblaster_volley_gun = {
                RequiredTreaty = "DefensiveAlliance",
            },
            wh_main_emp_veh_steam_tank = {
                RequiredTreaty = "MilitaryAlliance",
            },
        },
    },
}