require "libs.lua.string"

local export = {}

-- a bit of work is done every tick, 
-- the tick amount to repeat the whole export process must be greater than the individual steps done
local export_repeat_every_x_ticks = 480


function clear_data()
	global.need = {}
	global.supply = {}
end

function read_inventories_force(i)
	local forceName = "player"..i
	for _,forceBuildings in pairs(global.buildings[forceName]) do
		local combinator = forceBuildings.combinator
		local warehouse = forceBuildings.warehouse
		local content = warehouse.get_inventory(defines.inventory.chest).get_contents()

		-- combine warehouse + requested items
		local contentRequested = combinator.get_merged_signals()
		if contentRequested == nil then contentRequested = {} end

		for _, itemTable in pairs(contentRequested) do
			if itemTable.signal.type == "item" then
				local itemName = itemTable.signal.name
				local amount = itemTable.count
				if content[itemName] ~= nil then
					content[itemName] = content[itemName] - amount
				else 
					content[itemName] = -amount
				end
				if content[itemName] == 0 then content[itemName] = nil end
			end
		end
		-- put need/supply into global table
		for itemName, amount in pairs(content) do
			local t = nil
			-- only put export items into supply table, normal only into need
			if string.startsWith(itemName,"export_") and amount > 0 then
				t = global.supply
				itemName = string.sub(itemName,8)
			elseif not string.startsWith(itemName,"export_") and amount < 0 then
				t = global.need
				amount = amount * -1
			end
			if t ~= nil then
				if t[itemName] == nil then 
					t[itemName] = { 
						each = {},
						total = 0
					}
				end
				table.insert(t[itemName].each, {
					force = forceName,
					warehouse = warehouse,
					amount = amount
				})
				t[itemName].total = t[itemName].total + amount
			end
		end
	end
end


function distribute_items()
	game.print("need: " .. serpent.block(global.need))
	--game.print("supply: " .. serpent.block(global.supply))
end



function export.on_tick(event)
	local t = game.tick % export_repeat_every_x_ticks

	if t == 0 then
		clear_data()
	elseif t >= 1 and t <= 4 then
		read_inventories_force(t)
	elseif t == 5 then
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