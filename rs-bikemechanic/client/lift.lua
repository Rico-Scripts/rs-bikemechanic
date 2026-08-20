-- RS Bike Mechanic - Moto Lift client module

local lifts = {}
local liftTargets = {}

local function notify(message, kind)
    if lib and lib.notify then
        lib.notify({
            title = Config.NotifyTitle or 'RS Bike Mechanic',
            description = tostring(message or ''),
            type = kind or 'inform'
        })
    end
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then return nil end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(25) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function createLiftEntity(data)
    if lifts[data.id] and DoesEntityExist(lifts[data.id]) then
        DeleteEntity(lifts[data.id])
    end

    local model = data.model or Config.MotoLift.model
    local hash = loadModel(model)
    if not hash and Config.MotoLift.fallbackModel then
        hash = loadModel(Config.MotoLift.fallbackModel)
        model = Config.MotoLift.fallbackModel
    end
    if not hash then
        print(('[rs-bikemechanic] Moto lift model niet gevonden: %s'):format(tostring(model)))
        return
    end

    local entity = CreateObjectNoOffset(hash, data.x, data.y, data.z, false, false, false)
    SetEntityHeading(entity, data.heading or 0.0)
    FreezeEntityPosition(entity, true)
    SetEntityInvincible(entity, true)
    SetEntityAsMissionEntity(entity, true, true)

    local height = data.raised and Config.MotoLift.raiseHeight or 0.0
    SetEntityCoordsNoOffset(entity, data.x, data.y, data.z + height, false, false, false)

    lifts[data.id] = entity
    SetModelAsNoLongerNeeded(hash)

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(entity, {
            {
                name = ('rs_moto_lift_%s'):format(data.id),
                icon = 'fa-solid fa-arrows-up-down',
                label = 'Motorheftafel bedienen',
                distance = Config.MotoLift.targetDistance or 2.0,
                onSelect = function()
                    TriggerEvent('rs-bikemechanic:client:liftMenu', data.id)
                end
            }
        })
        liftTargets[data.id] = true
    end
end

local function closestMotorcycle(coords, radius)
    local closest, closestDistance
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if GetVehicleClass(vehicle) == Config.MotorcycleClass then
            local distance = #(coords - GetEntityCoords(vehicle))
            if distance <= radius and (not closestDistance or distance < closestDistance) then
                closest = vehicle
                closestDistance = distance
            end
        end
    end
    return closest
end

local function alignBikeToLift(id)
    local data = Config.MotoLift.locations[id]
    if not data then return end

    local lift = lifts[id]
    if not lift or not DoesEntityExist(lift) then return end

    local bike = closestMotorcycle(GetEntityCoords(lift), Config.MotoLift.vehicleRadius or 3.0)
    if not bike then
        return notify('Geen motor dichtbij de heftafel gevonden.', 'error')
    end

    local liftCoords = GetEntityCoords(lift)
    SetEntityCoordsNoOffset(bike, liftCoords.x, liftCoords.y, liftCoords.z + (Config.MotoLift.vehicleOffsetZ or 0.35), false, false, false)
    SetEntityHeading(bike, GetEntityHeading(lift) + (Config.MotoLift.vehicleHeadingOffset or 0.0))
    FreezeEntityPosition(bike, true)
    Entity(bike).state:set('rsMotoLiftId', id, true)
    notify('Motor op de heftafel geplaatst.', 'success')
end

local function releaseBike(id)
    for _, vehicle in ipairs(GetGamePool('CVehicle')) do
        if Entity(vehicle).state.rsMotoLiftId == id then
            FreezeEntityPosition(vehicle, false)
            Entity(vehicle).state:set('rsMotoLiftId', nil, true)
        end
    end
end

RegisterNetEvent('rs-bikemechanic:client:liftMenu', function(id)
    local options = {
        {
            title = 'Motor omhoog',
            icon = 'fa-solid fa-arrow-up',
            onSelect = function()
                TriggerServerEvent('rs-bikemechanic:server:setLiftState', id, true)
            end
        },
        {
            title = 'Motor omlaag',
            icon = 'fa-solid fa-arrow-down',
            onSelect = function()
                TriggerServerEvent('rs-bikemechanic:server:setLiftState', id, false)
            end
        },
        {
            title = 'Motor positioneren',
            icon = 'fa-solid fa-motorcycle',
            onSelect = function()
                alignBikeToLift(id)
            end
        },
        {
            title = 'Motor vrijgeven',
            icon = 'fa-solid fa-unlock',
            onSelect = function()
                releaseBike(id)
            end
        }
    }

    lib.registerContext({ id = 'rs_moto_lift_menu', title = 'RS Motorheftafel', options = options })
    lib.showContext('rs_moto_lift_menu')
end)

RegisterNetEvent('rs-bikemechanic:client:syncLifts', function(states)
    for id, config in pairs(Config.MotoLift.locations or {}) do
        local state = states and states[id] or false
        createLiftEntity({
            id = id,
            x = config.coords.x,
            y = config.coords.y,
            z = config.coords.z,
            heading = config.heading or 0.0,
            model = Config.MotoLift.model,
            raised = state == true
        })
    end
end)

RegisterNetEvent('rs-bikemechanic:client:setLiftState', function(id, raised)
    local config = Config.MotoLift.locations[id]
    local lift = lifts[id]
    if not config or not lift or not DoesEntityExist(lift) then return end

    local start = GetEntityCoords(lift)
    local targetZ = config.coords.z + (raised and Config.MotoLift.raiseHeight or 0.0)
    local duration = Config.MotoLift.moveDuration or 2500
    local started = GetGameTimer()

    while true do
        local elapsed = GetGameTimer() - started
        local t = math.min(elapsed / duration, 1.0)
        local z = start.z + (targetZ - start.z) * t
        SetEntityCoordsNoOffset(lift, config.coords.x, config.coords.y, z, false, false, false)

        for _, vehicle in ipairs(GetGamePool('CVehicle')) do
            if Entity(vehicle).state.rsMotoLiftId == id then
                local vc = GetEntityCoords(vehicle)
                SetEntityCoordsNoOffset(vehicle, vc.x, vc.y, z + (Config.MotoLift.vehicleOffsetZ or 0.35), false, false, false)
            end
        end

        if t >= 1.0 then break end
        Wait(0)
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('rs-bikemechanic:server:requestLiftStates')
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, entity in pairs(lifts) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
end)
