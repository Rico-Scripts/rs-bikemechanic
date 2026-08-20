local ESX = exports['es_extended']:getSharedObject()

local profiles = {}
local dutyState = {}
local actionCooldown = {}
local pendingServices = {}
local pendingDynos = {}

-- =========================================================
-- HELPERS
-- =========================================================

local function onlineSource(value)
    local player = tonumber(value)

    if not player or player <= 0 then
        return nil
    end

    if not GetPlayerName(player) then
        return nil
    end

    return player
end

local function throttle(source, key, milliseconds)
    local now = GetGameTimer()
    local token = ('%s:%s'):format(source, key)

    if actionCooldown[token]
        and now - actionCooldown[token] < milliseconds then
        return false
    end

    actionCooldown[token] = now

    return true
end

local function xPlayer(source)
    source = onlineSource(source)

    if not source then
        return nil
    end

    return ESX.GetPlayerFromId(source)
end

local function playerName(source)
    source = onlineSource(source)

    if not source then
        return 'Onbekend'
    end

    local player = ESX.GetPlayerFromId(source)

    if player then
        local first =
            player.get('firstName')
            or player.get('firstname')

        local last =
            player.get('lastName')
            or player.get('lastname')

        local full = ('%s %s'):format(
            first or '',
            last or ''
        )

        full = full:match('^%s*(.-)%s*$')

        if full ~= '' then
            return full
        end
    end

    return GetPlayerName(source) or 'Onbekend'
end

