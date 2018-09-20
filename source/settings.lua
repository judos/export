data:extend(
{
	{
		type = "bool-setting",
		name = "export_players_can_build_in_other_districts",
		setting_type = "runtime-per-user",
		order = "a",

		default_value = false
	},
	{
		type = "double-setting",
		name = "export_multiply_factor",
		setting_type = "runtime-global",
		order = "a",

		default_value = 1.5,
    minimum_value = 1,
    maximum_value = 10
	}
})