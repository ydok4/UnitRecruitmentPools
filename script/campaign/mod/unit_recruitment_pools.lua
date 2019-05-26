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
-- Loaders
require 'script/_lib/core/loaders/urp_resource_loader';
-- Listeners
require 'script/_lib/core/listeners/urp_listeners';

URP_Log_Start();

function unit_recruitment_pools()
    URP_Log_Finished();
    out("URP: Main mod function");
    URP_Log("Main mod function");
    -- Check if RecruimentManager already exists or not
    if not _G.RM then
        _G.RM = RecruitmentManager:new({
            EnableLogging = true,
        });
        _G.RM:Initialise(core);
    end
    -- Check if RecruitmentUIManager already exists or not
    if not _G.RMUI then
        _G.RMUI = RecruitmentUIManager:new({
            EnableLogging = true,
        });
    end
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
    -- This registers our functions with the Recruitment UI manager
    _G.RMUI:RegisterUIEventCallback("URP UI Event callback", function(context) urp:UIEventCallback(context); end);
    _G.RMUI:RegisterRefreshUICallback("URP UI callback", function(context) urp:RefreshUICallback(context); end);
    _G.RM:RegisterRecruitmentCallback("URP RM callback", function(context) urp:UpdateEffectBundles(context); end);
    RMUI:SetupPostUIListeners(core);
    URP_SetupPostUIListeners(urp);
    URP_Log("Finished");
    out("URP: Finished startup");
    URP_Log_Finished();
end

-- Saving/Loading Callbacks
-- These need to be outside of the Constructor function
-- because that is called by the game too late
cm:add_saving_game_callback(
    function(context)
        URP_Log_Finished();
        URP_Log("Saving callback");
        out("URP: Saving callback");
        InitialiseSaveHelper(cm, context);
        URP_SaveUnitPools(urp);
        URP_Log_Finished();
    end
);

cm:add_loading_game_callback(
    function(context)
        out("URP: Loading callback");
        InitialiseLoadHelper(cm, context);
        URP_LoadUnitPools(urp);
        out("URP: Finished loading");
	end
);