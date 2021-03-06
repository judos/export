local split = require("mapgen/split")
local export = require("control/export_items")

--[[
global data used:
	{
		version = $version
		buildings[$force] = {
			{
				combinator = (combinator)
				warehouse = (warehouse)
			}
		}
		need/supply[$itemName] = {
			each = {
				{
					force = $forceName,
					warehouse = $warehouse,
					amount = $amount
				}
			},
			total = $amount
		}
	}

]]-- 

-- Init --
script.on_init(function()
	split.on_init()
end)

script.on_configuration_changed(function()
	local g = global
	local previousVersion = g.version
	if previousVersion==nil then
		
	end
	if g.version ~= previousVersion then
		info("Previous global data version: "..previousVersion)
		info("Migrated to version "..g.version)
	end
end)

script.on_event(defines.events.on_tick, function(event)
	export.on_tick(event)
end)

script.on_event(defines.events.on_chunk_generated, function(event)
	split.on_chunk_generated(event)
end)

script.on_event(defines.events.on_player_created, function(event)
	split.on_player_created(event)
end)

script.on_event(defines.events.on_built_entity, function(event)
	split.on_built_entity(event)
end)

function xx(obj)
	game.print(serpent.block(obj))
end