local function identifier(source)
    local player = xPlayer(source)

    if player and player.identifier then
        return player.identifier
    end

    source = onlineSource(source)

    if not source then
        return nil
    end

    for _, prefix in ipairs({
        'license2:',
        'license:',
        'fivem:'
    }) do

        for _, id in ipairs(GetPlayerIdentifiers(source) or {}) do
            if id:sub(1, #prefix) == prefix then
                return id
            end
        end

    end

    return nil
end

local function discordId(source)
    source = onlineSource(source)

    if not source then
        return 'Niet gekoppeld'
    end

    for _, value in ipairs(GetPlayerIdentifiers(source) or {}) do
        if value:sub(1, 8) == 'discord:' then
            return '<@' .. value:sub(9) .. '>'
        end
    end

    return 'Niet gekoppeld'
end

-- =========================================================
-- JOB
-- =========================================================

local function isMechanicJob(job)
    return job
        and job.name == Config.JobName
end

local function rankData(rank)
    return Config.Ranks[tonumber(rank) or -1]
end

local function currentDuty(source, player, job)

    if dutyState[source] ~= nil then
        return dutyState[source]
    end

    if job and type(job.onDuty) == 'boolean' then
        return job.onDuty
    end

    return true
end

local function loadProfile(source, refresh)

    source = onlineSource(source)

    if not source then
        return nil
    end

    if profiles[source] and not refresh then
        return profiles[source]
    end

    local player = ESX.GetPlayerFromId(source)

    if not player then
        profiles[source] = nil
        return nil
    end

    local job = player.getJob()

    if not isMechanicJob(job) then
        profiles[source] = nil
        return nil
    end

    local grade = tonumber(job.grade) or 0

    local rank =
        Config.ESXGradeToRank[grade]

    if rank == nil then
        rank = grade
    end

    if not rankData(rank) then
        rank = 0
    end

    local profile = {

        identifier = player.identifier,

        player_name = playerName(source),

        rank = rank,

        esx_grade = grade,

        on_duty = currentDuty(
            source,
            player,
            job
        ),

        rankData = rankData(rank),

        job = job.name,

        jobLabel =
            job.label
            or Config.JobLabel

    }

    profiles[source] = profile

    return profile
end

local function publicProfile(profile)

    if not profile then
        return nil
    end

    return {

        rank = profile.rank,

        rankLabel =
            profile.rankData
            and profile.rankData.label
            or 'Monteur',

        onDuty =
            profile.on_duty == true,

        permissions =
            profile.rankData or {},

        job = profile.job,

        jobLabel = profile.jobLabel

    }
end

local function allowed(source, permission, minimum)

    local profile = loadProfile(source)

    if not profile then
        return false, nil
    end

    if Config.RequireDuty
        and not profile.on_duty
        and permission ~= 'employees' then

        return false, profile
    end

    local rank = rankData(profile.rank)

    if not rank then
        return false, profile
    end

    if rank[permission] ~= true then
        return false, profile
    end

    if profile.rank < (minimum or 0) then
        return false, profile
    end

    return true, profile
end

-- =========================================================
-- WEBHOOK
-- =========================================================

local Webhooks = {

    default =
        GetConvar(
            'rs_bikemechanic_webhook_default',
            ''
        ),

    employees =
        GetConvar(
            'rs_bikemechanic_webhook_employees',
            ''
        ),

    services =
        GetConvar(
            'rs_bikemechanic_webhook_services',
            ''
        ),

    products =
        GetConvar(
            'rs_bikemechanic_webhook_products',
            ''
        ),

    security =
        GetConvar(
            'rs_bikemechanic_webhook_security',
            ''
        )

}

local function webhookColor(typeName)

    return ({
        employees = 3447003,
        services = 5763719,
        products = 16753920,
        security = 15548997,
        dyno = 10181046
    })[typeName] or 8421504

end

local function log(typeName, title, source, fields)

    local url =
        Webhooks[typeName]
        or Webhooks.default

    if not url or url == '' then
        return
    end

    local validSource =
        onlineSource(source)

    local base = {

        {
            name = 'Uitvoerder',
            value =
                validSource
                and playerName(validSource)
                or 'Server',
            inline = true
        },

        {
            name = 'Server ID',
            value =
                validSource
                and tostring(validSource)
                or '-',
            inline = true
        },

        {
            name = 'Discord',
            value =
                validSource
                and discordId(validSource)
                or '-',
            inline = true
        }

    }

    for _, field in ipairs(fields or {}) do
        base[#base + 1] = field
    end

    PerformHttpRequest(
        url,
        function() end,
        'POST',
        json.encode({

            username =
                'RS Mechanic Logs',

            allowed_mentions = {
                parse = {}
            },

            embeds = {{

                title = title,

                color =
                    webhookColor(typeName),

                fields = base,

                footer = {
                    text = 'Rico Scripts RS Mechanic'
                },

                timestamp =
                    os.date(
                        '!%Y-%m-%dT%H:%M:%SZ'
                    )

            }}

        }),
        {
            ['Content-Type'] =
                'application/json'
        }
    )

end

-- =========================================================
-- PROFILE
-- =========================================================

lib.callback.register(
    'rs-bikemechanic:profile',
    function(source)

        source = onlineSource(source)

        if not source then
            return nil
        end

        if not throttle(
            source,
            'profile',
            750
        ) then

            return publicProfile(
                profiles[source]
            )

        end

        return publicProfile(
            loadProfile(source, true)
        )

    end
)

-- =========================================================
-- DUTY
-- =========================================================

lib.callback.register(
    'rs-bikemechanic:toggleDuty',
    function(source)

        source = onlineSource(source)

        if not source then
            return false,
                'Speler is niet meer online.'
        end

        if not throttle(
            source,
            'duty',
            1500
        ) then

            return false,
                'Wacht even.'

        end

        local profile =
            loadProfile(source)

        if not profile then
            return false,
                'Je hebt geen RS Mechanic job.'
        end

        profile.on_duty =
            not profile.on_duty

        dutyState[source] =
            profile.on_duty

        log(
            'employees',
            profile.on_duty
                and 'In dienst gegaan'
                or 'Uit dienst gegaan',
            source
        )

        return true,
            profile.on_duty

    end
)

exports(
    'IsEmployeeOnDuty',
    function(source)

        local profile =
            loadProfile(
                tonumber(source),
                false
            )

        return profile
            and profile.on_duty == true
            or false

    end
)

-- =========================================================
-- SHOP
-- =========================================================

local function getProduct(name)

    for _, item in ipairs(
        Config.Shop.items
    ) do

        if item.name == name then
            return item
        end

    end

    return nil
end

lib.callback.register(
    'rs-bikemechanic:buyProduct',
    function(source, name, amount)

        source = onlineSource(source)

        if not source then
            return false,
                'Speler is niet meer online.'
        end

        if not throttle(
            source,
            'product',
            750
        ) then

            return false,
                'Wacht even.'

        end

        local item =
            getProduct(
                type(name) == 'string'
                and name
                or ''
            )

        amount =
            math.floor(
                tonumber(amount) or 0
            )

        if not item
            or amount < 1
            or amount > 25 then

            return false,
                'Ongeldig product of aantal.'

        end

        local ok, profile =
            allowed(
                source,
                'products',
                item.minRank
            )

        if not ok then
            return false,
                'Je hebt hiervoor geen rechten.'
        end

        local player =
            ESX.GetPlayerFromId(source)

        if not player then
            return false,
                'ESX speler niet gevonden.'
        end

        local total =
            item.price * amount

        local balance

        if Config.CurrencyMode == 'bank' then

            local account =
                player.getAccount('bank')

            balance =
                account
                and account.money
                or 0

        else

            balance =
                player.getMoney()

        end

        if balance < total then
            return false,
                'Onvoldoende geld.'
        end

        if not exports.ox_inventory:CanCarryItem(
            source,
            item.name,
            amount
        ) then

            return false,
                'Je inventory zit vol.'

        end

        if Config.CurrencyMode == 'bank' then
            player.removeAccountMoney(
                'bank',
                total
            )
        else
            player.removeMoney(total)
        end

        local added =
            exports.ox_inventory:AddItem(
                source,
                item.name,
                amount
            )

        if not added then

            if Config.CurrencyMode == 'bank' then
                player.addAccountMoney(
                    'bank',
                    total
                )
            else
                player.addMoney(total)
            end

            return false,
                'Product kon niet worden gegeven.'

        end

        log(
            'products',
            'Product gekocht',
            source,
            {

                {
                    name = 'Product',
                    value =
                        ('%sx %s'):format(
                            amount,
                            item.label
                        ),
                    inline = true
                },

                {
                    name = 'Bedrag',
                    value =
                        ('€%s'):format(total),
                    inline = true
                },

                {
                    name = 'Rang',
                    value =
                        profile.rankData.label,
                    inline = true
                }

            }
        )

        return true,
            'Aankoop voltooid.'

    end
)

-- =========================================================
-- VEHICLE VALIDATION
-- =========================================================

local function validVehicle(source, netId)

    netId =
        tonumber(netId)

    if not netId then
        return false
    end

    local entity =
        NetworkGetEntityFromNetworkId(
            netId
        )

    if not entity
        or entity == 0
        or not DoesEntityExist(entity) then

        return false
    end

    local ped =
        GetPlayerPed(source)

    if not ped or ped == 0 then
        return false
    end

    local playerCoords =
        GetEntityCoords(ped)

    local vehicleCoords =
        GetEntityCoords(entity)

    if #(
        playerCoords -
        vehicleCoords
    ) > Config.MaxVehicleDistance + 1.0 then

        return false
    end

    local vehicleClass =
        GetVehicleClass(entity)

    local vehicleType =
        Config.VehicleClasses[
            vehicleClass
        ]

    if not vehicleType then
        return false
    end

    for _, zone in ipairs(
        Config.WorkZones
    ) do

        if #(
            playerCoords -
            zone.coords
        ) <= zone.radius + 1.0 then

            return true,
                entity,
                vehicleType

        end

    end

    return false
