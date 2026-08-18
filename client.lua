-- DPS railway rider tools. Separate resource so deploys never restart
-- dps-trains (which would reset every train to its spawn).

local seated = nil   -- { carriage = ent } while attach-seated
local promptShown = nil

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

local function doBoard()
    local ped = PlayerPedId()
    if seated then return end
    local carriage = nearestCarriage(8.0)
    if not carriage then return end
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(carriage))
    for seat = 0, seats - 2 do
        if IsVehicleSeatFree(carriage, seat) then
            TaskWarpPedIntoVehicle(ped, carriage, seat)
            return
        end
    end
    -- coaches ship no native seat bones: attach-seat inside the car instead
    local off = { x = 0.9 * (math.random(0, 1) == 0 and 1 or -1), y = math.random(-60, 60) / 10.0, z = 0.6 }
    AttachEntityToEntity(ped, carriage, 0, off.x, off.y, off.z, 0.0, 0.0, 90.0, false, true, false, true, 2, true)
    lib.requestAnimDict('anim@amb@business@bgen@bgen_no_work@', 3000)
    TaskPlayAnim(ped, 'anim@amb@business@bgen@bgen_no_work@', 'sit_phone_phoneputdown_idle_nowork', 8.0, 8.0, -1, 1, 1.0, false, false, false)
    seated = { carriage = carriage }
end

local function doDisembark()
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
    elseif IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 0)
    end
end

-- proximity prompt: near a coach -> [E] Board; while riding -> [E] Disembark
CreateThread(function()
    while true do
        local want = nil
        if seated then
            want = 'disembark'
        else
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) and nearestCarriage(5.5) then
                want = 'board'
            end
        end

        if want ~= promptShown then
            if want == 'board' then
                lib.showTextUI('[E] Board Train', { position = 'right-center', icon = 'train' })
            elseif want == 'disembark' then
                lib.showTextUI('[E] Disembark', { position = 'right-center', icon = 'person-walking-arrow-right' })
            else
                lib.hideTextUI()
            end
            promptShown = want
        end

        if want then
            Wait(0)
            if IsControlJustPressed(0, 38) then  -- E
                if want == 'board' then doBoard() else doDisembark() end
            end
        else
            Wait(600)
        end
    end
end)

RegisterCommand('board', doBoard, false)
RegisterCommand('disembark', doDisembark, false)

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
