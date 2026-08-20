Config = {}

Config.NotifyTitle = 'Rico Scripts RS Mechanic'

Config.TabletCommand = 'rsmechanic'
Config.TabletKey = 'F6'

Config.CurrencyMode = 'cash' -- cash / bank

-- =========================================================
-- ESX JOB
-- =========================================================

Config.JobName = 'rsmechanic'
Config.JobLabel = 'RS Mechanic'

Config.UnemployedJob = 'unemployed'
Config.UnemployedGrade = 0

-- ESX grade -> RS Mechanic rank
Config.ESXGradeToRank = {
    [0] = 0,
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,
    [5] = 5,
    [6] = 6
}

-- RS Mechanic rank -> ESX grade
Config.RankToESXGrade = {
    [0] = 0,
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,
    [5] = 5,
    [6] = 6
}

Config.RequireDuty = true

Config.OwnerAce = 'rs.bikemechanic.admin'

-- =========================================================
-- RANKS
-- =========================================================

Config.Ranks = {

    [0] = {
        name = 'trainee',
        label = 'Leerling',
        service = true,
        upgrades = false,
        products = true,
        employees = false
    },

    [1] = {
        name = 'junior',
        label = 'Junior Monteur',
        service = true,
        upgrades = false,
        products = true,
        employees = false
    },

    [2] = {
        name = 'mechanic',
        label = 'Monteur',
        service = true,
        upgrades = true,
        products = true,
        employees = false
    },

    [3] = {
        name = 'senior',
        label = 'Senior Monteur',
        service = true,
        upgrades = true,
        products = true,
        employees = false
    },

    [4] = {
        name = 'chief',
        label = 'Chef Werkplaats',
        service = true,
        upgrades = true,
        products = true,
        employees = true,
        maxManageRank = 3
    },

    [5] = {
        name = 'manager',
        label = 'Manager',
        service = true,
        upgrades = true,
        products = true,
        employees = true,
        maxManageRank = 4
    },

    [6] = {
        name = 'owner',
        label = 'Eigenaar',
        service = true,
        upgrades = true,
        products = true,
        employees = true,
        maxManageRank = 5
    }

}

-- =========================================================
-- VEHICLES
-- =========================================================

Config.VehicleClasses = {

    [0] = 'car',
    [1] = 'car',
    [2] = 'car',
    [3] = 'car',
    [4] = 'car',
    [5] = 'car',
    [6] = 'car',
    [7] = 'car',

    -- Motorcycles
    [8] = 'motorcycle',

    [9] = 'car',
    [10] = 'car',
    [11] = 'car',
    [12] = 'car',
    [13] = 'car',
    [14] = 'car',
    [15] = 'car',
    [16] = 'car',
    [17] = 'car',
    [18] = 'car',
    [19] = 'car',
    [20] = 'car',
    [21] = 'car'
}

Config.MotorcycleClass = 8

Config.TargetDistance = 2.2
Config.MaxVehicleDistance = 4.0

-- =========================================================
-- WERKPLAATS
-- =========================================================

Config.WorkZones = {

    {
        coords = vec3(1147.1097, -792.4723, 56.4206),
        radius = 16.0
    }

}

-- =========================================================
-- DYNO
-- =========================================================

Config.Stations = {

    main = {

        label = 'RS Mechanic Dyno',
        
        coords = vec3(1151.30, -794.50, 56.42),

        heading = 90.0,

        radius = 4.0,

        maxVehicleDistance = 5.0,

        targetIcon = 'fa-solid fa-gauge-high',

        targetLabel = 'Dynotest starten',

        allowedTypes = {
            car = true,
            motorcycle = true
        }

    }

}

Config.Dyno = {

    enabled = true,

    duration = 15000,

    alignmentTolerance = 4.0,

    headingTolerance = 20.0,

    freezeVehicle = true,

    modelMultipliers = {

        -- Voorbeelden
        adder = 1.00,
        t20 = 1.02,
        bati = 1.00,
        bati2 = 1.02

    },

    modelPower = {

        car = {
            baseHorsepower = 220,
            baseTorque = 280
        },

        motorcycle = {
            baseHorsepower = 95,
            baseTorque = 110
        }

    }

}

Config.Dyno.Security = {

    maxHorsepower = 5000,

    maxTorque = 5000,

    maxTopSpeed = 500,

    maxZeroToHundred = 60

}

-- =========================================================
-- SOFTWARE
-- =========================================================

