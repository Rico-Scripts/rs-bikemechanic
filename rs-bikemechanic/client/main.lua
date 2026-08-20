local profile = nil
local tabletOpen = false
local selectedVehicle = nil
local selectedStation = nil
local lastResult = nil

local softwareCache = {}

local lastThrottle = 0.0
local boostBuilt = false
local launchArmed = false

local lastAntilag = 0
local lastLaunch = 0
local lastDump = 0
local lastExhaustPop = 0

local lastPerformanceVehicle = nil
local targetZones = {}

-- =========================================================
-- GENERAL
-- =========================================================

local function notify(message, kind)

    lib.notify({
        title = Config.NotifyTitle,
        description = message,
        type = kind or 'inform'
    })

end

local function trim(value)

    return value
        and value:match('^%s*(.-)%s*$')
        or ''

end

local function motorcycle(vehicle)

    return vehicle
        and vehicle ~= 0
        and DoesEntityExist(vehicle)
        and GetVehicleClass(vehicle)
            == Config.MotorcycleClass

end

local function vehicleType(vehicle)

    if not vehicle
        or vehicle == 0
        or not DoesEntityExist(vehicle) then

        return nil
    end

    return Config.VehicleClasses[
        GetVehicleClass(vehicle)
    ]

end

local function displayModel(vehicle)

    local displayName =
        GetDisplayNameFromVehicleModel(
            GetEntityModel(vehicle)
        )

    if not displayName
        or displayName == '' then

        displayName = 'UNKNOWN'
    end

    local label =
        GetLabelText(displayName)

    if not label
        or label == 'NULL' then

        label = displayName
    end

    return label,
        string.lower(displayName)

end

local function vehicleData(vehicle)

    local typeName =
        vehicleType(vehicle)

    if not typeName then
        return nil
    end

    local label, model =
        displayModel(vehicle)

    return {

        plate =
            trim(
                GetVehicleNumberPlateText(
                    vehicle
                )
            ),

        model = model,

        label = label,

        type = typeName,

        engine =
            math.floor(
                GetVehicleEngineHealth(
                    vehicle
                ) / 10
            ),

        body =
            math.floor(
                GetVehicleBodyHealth(
                    vehicle
                ) / 10
            )

    }

end

-- =========================================================
-- VEHICLES
-- =========================================================

local function closestMotorcycle()

    local origin =
        GetEntityCoords(cache.ped)

    local closest
    local distance =
        Config.MaxVehicleDistance + 0.01

    for _, vehicle in ipairs(
        GetGamePool('CVehicle')
    ) do

        if motorcycle(vehicle) then

            local currentDistance =
                #(origin -
                    GetEntityCoords(vehicle))

            if currentDistance < distance then

                closest = vehicle
                distance = currentDistance

            end

        end

    end

    return closest
end

local function closestVehicle(station)

    local found
    local distance =
        station.maxVehicleDistance + 0.01

    for _, vehicle in ipairs(
        GetGamePool('CVehicle')
    ) do

        local typeName =
            vehicleType(vehicle)

        if typeName
            and station.allowedTypes[
                typeName
            ] then

            local current =
                #(
                    station.coords -
                    GetEntityCoords(vehicle)
                )

            if current < distance then

                found = vehicle
                distance = current

            end

        end

    end

    return found
end

local function stationById(id)

    return id
        and Config.Stations[id]
        or nil

end

local function nearestStation()

    local coords =
        GetEntityCoords(
            PlayerPedId()
        )

    local stationId
    local distance

    for id, station in pairs(
        Config.Stations
    ) do

        local current =
            #(coords -
                station.coords)

        if not distance
            or current < distance then

            stationId = id
            distance = current

        end

    end

    return stationId
end

-- =========================================================
-- PROFILE
-- =========================================================

local function refreshProfile()

    profile =
        lib.callback.await(
            'rs-bikemechanic:profile',
            false
        )

    return profile
        and type(profile.permissions)
            == 'table'

end

-- =========================================================
-- TABLET
-- =========================================================

