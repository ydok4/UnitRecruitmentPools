urp = {};
_G.urp = urp;

-- Helpers
require 'script/_lib/core/helpers/urp_datahelpers';
require 'script/_lib/core/helpers/urp_loadhelpers';
require 'script/_lib/core/helpers/urp_savehelpers';
-- Models
require 'script/_lib/core/model/UnitRecruitmentPools';
require 'script/_lib/core/model/RecruitmentUIManager';
require 'script/_lib/core/model/RecruitmentManager';
require 'script/_lib/core/model/UnitReplenishmentUIManager';
-- Listeners
require 'script/_lib/core/listeners/urp_listeners';

URP_Log_Start();

function z_unit_recruitment_pools()
    out("URP: Main mod function");
    URP_Log("Main mod function");

    urp = UnitRecruitmentPools:new({
        urpui = {},
        FactionUnitData = urp.FactionUnitData,
        FactionBuildingData = urp.FactionBuildingData,
        CharacterBuildingData = urp.CharacterBuildingData,
    });

    if cm:is_new_game() then
        URP_Log("New Game");
        urp:Initialise();
        -- This callback is required so that startup happens after
        -- the game spawns any startup armies. This allows them to be replaced if required.
        cm:callback(function() urp:NewGameStartUp(); end, 1);
    else
        URP_Log("Existing game");
        urp:Initialise();
    end

    -- Check if RecruitmentManager already exists or not
    if not _G.RM then
        _G.RM = RecruitmentManager:new({
            EnableLogging = false,
        });
        _G.RM:Initialise(core);
        cm:callback(function() _G.RM:UpdateCacheWithFactionCharacterForceData(urp.HumanFaction); end, 0);
    end
    _G.RM:RegisterRecruitmentCallback("URP RM callback", function(context)
        if context.ListenerContext == "RM_FactionTurnStart"
        and cm:turn_number() > 1
        and context.Faction:name() ~= "rebels" then
            urp:ApplyFactionBuildingUnitPoolModifiers(context.Faction);
            urp:UpdateDiplomacyUnitPools(context.Faction);
        end
        if context.ListenerContext ~= "URP_CharacterKilled" then
            cm:callback(function() urp:UpdateEffectBundles(context); end, 0);
        end
    end);

    -- Check if RecruitmentUIManager already exists or not
    if not _G.RMUI then
        _G.RMUI = RecruitmentUIManager:new({
            EnableLogging = false,
        });
        _G.RMUI:SetupPostUIListeners(core);
    end
    -- This registers our functions with the Recruitment UI manager
    _G.RMUI:RegisterUIEventCallback("URP UI Event callback", function(context) urp:UIEventCallback(context); end);
    _G.RMUI:RegisterRefreshUICallback("URP UI callback", function(context) urp:RefreshUICallback(context); end);


    -- Unit replenishment UI manager
    _G.UIPM = UnitReplenishmentUIManager:new({
        EnableLogging = false,
    });
    _G.RMUI:RegisterRefreshUICallback("UIPM UI callback", function(context) _G.UIPM:RMUIWrapper(context); end);
    -- This is wrapped in a callback so it will run after all the patches have started
    _G.UIPM:SetupPostUIListeners(core, urp);
    URP_SetupPostUIListeners(urp);
    URP_Log("Finished");
    out("URP: Finished startup");
    URP_Log_Finished();
end

-- Saving/Loading Callbacks
cm:add_saving_game_callback(
    function(context)
        URP_Log_Finished();
        URP_Log("Saving callback");
        out("URP: Saving callback");
        URP_InitialiseSaveHelper(cm, context);
        URP_SaveUnitPools(urp);
        URP_SaveFactionBuildingPools(urp);
        URP_SaveCharacterBuildingPools(urp);
        URP_Log_Finished();
    end
);

cm:add_loading_game_callback(
    function(context)
        out("URP: Loading callback");
        URP_InitialiseLoadHelper(cm, context);
        URP_LoadUnitPools(urp);
        URP_LoadFactionBuildingPools(urp);
        URP_LoadCharacterBuildingPools(urp);
        out("URP: Finished loading");
	end
);