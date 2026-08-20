-- Server-side compatibility for client-only GET_VEHICLE_CLASS.
-- FiveM exposes GET_VEHICLE_TYPE server-side, so translate the only
-- vehicle groups this resource supports into representative GTA classes.

if type(GetVehicleClass) ~= 'function' then
    local serverGetVehicleType = GetVehicleType

    function GetVehicleClass(entity)
        if not entity or entity == 0 then
            return nil
        end

        if type(serverGetVehicleType) ~= 'function' then
            return nil
        end

        local ok, vehicleType = pcall(serverGetVehicleType, entity)

        if not ok then
            return nil
        end

        if vehicleType == 'bike' then
            return Config.MotorcycleClass or 8
        end

        if vehicleType == 'automobile' then
            return 0
        end

        -- Unsupported types (boat/heli/plane/trailer/train/etc.) deliberately
        -- return nil so Config.VehicleClasses rejects them.
        return nil
    end
end