end

-- =========================================================
-- SERVICES
-- =========================================================

local function serviceItems(service)

    if service.items then
        return service.items
    end

    return {{
        name = service.item,
        count = service.count or 1
    }}

end

local function hasItems(source, items)

    for _, item in ipairs(items) do

        local count =
            exports.ox_inventory:Search(
                source,
                'count',
                item.name
            )

        if count < item.count then

            return false,
                ('Je mist %sx %s.'):format(
                    item.count,
                    item.name
                )

        end

    end

    return true
end

local function removeItems(source, items)

    local removed = {}

    for _, item in ipairs(items) do

        local success =
            exports.ox_inventory:RemoveItem(
                source,
                item.name,
                item.count
            )

        if not success then

            for _, restore in ipairs(
                removed
            ) do

                exports.ox_inventory:AddItem(
                    source,
                    restore.name,
                    restore.count
                )

            end

            return false
        end

        removed[#removed + 1] = item

    end

    return true
end

lib.callback.register(
    'rs-bikemechanic:canService',
    function(
        source,
        serviceName,
        netId
    )

        source = onlineSource(source)

        if not source then
            return false,
                'Speler is niet meer online.'
        end

        if not throttle(
            source,
            'service_start',
            750
        ) then

            return false,
                'Wacht even.'

        end

        local service =
            Config.Services[
                type(serviceName) == 'string'
                and serviceName
                or ''
            ]

        if not service then
            return false,
                'Onbekende service.'
        end

        local permission =
            service.category == 'upgrade'
            and 'upgrades'
            or 'service'

        local ok =
            allowed(
                source,
                permission,
                service.minRank
            )

        if not ok then
            return false,
                'Onvoldoende rechten of niet in dienst.'
        end

        local valid, entity =
            validVehicle(
                source,
                netId
            )

        if not valid then
            return false,
                'Voertuig of werkplaatslocatie kon niet worden bevestigd.'
        end

        local items =
            serviceItems(service)

        local owns, reason =
            hasItems(
                source,
                items
            )

        if not owns then
            return false, reason
        end

        local plate =
            tostring(
                GetVehicleNumberPlateText(entity)
                or ''
            ):match(
                '^%s*(.-)%s*$'
            )

        pendingServices[source] = {

            service = serviceName,

            netId = tonumber(netId),

            plate = plate,

            started = GetGameTimer(),

            duration = service.duration

        }

        return true
    end
)

lib.callback.register(
    'rs-bikemechanic:finishService',
    function(
        source,
        serviceName,
        netId
    )

        source = onlineSource(source)

        if not source then
            return false,
                'Speler is niet meer online.'
        end

        if not throttle(
            source,
            'service',
            1000
        ) then

            return false,
                'Wacht even.'

        end

        local service =
            Config.Services[
                type(serviceName) == 'string'
                and serviceName
                or ''
            ]

        local pending =
            pendingServices[source]

        pendingServices[source] = nil

        if not service
            or not pending
            or pending.service ~= serviceName
            or pending.netId ~= tonumber(netId) then

            return false,
                'Ongeldige aanvraag.'
        end

        if GetGameTimer()
            - pending.started
            < math.max(
                0,
                pending.duration - 750
            ) then

            return false,
                'De werktijd is niet voltooid.'
        end

        local valid, entity =
            validVehicle(
                source,
                netId
            )

        if not valid then
            return false,
                'Voertuigcontrole mislukt.'
        end

        local plate =
            tostring(
                GetVehicleNumberPlateText(entity)
                or ''
            ):match(
                '^%s*(.-)%s*$'
            )

        if plate == ''
            or plate ~= pending.plate
            or #plate > 12 then

            return false,
                'Kentekencontrole mislukt.'
        end

        local permission =
            service.category == 'upgrade'
            and 'upgrades'
            or 'service'

        local ok, profile =
            allowed(
                source,
                permission,
                service.minRank
            )

        if not ok then
            return false,
                'Onvoldoende rechten.'
        end

        local items =
            serviceItems(service)

        local owns, reason =
            hasItems(
                source,
                items
            )

        if not owns then
            return false, reason
        end

        if not removeItems(
            source,
            items
        ) then

            return false,
                'Onderdelen konden niet worden gebruikt.'
        end

        MySQL.insert.await(
            [[
                INSERT INTO rs_bikemechanic_service_history
                (
                    plate,
                    mechanic_identifier,
                    mechanic_name,
                    service_name
                )
                VALUES (?, ?, ?, ?)
            ]],
            {
                plate,
                profile.identifier,
                playerName(source),
                serviceName
            }
        )

        if service.effect
            and service.effect.software then

            local software =
                service.effect.software

            MySQL.insert.await(
                [[
                    INSERT INTO rs_bikemechanic_vehicle_software
                    (
                        plate,
                        antilag,
                        launch_control,
                        stage,
                        sport_exhaust
                    )
                    VALUES (?, ?, ?, ?, ?)

                    ON DUPLICATE KEY UPDATE

                    antilag =
                        GREATEST(
                            antilag,
                            VALUES(antilag)
                        ),

                    launch_control =
                        GREATEST(
                            launch_control,
                            VALUES(launch_control)
                        ),

                    stage =
                        GREATEST(
                            stage,
                            VALUES(stage)
                        ),

                    sport_exhaust =
                        GREATEST(
                            sport_exhaust,
                            VALUES(sport_exhaust)
                        )
                ]],
                {
                    plate,

                    software.antilag
                        and 1 or 0,

                    software.launchControl
                        and 1 or 0,

                    tonumber(
                        software.stage
                    ) or 0,

                    software.sportExhaust
                        and 1 or 0
                }
            )

        end

        log(
            'services',
            'Werk uitgevoerd',
            source,
            {

                {
                    name = 'Werk',
                    value = service.label,
                    inline = true
                },

                {
                    name = 'Kenteken',
                    value = plate,
                    inline = true
                },

                {
                    name = 'Rang',
                    value =
                        profile.rankData.label,
                    inline = true
                }

            }
        )

        return true
    end
)

-- =========================================================
-- SOFTWARE
-- =========================================================

lib.callback.register(
    'rs-bikemechanic:vehicleSoftware',
    function(source, plate)

        source = onlineSource(source)

        if not source then
            return {}
        end

        if not throttle(
            source,
            'vehicle_software',
            500
        ) then

            return {}
        end

        plate =
            tostring(plate or '')
            :match(
                '^%s*(.-)%s*$'
            )

        if plate == ''
            or #plate > 12 then

            return {}
        end

        local row =
            MySQL.single.await(
                [[
                    SELECT
                        antilag,
                        launch_control,
                        stage,
                        sport_exhaust
                    FROM rs_bikemechanic_vehicle_software
                    WHERE plate = ?
                ]],
                { plate }
            )

        if not row then
            return {}
        end

        return {

            antilag =
                row.antilag == 1,

            launchControl =
                row.launch_control == 1,

            stage =
                tonumber(row.stage) or 0,

            sportExhaust =
                row.sport_exhaust == 1

        }

    end
)

-- =========================================================
-- SOFTWARE SOUND
-- =========================================================

RegisterNetEvent(
    'rs-bikemechanic:softwareSound',
    function(sound)

        local source =
            onlineSource(source)

        if not source then
            return
        end

        if not throttle(
            source,
            'software_sound',
            180
        ) then
            return
        end

        if type(sound) ~= 'string' then
            return
        end

        local allowedSounds = {

            dumpvalve =
                Config.Software.sounds
                .dumpValve.volume,

            antilag_pop =
                Config.Software.sounds
                .antilag.volume

        }

        local volume =
            allowedSounds[sound]

        if not volume then
            return
        end

        local ped =
            GetPlayerPed(source)

        if not ped or ped == 0 then
            return
        end

        local vehicle =
            GetVehiclePedIsIn(
                ped,
                false
            )

        if not vehicle
            or vehicle == 0 then

            return
        end

        TriggerClientEvent(
            'rs-bikemechanic:softwareSound',
            -1,
            GetEntityCoords(vehicle),
            sound,
            volume
        )

    end
)

-- =========================================================
-- DYNO
-- =========================================================

local function validDynoVehicle(
    source,
    stationId,
    netId
)

    if not Config.Dyno.enabled then
        return false
    end

    local station =
        Config.Stations[stationId]

    if not station then
        return false
    end

    local entity =
        NetworkGetEntityFromNetworkId(
            tonumber(netId) or -1
        )

    if not entity
        or entity == 0
        or not DoesEntityExist(entity) then

        return false
    end

    local vehicleClass =
        GetVehicleClass(entity)

    local vehicleType =
        Config.VehicleClasses[
            vehicleClass
        ]

    if not vehicleType
        or not station.allowedTypes[
            vehicleType
        ] then

        return false
    end

    local ped =
        GetPlayerPed(source)

    if not ped or ped == 0 then
        return false
    end

    local vehicleCoords =
        GetEntityCoords(entity)

    local playerCoords =
        GetEntityCoords(ped)

    if #(
        vehicleCoords -
        station.coords
    ) > station.maxVehicleDistance + 1.0 then

        return false
    end

    if #(
        playerCoords -
        station.coords
    ) > station.maxVehicleDistance + 4.0 then

        return false
    end

    return true,
        entity,
        vehicleType,
        station