local function closeTablet()

    tabletOpen = false

    SetNuiFocus(
        false,
        false
    )

    SendNUIMessage({
        action = 'hide'
    })

end

local function servicesForRank(rank)

    local result = {}

    for name, service in pairs(
        Config.Services
    ) do

        result[#result + 1] = {

            name = name,

            label = service.label,

            category =
                service.category,

            image = service.image,

            duration =
                service.duration,

            minRank =
                service.minRank,

            locked =
                rank < service.minRank,

            item =
                service.item,

            count =
                service.count or 1

        }

    end

    table.sort(
        result,
        function(a, b)

            if a.category == b.category then
                return a.label < b.label
            end

            return a.category < b.category

        end
    )

    return result
end

local function productsForRank(rank)

    local result = {}

    for _, item in ipairs(
        Config.Shop.items
    ) do

        result[#result + 1] = {

            name = item.name,

            label = item.label,

            price = item.price,

            image = item.image,

            minRank = item.minRank,

            locked =
                rank < item.minRank

        }

    end

    return result
end

local function openTablet(
    vehicle,
    startTab
)

    if not refreshProfile() then

        notify(
            'Je bent geen medewerker van RS Mechanic.',
            'error'
        )

        return
    end

    if Config.RequireDuty
        and not profile.onDuty then

        notify(
            'Je bent niet in dienst.',
            'error'
        )

        return
    end

    selectedVehicle =
        vehicle
        or selectedVehicle

    local employees = {}

    if profile.permissions.employees then

        employees =
            lib.callback.await(
                'rs-bikemechanic:employees',
                false
            ) or {}

    end

    local ranks = {}

    for id, rank in pairs(
        Config.Ranks
    ) do

        ranks[#ranks + 1] = {
            id = id,
            label = rank.label
        }

    end

    table.sort(
        ranks,
        function(a, b)
            return a.id < b.id
        end
    )

    local station =
        stationById(
            selectedStation
        )

    tabletOpen = true

    SetNuiFocus(
        true,
        true
    )

    SendNUIMessage({

        action = 'show',

        profile = profile,

        vehicle =
            vehicleData(
                selectedVehicle
            ),

        services =
            servicesForRank(
                profile.rank
            ),

        products =
            productsForRank(
                profile.rank
            ),

        employees = employees,

        ranks = ranks,

        station = station
            and {
                id = selectedStation,
                label = station.label
            }
            or nil,

        dynoEnabled =
            Config.Dyno.enabled,

        startTab =
            startTab or 'service',

        imageBase =
            ('nui://%s/inventory_images/')
            :format(
                GetCurrentResourceName()
            )

    })

end

-- =========================================================
-- SERVICES
-- =========================================================

local function maximumMod(
    vehicle,
    mod
)

    local count =
        GetNumVehicleMods(
            vehicle,
            mod
        )

    local index = count - 1

    if index >= 0 then

        SetVehicleMod(
            vehicle,
            mod,
            index,
            false
        )

    end

end

local function applyEffect(
    vehicle,
    effect
)

    effect = effect or {}

    if effect.engine then

        SetVehicleEngineHealth(
            vehicle,
            math.min(
                1000.0,
                GetVehicleEngineHealth(
                    vehicle
                ) + effect.engine
            )
        )

    end

    if effect.body then

        SetVehicleBodyHealth(
            vehicle,
            math.min(
                1000.0,
                GetVehicleBodyHealth(
                    vehicle
                ) + effect.body
            )
        )

    end

    if effect.tires then

        for wheel = 0, 7 do
            SetVehicleTyreFixed(
                vehicle,
                wheel
            )
        end

    end

    if effect.mods then

        SetVehicleModKit(
            vehicle,
            0
        )

        if effect.mods.turbo then
            ToggleVehicleMod(
                vehicle,
                18,
                true
            )
        end

        if effect.mods.engine then
            maximumMod(
                vehicle,
                11
            )
        end

        if effect.mods.brakes then
            maximumMod(
                vehicle,
                12
            )
        end

        if effect.mods.transmission then
            maximumMod(
                vehicle,
                13
            )
        end

        if effect.mods.suspension then
            maximumMod(
                vehicle,
                15
            )
        end

        if effect.mods.exhaust then
            maximumMod(
                vehicle,
                4
            )
        end

    end

