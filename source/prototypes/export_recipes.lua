require("libs.lua.table")

for name,tabl in pairs(data.raw.recipe) do
	local export = false
	
	if tabl.result then
		if data.raw.item["export_"..tabl.result] then
			export = true
		end
	elseif tabl.results then
		print("not implemented: "..name)
	end
	
	
	if export then
		local recipe = table.deepcopy(tabl)
		table.addTable(recipe,{
			name = "export_"..name,
			result = "export_"..tabl.result
		})
		
		data:extend({
			recipe
		})
	end
	
	
	
end