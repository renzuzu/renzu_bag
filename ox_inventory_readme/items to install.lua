-- put  this on your ox items /data/items.lua
-- put the images to /web/build/images or web/images/
['bag'] = {
	label = 'Bag',
	weight = 0,
	stack = false,
	close = true,
	description = '',
	client = {
		export = 'renzu_bag.useItem',
		disable = { move = true, car = true, combat = true },
		usetime = 1,
		remove = function(total)
			if _G.bagID then
				SetPedComponentVariation(cache.ped,5,_G.bagID,0,2)
				_G.bagID = nil
			end
		end
	},
	buttons = {
		{
			label = 'Wear / Unwear bag',
			action = function(slot)
				print(_G.bagID,'_G.bagID')
				if _G.bagID == nil then
					_G.bagID = GetPedDrawableVariation(cache.ped, 5)
					TriggerEvent('renzu_bag:Wearbag', slot)
				else
					SetPedComponentVariation(cache.ped,5,_G.bagID,0,2)
					_G.bagID = nil
				end
			end
		}
	},
},