end

local function performService(name)

    local service =
        Config.Services[name]

    if not service then
        return
    end

    local vehicle =
        selectedVehicle

    if not motorcycle(vehicle) then

        vehicle =
            closestMotorcycle()

        selectedVehicle =
            vehicle

    end

    if not motorcycle(vehicle) then

        notify(
            'Geen motor dichtbij gevonden.',
            'error'
        )

        return
    end

    local inside = false

    local coords =
        GetEntityCoords(
            PlayerPedId()
        )

    for _, zone in ipairs(
        Config.WorkZones
    ) do

        if #(coords -
            zone.coords)
            <= zone.radius then

            inside = true
            break

        end

    end

    if not inside then

        notify(
            'Je moet dit in de werkplaats doen.',
            'error'
        )

        return
    end

    local netId =
        NetworkGetNetworkIdFromEntity(
            vehicle
        )

    local allowed, reason =
        lib.callback.await(
            'rs-bikemechanic:canService',
            false,
            name,
            netId
        )

    if not allowed then

        notify(
            reason or 'Niet toegestaan.',
            'error'
        )

        return
    end

    closeTablet()

    local completed =
        lib.progressCircle({

            duration =
                service.duration,

            label =
                service.label,

            canCancel = true,

            disable = {
                car = true,
                move = true,
                combat = true
            },

            anim = {
                dict =
                    'mini@repair',

                clip =
                    'fixing_a_ped'
            }

        })

    if not completed then

        notify(
            'Werk geannuleerd.',
            'error'
        )

        return
    end

    local success, message =
        lib.callback.await(
            'rs-bikemechanic:finishService',
            false,
            name,
            netId
        )

    if not success then

        notify(
            message
                or 'Werk kon niet worden afgerond.',
            'error'
        )

        return
    end

    applyEffect(
        vehicle,
        service.effect
    )

    softwareCache[
        trim(
            GetVehicleNumberPlateText(
                vehicle
            )
        )
    ] = nil

    notify(
        service.label
            .. ' afgerond.',
        'success'
    )

end

-- =========================================================
-- SOFTWARE
-- =========================================================

local function software(vehicle)

    local plate =
        trim(
            GetVehicleNumberPlateText(
                vehicle
            )
        )

    local cached =
        softwareCache[plate]

    local now =
        GetGameTimer()

    if cached
        and now - cached.time
            < Config.Software.cacheTime then

        return cached.data
    end

    local data =
        lib.callback.await(
            'rs-bikemechanic:vehicleSoftware',
            false,
            plate
        ) or {}

    softwareCache[plate] = {
        time = now,
        data = data
    }

    return data
end

local function exhaustBone(vehicle)

    for _, name in ipairs({
        'exhaust',
        'exhaust_2',
        'exhaust_3',
        'exhaust_4'
    }) do

        local bone =
            GetEntityBoneIndexByName(
                vehicle,
                name
            )

        if bone ~= -1 then
            return bone
        end

    end

    return GetEntityBoneIndexByName(
        vehicle,
        'chassis'
    )
end

local function backfire(
    vehicle,
    scale
)

    RequestNamedPtfxAsset(
        'core'
    )

    local timeout =
        GetGameTimer() + 1000

    while not HasNamedPtfxAssetLoaded(
        'core'
    )
    and GetGameTimer() < timeout do

        Wait(0)

    end

    UseParticleFxAssetNextCall(
        'core'
    )

    local bone =
        exhaustBone(vehicle)

    if bone ~= -1 then

        StartNetworkedParticleFxNonLoopedOnEntityBone(
            'veh_backfire',
            vehicle,
            0.0,
            -0.08,
            0.0,
            0.0,
            0.0,
            0.0,
            bone,
            scale or 1.0,
            false,
            false,
            false
        )

    end

