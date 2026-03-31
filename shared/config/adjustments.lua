Config.RemoveHudComponents = {
    [1] = true, --WANTED_STARS,
    [2] = true, --WEAPON_ICON
    [3] = true, --CASH
    [4] = true, --MP_CASH
    [5] = true, --MP_MESSAGE
    [6] = true, --VEHICLE_NAME
    [7] = true, -- AREA_NAME
    [8] = true, -- VEHICLE_CLASS
    [9] = true, --STREET_NAME
    [13] = true, --CASH_CHANGE
    [19] = true, --WEAPON_WHEEL
    [20] = true, --WEAPON_WHEEL_STATS
}

-- Pattern string format
--1 will lead to a random number from 0-9.
--A will lead to a random letter from A-Z.
-- . will lead to a random letter or number, with a 50% probability of being either.
--^1 will lead to a literal 1 being emitted.
--^A will lead to a literal A being emitted.
--Any other character will lead to said character being emitted.
-- A string shorter than 8 characters will be padded on the right.
Config.CustomAIPlates = "........" -- Custom plates for AI vehicles

Config.DiscordActivity = {
    appId = 0, -- Discord Application ID,
    assetName = "LargeIcon", --image name for the "large" icon.
    assetText = "{server_name}", -- Text to display on the asset
    buttons = {
        { label = "Join Server", url = "fivem://connect/{server_endpoint}" },
        { label = "Discord", url = "https://discord.esx-framework.org" },
    },
    presence = "{player_name} [{player_id}] | {server_players}/{server_maxplayers}",
    refresh = 1 * 60 * 1000, -- 1 minute
}
