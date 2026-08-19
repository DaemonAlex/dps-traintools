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
    if GetEntitySpeed(carriage) > 1.5 then return end  -- no boarding moving trains
    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(carriage))
    for seat = 0, seats - 2 do
        if IsVehicleSeatFree(carriage, seat) then
            TaskWarpPedIntoVehicle(ped, carriage, seat)
            return
        end
    end
    -- no native seat bones: attach-seat with a spot fitted to the car type.
    -- Engines seat you up in the cab; the caboose puts you on its deck;
    -- coaches spread riders along the car. (Job-gating for engine/caboose
    -- comes later - for now anyone can ride anywhere.)
    local model = GetEntityArchetypeName(carriage) or ''
    local off
    if model:find('streak') and not model:find('c$') and not model:find('cab') or model == 'sd70mac' or model == 'gevo' then
        -- engine cab: high floor, near the rear of the cab
        off = { x = 0.55 * (math.random(0, 1) == 0 and 1 or -1), y = 5.5, z = 1.35 }
    elseif model == 'freightcaboose' or model:find('cab') then
        -- caboose / cab car: center deck
        off = { x = 0.5 * (math.random(0, 1) == 0 and 1 or -1), y = math.random(-20, 20) / 10.0, z = 1.05 }
    else
        off = { x = 0.9 * (math.random(0, 1) == 0 and 1 or -1), y = math.random(-60, 60) / 10.0, z = 0.6 }
    end
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

-- riding state covers BOTH modes: attach-seated (coaches) and native seats
-- (e.g. the engine cab), so every rider always gets the prompt
local stopRequested = false


-- boarding is only offered at platforms: train must be STOPPED and the
-- player within 60m of a station (matches the station blip list)
local STATIONS = {
    vec3(-446.82, 5362.51, 80.67), vec3(111.85, 6317.60, 30.69),
    vec3(2599.30, 2912.57, 38.57), vec3(2450.27, 2482.35, 41.07),
    vec3(2610.99, 1649.71, 26.62), vec3(669.27, -1104.79, 22.74),
    vec3(217.43, -2436.63, 6.21),  vec3(1870.67, 3544.59, 37.67),
    vec3(243.68, -1198.62, 37.05), vec3(-549.43, -1290.78, 24.91),
    vec3(-900.24, -2343.76, -13.65), vec3(-1104.42, -2728.99, -9.32),
    vec3(-1067.23, -2708.14, -9.32), vec3(-866.52, -2294.89, -13.63),
    vec3(-528.64, -1267.25, 24.90), vec3(284.76, -1209.94, 37.12),
    vec3(-287.12, -301.92, 8.15),  vec3(-848.52, -148.13, 18.04),
}
local function atStation(pos)
    for i = 1, #STATIONS do
        if #(pos - STATIONS[i]) < 60.0 then return true end
    end
    return false
end

local function ridingCarriage()
    if seated then return seated.carriage end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if GetVehicleClass(veh) == 21 then return veh end
    end
    return nil
end

-- proximity prompt state machine:
--   near a coach            -> [E] Board Train
--   riding, train stopped   -> [E] Disembark            (immediate)
--   riding, train moving    -> [E] Disembark at next stop (requests the stop)
--   stop requested          -> auto-steps you off when the train halts
CreateThread(function()
    while true do
        local want = nil
        local carriage = ridingCarriage()
        if carriage then
            local speed = GetEntitySpeed(carriage)
            if speed < 1.5 then
                if stopRequested then
                    stopRequested = false
                    doDisembark()
                    want = nil
                else
                    want = 'off_now'
                end
            elseif stopRequested then
                want = 'queued'
            else
                want = 'off_next'
            end
        else
            stopRequested = false
            local ped = PlayerPedId()
            if not IsPedInAnyVehicle(ped, false) then
                local c = nearestCarriage(5.5)
                -- stopped train + at a platform = boarding allowed
                if c and GetEntitySpeed(c) < 1.5 and atStation(GetEntityCoords(ped)) then
                    want = 'board'
                end
            end
        end

        if want ~= promptShown then
            if want == 'board' then
                lib.showTextUI('[E] Board Train', { position = 'right-center', icon = 'train' })
            elseif want == 'off_now' then
                lib.showTextUI('[E] Disembark', { position = 'right-center', icon = 'person-walking-arrow-right' })
            elseif want == 'off_next' then
                lib.showTextUI('[E] Disembark at next stop', { position = 'right-center', icon = 'person-walking-arrow-right' })
            elseif want == 'queued' then
                lib.showTextUI('Disembarking at next stop...', { position = 'right-center', icon = 'clock' })
            else
                lib.hideTextUI()
            end
            promptShown = want
        end

        if want then
            Wait(0)
            if IsControlJustPressed(0, 38) then  -- E
                if want == 'board' then
                    doBoard()
                elseif want == 'off_now' then
                    doDisembark()
                elseif want == 'off_next' then
                    stopRequested = true
                elseif want == 'queued' then
                    stopRequested = false  -- changed your mind
                end
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


-- DPS: blip sprite preview - /blippreview <id> drops a test blip at your
-- position with that sprite so icon candidates can be judged on the real map.
-- /blippreview with no arg removes it.
local previewBlip = nil
RegisterCommand('blippreview', function(_, args)
    if previewBlip then RemoveBlip(previewBlip) previewBlip = nil end
    local id = tonumber(args[1])
    if not id then print('[blippreview] cleared') return end
    local pos = GetEntityCoords(PlayerPedId())
    previewBlip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(previewBlip, id)
    SetBlipScale(previewBlip, 0.8)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('PREVIEW sprite %d'):format(id))
    EndTextCommandSetBlipName(previewBlip)
    print(('[blippreview] showing sprite %d on your map'):format(id))
end, false)


