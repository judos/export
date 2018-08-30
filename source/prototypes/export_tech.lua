require("libs.lua.table")

for name,tabl in pairs(data.raw.technology) do
	local addEffect = {}
	if tabl.effects then
		for _,modifier in pairs(tabl.effects) do

			if modifier.type == "unlock-recipe" then
				local recipe = modifier.recipe
				if data.raw.recipe["export_"..recipe] then
					
					table.insert(addEffect,{
						type = "unlock-recipe",
						recipe = "export_"..recipe
					})
					
				end
			end
			
		end
		
		for _,modifier in pairs(addEffect) do
			table.insert(tabl.effects, modifier)
		end
	end
	
end