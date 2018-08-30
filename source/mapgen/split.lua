require "libs.lua.functionBindings"

-- required to call these functions for events:
-- on_init
-- on_chunk_generated
-- on_player_created

local split={}

local spawn_size = 64
local ressSize = 8

function generate_water_in_chunk(x,y,surface) -- coords are left_top of chunk
	local tiles = square({{-2,-5},{2,5}},translate(x+16,y+16,generate_water_tile))
	surface.set_tiles(tiles, true)
end

local startingResource = {
	["-2,-2"]={"iron-ore",8,200},
	["-2,-1"]={"copper-ore",7,200},
	["-1,-2"]={"stone",8,200},
	["-1,-1"]={"coal",8,400},
	["-1,1"]= generate_water_in_chunk,
	
	["1,-2"]={"iron-ore",8,200},
	["1,-1"]={"copper-ore",7,200},
	["0,-2"]={"stone",8,200},
	["0,-1"]={"coal",8,400},
	["0,1"]=generate_water_in_chunk
}



function generate_border_tile(x,y,tiles)
	if x>=-5 and x<= 5 then
		table.insert(tiles, {name="out-of-map",position={x,y}})
	end
end

function generate_spawn_tile(x,y)
	if x>= -spawn_size+5 and x<= spawn_size-5 and y>=-spawn_size+5 and y<=spawn_size-5 then
		return {name="grass-1",position={x,y}}
	elseif x>= -spawn_size and x<= spawn_size and y>=-spawn_size and y<=spawn_size then
		return {name="dirt-7",position={x,y}}
	end
end

function generate_resource(x,y,name,amount)
	return {name=name,position={x,y},amount=amount}
end

function generate_water_tile(x,y)
	return {name="water",position={x,y}}
end
	

function is_spawn_chunk(left_top)
	return left_top.x>= -spawn_size and left_top.x < spawn_size
		and left_top.y>= -spawn_size and left_top.y < spawn_size
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

function split.on_init()
	game.create_force("player2")
	game.forces['player'].set_spawn_position({-15,0},game.surfaces[1])
	game.forces['player2'].set_spawn_position({15,0},game.surfaces[1])	
end


function split.on_chunk_generated(event)

  -- only check nauvis 
	if event.surface ~= game.surfaces[1] then return end
	
	if is_spawn_chunk(event.area.left_top) then
		local tiles = square(event.area, generate_spawn_tile)
		event.surface.set_tiles(tiles, true)
		event.surface.destroy_decoratives(event.area)
		local entities = event.surface.find_entities_filtered{area=event.area, type= {"resource","tree"}}
		for _,entity in pairs(entities) do
			entity.destroy()
		end
		
		local chunkCoords = {math.floor(event.area.left_top.x/32),
			math.floor(event.area.left_top.y/32)}
		local chunkStr = chunkCoords[1]..","..chunkCoords[2]
		local resGen = startingResource[chunkStr]
		if resGen ~= nil and type(resGen)=="function" then
			resGen(event.area.left_top.x, event.area.left_top.y,game.surfaces[1])
		elseif resGen ~= nil then
			local sur = game.surfaces[1]
			local fs = resGen[2] -- field Size
			local entities = square({{-fs,-fs},{fs,fs}},
				translate(event.area.left_top.x+16,event.area.left_top.y+16,
				bind34(generate_resource,resGen[1],resGen[3])))
			foreach(entities,sur.create_entity)
		end
		
	end
	
	if event.area.right_bottom.x < -32 or
		event.area.left_top.x > 32 then
		return
	end
	
	-- xx(event.area)
	
	local tiles = {}
	for x = event.area.left_top.x, event.area.right_bottom.x do
		for y = event.area.left_top.y, event.area.right_bottom.y do
			generate_border_tile(x,y,tiles)
		end
	end
	event.surface.set_tiles(tiles, true)

end


function split.on_player_created(event)
	local nr = event.player_index
	local force = nr % 2
	if force == 0 then
		game.players[nr].force = 'player2'
		game.players[nr].teleport( game.players[nr].force.get_spawn_position(game.surfaces[1]))
	end
end




return split