end

lib.callback.register(
    'rs-bikemechanic:dynoStart',
    function(
        source,
        stationId,
        netId
    )

        source = onlineSource(source)

        if not source then
            return false,
                'Speler is niet meer online.'
        end

        if not throttle(
            source,
            'dyno_start',
            1000
        ) then

            return false,
                'Wacht even.'

        end

        local ok =
            allowed(
                source,
                'service'
            )

        if not ok then
            return false,
                'Je bent niet bevoegd voor de dyno.'
        end

        local valid,
            entity,
            vehicleType,
            station =
            validDynoVehicle(
                source,
                stationId,
                netId
            )

        if not valid then
            return false,
                'Voertuig of dynostation kon niet worden bevestigd.'
        end

        local plate =
            tostring(
                GetVehicleNumberPlateText(entity)
                or ''
            ):match(
                '^%s*(.-)%s*$'
            )

        if plate == ''
            or #plate > 12 then

            return false,
                'Ongeldig kenteken.'
        end

        pendingDynos[source] = {

            stationId = stationId,

            netId = tonumber(netId),

            vehicleType = vehicleType,

            plate = plate,

            started = GetGameTimer(),

            duration =
                Config.Dyno.duration

        }

        return true
    end
)

lib.callback.register(
    'rs-bikemechanic:dynoCancel',
    function(source)

        source =
            onlineSource(source)

        if not source then
            return false
        end

        pendingDynos[source] = nil

        return true
    end
)

