local ESX = nil
local charge = 0
local Registers = {}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(100)
	end
    ESX.PlayerData = ESX.GetPlayerData()
end)

Citizen.CreateThread(function()
    TriggerServerEvent('gr8_registers:onJoinStatus')
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    TriggerServerEvent('gr8_registers:onJoinStatus')
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job
end)

function UpdateRegisters()
    for i,v in pairs(Registers) do
        print(json.encode(Registers))
        exports['qtarget']:AddBoxZone('register' .. i, v.coords, v.l, v.w, {
            name='register' .. i,
            heading=v.heading,
            minZ=v.minZ,
            maxZ=v.maxZ
            }, {
            options = {
                {
                    event = "gr8_registers:setTotal",
                    icon = "fas fa-cash-register",
                    label = "SET TOTAL TO PAY",
                    job = v.job,
                    register = i,
                    amount = v.amount,
                    canInteract = function()
                        if v.amount == 0 then
                            return true
                        end
                    end
                },
                {
                    event = "gr8_registers:clearTotal",
                    icon = "fas fa-cash-register",
                    label = "CLEAR TOTAL",
                    job = v.job,
                    register = i,
                    amount = 0,
                    canInteract = function()
                        if v.amount > 0 then
                            return true
                        end
                    end
                },
                {
                    event = "gr8_registers:payTotal",
                    icon = "fas fa-cash-register",
                    label = "PAY $" .. v.amount,
                    register = i,
                    amount = v.amount,
                    registerJob = v.job,
                },
            },
            distance = 2.5 
        })
    end
end

AddEventHandler('gr8_registers:setTotal', function(info)
    local data = lib.inputDialog('REGISTER', {'TOTAL DUE:'})
    if data then
        if data[1] == nil then return end
        info.amount = data[1]
        TriggerServerEvent('gr8_registers:createCharge', info)
        lib.notify({
            title = 'Register', description = 'TOTAL DUE SET: $' .. tonumber(info.amount),
            position = 'bottom',
            type = 'inform',
            duration = 5000,
        })
    end
end)

AddEventHandler('gr8_registers:clearTotal', function(info)
    TriggerServerEvent('gr8_registers:createCharge', info)
end)

RegisterNetEvent('gr8_registers:payTotal')
AddEventHandler('gr8_registers:payTotal', function(data)
    if data.amount > 0 then
        local options = {}
        local accountTotal = nil
        local cashTotal = nil
        ESX.TriggerServerCallback("gr8_registers:getClientAccountMoney", function(bankTotal, cashTotal)
            local paymentTypes = {
                'Cash',
                'Credit',
                'Cancel'
            }
            accountTotal = bankTotal
            cashTotal = cashTotal
            if bankTotal < data.amount then
                table.remove(paymentTypes, 2)
            end
            if cashTotal < data.amount then
                table.remove(paymentTypes, 1)
            end
            for k,v in pairs(paymentTypes) do 
                options[k] = {arrow = true,
                    title = v,
                    event = "gr8_registers:client:chargeMe",
                    arrow = true,
                    args = {v, data}
                }
            end
            lib.registerContext({
                id = 'register',
                title = 'Register',
                arrow = true,
                options = options
            })
            lib.showContext('register')
        end)
    end
end)

RegisterNetEvent('gr8_registers:client:chargeMe', function(data)
    if data[1] ~= "Cancel" then
        TriggerServerEvent('gr8_registers:chargeMe', data)
    end
end)

RegisterNetEvent('gr8_registers:updateTotal')
AddEventHandler('gr8_registers:updateTotal', function(NewList)
    Registers = NewList
    UpdateRegisters()
end)

RegisterNetEvent('gr8_registers:notifyPaymentClient')
AddEventHandler('gr8_registers:notifyPaymentClient', function(OrderTotal, job)
    if ESX.PlayerData.job.name == job then
        lib.notify({
            description = "An order was paid for $" .. OrderTotal .. ".00",
            position = 'bottom',
            type = 'inform',
            duration = 5000,
        })
    end
end)