


local tabl = {"stone-furnace", "steel-furnace", "electric-furnace"}

for _,name in pairs(tabl) do
	-- copy entities
	
	local furnace = deepcopy(data.raw.furnace[name])
	furnace.name = "export_"..name
	furnace.crafting_categories = {"export_smelting"}
	furnace.minable.result = "export_"..name
	local icon_size = furnace.icon_size or 32
	local sticker = {
		icon = "__export__/graphics/sticker-"..icon_size..".png",
		icon_size = icon_size,
	}
	iconAddLast(furnace,sticker)
	data:extend({ furnace })


	data.raw.item["export_"..name].place_result = "export_"..name


end