Config.Software = {

    enabled = true,

    cacheTime = 10000,

    turboBoostRpm = 0.62,

    soundDistance = 28.0,

    sounds = {

        dumpValve = {
            file = 'dumpvalve',
            volume = 0.62
        },

        antilag = {
            file = 'antilag_pop',
            volume = 0.72
        },

        launch = {
            file = 'antilag_pop',
            volume = 0.82
        }

    },

    dumpValve = {

        enabled = true,

        minRpm = 0.42,

        minThrottle = 0.45,

        cooldown = 650,

        requiresTurbo = true

    },

    antilag = {

        enabled = true,

        minRpm = 0.34,

        minSpeed = 3.0,

        cooldown = 260,

        chance = 92,

        burstMin = 1,

        burstMax = 3,

        scale = 1.35

    },

    launchControl = {

        enabled = true,

        maxSpeed = 2.0,

        minRpm = 0.42,

        cooldown = 380,

        launchSpeed = 18.0,

        scale = 1.25

    }

}

-- =========================================================
-- PERFORMANCE
-- =========================================================

Config.Performance = {

    stage2 = {

        power = 18.0,

        torque = 1.12,

        dynoMultiplier = 1.12

    },

    sportExhaust = {

        power = 5.0,

        torque = 1.04,

        dynoMultiplier = 1.04

    },

    exhaustSound = {

        enabled = true,

        minRpm = 0.38,

        cooldown = 520,

        chance = 65,

        scale = 1.10,

        file = 'antilag_pop',

        volume = 0.88

    }

}

-- =========================================================
-- SHOP
-- =========================================================

Config.Shop = {

    coords = vec3(1142.9900, -786.6000, 58.1100),

    radius = 1.5,

    label = 'Onderdelenmagazijn',

    items = {

        {
            name = 'rs_bikemechanic_tablet',
            label = 'Werkplaatstablet',
            price = 500,
            minRank = 0,
            image = 'rs_bikemechanic_tablet.svg'
        },

        {
            name = 'rs_moto_engine_oil',
            label = 'Motorolie',
            price = 75,
            minRank = 0,
            image = 'rs_moto_engine_oil.svg'
        },

        {
            name = 'rs_moto_spark_plugs',
            label = 'Bougies',
            price = 120,
            minRank = 0,
            image = 'rs_moto_spark_plugs.svg'
        },

        {
            name = 'rs_moto_brake_pads',
            label = 'Motor remblokken',
            price = 160,
            minRank = 0,
            image = 'rs_moto_brake_pads.svg'
        },

        {
            name = 'rs_moto_chain',
            label = 'Motorketting',
            price = 220,
            minRank = 1,
            image = 'rs_moto_chain.svg'
        },

        {
            name = 'rs_moto_tire_set',
            label = 'Motorbandenset',
            price = 300,
            minRank = 1,
            image = 'rs_moto_tire_set.svg'
        },

        {
            name = 'rs_moto_battery',
            label = 'Motoraccu',
            price = 250,
            minRank = 1,
            image = 'rs_moto_battery.svg'
        },

        {
            name = 'rs_moto_clutch_cable',
            label = 'Koppelingskabel',
            price = 140,
            minRank = 1,
            image = 'rs_moto_clutch_cable.svg'
        },

        {
            name = 'rs_moto_turbo_kit',
            label = 'Motor Turbo Kit',
            price = 2800,
            minRank = 2,
            image = 'rs_moto_turbo_kit.svg'
        },

        {
            name = 'rs_moto_ecu',
            label = 'Race ECU',
            price = 1800,
            minRank = 2,
            image = 'rs_moto_ecu.svg'
        },

        {
            name = 'rs_moto_sport_exhaust',
            label = 'Sportuitlaat',
            price = 1250,
            minRank = 2,
            image = 'rs_moto_sport_exhaust.svg'
        },

        {
            name = 'rs_moto_race_brakes',
            label = 'Race-remmenset',
            price = 1500,
            minRank = 2,
            image = 'rs_moto_race_brakes.svg'
        },

        {
            name = 'rs_moto_race_transmission',
            label = 'Race-transmissie',
            price = 2200,
            minRank = 2,
            image = 'rs_moto_race_transmission.svg'
        },

        {
            name = 'rs_moto_sport_suspension',
            label = 'Sportvering',
            price = 1700,
            minRank = 2,
            image = 'rs_moto_sport_suspension.svg'
        },

        {
            name = 'rs_moto_antilag_software',
            label = 'Antilag software',
            price = 2400,
            minRank = 3,
            image = 'rs_moto_antilag_software.svg'
        },

        {
            name = 'rs_moto_launch_control',
            label = '2-step Launch Control',
            price = 2100,
            minRank = 3,
            image = 'rs_moto_launch_control.svg'
        },

        {
            name = 'rs_moto_stage2_software',
            label = 'Stage 2 software',
            price = 3900,
            minRank = 3,
            image = 'rs_moto_stage2_software.svg'
        }

    }

}

-- =========================================================
-- SERVICES
-- =========================================================

