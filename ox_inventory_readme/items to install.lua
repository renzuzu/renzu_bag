-- put  this on your ox items /data/items.lua
-- put the images to /web/build/images or web/images/
['bag'] = {
	label = 'Bag',
	weight = 0,
	stack = false,
	close = true,
	description = ''
	client = {
		export = 'renzu_bag.useItem',
		disable = { move = true, car = true, combat = true },
		usetime = 1,
	}
},