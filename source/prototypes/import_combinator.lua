require "libs.lua.table"



local importCombinator = deepcopy(data.raw["constant-combinator"]["constant-combinator"])
importCombinator.name = "import-combinator"
importCombinator.order = "zz"
data:extend({ importCombinator })