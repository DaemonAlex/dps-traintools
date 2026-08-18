-- DPS railway rider tools. Separate resource so deploying it never restarts
-- dps-trains (which would reset every train to its spawn).

local seated = nil  -- { carriage = ent } when attached (no-native-seat mode)

local function nearestCarriage(maxDist)
    local pos = GetEntityCoords(PlayerPedId())
    local best, bestDist = nil, maxDist
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        if GetVehicleClass(veh) == 21 then
            for i = -1, 12 do
                local c = (i == -1) and veh or GetTrainCarriage(veh, i)
                if c and c ~= 0 and DoesEntityExist(c) then
                    local d = #(GetEntityCoords(c) - pos)
                    if d < bestDist then best, bestDist = c, d end
                end
            end
        end
    end
    return best
end

RegisterCommand('board', function()
    local ped = PlayerPedId()
    if seated then return end
    local carriage = nearestCarriage(14.0)
    if not carriage then
        print('[board] no train carriage within 14m')
        return
    end
    -- try real seats first
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(carriage))
    for seat = 0, seats - 2 do
        if IsVehicleSeatFree(carriage, seat) then
            TaskWarpPedIntoVehicle(ped, carriage, seat)
            print(('[board] native seat %d'):format(seat))
            return
        end
    end
    -- no native passenger seats: attach seated inside the coach (metro style)
    local off = { x = 0.9 * (math.random(0, 1) == 0 and 1 or -1), y = math.random(-60, 60) / 10.0, z = 0.6 }
    AttachEntityToEntity(ped, carriage, 0, off.x, off.y, off.z, 0.0, 0.0, 90.0, false, true, false, true, 2, true)
    RequestAnimDict('anim@amb@business@bgen@bgen_no_work@')
    local deadline = GetGameTimer() + 3000
    while not HasAnimDictLoaded('anim@amb@business@bgen@bgen_no_work@') and GetGameTimer() < deadline do Wait(10) end
    TaskPlayAnim(ped, 'anim@amb@business@bgen@bgen_no_work@', 'sit_phone_phoneputdown_idle_nowork', 8.0, 8.0, -1, 1, 1.0, false, false, false)
    seated = { carriage = carriage }
    print('[board] attached-seat mode (coach has no native seats)')
end, false)

RegisterCommand('disembark', function()
    local ped = PlayerPedId()
    if seated then
        DetachEntity(ped, true, true)
        ClearPedTasks(ped)
        local c = seated.carriage
        seated = nil
        if DoesEntityExist(c) then
            local pos = GetOffsetFromEntityInWorldCoords(c, 2.5, 0.0, 0.5)
            SetEntityCoords(ped, pos.x, pos.y, pos.z, false, false, false, false)
        end
        print('[disembark] off the train')
    elseif IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 0)
    end
end, false)

-- seat-mapping survey tool: stand at a seat spot, /seatmark, offsets log server-side
RegisterCommand('seatmark', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local carriage = nearestCarriage(30.0)
    if not carriage then print('[seatmark] no carriage in 30m') return end
    local off = GetOffsetFromEntityGivenWorldCoords(carriage, pos.x, pos.y, pos.z)
    local relHeading = (GetEntityHeading(ped) - GetEntityHeading(carriage)) % 360.0
    local model = GetEntityArchetypeName(carriage) or 'unknown'
    TriggerServerEvent('dps-traintools:seatmark',
        ('model=%s vec4(%.4f, %.4f, %.4f, %.4f)'):format(model, off.x, off.y, off.z, relHeading))
    print(('[seatmark] logged %s %.2f %.2f %.2f'):format(model, off.x, off.y, off.z))
end, false)
