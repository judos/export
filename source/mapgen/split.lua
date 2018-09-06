require "libs.lua.functionBindings"

-- required to call these functions for events:
-- on_init
-- on_chunk_generated
-- on_player_created

local split={}

local spawn_size = 3 -- radius amount of chunks starting area per force (3 minimum for resources config below)
local amount_warehouses = 6 -- amount of warehouses placed at the border
local split_border_radius = 5 -- black border where forces can't cross

local startingResource = {
	["3,3"]={"iron-ore",8,8,200},
	["3,2"]={"copper-ore",7,7,200},
	["2,2"]={"stone",8,8,200},
	["2,3"]={"coal",8,8,400},
	["1,3"]={"water",2,5}	
}

--[[ Text representation of the map:

   |
   |
   |
---X---
   |  
   | SC
   |WcI


]]--

function pos_to_chunkPos(coords)
	local chunkX = math.floor((coords.x or coords[1]) / 32)
	local chunkY = math.floor((coords.y or coords[2]) / 32)
	return { x = chunkX, y = chunkY }
end


function is_spawn_chunk(left_top)
	local chunkPos = pos_to_chunkPos(left_top)
	return chunkPos.x >= -spawn_size and chunkPos.x <= spawn_size and
		chunkPos.y >= -spawn_size and chunkPos.y <= spawn_size
end


function square(area, lambda)
	local result = {}
	local lt = area.left_top or area[1]
	local rb = area.right_bottom or area[2]
	for x = lt.x or lt[1], rb.x or rb[1] do
		for y = lt.y or lt[2], rb.y or rb[2] do
			local val = lambda(x,y)
			if val ~= nil then
				table.insert(result,val)
			end
		end
	end
	return result
end


function translate(tx,ty,lambda)
	return function(x,y)
		return lambda(x+tx, y+ty)
	end
end


function foreach(tabl, lambda)
	for _,x in pairs(tabl) do
		lambda(x)
	end
end

function filter(filter, lambda)
	return function(x,y)
		if filter(x,y) then return lambda(x,y) end
	end
end


-- Tile creators

function generate_spawn_tile(x,y)
	local b = 5 -- border of dirt on the outside of spawn area
	local outerAreaLT = -spawn_size * 32
	local outerAreaRB = spawn_size * 32 + 32 -- chunk 0,0 is used for water
	if x < outerAreaLT + b or x > outerAreaRB - b or
		y < outerAreaLT + b or y > outerAreaRB - b then
		return {name="dirt-7",position={x,y}}
	else
		return {name="grass-1",position={x,y}}
	end
end


function generate_resource_tile(x,y,name,amount)
	return {name = name, position = {x,y}, amount = amount}
end


function generate_water_tile(x,y)
	return {name = "water", position = {x,y}}
end

function generate_border_tile(x,y)
	return {name = "out-of-map", position = {x,y}}
end


-- Chunk modifiers / generators

function chunk_generator_spawn_tiles(event)
	-- place floor tiles (grass + dirt), remove decoratives
	if not is_spawn_chunk(event.area.left_top) then return end
	local tiles = square(event.area, generate_spawn_tile)
	event.surface.set_tiles(tiles, true)
	event.surface.destroy_decoratives(event.area)
end


function chunk_generator_spawn_clean_area(event)
	if not is_spawn_chunk(event.area.left_top) then return end
	local entities = event.surface.find_entities_filtered{area=event.area, type= {"resource","tree"}}
	for _,entity in pairs(entities) do
		entity.destroy()
	end
end


function chunk_generator_spawn_starting_resource(event)
	if not is_spawn_chunk(event.area.left_top) then return end
	local chunkPos = pos_to_chunkPos(event.area.left_top)
	local chunkStr = math.abs(chunkPos.x) .. "," .. math.abs(chunkPos.y)
	local resGen = startingResource[chunkStr]
	if resGen == nil then return end
	local entities = 
		square({{-resGen[2],-resGen[3]},{resGen[2],resGen[3]}},
		translate(event.area.left_top.x+16,event.area.left_top.y+16, function(x,y)
			if resGen[1] == "water" then
				return generate_water_tile(x,y)
			else
				return generate_resource_tile(x,y,resGen[1],resGen[4])
			end
		end))
	if resGen[1] == "water" then
		event.surface.set_tiles(entities, true)
	else
		foreach(entities,event.surface.create_entity)
	end