end

local function playSound(sound)

    if sound
        and sound.file then

        TriggerServerEvent(
            'rs-bikemechanic:softwareSound',
            sound.file
        )

    end

end

local function softwareEffects(vehicle)

    local installed =
        software(vehicle)

    local rpm =
        GetVehicleCurrentRpm(
            vehicle
        )

    local speed =
        GetEntitySpeed(
            vehicle
        )

    local throttle =
        GetControlNormal(
            0,
            71
        )

    local accelerating =
        throttle > 0.45

    local braking =
        IsControlPressed(0, 72)
        or IsControlPressed(0, 76)

    local turbo =
        IsToggleModOn(
            vehicle,
            18
        )

    local now =
        GetGameTimer()

    if turbo
        and accelerating
        and rpm >=
            Config.Software.turboBoostRpm then

        boostBuilt = true

    end

    -- Dump valve
    local dump =
        Config.Software.dumpValve

    if dump.enabled
        and boostBuilt
        and lastThrottle
            >= dump.minThrottle
        and throttle < 0.12
        and rpm >= dump.minRpm
        and now - lastDump
            >= dump.cooldown
        and (
            not dump.requiresTurbo
            or turbo
        ) then

        lastDump = now
        boostBuilt = false

        playSound(
            Config.Software.sounds.dumpValve
        )

    end

    -- Antilag
    local anti =
        Config.Software.antilag

    if anti.enabled
        and installed.antilag
        and turbo
        and not accelerating
        and rpm >= anti.minRpm
        and speed >= anti.minSpeed
        and now - lastAntilag
            >= anti.cooldown
        and math.random(100)
            <= anti.chance then

        lastAntilag = now

        local count =
            math.random(
                anti.burstMin,
                anti.burstMax
            )

        for i = 1, count do

            backfire(
                vehicle,
                anti.scale
            )

            playSound(
                Config.Software.sounds.antilag
            )

            if i < count then
                Wait(65)
            end

        end

    end

    -- Launch control
    local launch =
        Config.Software.launchControl

    if launch.enabled
        and installed.launchControl
        and speed <= launch.maxSpeed
        and accelerating
        and braking
        and rpm >= launch.minRpm then

        launchArmed = true

        if now - lastLaunch
            >= launch.cooldown then

            lastLaunch = now

            backfire(
                vehicle,
                launch.scale
            )

            playSound(
                Config.Software.sounds.launch
            )

        end

    elseif launchArmed
        and accelerating
        and not braking then

        launchArmed = false

        SetVehicleBoostActive(
            vehicle,
            true
        )

        SetVehicleForwardSpeed(
            vehicle,
            launch.launchSpeed
        )

        backfire(
            vehicle,
            launch.scale
        )

        playSound(
            Config.Software.sounds.launch
        )

    elseif not accelerating then

        launchArmed = false

    end

    -- Performance
    local power = 0.0
    local torque = 1.0

    if (tonumber(
        installed.stage
    ) or 0) >= 2 then

        power =
            power
            + Config.Performance.stage2.power

        torque =
            torque
            * Config.Performance.stage2.torque

    end

    if installed.sportExhaust then

        power =
            power
            + Config.Performance.sportExhaust.power

        torque =
            torque
            * Config.Performance.sportExhaust.torque

    end

    SetVehicleEnginePowerMultiplier(
        vehicle,
        power
    )

    SetVehicleEngineTorqueMultiplier(
        vehicle,
        torque
    )

    lastPerformanceVehicle =
        vehicle

    -- Exhaust pops
    local exhaust =
        Config.Performance.exhaustSound

    if exhaust.enabled
        and installed.sportExhaust
        and lastThrottle > 0.45
        and throttle < 0.12
        and rpm >= exhaust.minRpm
        and now - lastExhaustPop
            >= exhaust.cooldown
        and math.random(100)
            <= exhaust.chance then

        lastExhaustPop = now

        backfire(
            vehicle,
            exhaust.scale
        )

        playSound(exhaust)

    end

    lastThrottle = throttle