Config.Services = {

    engine_oil = {
        category = 'service',
        label = 'Motorolie vervangen',
        item = 'rs_moto_engine_oil',
        count = 1,
        duration = 8500,
        minRank = 0,
        image = 'rs_moto_engine_oil.svg',
        effect = {
            engine = 250.0,
            body = 25.0
        }
    },

    spark_plugs = {
        category = 'service',
        label = 'Bougies vervangen',
        item = 'rs_moto_spark_plugs',
        count = 1,
        duration = 9500,
        minRank = 0,
        image = 'rs_moto_spark_plugs.svg',
        effect = {
            engine = 180.0
        }
    },

    brake_pads = {
        category = 'service',
        label = 'Remblokken vervangen',
        item = 'rs_moto_brake_pads',
        count = 1,
        duration = 9000,
        minRank = 0,
        image = 'rs_moto_brake_pads.svg',
        effect = {
            body = 80.0
        }
    },

    chain = {
        category = 'service',
        label = 'Ketting vervangen',
        item = 'rs_moto_chain',
        count = 1,
        duration = 10500,
        minRank = 1,
        image = 'rs_moto_chain.svg',
        effect = {
            engine = 120.0,
            body = 70.0
        }
    },

    tires = {
        category = 'service',
        label = 'Motorbanden vervangen',
        item = 'rs_moto_tire_set',
        count = 1,
        duration = 12000,
        minRank = 1,
        image = 'rs_moto_tire_set.svg',
        effect = {
            tires = true,
            body = 100.0
        }
    },

    battery = {
        category = 'service',
        label = 'Accu vervangen',
        item = 'rs_moto_battery',
        count = 1,
        duration = 9000,
        minRank = 1,
        image = 'rs_moto_battery.svg',
        effect = {
            engine = 140.0
        }
    },

    turbo = {
        category = 'upgrade',
        label = 'Turbo kit monteren',
        item = 'rs_moto_turbo_kit',
        count = 1,
        duration = 18000,
        minRank = 2,
        image = 'rs_moto_turbo_kit.svg',
        effect = {
            mods = {
                turbo = true
            }
        }
    },

    ecu = {
        category = 'upgrade',
        label = 'Race ECU installeren',
        item = 'rs_moto_ecu',
        count = 1,
        duration = 16000,
        minRank = 2,
        image = 'rs_moto_ecu.svg',
        effect = {
            mods = {
                engine = true
            }
        }
    },

    race_brakes = {
        category = 'upgrade',
        label = 'Race-remmen monteren',
        item = 'rs_moto_race_brakes',
        count = 1,
        duration = 15000,
        minRank = 2,
        image = 'rs_moto_race_brakes.svg',
        effect = {
            mods = {
                brakes = true
            }
        }
    },

    transmission = {
        category = 'upgrade',
        label = 'Race-transmissie monteren',
        item = 'rs_moto_race_transmission',
        count = 1,
        duration = 17000,
        minRank = 2,
        image = 'rs_moto_race_transmission.svg',
        effect = {
            mods = {
                transmission = true
            }
        }
    },

    suspension = {
        category = 'upgrade',
        label = 'Sportvering monteren',
        item = 'rs_moto_sport_suspension',
        count = 1,
        duration = 15000,
        minRank = 2,
        image = 'rs_moto_sport_suspension.svg',
        effect = {
            mods = {
                suspension = true
            }
        }
    },

    exhaust = {
        category = 'upgrade',
        label = 'Sportuitlaat monteren',
        item = 'rs_moto_sport_exhaust',
        count = 1,
        duration = 14000,
        minRank = 2,
        image = 'rs_moto_sport_exhaust.svg',
        effect = {
            mods = {
                exhaust = true
            },
            software = {
                sportExhaust = true
            }
        }
    },

    antilag = {
        category = 'upgrade',
        label = 'Antilag installeren',
        item = 'rs_moto_antilag_software',
        count = 1,
        duration = 13500,
        minRank = 3,
        image = 'rs_moto_antilag_software.svg',
        effect = {
            software = {
                antilag = true
            }
        }
    },

    launch = {
        category = 'upgrade',
        label = '2-step installeren',
        item = 'rs_moto_launch_control',
        count = 1,
        duration = 13000,
        minRank = 3,
        image = 'rs_moto_launch_control.svg',
        effect = {
            software = {
                launchControl = true
            }
        }
    },

    stage2 = {
        category = 'upgrade',
        label = 'Stage 2 installeren',
        item = 'rs_moto_stage2_software',
        count = 1,
        duration = 18000,
        minRank = 3,
        image = 'rs_moto_stage2_software.svg',
        effect = {
            software = {
                antilag = true,
                launchControl = true,
                stage = 2
            }
        }
    }

}