-- ============================================
-- NPC RIDERS (DPS)
-- Passenger coaches get local (non-networked) civilian riders - pure
-- atmosphere at zero network cost; each client dresses trains it can see.
-- ============================================
local RIDERS = {
    minPerCoach = 2,
    maxPerCoach = 4,
    hoboChance = 20,          -- % chance the caboose carries a stowaway
    models = {
        'a_m_m_business_01', 'a_f_y_business_02', 'a_m_y_vinewood_01',
        'a_f_y_tourist_01', 'a_m_m_skater_01', 'a_f_m_bodybuild_01',
        'a_m_y_stbla_02', 'a_f_y_hipster_02', 'a_m_m_farmer_01',
        'a_m_y_genstreet_01',
    },
}
local dressedTrains = {}   -- [engineEntity] = { peds = {...}, members = {...} }
local carriageOwner = {}   -- [carriageEntity] = engineEntity, so a train is dressed once

local function spawnRider(carriage, off)
    local model = RIDERS.models[math.random(#RIDERS.models)]
    local hash = lib.requestModel(model, 3000)
    if not hash then return nil end
    local pos = GetEntityCoords(carriage)
    local ped = CreatePed(4, hash, pos.x, pos.y, pos.z + 1.0, 0.0, false, false)  -- LOCAL ped
    SetModelAsNoLongerNeeded(hash)
    if not DoesEntityExist(ped) then return nil end
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    AttachEntityToEntity(ped, carriage, 0, off.x, off.y, off.z, 0.0, 0.0, off.h or 90.0, false, true, false, true, 2, true)
    lib.requestAnimDict('anim@amb@business@bgen@bgen_no_work@', 3000)
    TaskPlayAnim(ped, 'anim@amb@business@bgen@bgen_no_work@', 'sit_phone_phoneputdown_idle_nowork', 8.0, 8.0, -1, 1, 1.0, false, false, false)
    return ped
end

local function dressTrain(engine)
    local bucket = { peds = {}, members = {} }
    dressedTrains[engine] = bucket
    carriageOwner[engine] = engine
    for i = 0, 12 do
        local c = GetTrainCarriage(engine, i)
        if not c or c == 0 or not DoesEntityExist(c) then break end
        bucket.members[#bucket.members + 1] = c
        carriageOwner[c] = engine
        local model = GetEntityArchetypeName(c) or ''
        if model == 'streakc' or model == 'streakcoasterc' then
            for _ = 1, math.random(RIDERS.minPerCoach, RIDERS.maxPerCoach) do
                local off = { x = 0.9 * (math.random(0, 1) == 0 and 1 or -1),
                              y = math.random(-60, 60) / 10.0, z = 0.6,
                              h = math.random(0, 1) == 0 and 90.0 or 270.0 }
                local ped = spawnRider(c, off)
                if ped then bucket.peds[#bucket.peds + 1] = ped end
                Wait(50)
            end
        elseif model == 'freightcaboose' and math.random(100) <= RIDERS.hoboChance then
            local ped = spawnRider(c, { x = 0.0, y = -1.5, z = 1.05, h = 180.0 })
            if ped then bucket.peds[#bucket.peds + 1] = ped end
        end
    end
end

CreateThread(function()
    while true do
        Wait(5000)
        -- dress newly-seen trains. EVERY carriage is vehicle class 21, so resolve
        -- each to its engine and dress once per engine (was dressing per-carriage
        -- -> ~Nx rider overspawn and stale dressedTrains keys).
        for _, veh in ipairs(GetGamePool('CVehicle')) do
            -- EVERY carriage is vehicle class 21, so this pool contains the whole
            -- consist. Dress once per train: only an entity that actually has a
            -- second carriage is treated as the head, and anything already claimed
            -- by a dressed train is skipped. (An earlier version called
            -- GetTrainCarriageEngine, which is NOT a real native and errored here.)
            if GetVehicleClass(veh) == 21 and not dressedTrains[veh] and not carriageOwner[veh] then
                local second = GetTrainCarriage(veh, 1)
                if second and second ~= 0 and DoesEntityExist(second) then
                    dressTrain(veh)
                end
            end
        end
        -- clean up riders whose train left our world
        for engine, bucket in pairs(dressedTrains) do
            if not DoesEntityExist(engine) then
                for _, ped in ipairs(bucket.peds) do
                    if DoesEntityExist(ped) then DeleteEntity(ped) end
                end
                for _, c in ipairs(bucket.members or {}) do
                    carriageOwner[c] = nil
                end
                carriageOwner[engine] = nil
                dressedTrains[engine] = nil
            end
        end
    end
end)

-- Clean up everything this resource spawned on stop/restart (it exists to be
-- redeployed independently, so leaks would accumulate every deploy)
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for engine, bucket in pairs(dressedTrains) do
        for _, ped in ipairs(bucket.peds) do
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end
        dressedTrains[engine] = nil
    end
    if seated then
        DetachEntity(PlayerPedId(), true, true)
        ClearPedTasks(PlayerPedId())
        seated = nil
    end
    if previewBlip then RemoveBlip(previewBlip) previewBlip = nil end
end)
