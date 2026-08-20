local ESX = exports['es_extended']:getSharedObject()

local originalRegister = lib.callback.register

local function dutyAvailable()
    return GetResourceState('rs-duty') == 'started'
end

local function syncJobDuty(source)
    local src = tonumber(source)
    if not src or src <= 0 then
        return false
    end

    if not dutyAvailable() then
        return false
    end

    local ok, onDuty = pcall(function()
        return exports['rs-duty']:IsOnDuty(src)
    end)

    if not ok then
        return false
    end

    onDuty = onDuty == true

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        return onDuty
    end

    if type(xPlayer.job) == 'table' then
        xPlayer.job.onDuty = onDuty
    end

    if xPlayer.getJob then
        local job = xPlayer.getJob()
        if type(job) == 'table' then
            job.onDuty = onDuty
        end
    end

    return onDuty
end

-- main.lua blijft alle normale callbacks registreren. Alleen de twee duty-
-- gerelateerde callbacks worden omwikkeld zodat rs-duty de enige bron is.
lib.callback.register = function(name, callback)
    if name == 'rs-bikemechanic:profile' and type(callback) == 'function' then
        return originalRegister(name, function(source, ...)
            syncJobDuty(source)
            return callback(source, ...)
        end)
    end

    if name == 'rs-bikemechanic:toggleDuty' then
        return originalRegister(name, function(source)
            local src = tonumber(source)

            if not src or src <= 0 then
                return false, false
            end

            if not dutyAvailable() then
                return false, false
            end

            local ok, success = pcall(function()
                return exports['rs-duty']:ToggleDuty(src)
            end)

            if not ok or success ~= true then
                return false, syncJobDuty(src)
            end

            return true, syncJobDuty(src)
        end)
    end

    return originalRegister(name, callback)
end

-- Synchroniseer ook wanneer rs-duty via een Jobs Creator punt verandert.
AddStateBagChangeHandler('rsDuty', nil, function(bagName, _, value)
    local playerId = tonumber(tostring(bagName):match('player:(%d+)'))
    if not playerId then
        return
    end

    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        return
    end

    local onDuty = value == true

    if type(xPlayer.job) == 'table' then
        xPlayer.job.onDuty = onDuty
    end

    if xPlayer.getJob then
        local job = xPlayer.getJob()
        if type(job) == 'table' then
            job.onDuty = onDuty
        end
    end
end)
