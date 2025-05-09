local QBCore = exports['qb-core']:GetCoreObject()

RegisterServerEvent('qb-methrun:GiveBriefcase', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.AddItem('briefcase', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['briefcase'], 'add')
end)

RegisterServerEvent('qb-methrun:Payout', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local amount = math.random(80000, 100000)
    Player.Functions.RemoveItem('briefcase', 1)
    Player.Functions.AddItem('unmarked_money', amount)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items['unmarked_money'], 'add')
    TriggerClientEvent('QBCore:Notify', src, "You received $" .. amount .. " unmarked money!", 'success')
end)