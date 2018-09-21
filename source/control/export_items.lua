require "libs.lua.string"
require "libs.lua.table"
require "libs.logging"

local export = {}

-- a bit of work is done every tick, 
-- the tick amount to repeat the whole export process must be greater than the individual steps done
local export_repeat_every_x_ticks = 5 * 60



--[[
initital Pseudo-code

	Read all inventories (normal items)
	Read all inventories (export items) 
	Read all combinators and subtract from already available items in warehouse
	if negative put an entry into the need table

	loop for every supply (if there is need and supply for an item)

		calculate total need
		calculate total supply
		calculate fulfill need/provide rate

		move items according to need/provide rate
]]--



function clear_data()
	global.need = {}
	global.supply = {}
end


function get_items_of_combinator(combinator)
	local contentRequested = combinator.get_merged_signals()
	if contentRequested == nil then contentRequested = {} end
	local result = {}
	for _, itemTable in pairs(contentRequested) do
		if itemTable.signal.type == "item" then
			result[itemTable.signal.name] = itemTable.count
		end
	end
	return result
end


function init_table_entry(t, itemName)
	if t[itemName] == nil then 
		t[itemName] = { 
			each = {},
			total = 0
		}
	end
end

function read_inventories_force(i)
	local forceName = "player"..i
	-- if you supply items, can't simultaneously need them (simplifies distribution logic)
	local providedItems = {}

	for _,forceBuildings in pairs(global.buildings[forceName]) do
		local combinator = forceBuildings.combinator
		local warehouse = forceBuildings.warehouse
		local content = warehouse.get_inventory(defines.inventory.chest).get_contents()

		-- combine warehouse + requested items
		local contentRequested = get_items_of_combinator(combinator)
		table.numericAddTable(content,contentRequested,-1)

		-- put need/supply into global table
		for itemName, amount in pairs(content) do
			local t = nil
			-- only put export items into supply table, normal only into need
			if string.startsWith(itemName,"export_") and amount > 0 then
				t = global.supply
				itemName = string.sub(itemName,8)
				providedItems[itemName] = true
			elseif not string.startsWith(itemName,"export_") and amount < 0 then
				t = global.need
				amount = amount * -1
			end
			if t ~= nil then
				init_table_entry(t,itemName)
				table.insert(t[itemName].each, {
					force = forceName,
					warehouse = warehouse,
					amount = amount
				})
				t[itemName].total = t[itemName].total + amount
			end
		end
	end

	-- remove request of items that are provided by your self
	for itemName,dataTable in pairs(global.need) do
		if providedItems[itemName] then
			for key,provideTable in pairs(dataTable.each) do
				if provideTable.force == forceName then
					dataTable.each[key] = nil
					dataTable.total = dataTable.total - provideTable.amount
				end
			end
			if dataTable.total == 0 then global.need[itemName] = nil end
		end
	end
end


function distribute_items()
	info("need: " .. serpent.block(global.need))
	info("supply: " .. serpent.block(global.supply))

	for itemName,needTable in pairs(global.need) do
		if global.supply[itemName] ~= nil then
			distribute_item(itemName)
		end
	end
end

local xxx=0
function distribute_item(itemName)
	local need = global.need[itemName]
	local supply = global.supply[itemName]
	local needFactor = 1
	if need.total > supply.total * settings.global.export_multiply_factor.value then
		needFactor = supply.total * settings.global.export_multiply_factor.value / need.total
	end
	local inserted = add_warehouse_items_factor(need.each,itemName,needFactor) -- round up
	local supplyFactor = inserted / (supply.total * settings.global.export_multiply_factor.value)
	local removed = add_warehouse_items_factor(supply.each,"export_"..itemName,-supplyFactor) -- round up
	removed = removed * settings.global.export_multiply_factor.value
	if inserted > removed then
		removed = removed + add_warehouse_items_constant(need.each,itemName, removed - inserted) -- remove excess items
	elseif removed > inserted then
		inserted = inserted + add_warehouse_items_constant(need.each,itemName, removed - inserted) -- add additional items
	end

	if math.abs(inserted - removed) >= 1 then
		warn("export WARN: item distribute difference: "..tostring(inserted-removed))
	end
	
	info("inserted "..tostring(inserted)..", removed: "..tostring(removed).." "..itemName)
	info("need: "..tostring(needFactor)..", supply: "..tostring(supplyFactor))
end


function add_warehouse_items_constant(t, itemName, itemsToMove)
	local itemsPerWarehouse = math.ceil(math.abs(itemsToMove) / #t)
	info("per warehouse: "..tostring(itemsPerWarehouse).." toMove: "..tostring(itemsToMove))
	local movedTotal = 0
	local moved
	for _,data in pairs(t) do
		local inventory = data.warehouse.get_inventory(defines.inventory.chest)
		local items = {
			name = itemName,
			count = math.min(math.abs(itemsPerWarehouse), math.floor(math.abs(itemsToMove)))
		}
		if itemsToMove >= 1 then
			moved = inventory.insert(items)
		elseif itemsToMove <= -1 then
			moved = -inventory.remove(items)
		else
			return movedTotal
		end
		itemsToMove = itemsToMove - moved
		movedTotal = movedTotal + math.abs(moved)
	end
	return movedTotal
end


function add_warehouse_items_factor(t, itemName, factor)
	local moved = 0
	for _,data in pairs(t) do
		local inventory = data.warehouse.get_inventory(defines.inventory.chest)
		local items = {
			name = itemName,
			count = math.ceil(math.abs(factor) * data.amount)
		}
		if factor > 0 then
			moved = moved + inventory.insert(items)
		else
			moved = moved + inventory.remove(items)
		end
	end
	return moved
end

function testing_randomize()
	for forceName,buildings in pairs(global.buildings) do
		local case = math.random(0,1)
		for _,t in pairs(buildings) do
			testing_randomize_table(t, case)
		end
	end
end

function testing_randomize_table(t,case)
	local w = t.warehouse
	local inventory = w.get_inventory(defines.inventory.chest)
	inventory.clear()
	if case == 0 then -- provide
		local x = math.random(0,100)
		if x>0 then inventory.insert{name="export_iron-plate",count=x} end
	else
		local x = math.random(0,100)
		if x>0 then inventory.insert{name="iron-plate",count=x} end
		local c = t.combinator
		x = math.random(0,100)
		c.get_or_create_control_behavior().set_signal(1, {signal = {type = "item", name = "iron-plate"}, count = x})
	end
end



function export.on_tick(event)
	local t = game.tick % export_repeat_every_x_ticks

	if t == 0 then
		clear_data()
	elseif t >= 1 and t <= 4 then
		read_inventories_force(t)
	elseif t == 5 then
		distribute_items()
	elseif t == 6 then
		--testing_randomize()
	end

end

return export