lib.callback.register(
    'rs-bikemechanic:dynoFinish',
    function(
        source,
        stationId,
        netId,
        result
    )

        source =
            onlineSource(source)

        if not source then
            return false,
                'Speler is niet meer online.'
        end

        if not throttle(
            source,
            'dyno_finish',
            1000
        ) then

            return false,
                'Wacht even.'
        end

        if type(result) ~= 'table' then
            return false,
                'Ongeldig dyno-resultaat.'
        end

        local pending =
            pendingDynos[source]

        pendingDynos[source] = nil

        if not pending then
            return false,
                'Geen actieve dynotest.'
        end

        if pending.stationId ~= stationId
            or pending.netId ~= tonumber(netId) then

            return false,
                'Dynotest validatie mislukt.'
        end

        if GetGameTimer()
            - pending.started
            < math.max(
                0,
                pending.duration - 750
            ) then

            return false,
                'Dynotest is niet voltooid.'
        end

        local valid,
            entity,
            vehicleType,
            station =
            validDynoVehicle(
                source,
                stationId,
                netId
            )

        if not valid then
            return false,
                'Voertuigvalidatie mislukt.'
        end

        if vehicleType ~= pending.vehicleType then
            return false,
                'Voertuigtype gewijzigd.'
        end

        local plate =
            tostring(
                GetVehicleNumberPlateText(entity)
                or ''
            ):match(
                '^%s*(.-)%s*$'
            )

        if plate ~= pending.plate then
            return false,
                'Kentekencontrole mislukt.'
        end

        if tostring(result.plate or '')
            ~= plate then

            return false,
                'Resultaat hoort niet bij dit voertuig.'
        end

        local hp =
            math.floor(
                tonumber(
                    result.horsepower
                ) or -1
            )

        local torque =
            math.floor(
                tonumber(
                    result.torque
                ) or -1
            )

        local topSpeed =
            math.floor(
                tonumber(
                    result.topSpeed
                ) or -1
            )

        local zeroToHundred =
            tonumber(
                result.zeroToHundred
            ) or 0

        if hp < 0
            or hp > Config.Dyno.Security.maxHorsepower then

            return false,
                'PK-resultaat buiten bereik.'
        end

        if torque < 0
            or torque > Config.Dyno.Security.maxTorque then

            return false,
                'Koppel-resultaat buiten bereik.'
        end

        if topSpeed < 0
            or topSpeed > Config.Dyno.Security.maxTopSpeed then

            return false,
                'Topsnelheid buiten bereik.'
        end

        if zeroToHundred < 0
            or zeroToHundred
                > Config.Dyno.Security.maxZeroToHundred then

            return false,
                '0-100 resultaat buiten bereik.'
        end

        local worker =
            loadProfile(source)

        if not worker then
            return false,
                'Mechanic profiel niet gevonden.'
        end

        local model =
            tostring(
                result.model or 'unknown'
            ):sub(1, 64)

        MySQL.insert.await(
            [[
                INSERT INTO rs_dyno_history
                (
                    plate,
                    model,
                    mechanic_identifier,
                    mechanic_name,
                    horsepower,
                    torque,
                    top_speed,
                    zero_to_hundred
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ]],
            {

                plate,

                model,

                worker.identifier,

                playerName(source),

                hp,

                torque,

                topSpeed,

                zeroToHundred

            }
        )

        log(
            'dyno',
            'Dynotest afgerond',
            source,
            {

                {
                    name = 'Voertuig',
                    value =
                        vehicleType == 'motorcycle'
                        and 'Motor'
                        or 'Auto',
                    inline = true
                },

                {
                    name = 'Testbank',
                    value = station.label,
                    inline = true
                },

                {
                    name = 'Kenteken',
                    value = plate,
                    inline = true
                },

                {
                    name = 'Resultaat',
                    value =
                        ('%s PK / %s Nm'):format(
                            hp,
                            torque
                        ),
                    inline = true
                }

            }
        )

        return true
    end
)

lib.callback.register(
    'rs-bikemechanic:dynoHistory',
    function(source, plate)

        source =
            onlineSource(source)

        if not source then
            return {}
        end

        if not throttle(
            source,
            'dyno_history',
            750
        ) then

            return {}
        end

        local ok =
            allowed(
                source,
                'service'
            )

        if not ok then
            return {}
        end

        plate =
            tostring(
                plate or ''
            ):match(
                '^%s*(.-)%s*$'
            )

        if plate ~= '' then

            return MySQL.query.await(
                [[
                    SELECT
                        plate,
                        model,
                        mechanic_name,
                        horsepower,
                        torque,
                        top_speed,
                        zero_to_hundred,
                        tested_at
                    FROM rs_dyno_history
                    WHERE plate = ?
                    ORDER BY id DESC
                    LIMIT 25
                ]],
                { plate }
            )

        end

        return MySQL.query.await(
            [[
                SELECT
                    plate,
                    model,
                    mechanic_name,
                    horsepower,
                    torque,
                    top_speed,
                    zero_to_hundred,
                    tested_at
                FROM rs_dyno_history
                ORDER BY id DESC
                LIMIT 50
            ]]
        )

    end
)

-- =========================================================
-- EMPLOYEES
-- =========================================================

lib.callback.register(
    'rs-bikemechanic:employees',
    function(source)

        source =
            onlineSource(source)

        if not source then
            return {}
        end

        if not throttle(
            source,
            'employees_read',
            1500
        ) then

            return {}
        end

        local ok =
            allowed(
                source,
                'employees'
            )

        if not ok then
            return {}
        end

        local rows =
            MySQL.query.await(
                [[
                    SELECT
                        identifier,
                        firstname,
                        lastname,
                        job,
                        job_grade
                    FROM users
                    WHERE job = ?
                    ORDER BY
                        job_grade DESC,
                        firstname ASC,
                        lastname ASC
                ]],
                {
                    Config.JobName
                }
            ) or {}

        for _, row in ipairs(rows) do

            local grade =
                tonumber(
                    row.job_grade
                ) or 0

            row.rank =
                Config.ESXGradeToRank[grade]
                or grade

            row.player_name =
                (
                    (row.firstname or '')
                    .. ' '
                    .. (row.lastname or '')
                ):match(
                    '^%s*(.-)%s*$'
                )

            row.on_duty = 0

            for _, playerId
                in ipairs(GetPlayers()) do

                local id =
                    tonumber(playerId)

                local player =
                    ESX.GetPlayerFromId(id)

                if player
                    and player.identifier
                        == row.identifier then

                    row.on_duty =
                        currentDuty(
                            id,
                            player,
                            player.getJob()
                        )
                        and 1
                        or 0

                    break
                end

            end

        end

        return rows
    end
)

local function onlineByIdentifier(id)

    for _, playerId
        in ipairs(GetPlayers()) do

        local source =
            tonumber(playerId)

        local player =
            ESX.GetPlayerFromId(source)

        if player
            and player.identifier == id then

            return source
        end

    end

    return nil
end

lib.callback.register(
    'rs-bikemechanic:employeeAction',
    function(
        source,
        action,
        targetValue,
        desiredRank
    )

        source =
            onlineSource(source)

        if not source then
            return false,
                'Speler niet online.'
        end

        if not throttle(
            source,
            'employee',
            750
        ) then

            return false,
                'Wacht even.'
        end

        local ok, actor =
            allowed(
                source,
                'employees'
            )

        if not ok then
            return false,
                'Geen toegang.'
        end

        local actorRules =
            actor.rankData

        local targetSource
        local targetId
        local targetName
        local targetRank

        -- HIRE
        if action == 'hire' then

            targetSource =
                onlineSource(targetValue)

            if not targetSource then
                return false,
                    'Speler moet online zijn.'
            end

            local target =
                ESX.GetPlayerFromId(
                    targetSource
                )

            if not target then
                return false,
                    'ESX speler niet gevonden.'
            end

            if isMechanicJob(
                target.getJob()
            ) then

                return false,
                    'Deze speler is al medewerker.'
            end

            targetId =
                target.identifier

            targetName =
                playerName(targetSource)

            targetRank = 0

            target.setJob(
                Config.JobName,
                Config.RankToESXGrade[0] or 0
            )

            dutyState[targetSource] =
                false

        else

            targetId =
                tostring(
                    targetValue or ''
                )

            targetSource =
                onlineByIdentifier(
                    targetId
                )

            if not targetSource then
                return false,
                    'Medewerker moet online zijn.'
            end

            local target =
                ESX.GetPlayerFromId(
                    targetSource
                )

            if not target then
                return false,
                    'Medewerker niet gevonden.'
            end

            local job =
                target.getJob()

            if not isMechanicJob(job) then
                return false,
                    'Medewerker niet gevonden.'
            end

            targetName =
                playerName(targetSource)

            targetRank =
                Config.ESXGradeToRank[
                    tonumber(job.grade) or 0
                ]
                or tonumber(job.grade)
                or 0

            if targetId
                == actor.identifier then

                return false,
                    'Je kunt jezelf niet beheren.'
            end

            if targetRank >= actor.rank then
                return false,
                    'Je kunt deze medewerker niet beheren.'
            end

            if targetRank
                > (actorRules.maxManageRank or -1) then

                return false,
                    'Deze medewerker heeft een te hoge rang.'
            end

            if action == 'setRank' then

                desiredRank =
                    math.floor(
                        tonumber(
                            desiredRank
                        ) or -1
                    )

                if not rankData(
                    desiredRank
                ) then

                    return false,
                        'Ongeldige rang.'
                end

                if desiredRank
                    >= actor.rank then

                    return false,
                        'Je kunt iemand niet op je eigen rang zetten.'
                end

                if desiredRank
                    > (actorRules.maxManageRank or -1) then

                    return false,
                        'Deze rang mag je niet geven.'
                end

                target.setJob(
                    Config.JobName,
                    Config.RankToESXGrade[
                        desiredRank
                    ] or desiredRank
                )

                dutyState[targetSource] =
                    false

            elseif action == 'fire' then

                target.setJob(
                    Config.UnemployedJob,
                    Config.UnemployedGrade
                )

                dutyState[targetSource] =
                    nil

            else

                return false,
                    'Onbekende actie.'
            end

        end

        if targetSource then

            profiles[targetSource] = nil

            TriggerClientEvent(
                'rs-bikemechanic:profileChanged',
                targetSource
            )

        end

        log(
            'employees',
            action == 'hire'
                and 'Medewerker aangenomen'
                or action == 'fire'
                and 'Medewerker ontslagen'
                or 'Rang gewijzigd',
            source,
            {

                {
                    name = 'Medewerker',
                    value = targetName,
                    inline = true
                },

                {
                    name = 'Actie',
                    value = action,
                    inline = true
                },

                {
                    name = 'Nieuwe rang',
                    value =
                        action == 'setRank'
                        and rankData(
                            desiredRank
                        ).label
                        or action == 'hire'
                        and rankData(0).label
                        or '-',
                    inline = true
                }

            }
        )

        return true,
            'ESX medewerkerbestand bijgewerkt.'

    end
)

-- =========================================================
-- OWNER COMMAND
-- =========================================================

RegisterCommand(
    'rsbikeowner',
    function(source, args)

        if source ~= 0
            and not IsPlayerAceAllowed(
                source,
                Config.OwnerAce
            ) then

            return
        end

        local target =
            onlineSource(args[1])

        if not target then

            print(
                'Gebruik: /rsbikeowner [server-id]'
            )

            return
        end

        local player =
            ESX.GetPlayerFromId(target)

        if not player then
            return
        end

        player.setJob(
            Config.JobName,
            Config.RankToESXGrade[6] or 6
        )

        dutyState[target] = true
        profiles[target] = nil

        TriggerClientEvent(
            'rs-bikemechanic:profileChanged',
            target
        )

        log(
            'employees',
            'RS Mechanic eigenaar ingesteld',
            source ~= 0 and source or nil,
            {
                {
                    name = 'Medewerker',
                    value = playerName(target)
                }
            }
        )

    end,
    false
)

-- =========================================================
-- DATABASE CHECK
-- =========================================================

CreateThread(function()

    Wait(1000)

    local ok, present =
        pcall(
            MySQL.scalar.await,
            [[
                SELECT COUNT(*)
                FROM information_schema.tables
                WHERE table_schema = DATABASE()
                AND table_name IN (
                    'users',
                    'rs_bikemechanic_service_history',
                    'rs_bikemechanic_vehicle_software',
                    'rs_dyno_history'
                )
            ]]
        )

    if not ok or tonumber(present) ~= 4 then

        print(
            '^1[rs-bikemechanic] Database niet compleet. Importeer sql/install.sql.^7'
        )

        return
    end

    print(
        '^2[rs-bikemechanic] RS Mechanic ESX actief - job: '
        .. Config.JobName
        .. ' | Dyno geïntegreerd.^7'
    )

end)

-- =========================================================
-- CLEANUP
-- =========================================================

AddEventHandler(
    'playerDropped',
    function()

        local source = source

        profiles[source] = nil
        dutyState[source] = nil
        pendingServices[source] = nil
        pendingDynos[source] = nil

        local prefix =
            tostring(source) .. ':'

        for key in pairs(
            actionCooldown
        ) do

            if key:sub(
                1,
                #prefix
            ) == prefix then

                actionCooldown[key] = nil

            end

        end

    end
)