end


function chunk_generator_split_base_borders(event)
	local chunkPos = pos_to_chunkPos(event.area.left_top)
	if chunkPos.x ~= 0 and chunkPos.y ~= 0 then return end
	local r = split_border_radius
	if chunkPos.x == 0 then
		local tiles = square({{-r, -16}, {r, 15}},
			translate(event.area.left_top.x + 16, event.area.left_top.y + 16, 
			generate_border_tile))
		event.surface.set_tiles(tiles, true)
	end
	if chunkPos.y == 0 then
		local tiles = square({{-16, -r}, {15, r}},
			translate(event.area.left_top.x + 16, event.area.left_top.y + 16, 
			generate_border_tile))
		event.surface.set_tiles(tiles, true)
	end
	if chunkPos.x == 0 and chunkPos.y == 0 then
		local tiles = square({{-r, -r}, {r, r}},
			translate(16,16,
			filter(function(x,y) return (x-16+y-16 == 0) or (x-16-y+16 == 0) end,
			generate_spawn_tile)))
		 event.surface.set_tiles(tiles, true)
	end
end


function chunk_generator_warehouses(event)
	local left_top = event.area.left_top
	local chunkPos = pos_to_chunkPos(left_top)
	if chunkPos.x ~= 0 and chunkPos.y ~= 0 then return end
	if chunkPos.x == 0 and chunkPos.y == 0 then return end
	if math.abs(chunkPos.x) > amount_warehouses or math.abs(chunkPos.y) > amount_warehouses then return end

	local coords, forces
	if chunkPos.x == 0 then
		coords = { {left_top.x + 8, left_top.y + 16}, {left_top.x + 24, left_top.y + 16} }
		forces = { chunkPos.y>0 and 2 or 3, chunkPos.y > 0 and 1 or 4 }
	elseif chunkPos.y == 0 then
		coords = { {left_top.x + 16, left_top.y + 8}, {left_top.x + 16, left_top.y + 24} }
		forces = { chunkPos.x>0 and 4 or 3, chunkPos.x > 0 and 1 or 2 }
	end
	for i=1,2 do
		local entity = event.surface.create_entity{
			name = "warehouse-basic", 
			position = coords[i], 
			force = "player" .. forces[i]
		}
		entity.destructible = false
		entity.minable = false

	end
end


-- all the different modifications on top of the vanilla map generation in order:
local chunk_generators = {
	chunk_generator_spawn_tiles,
	chunk_generator_spawn_clean_area,
	chunk_generator_spawn_starting_resource,
	chunk_generator_split_base_borders,
	chunk_generator_warehouses
}



function split.on_chunk_generated(event)
  -- only check nauvis 
	if event.surface ~= game.surfaces[1] then return end

	for _,generator in pairs(chunk_generators) do
		generator(event)
	end

end


function split.on_init()
	game.create_force("player1")
	game.create_force("player2")
	game.create_force("player3")
	game.create_force("player4")
	local d = 5
	game.forces['player1'].set_spawn_position({32+d, 32+d},game.surfaces[1])
	game.forces['player2'].set_spawn_position({-d, 32+d},game.surfaces[1])
	game.forces['player3'].set_spawn_position({-d, -d},game.surfaces[1])
	game.forces['player4'].set_spawn_position({32+d, -d},game.surfaces[1])
	for i=1,4 do
		for j=1,4 do
			if i ~= j then
				game.forces['player'..i].set_cease_fire('player'..j, true)
			end
		end
	end

end

function split.on_player_created(event)
	local nr = event.player_index
	local force = (nr-1) % 4 + 1

	game.players[nr].force = 'player'..force
	game.players[nr].teleport( game.players[nr].force.get_spawn_position(game.surfaces[1]))
end



return split