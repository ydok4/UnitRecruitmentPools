urp = {};
_G.urp = urp;

-- Helpers
require 'script/_lib/core/helpers/datahelpers';
require 'script/_lib/core/helpers/loadhelpers';
require 'script/_lib/core/helpers/savehelpers';
-- Models
require 'script/_lib/core/model/urp';
require 'script/_lib/core/model/urpui';
-- Loaders
require 'script/_lib/core/loaders/urp_resource_loader';
-- Listeners
require 'script/_lib/core/listeners/urp_listeners';

URP_Log_Start();

function unit_recruitment_pools()
    URP_Log_Finished();
    out("URP: Main mod function");
    URP_Log("Main mod function");

    urp = UnitRecruitmentPools:new({
        urpui = {},
        FactionUnitData = urp.FactionUnitData,
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
    SetupPostUIListeners(urp);
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