Adjustments = {}
local LocalPlayerPed, LocalPlayerId = 0, 0
local lastHealth = 200

-- Pre-calculate HUD components to hide
local HudComponentsToHide = {}
for i, status in pairs(Config.RemoveHudComponents) do
    if status then
        table.insert(HudComponentsToHide, i)
    end
end

-- 1. MAIN GLOBAL PERFORMANCE THREAD (High frequency, one loop)
CreateThread(function()
    local scaleformCounter = 0
    local minimap = RequestScaleformMovie("minimap")
    
    while true do
        Wait(0)
        
        LocalPlayerPed = PlayerPedId()
        LocalPlayerId = PlayerId()
        
        -- Ragdoll / Fall Damage Prevention (Moved from events.lua for optimization)
        local isFalling = IsPedFalling(LocalPlayerPed) or IsEntityInAir(LocalPlayerPed)
        if isFalling then
            SetPedCanRagdoll(LocalPlayerPed, false)
            SetEntityProofs(LocalPlayerPed, false, false, false, false, false, false, false, true)

            local currentHealth = GetEntityHealth(LocalPlayerPed)
            if currentHealth < lastHealth then
                SetEntityHealth(LocalPlayerPed, lastHealth)
            end
        else
            SetPedCanRagdoll(LocalPlayerPed, true)
            SetEntityProofs(LocalPlayerPed, false, false, false, false, false, false, false, false)
            lastHealth = GetEntityHealth(LocalPlayerPed)
        end

        SetWeaponDamageModifier(`VEHICLE_HIT`, 0.0)

        -- HUD Hiding (Optimized)
        for i = 1, #HudComponentsToHide do
            local component = HudComponentsToHide[i]
            HideHudComponentThisFrame(component)
            if component == 19 then
                DisableControlAction(0, 37, true) -- WEAPON_WHEEL
            end
        end

        -- NPC Suppression (Must be every frame)
        SetPedDensityMultiplierThisFrame(0.0)
        SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
        SetRandomVehicleDensityMultiplierThisFrame(0.0)
        SetParkedVehicleDensityMultiplierThisFrame(0.0)
        SetVehicleDensityMultiplierThisFrame(0.0)
        SetAmbientVehicleRangeMultiplierThisFrame(0.0)
        SetAmbientPedRangeMultiplierThisFrame(0.0)
        SetDistantCarsEnabled(false)
        
        SetEveryoneIgnorePlayer(LocalPlayerId, true)
        SetPoliceIgnorePlayer(LocalPlayerId, true)
        SetDispatchCopsForPlayer(LocalPlayerId, false)

        scaleformCounter = scaleformCounter + 1
        if scaleformCounter >= 10 then
            scaleformCounter = 0
            if HasScaleformMovieLoaded(minimap) then
                BeginScaleformMovieMethod(minimap, "SETUP_HEALTH_ARMOUR")
                ScaleformMovieMethodAddParamInt(3) 
                EndScaleformMovieMethod()
            end
        end
    end
end)

-- 2. BACKGROUND CLEANUP THREAD (Low frequency)
CreateThread(function()
    while true do
        if LocalPlayerPed ~= 0 then
            local coords = GetEntityCoords(LocalPlayerPed)
            ClearAreaOfPeds(coords.x, coords.y, coords.z, 300.0, 1)
            ClearAreaOfVehicles(coords.x, coords.y, coords.z, 300.0, false, false, false, false, false)
            RemoveVehiclesFromGeneratorsInArea(coords.x - 500.0, coords.y - 500.0, coords.z - 500.0, coords.x + 500.0, coords.y + 500.0, coords.z + 500.0)
        end
        Wait(5000)
    end
end)

-- 3. INITIALIZATION & RECOVERY
CreateThread(function()
    while not ESX.PlayerLoaded do Wait(100) end
    
    SetPlayerTargetingMode(0) 
    SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
    ClearPlayerWantedLevel(PlayerId())
    SetMaxWantedLevel(0)

    for i = 1, 15 do EnableDispatchService(i, false) end
    SetAudioFlag('PoliceScannerDisabled', true)

    SetCanAttackFriendly(PlayerPedId(), true, false)
    NetworkSetFriendlyFireOption(true)
    
    -- Sync Minimap/Bigmap state once
    SetRadarBigmapEnabled(true, false)
    Wait(100)
    SetRadarBigmapEnabled(false, false)
end)

-- 4. EVENTS (Minimalist)
AddEventHandler("esx:enteredVehicle", function(vehicle, _, seat)
    if seat > -1 then
        SetPedConfigFlag(PlayerPedId(), 184, true) 
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
        player_name = function() return GetPlayerName(PlayerId()) end,
        player_id = function() return GetPlayerServerId(PlayerId()) end,
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