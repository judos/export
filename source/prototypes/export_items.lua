require("libs.lua.string")
require("libs.lua.table")
require("libs.prototypes.icons")

data:extend(
{
  {
    type = "item-group",
    name = "export",
    order = "g",
    icon = "__export__/graphics/export.png",
    icon_size = 64
  },
	{
    type = "item-subgroup",
    name = "export_items",
    group = "export",
    order = "a"
  },
})


function main()
	local types = {
		"item", "rail-planner", "module", 
		"tool", -- research packs
		"item-with-entity-data", -- cars, trains, wagon, tanks
		"gun", "armor", "ammo", "mining-tool", "repair-tool", "selection-tool",
		"capsule" -- capsules, grenades, discharge defence
	}
	 
	for _,typ in pairs(types) do
		for name,itemTable in pairs(data.raw[typ]) do
			if not name:starts("export_") and not name:find("barrel") then
				create_item(name,itemTable)
			end
		end
	end
end

function l(text)
	if ll then
		print(serpent.block(text))
	end
end

function create_item(name,itemTable)
	ll = false --name =="nuclear-fuel"
	
	local icon_size = itemTable.icon_size or 32
	local sticker = {
		icon = "__export__/graphics/sticker-"..icon_size..".png",
		icon_size = icon_size
	}
	local itemCopy = deepcopy(itemTable)
	iconAddLast(itemCopy, sticker)
	
	data:extend({
		{
			type = "item",
			name = "export_"..name,
			icons = itemCopy.icons,
			icon_size = itemCopy.icon_size,
			flags = itemTable.flags,
			subgroup = "export_items",
			order = itemTable.order,
			stack_size = itemTable.stack_size
		}
	--[[
	{
			type = "recipe",
			name = "export_"..name,
			icon_size = 32,
			category = "incinerator",
			icon = "__hardCrafting__/graphics/icons/fire.png",
			hidden = true,
			ingredients = {{name, 1}},
			energy_required = time,
			results =
			{
				{type="item", name="coal-dust", probability=0.1, amount_min=1, amount_max=1},
			}
		}
		]]--
	})
end

main()