local QBCore = exports['qb-core']:GetCoreObject()
local methRunActive = false
local deliveryBlip = nil
local ambushBlip = nil
local returnBlip = nil
local carEntity = nil

local function loadModel(model)
    local modelHash = type(model) == 'number' and model or GetHashKey(model)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do Wait(10) end
    return modelHash
end

local function createPed()
    local model = loadModel('g_m_m_mexboss_01')
    local coords = Config.StartPed.coords
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    exports.ox_target:addLocalEntity(ped, {
        {
            label = 'Start Meth Run',
            icon = 'fa-solid fa-vial',
            onSelect = function()
                StartMethRun()
            end
        }
    })
end

function StartMethRun()
    if methRunActive then
        lib.notify({ title = 'Meth Run', description = 'You are already on a run.', type = 'error' })
        return
    end

    local items = exports.ox_inventory:Search('slots', 'methbags')
    local count = 0
    for _, item in pairs(items) do
        count += item.count
    end

    if count < 10 then
        lib.notify({ title = 'Meth Run', description = 'You need 10 methbags!', type = 'error' })
        return
    end

    TriggerServerEvent('ox_inventory:removeItem', 'methbags', 10)
    methRunActive = true

    lib.notify({ title = 'Meth Run', description = 'Go to the GPS location.', type = 'inform' })
    deliveryBlip = AddBlipForCoord(Config.FirstDropoff)
    SetBlipRoute(deliveryBlip, true)

    CreateThread(function()
        local delivered = false
        while not delivered do
            Wait(2)
            local coords = GetEntityCoords(PlayerPedId())
            if #(coords - Config.FirstDropoff) < 15.0 then
                delivered = true
                RemoveBlip(deliveryBlip)
                SpawnMethCar()
            end
        end
    end)
end

function SpawnMethCar()
    local model = loadModel(Config.MethDeliveryCar)
    carEntity = CreateVehicle(model, Config.FirstDropoff.x, Config.FirstDropoff.y, Config.FirstDropoff.z, 0.0, true, false)
    TaskWarpPedIntoVehicle(PlayerPedId(), carEntity, -1)

    CreateThread(function()
        while true do
            Wait(1000)
            if IsPedInVehicle(PlayerPedId(), carEntity, false) then
                SetNewWaypoint(Config.AmbushLocation.x, Config.AmbushLocation.y)
                break
            end
        end
    end)

    CreateThread(function()
        local ambushed = false
        while not ambushed do
            Wait(2000)
            if #(GetEntityCoords(PlayerPedId()) - Config.AmbushLocation) < 30.0 then
                ambushed = true
                SpawnGuards()
            end
        end
    end)
end

function SpawnGuards()
    for _, coords in pairs(Config.AmbushGuards) do
        local pedModel = loadModel('g_m_y_mexgoon_01')
        local ped = CreatePed(0, pedModel, coords.x, coords.y, coords.z, coords.w, true, false)
        GiveWeaponToPed(ped, `WEAPON_SMG`, 250, false, true)
        TaskCombatPed(ped, PlayerPedId(), 0, 16)
    end

    Wait(10000) -- simplified wait for combat
    SpawnHandoverPed()
end

function SpawnHandoverPed()
    local model = loadModel('g_m_m_mexboss_01')
    local coords = Config.HandoverPed
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            label = 'Handover Meth',
            icon = 'fa-solid fa-briefcase',
            onSelect = function()
                DeleteEntity(ped)
                TriggerServerEvent('qb-methrun:server:StartPDAlert', GetEntityCoords(carEntity))
                StartTracking()
            end
        }
    })
end

function StartTracking()
    lib.notify({ title = 'Meth Run', description = 'Police have been alerted. You are being tracked!', type = 'error' })

    Wait(1 * 60000)

    lib.notify({ title = 'Meth Run', description = 'Tracker disabled. Go to drop-off point.', type = 'inform' })
    returnBlip = AddBlipForCoord(Config.FinalReturn.coords)
    SetBlipRoute(returnBlip, true)

    CreateThread(function()
        while true do
            Wait(2000)
            if #(GetEntityCoords(PlayerPedId()) - Config.FinalReturn.coords) < 15.0 then
                SpawnReturnPed()
                break
            end
        end
    end)
end

function SpawnReturnPed()
    local model = loadModel('g_m_m_mexboss_01')
    local coords = Config.FinalReturn.ped
    local ped = CreatePed(0, model, coords.x, coords.y, coords.z, coords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports.ox_target:addLocalEntity(ped, {
        {
            label = 'Return Vehicle',
            icon = 'fa-solid fa-sack-dollar',
            onSelect = function()
                TriggerServerEvent('qb-methrun:server:CompleteRun')
                DeleteEntity(carEntity)
                DeleteEntity(ped)
                RemoveBlip(returnBlip)
                methRunActive = false
            end
        }
    })
end

CreateThread(function()
    Wait(1000)
    createPed()
end)