end

-- =========================================================
-- DYNO
-- =========================================================

local function headingDifference(a, b)

    local difference =
        math.abs(
            (a - b + 180.0)
            % 360.0
            - 180.0
        )

    return difference

end

local function aligned(
    vehicle,
    station
)

    local distance =
        #(
            GetEntityCoords(vehicle)
            - station.coords
        )

    if distance >
        Config.Dyno.alignmentTolerance then

        return false
    end

    local heading =
        headingDifference(
            GetEntityHeading(vehicle),
            station.heading
        )

    return heading <=
        Config.Dyno.headingTolerance

end

local function requestControl(
    entity
)

    if NetworkHasControlOfEntity(
        entity
    ) then

        return true
    end

    NetworkRequestControlOfEntity(
        entity
    )

    local timeout =
        GetGameTimer() + 1500

    while not NetworkHasControlOfEntity(
        entity
    )
    and GetGameTimer() < timeout do

        Wait(0)

    end

    return NetworkHasControlOfEntity(
        entity
    )

end

local function modLevel(
    vehicle,
    mod
)

    local current =
        GetVehicleMod(
            vehicle,
            mod
        )

    if current < 0 then
        return 0
    end

    return current + 1

end

local function calculateDyno(
    vehicle,
    stationId
)

    SetVehicleModKit(
        vehicle,
        0
    )

    local typeName =
        vehicleType(vehicle)

    local power =
        Config.Dyno.modelPower[
            typeName
        ]

    if not power then
        return nil
    end

    local _, model =
        displayModel(vehicle)

    local force =
        GetVehicleHandlingFloat(
            vehicle,
            'CHandlingData',
            'fInitialDriveForce'
        ) or 0.28

    local inertia =
        GetVehicleHandlingFloat(
            vehicle,
            'CHandlingData',
            'fDriveInertia'
        ) or 1.0

    local flat =
        GetVehicleHandlingFloat(
            vehicle,
            'CHandlingData',
            'fInitialDriveMaxFlatVel'
        ) or 140.0

    local engine =
        modLevel(
            vehicle,
            11
        )

    local transmission =
        modLevel(
            vehicle,
            13
        )

    local brakes =
        modLevel(
            vehicle,
            12
        )

    local suspension =
        modLevel(
            vehicle,
            15
        )

    local turbo =
        IsToggleModOn(
            vehicle,
            18
        )

    local condition =
        math.max(
            0,
            math.min(
                1000,
                GetVehicleEngineHealth(
                    vehicle
                )
            )
        ) / 1000

    local plate =
        trim(
            GetVehicleNumberPlateText(
                vehicle
            )
        )

    local installed =
        lib.callback.await(
            'rs-bikemechanic:vehicleSoftware',
            false,
            plate
        ) or {}

    local upgrades =
        1
        + engine * 0.085
        + transmission * 0.055
        + suspension * 0.015
        + brakes * 0.01
        + (
            turbo
            and 0.18
            or 0
        )

    local multiplier =
        Config.Dyno.modelMultipliers[
            model
        ] or 1.0

    if (
        tonumber(
            installed.stage
        ) or 0
    ) >= 2 then

        multiplier =
            multiplier
            * Config.Performance.stage2.dynoMultiplier

    end

    if installed.sportExhaust then

        multiplier =
            multiplier
            * Config.Performance.sportExhaust.dynoMultiplier

    end

    local horsepower =
        (
            power.baseHorsepower
            + force * (
                typeName == 'motorcycle'
                and 150
                or 210
            )
            + inertia * 24
            + flat * 0.42
        )
        * multiplier
        * upgrades
        * (
            0.76
            + condition * 0.24
        )

    local torque =
        (
            power.baseTorque
            + force * (
                typeName == 'motorcycle'
                and 190
                or 260
            )
            + inertia * 42
        )
        * multiplier
        * (
            1
            + transmission * 0.04
        )
        * condition

    local topSpeed =
        flat
        * 1.22
        * (
            1
            + transmission * 0.025
        )

    local zeroToHundred =
        math.max(
            2.1,
            7.8
            - force * 8.5
            - engine * 0.28
            - transmission * 0.18
            - (
                turbo
                and 0.45
                or 0
            )
        )

    return {

        plate = plate,

        model = model,

        vehicleType = typeName,

        stationId = stationId,

        horsepower =
            math.floor(
                horsepower
            ),

        torque =
            math.floor(
                torque
            ),

        topSpeed =
            math.floor(
                topSpeed
            ),

        zeroToHundred =
            tonumber(
                string.format(
                    '%.2f',
                    zeroToHundred
                )
            ),

        engineHealth =
            math.floor(
                condition * 100
            ),

        bodyHealth =
            math.floor(
                GetVehicleBodyHealth(
                    vehicle
                ) / 10
            ),

        turbo = turbo,

        engineLevel = engine,

        transmissionLevel =
            transmission,

        brakeLevel = brakes,

        suspensionLevel =
            suspension

    }

