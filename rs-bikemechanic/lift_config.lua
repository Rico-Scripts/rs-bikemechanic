-- RS Bike Mechanic - Moto Lift configuration

Config.MotoLift = {
    enabled = true,

    -- Vervang alleen dit model zodra de Blender/CodeWalker export klaar is.
    model = 'rs_moto_lift',

    -- Tijdelijke fallback zodat de scriptlaag al getest kan worden vóór de echte prop bestaat.
    fallbackModel = 'prop_tool_bench02_ld',

    targetDistance = 2.0,
    serverDistance = 5.0,
    vehicleRadius = 3.0,
    vehicleOffsetZ = 0.35,
    vehicleHeadingOffset = 0.0,

    raiseHeight = 0.92,
    moveDuration = 2500,
    cooldown = 1500,

    locations = {
        main = {
            coords = vec3(1147.65, -789.35, 56.42),
            heading = 90.0
        }
    }
}
