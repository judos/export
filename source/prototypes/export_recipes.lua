require("libs.lua.table")
require("libs.lua.indices")
require("libs.prototypes.recipe")


data:extend({
  {
    type = "recipe-category",
    name = "export_smelting"
  },
})


function check(tabl,keyArr)
	local value = table.getMD(tabl,keyArr)
	if value == nil then
		return
	end
	
	if type(value)=="string" then
		table.setMD(tabl,keyArr,"export_"..value)
		return
	elseif type(value)=="table" then
		for _,result in pairs(value) do
			if data.raw.item["export_"..result.name] then
				result.name = "export_"..result.name
			end
		end
		return
	end
	error("invalid type "..type(value).." received for keyArr: "..serpent.block(keyArr).." and table: "..serpent.block(tabl))
end


function updateRecipeIcon(recipeNew)
	local icon_size = recipeNew.icon_size
	if icon_size and (icon_size ~= 32 and icon_size ~= 64 and icon_size ~= 128) then
		error("ERROR: icon_size that is not 32, 64 or 128: "..name)
	end
	if not icon_size then icon_size = 32 end
	local sticker = {
		icon = "__export__/graphics/sticker-"..icon_size..".png",
		icon_size = icon_size,
	}
	local icons = {}
	if recipeNew.icon then
		icons = { {icon=recipeNew.icon}, sticker }
	elseif recipeNew.icons then
		icons = table.deepcopy(recipeNew.icons)
		table.insert(icons, sticker)
	end
	recipeNew.icon = nil
	recipeNew.icons = icons
end


for name,recipe in pairs(data.raw.recipe) do
	if not name:starts("export_") then
		xxx = name =="copper-plate"
		xx("Before "..name)
		xx(recipe)
		--ll = false --name=="submachine-gun"
		
		-- find results (depending on difficulty/result/results)
		local results = recipeGetResults(recipe)
		
		-- check whether this recipe needs exporting
		local export = true
		for _,result in pairs(results) do
			xx("checking item: "..result.name)
			if not data.raw.item["export_"..result.name] then
				export = false
			end
		end
		
		xx("export: "..tostring(export))
		if export then
			local recipeNew = deepcopy(recipe)
			recipeNew.name = "export_"..recipe.name
			
			if recipeNew.icon or recipeNew.icons then
				updateRecipeIcon(recipeNew)
			end
			
			if recipeNew.category == "smelting" then
				recipeNew.category = "export_smelting"
			end
				
			check(recipeNew,{"result"})
			check(recipeNew,{"results"})
			check(recipeNew,{"normal","result"})
			check(recipeNew,{"normal","results"})
			check(recipeNew,{"expensive","result"})
			check(recipeNew,{"expensive","results"})

			xx("added:")
			xx(recipeNew)
			
			data:extend({
				recipeNew
			})
		end
	
	end
end

