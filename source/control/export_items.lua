local export = {}

-- a bit of work is done every tick, 
-- the tick amount to repeat the whole export process must be greater than the individual steps done
local export_repeat_every_x_ticks = 60

local x = 999999


function clear_data()
	global.need = {}
	global.supply = {}
end

function read_inventories_force(i)
	local forceName = "player"..i
	for _,table in pairs(global.buildings[forceName]) do
		local combinator = table.combinator
		local warehouse = table.warehouse
		local content = warehouse.get_inventory(defines.inventory.chest).get_contents()

	end
end

function calculate_totals()

end

function distribute_items()
	
end



function export.on_tick(event)
	local t = game.tick % export_repeat_every_x_ticks

	if t == 0 then
		clear_data()
	elseif t >= 1 and t <= 4 then
		read_inventories_force(t)
	elseif t == 5 then
		calculate_totals()
	elseif t == 6 then
		distribute_items()
	end
	--[[
		Read all inventories (normal items)
		Read all inventories (export items) 
		Read all combinators and subtract from already available items in warehouse
		if negative put an entry into the need table

		loop for every supply (if there is need and supply for an items)

			calculate total need
			calculate total supply
			calculate fulfill need/provide rate

			move items according to need/provide rate
	]]--

end

return export