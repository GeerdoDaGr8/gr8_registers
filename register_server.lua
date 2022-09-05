local ox_inventory = exports.ox_inventory

Registers = {
    --NP Burgershot
    {job = 'burgershot', coords = vector3(-1196.34, -890.79, 13.98), l = 0.4, w = 0.85, heading = 34, minZ = 12.98, maxZ = 14.58, amount = 0 },
    {job = 'burgershot', coords = vector3(-1195.5, -892.16, 13.98), l = 0.9, w = 1.0, heading = 34, minZ = 12.98, maxZ = 14.58, amount = 0 },
    {job = 'burgershot', coords = vector3(-1194.4, -893.66, 13.98), l = 0.9, w = 0.9, heading = 34, minZ = 12.98, maxZ = 14.58, amount = 0 },
    --UWU Cafe
    {job = 'cafe', coords = vector3(-584.01, -1061.46, 22.34), l = 0.4, w = 0.4, heading = 0, minZ = 22.14, maxZ = 22.54, amount = 0 },
    {job = 'cafe', coords = vector3(-584.06, -1058.71, 22.34), l = 0.4, w = 0.4, heading = 0, minZ = 22.14, maxZ = 22.54, amount = 0 },
}

RegisterServerEvent('gr8_registers:onJoinStatus')
AddEventHandler('gr8_registers:onJoinStatus', function()
    local _source = source
    TriggerClientEvent('gr8_registers:updateTotal', _source, Registers)
end)

RegisterServerEvent('gr8_registers:createCharge')
AddEventHandler('gr8_registers:createCharge', function(data)
    Registers[data.register].amount = tonumber(data.amount)
    TriggerClientEvent('gr8_registers:updateTotal', -1, Registers)
end)

RegisterServerEvent('gr8_registers:getPaymentForClient')
AddEventHandler('gr8_registers:getPaymentForClient', function(source)
    local _source = source
    TriggerClientEvent('gr8_registers:PaymentClient', _source, OrderTotal)
end)

RegisterServerEvent('gr8_registers:chargeMe')
AddEventHandler('gr8_registers:chargeMe', function(data)
	local _source = source
    if data[1] == 'Credit' then
        local xPlayer = ESX.GetPlayerFromId(_source)
        xPlayer.removeAccountMoney('bank', data[2].amount)
    elseif data[1] == 'Cash' then
        ox_inventory:RemoveItem(_source, 'money', data[2].amount)
    end
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. data[2].registerJob, function(account)
        account.addMoney(data[2].amount)
    end)
    TriggerClientEvent('ox_lib:notify', _source, {position = 'bottom', type = 'success', description = "You Paid $" .. data[2].amount .. ".00", duration = 5000})
    TriggerClientEvent('gr8_registers:notifyPaymentClient', -1, data[2].amount, data[2].registerJob)
    Registers[data[2].register].amount = 0
    TriggerClientEvent('gr8_registers:updateTotal', -1, Registers)
end)

ESX.RegisterServerCallback('gr8_registers:getClientAccountMoney', function(source, cb)
    local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local bankTotal = xPlayer.getAccount('bank').money
    local cashTotal = ox_inventory:Search(_source, 'count', 'money')
	if bankTotal == nil then
		bankTotal = 0
	end
    if cashTotal == nil then
		cashTotal = 0
	end
	cb(bankTotal, cashTotal)
end)