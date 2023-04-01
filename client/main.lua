ESX = exports['es_extended']:getSharedObject()
local loaded = false
Citizen.CreateThread(function()
	PlayerData = ESX.GetPlayerData()
	player = LocalPlayer.state
	Wait(2000)
	loaded = ESX.PlayerLoaded
	for k,v in pairs(Config.item) do
		lib.requestModel(v.model) -- preload models
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(playerData)
    loaded = true
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	loaded = true
end)

local stash = {}
AddStateBagChangeHandler('bag' --[[key filter]], nil --[[bag filter]], function(bagName, key, value, _unused, replicated)
	Wait(0)
	if not value then return end
    local net = tonumber(bagName:gsub('entity:', ''), 10)
    local bag = NetworkGetEntityFromNetworkId(net)
	local ent = Entity(bag).state
	stash[value.serial] = value
	StashZone(value)
end)

Spheres = {}
OpenInventory = function(data)
	lib.registerContext({
		id = 'inventory_'..data.serial,
		title = data.label,
		onExit = function()
		end,
		options = {
			{
				title = 'Open Inventory',
				description = 'Open This Bag',
				onSelect = function(args)
					TriggerEvent('ox_inventory:openInventory', 'stash', {id = data.serial, name = data.label, slots = data.slots, weight = data.weights, coords = data.coord})
				end,
			},
			{
				title = 'Take Bag',
				description = 'Take the '..data.label,
				onSelect = function(args)
					print('Pressed the button!')
					Progress('Taking '..data.label)
					Pickup()
					TriggerServerEvent('renzu_bag:removeplacement',data)
				end,
			},
		},
	})
	lib.showContext('inventory_'..data.serial)
end

Pickup = function()
	lib.requestAnimDict('random@domestic')
	TaskPlayAnim(PlayerPedId(), 'random@domestic', 'pickup_low', 2.0, 2.0, -1, 48, 0, false, false,false)
end

Progress = function(text)
	lib.progressBar({
		duration = 1000,
		label = text..'..',
		useWhileDead = false,
		canCancel = true,
		disable = {
			car = false,
		}
	})
end

RegisterNetEvent('renzu_bag:removezone', function(data)
	if Spheres[data.serial] then
		Spheres[data.serial]:remove()
	end
	if #(GetEntityCoords(cache.ped) - vec3(data.coord.x,data.coord.y,data.coord.z)) < 2 then
		lib.hideTextUI()
	end
end)

Wearbag = function(id)
	SetPedComponentVariation(cache.ped,5,id,0,2)
end

RegisterNetEvent('renzu_bag:Wearbag', function(slot)
	local bags = exports.ox_inventory:Search('slots', 'bag')
	for k,v in pairs(bags) do
		if v.slot == slot then
			return Wearbag(v.metadata.componentid)
		end
	end
end)

exports('useItem', function(data, slot)
    exports.ox_inventory:useItem(data, function(data)
		Progress('Opening '..data.metadata.label)

		Pickup()

		lib.requestModel(data.metadata.model)

		local bag = CreateObject(data.metadata.model, GetEntityCoords(cache.ped)+GetEntityForwardVector(cache.ped)*0.8, true, true)

		while not DoesEntityExist(bag) do Wait(0) end

		PlaceObjectOnGroundProperly(bag)

		data.metadata.net = NetworkGetNetworkIdFromEntity(bag)

		data.metadata.coord = GetEntityCoords(bag)

		Wait(1000)
		
		FreezeEntityPosition(bag,true)
		
		data.item = data.name

		TriggerServerEvent('renzu_bag:placeobject',data)
	end)
end)

StashZone = function(data)
	function onEnter(self)
		lib.showTextUI('[E] - Open '..data.label, {
			position = "right-center",
			icon = 'briefcase',
			style = {
				borderRadius = 0,
				backgroundColor = '#202020',
				borderRadius = 20,
				borderStyle = 'solid',
				borderWidth = '1px',
				color = 'white'
			}
		})
	end
	
	function onExit(self)
		lib.hideTextUI()
	end
	
	function inside(self)
		local data = data
		if IsControlJustPressed(0,38) then
			print(data.serial,data.label)
			OpenInventory(data)
		end
	end
	
	local sphere = lib.zones.sphere({
		coords = data.coord,
		radius = 2,
		debug = false,
		inside = inside,
		onEnter = onEnter,
		onExit = onExit
	})
	Spheres[data.serial] = sphere
end

Shop = function()
	function onEnter(self)
		lib.showTextUI('[E] - Buy Bag', {
			position = "right-center",
			icon = 'hand',
			style = {
				borderRadius = 0,
				backgroundColor = '#48BB78',
				color = 'white'
			}
		})
	end

	function onExit(self)
		lib.hideTextUI()
	end

	function inside(self)
		if IsControlJustPressed(0,38) then
			BagShop()
		end
	end

	local sphere = lib.zones.sphere({
		coords = Config.Shopcoord,
		radius = 1,
		debug = false,
		inside = inside,
		onEnter = onEnter,
		onExit = onExit
	})
end

BagShop = function()
	local options = {}
	local secondary = {}
	local type = {}
	for k,v in pairs(Config.item) do
		table.insert(options,{
			title = v.label.. ' - Price: '..v.price..'$',
			arrow = true,
			description = 'Buy '..v.label..' | Slots: '..v.slots,
			onSelect = function(args)
				TriggerServerEvent('buybag',v)
			end,
		})
	end
	
	lib.registerContext({
		id = 'buybags',
		title = 'Buy Bags',
		onExit = function()
			print('Hello there')
		end,
		options = options
	})
	lib.showContext('buybags')
end

Citizen.CreateThread(function()
	Wait(1000)
	if Config.useShop then
		local blip = AddBlipForCoord(Config.Shopcoord)
		SetBlipSprite(blip, 586)
		SetBlipDisplay(blip, 4)
		SetBlipScale(blip, 0.8)
		SetBlipColour(blip, 3)
		SetBlipAsShortRange(blip, true)
		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName('Bag Shop')
		EndTextCommandSetBlipName(blip)
		Shop()
	end
end)