end

local function runDyno()

    if not refreshProfile() then

        notify(
            'Je bent geen RS Mechanic medewerker.',
            'error'
        )

        return
    end

    if Config.RequireDuty
        and not profile.onDuty then

        notify(
            'Je bent niet in dienst.',
            'error'
        )

        return
    end

    local station =
        stationById(
            selectedStation
        )

    if not station then

        notify(
            'Dynostation niet gevonden.',
            'error'
        )

        return
    end

    local vehicle =
        selectedVehicle

    if not vehicleType(vehicle) then
        vehicle =
            closestVehicle(station)
    end

    selectedVehicle =
        vehicle

    local typeName =
        vehicleType(vehicle)

    if not typeName
        or not station.allowedTypes[
            typeName
        ] then

        notify(
            'Zet een ondersteunde auto of motor op de testbank.',
            'error'
        )

        return
    end

    if not aligned(
        vehicle,
        station
    ) then

        notify(
            'Zet het voertuig recht en gecentreerd op de dyno.',
            'error'
        )

        return
    end

    if not requestControl(
        vehicle
    ) then

        notify(
            'Geen netwerkcontrole over het voertuig.',
            'error'
        )

        return
    end

    local netId =
        NetworkGetNetworkIdFromEntity(
            vehicle
        )

    local allowed, reason =
        lib.callback.await(
            'rs-bikemechanic:dynoStart',
            false,
            selectedStation,
            netId
        )

    if not allowed then

        notify(
            reason
                or 'Dynotest geweigerd.',
            'error'
        )

        return
    end

    closeTablet()

    SetVehicleEngineOn(
        vehicle,
        true,
        true,
        false
    )

    if Config.Dyno.freezeVehicle then

        FreezeEntityPosition(
            vehicle,
            true
        )

    end

    local testing = true

    CreateThread(
        function()

            local started =
                GetGameTimer()

            while testing
                and DoesEntityExist(
                    vehicle
                ) do

                local progress =
                    math.min(
                        1.0,
                        (
                            GetGameTimer()
                            - started
                        )
                        / Config.Dyno.duration
                    )

                SetVehicleCurrentRpm(
                    vehicle,
                    0.22
                    + math.sin(
                        progress
                        * math.pi
                    )
                    * 0.76
                )

                Wait(0)

            end

            if DoesEntityExist(
                vehicle
            ) then

                SetVehicleCurrentRpm(
                    vehicle,
                    0.2
                )

            end

        end
    )

    local success =
        lib.progressCircle({

            duration =
                Config.Dyno.duration,

            label =
                'Dynotest draait',

            canCancel = true,

            disable = {
                car = true,
                move = true,
                combat = true
            }

        })

    testing = false

    if Config.Dyno.freezeVehicle
        and DoesEntityExist(vehicle) then

        FreezeEntityPosition(
            vehicle,
            false
        )

    end

    if not success then

        lib.callback.await(
            'rs-bikemechanic:dynoCancel',
            false
        )

        notify(
            'Dynotest geannuleerd.',
            'error'
        )

        return
    end

    lastResult =
        calculateDyno(
            vehicle,
            selectedStation
        )

    if not lastResult then

        notify(
            'Dyno kon geen resultaat berekenen.',
            'error'
        )

        return
    end

    local saved, message =
        lib.callback.await(
            'rs-bikemechanic:dynoFinish',
            false,
            selectedStation,
            netId,
            lastResult
        )

    if not saved then

        notify(
            message
                or 'Dyno-resultaat geweigerd.',
            'error'
        )

        return
    end

    notify(
        (
            'Dyno klaar: %s PK / %s Nm'
        ):format(
            lastResult.horsepower,
            lastResult.torque
        ),
        'success'
    )

    Wait(500)

    openTablet(
        vehicle,
        'dyno'
    )

