Adjustments = {}

-- 1. PERSISTENT GLOBAL ADJUSTMENTS (NPC Removal & Weapon Wheel Blocking)
CreateThread(function()
    while true do
        Wait(0)
        
        -- Prevent Car Kill (Ramming Damage)
        SetWeaponDamageModifier(`VEHICLE_HIT`, 0.0)

        -- Block Weapon Wheel (TAB) & Hide Components
        for i, status in pairs(Config.RemoveHudComponents) do
            if status then
                HideHudComponentThisFrame(i)
                
                -- Block the Weapon Wheel specifically
                -- Using ONLY DisableControlAction(0, 37) as it is the most stable method
                if i == 19 then
                    DisableControlAction(0, 37, true) 
                end
            end
        end

        -- 2. ABSOLUTE NPC REMOVAL (Ambient Peds & Vehicles)
        SetPedDensityMultiplierThisFrame(0.0)
        SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
        SetRandomVehicleDensityMultiplierThisFrame(0.0)
        SetParkedVehicleDensityMultiplierThisFrame(0.0)
        SetVehicleDensityMultiplierThisFrame(0.0)
        
        SetAmbientVehicleRangeMultiplierThisFrame(0.0)
        SetAmbientPedRangeMultiplierThisFrame(0.0)
        SetDistantCarsEnabled(false)
        
        SetEveryoneIgnorePlayer(PlayerId(), true)
        SetPoliceIgnorePlayer(PlayerId(), true)
        SetDispatchCopsForPlayer(PlayerId(), false)
    end
end)

-- 3. BACKGROUND CLEANUP (Purge existing entities)
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        if playerPed and playerPed ~= 0 then
            local coords = GetEntityCoords(playerPed)
            ClearAreaOfPeds(coords.x, coords.y, coords.z, 300.0, 1)
            ClearAreaOfVehicles(coords.x, coords.y, coords.z, 300.0, false, false, false, false, false)
            RemoveVehiclesFromGeneratorsInArea(coords.x - 500.0, coords.y - 500.0, coords.z - 500.0, coords.x + 500.0, coords.y + 500.0, coords.z + 500.0)
        end
        Wait(5000)
    end
end)

-- 4. INITIALIZATION ADJUSTMENTS
CreateThread(function()
    while not ESX.PlayerLoaded do Wait(100) end
    
    SetPlayerTargetingMode(0) -- Standard Free Aim (Best for PVP)
    SetPlayerHealthRechargeMultiplier(ESX.playerId, 0.0)
    ClearPlayerWantedLevel(ESX.playerId)
    SetMaxWantedLevel(0)

    -- Dispatch Services
    for i = 1, 15 do EnableDispatchService(i, false) end
    SetAudioFlag('PoliceScannerDisabled', true)

    -- Friendly Fire Enable
    local playerPed = PlayerPedId()
    SetCanAttackFriendly(playerPed, true, false)
    NetworkSetFriendlyFireOption(true)
end)

-- 5. EVENTS
AddEventHandler("esx:enteredVehicle", function(vehicle, _, seat)
    if seat > -1 then
        local playerPed = PlayerPedId()
        SetPedIntoVehicle(playerPed, vehicle, seat)
        SetPedConfigFlag(playerPed, 184, true) -- Block drive-by auto-locking for/from NPCs
    end
    SetVehRadioStation(vehicle, "OFF")
    SetUserRadioControlEnabled(false)
end)

function Adjustments:ReplacePlaceholders(text)
    local placeHolders = {
        server_name = function() return GetConvar("sv_projectName", "ESX-Framework") end,
        server_endpoint = function() return GetCurrentServerEndpoint() or "localhost:30120" end,
        server_players = function() return GlobalState.playerCount or 0 end,
        server_maxplayers = function() return GetConvarInt("sv_maxClients", 48) end,
        player_name = function() return GetPlayerName(ESX.playerId) end,
        player_id = function() return ESX.serverId end,
    }
    for placeholder, cb in pairs(placeHolders) do
        local success, result = pcall(cb)
        if not success then result = "Unknown" end
        text = text:gsub(("{%s}"):format(placeholder), tostring(result))
    end
    return text
end

if Config.DiscordActivity.appId ~= 0 then
    CreateThread(function()
        while true do
            SetDiscordAppId(Config.DiscordActivity.appId)
            SetRichPresence(Adjustments:ReplacePlaceholders(Config.DiscordActivity.presence))
            SetDiscordRichPresenceAsset(Config.DiscordActivity.assetName)
            SetDiscordRichPresenceAssetText(Adjustments:ReplacePlaceholders(Config.DiscordActivity.assetText))
            Wait(Config.DiscordActivity.refresh)
        end
    end)
end

function Adjustments:Multipliers() end 
function Adjustments:Load() end 

-- 6. HIDE HEALTH & ARMOR BARS (Scaleform)
CreateThread(function()
    local minimap = RequestScaleformMovie("minimap")
    while not HasScaleformMovieLoaded(minimap) do Wait(0) end

    -- Toggle Bigmap once to refresh minimap state
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    
    while true do
        Wait(0)
        BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
        ScaleformMovieMethodAddParamInt(3) -- Hides HP/Armor bars (PVP Hud compatibility)
        EndScaleformMovieMethod()
    end
end)