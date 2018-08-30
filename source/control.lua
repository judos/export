split = require("mapgen/split")

-- global data used:
-- version = $version

-- Init --
script.on_init(function()
	split.on_init()
end)

script.on_configuration_changed(function()
	local g = global
	local previousVersion = g.version
	if previousVersion==nil then
		g.tasks = {}
	end
	if g.version ~= previousVersion then
		info("Previous global data version: "..previousVersion)
		info("Migrated to version "..g.version)
	end
end)

script.on_event(defines.events.on_tick, function(event)
end)


script.on_event(defines.events.on_chunk_generated, function(event)
	split.on_chunk_generated(event)
end)

script.on_event(defines.events.on_player_created, function(event)
	split.on_player_created(event)
end)


function xx(obj)
	game.print(serpent.block(obj))
end