end

-- =========================================================
-- COMMANDS / NUI
-- =========================================================

RegisterCommand(
    Config.TabletCommand,
    function()

        selectedStation =
            nearestStation()

        openTablet()

    end,
    false
)

RegisterKeyMapping(
    Config.TabletCommand,
    'Open RS Mechanic tablet',
    'keyboard',
    Config.TabletKey
)

RegisterNUICallback(
    'close',
    function(_, cb)

        closeTablet()

        cb(true)

    end
)

RegisterNUICallback(
    'service',
    function(data, cb)

        CreateThread(
            function()
                performService(
                    data.name
                )
            end
        )

        cb(true)

    end
)

RegisterNUICallback(
    'buy',
    function(data, cb)

        local ok, msg =
            lib.callback.await(
                'rs-bikemechanic:buyProduct',
                false,
                data.name,
                data.amount
            )

        cb({
            success = ok,
            message = msg
        })

    end
)

RegisterNUICallback(
    'duty',
    function(_, cb)

        local ok, state =
            lib.callback.await(
                'rs-bikemechanic:toggleDuty',
                false
            )

        if ok and profile then
            profile.onDuty = state
        end

        cb({
            success = ok,
            onDuty = state
        })

    end
)

RegisterNUICallback(
    'employee',
    function(data, cb)

        local ok, msg =
            lib.callback.await(
                'rs-bikemechanic:employeeAction',
                false,
                data.action,
                data.target,
                data.rank
            )

        cb({
            success = ok,
            message = msg
        })

    end
)

RegisterNUICallback(
    'refresh',
    function(_, cb)

        closeTablet()

        Wait(100)

        openTablet(
            selectedVehicle,
            'employees'
        )

        cb(true)

    end
)

RegisterNUICallback(
    'history',
    function(_, cb)

        cb(
            lib.callback.await(
                'rs-bikemechanic:history',
                false
            ) or {}
        )

    end
)

-- DYNO NUI

RegisterNUICallback(
    'startDyno',
    function(_, cb)

        cb(true)

        CreateThread(
            runDyno
        )

    end
)

RegisterNUICallback(
    'dynoHistory',
    function(data, cb)

        local vehicle =
            selectedVehicle

        local plate =
            data
            and data.plate
            or vehicle
            and trim(
                GetVehicleNumberPlateText(
                    vehicle
                )
            )
            or ''

        local history =
            lib.callback.await(
                'rs-bikemechanic:dynoHistory',
                false,
                plate
            ) or {}

        cb(history)

    end
)

-- =========================================================
-- PROFILE CHANGED
-- =========================================================

RegisterNetEvent(
    'rs-bikemechanic:profileChanged',
    function()

        profile = nil

        if tabletOpen then
            closeTablet()
        end

        notify(
            'Je RS Mechanic profiel is bijgewerkt.',
            'inform'
        )

    end
)

-- =========================================================
-- SOFTWARE SOUND
-- =========================================================

RegisterNetEvent(
    'rs-bikemechanic:softwareSound',
    function(
        coords,
        sound,
        baseVolume
    )

        local distance =
            #(
                GetEntityCoords(
                    cache.ped
                )
                - coords
            )

        if distance >
            Config.Software.soundDistance then

            return
        end

        SendNUIMessage({

            action = 'playSound',

            sound = sound,

            volume =
                (
                    baseVolume or 0.6
                )
                * (
                    1
                    - (
                        distance
                        / Config.Software.soundDistance
                    )
                )

        })

    end
)

