ESX = exports['es_extended']:getSharedObject()
CreateStash = function(data)
	return exports.ox_inventory:RegisterStash(data.serial, data.label, data.slots, data.weights, false)
end

lib.callback.register('renzu_bag:AddStash', function(source, data)
    CreateStash(data)
end)

CreateBag = function(data,serial)
	local metadata = {
	  description = data.label..' - Can store up to '..data.slots..' Items',
	  slots = data.slots,
	  serial = serial and tostring(serial) or tostring(math.random(999999,9999999999)), -- can be improved
	  label = data.label,
	  weights = data.weights,
	  model = data.model,
	  image = data.image
	}
	exports.ox_inventory:AddItem(data.src,data.item,1,metadata, false, function(success, a)
	end)
end
  
exports('CreateBag', function(data)
	CreateBag(data)
end)
  
RegisterNetEvent('buybag', function(v)
	local data = v
	local money = exports.ox_inventory:GetItem(source, 'money', nil, false)
	if money.count >= data.price then
		data.src = source
		CreateBag(data)
		exports.ox_inventory:RemoveItem(source, 'money', data.price, nil)
		TriggerClientEvent('renzu_bag:Notify',source, 'success', data.label..' has been Bought')
	else
		TriggerClientEvent('renzu_bag:Notify',source, 'error', data.label..' cannt afford pal')
	end
end)

ESX.RegisterUsableItem("bag", function(source,item,data)
	local xPlayer = ESX.GetPlayerFromId(source)
	local metadata = {
		slots = data.metadata.slots,
		weights = data.metadata.weights,
		serial = data.metadata.serial,
		label = data.metadata.label,
		model = data.metadata.model,
		item = item,
		image = data.metadata.image
	}
	TriggerClientEvent('renzu_bag:inventory',source,metadata)
	exports.ox_inventory:RemoveItem(source, item, 1, nil, data.slot)
end)

GlobalState.PersistentBags = json.decode(GetResourceKvpString('bags') or '[]') or {}
local entities = {}
RegisterNetEvent("renzu_bag:placeobject", function(data)
	local source = source
	local bag = NetworkGetEntityFromNetworkId(data.net)
	CreateStash(data)
	local ent = Entity(bag).state
	entities[data.net] = bag
	EnsureEntityStateBag(bag)
	data.random = os.time() -- make sure state bag is new to clients. its seems if its the same data the handler will not get the notification
	ent:set('bag', data, true)
	EnsureEntityStateBag(bag)
	Wait(1000)
	data.coord = GetEntityCoords(bag)
	local bags = json.decode(GetResourceKvpString('bags') or '[]') or {}
	bags[data.serial] = data
	SetResourceKvp('bags',json.encode(bags))
end)

RegisterNetEvent("renzu_bag:removeplacement", function(data)
	local source = source
	local bag = NetworkGetEntityFromNetworkId(data.net)
	if DoesEntityExist(bag) then
		local ent = Entity(bag).state
		ent:set('bag',nil,true) -- remove first, sometimes when deleted and same net id or entity id is used again to another entity the state bag still persist. this happens mostly on server rpc creatobjects or peds. imoexp
		Wait(500)
		DeleteEntity(bag)
		TriggerClientEvent('renzu_bag:removezone',-1,data)
		data.src = source
		CreateBag(data,data.serial)
		local bags = json.decode(GetResourceKvpString('bags') or '[]') or {}
		bags[data.serial] = nil
		SetResourceKvp('bags',json.encode(bags))
		entities[data.net] = nil
	end
end)

Citizen.CreateThread(function()
	Wait(1000)
	local bags = GlobalState.PersistentBags
	for k,v in pairs(bags) do
		local bag = CreateObjectNoOffset(v.model, v.coord.x,v.coord.y,v.coord.z, true, true)
		while not DoesEntityExist(bag) do Wait(0) end
		CreateStash(v)
		local ent = Entity(bag).state
		local net = NetworkGetNetworkIdFromEntity(bag)
		entities[net] = bag
		EnsureEntityStateBag(bag)
		v.net = net
		v.random = os.time() -- make sure state bag is new to clients. its seems if its the same data the handler will not get the notification
		ent:set('bag', v, true)
		FreezeEntityPosition(bag,true)
	end
end)

AddEventHandler('onResourceStop', function(re)
	if re == GetCurrentResourceName() then
		for k,v in pairs(entities) do
			if DoesEntityExist(NetworkGetEntityFromNetworkId(k)) then
				DeleteEntity(NetworkGetEntityFromNetworkId(k))
			end
		end
	end
end)