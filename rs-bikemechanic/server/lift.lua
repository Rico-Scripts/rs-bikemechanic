-- RS Bike Mechanic - Moto Lift server module

local liftStates = {}
local cooldowns = {}

local function playerAllowed(src)
    local xPlayer = ESX and ESX.GetPlayerFromId and ESX.GetPlayerFromId(src)
    if not xPlayer or not xPlayer.job or xPlayer.job.name ~= Config.JobName then
        return false, 'Je bent geen RS Mechanic.'
    end

    if Config.RequireDuty and GetResourceState('rs-duty') == 'started' then
        local ok, onDuty = pcall(function()
            return exports['rs-duty']:IsOnDuty(src)
        end)
        if not ok or onDuty ~= true then
            return false, 'Je bent niet in dienst.'
        end
    end

    return true
end

local function nearLift(src, id)
    local data = Config.MotoLift.locations[id]
    if not data then return false end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    return #(coords - data.coords) <= (Config.MotoLift.serverDistance or 5.0)
end

local function logLift(src, id, raised)
    local webhook = GetConvar('rs_bikemechanic_webhook_services', '')
    if webhook == '' then
        webhook = GetConvar('rs_bikemechanic_webhook_default', '')
    end
    if webhook == '' then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    local job = xPlayer and xPlayer.job or {}

    PerformHttpRequest(webhook, function() end, 'POST', json.encode({
        username = 'RS Mechanic Logs',
        allowed_mentions = { parse = {} },
        embeds = {{
            title = raised and 'Motorheftafel omhoog' or 'Motorheftafel omlaag',
            color = raised and 5763719 or 3447003,
            fields = {
                { name = 'Speler', value = GetPlayerName(src) or 'Onbekend', inline = true },
                { name = 'Server ID', value = tostring(src), inline = true },
                { name = 'Lift', value = tostring(id), inline = true },
                { name = 'Rang', value = tostring(job.grade_label or job.grade_name or job.grade or '-'), inline = true }
            },
            footer = { text = 'Rico Scripts RS Moto Lift' },
            timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
        }}
    }), { ['Content-Type'] = 'application/json' })
end

RegisterNetEvent('rs-bikemechanic:server:requestLiftStates', function()
    local src = source
    TriggerClientEvent('rs-bikemechanic:client:syncLifts', src, liftStates)
end)

RegisterNetEvent('rs-bikemechanic:server:setLiftState', function(id, raised)
    local src = source
    id = tostring(id or '')
    raised = raised == true

    if not Config.MotoLift or Config.MotoLift.enabled ~= true then return end
    if not Config.MotoLift.locations[id] then return end

    local now = GetGameTimer()
    if cooldowns[src] and now - cooldowns[src] < (Config.MotoLift.cooldown or 1500) then
        return
    end
    cooldowns[src] = now

    local allowed, reason = playerAllowed(src)
    if not allowed then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = Config.NotifyTitle or 'RS Bike Mechanic',
            description = reason,
            type = 'error'
        })
    end

    if not nearLift(src, id) then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = Config.NotifyTitle or 'RS Bike Mechanic',
            description = 'Je staat te ver van de motorheftafel.',
            type = 'error'
        })
    end

    if liftStates[id] == raised then return end

    liftStates[id] = raised
    TriggerClientEvent('rs-bikemechanic:client:setLiftState', -1, id, raised)
    logLift(src, id, raised)
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)

exports('GetMotoLiftState', function(id)
    return liftStates[tostring(id or '')] == true
end)