-- =========================================================
-- TARGET
-- =========================================================

exports.ox_target:addGlobalVehicle({

    {

        name =
            'rsmechanic_vehicle',

        icon =
            'fa-solid fa-wrench',

        label =
            'RS Mechanic openen',

        distance =
            Config.TargetDistance,

        canInteract =
            function(entity)

                return motorcycle(entity)

            end,

        onSelect =
            function(data)

                openTablet(
                    data.entity
                )

            end

    }

})

exports.ox_target:addSphereZone({

    coords =
        Config.Shop.coords,

    radius =
        Config.Shop.radius,

    options = {

        {

            name =
                'rsmechanic_shop',

            icon =
                'fa-solid fa-boxes-stacked',

            label =
                Config.Shop.label,

            distance =
                Config.TargetDistance,

            onSelect =
                function()

                    openTablet(
                        nil,
                        'products'
                    )

                end

        }

    }

})

-- DYNO TARGET

for stationId, station
    in pairs(Config.Stations) do

    local zone =
        exports.ox_target:addSphereZone({

            coords =
                station.coords,

            radius =
                station.radius,

            options = {

                {

                    name =
                        ('rsmechanic_dyno_%s')
                        :format(
                            stationId
                        ),

                    icon =
                        station.targetIcon,

                    label =
                        station.targetLabel,

                    distance =
                        Config.TargetDistance,

                    onSelect =
                        function()

                            selectedStation =
                                stationId

                            selectedVehicle =
                                closestVehicle(
                                    station
                                )

                            openTablet(
                                selectedVehicle,
                                'dyno'
                            )

                        end

                }

            }

        })

    targetZones[#targetZones + 1] =
        zone

end

-- =========================================================
-- RESOURCE START
-- =========================================================

AddEventHandler(
    'onClientResourceStart',
    function(resource)

        if resource
            ~= GetCurrentResourceName() then

            return
        end

        tabletOpen = false
        profile = nil
        selectedVehicle = nil
        selectedStation = nil

        SetNuiFocus(
            false,
            false
        )

        SendNUIMessage({
            action = 'hide'
        })

    end
)

-- =========================================================
-- RESOURCE STOP
-- =========================================================

AddEventHandler(
    'onResourceStop',
    function(resource)

        if resource
            ~= GetCurrentResourceName() then

            return
        end

        closeTablet()

        for _, zoneId in ipairs(
            targetZones
        ) do

            exports.ox_target:removeZone(
                zoneId
            )

        end

    end
)

-- =========================================================
-- ESC CLOSE
-- =========================================================

CreateThread(
    function()

        while true do

            Wait(0)

            if tabletOpen
                and IsControlJustPressed(
                    0,
                    322
                ) then

                closeTablet()

            end

        end

    end
)

-- =========================================================
-- SOFTWARE LOOP
-- =========================================================

CreateThread(
    function()

        while true do

            local wait = 750

            if Config.Software.enabled then

                local vehicle =
                    GetVehiclePedIsIn(
                        cache.ped,
                        false
                    )

                if motorcycle(vehicle)
                    and GetPedInVehicleSeat(
                        vehicle,
                        -1
                    ) == cache.ped then

                    wait = 0

                    softwareEffects(
                        vehicle
                    )

                else

                    if lastPerformanceVehicle
                        and DoesEntityExist(
                            lastPerformanceVehicle
                        ) then

                        SetVehicleEnginePowerMultiplier(
                            lastPerformanceVehicle,
                            0.0
                        )

                        SetVehicleEngineTorqueMultiplier(
                            lastPerformanceVehicle,
                            1.0
                        )

                    end

                    lastPerformanceVehicle =
                        nil

                    lastThrottle = 0.0
                    boostBuilt = false
                    launchArmed = false

                end

            end

            Wait(wait)

        end

    end
)