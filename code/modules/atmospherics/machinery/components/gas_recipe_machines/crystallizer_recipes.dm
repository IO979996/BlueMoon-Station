/// Global list of recipes for atmospheric machines (id -> recipe)
GLOBAL_LIST_INIT(gas_recipe_meta, gas_recipes_list())

/proc/gas_recipes_list()
	. = list()
	for(var/recipe_path in subtypesof(/datum/gas_recipe))
		var/datum/gas_recipe/recipe = new recipe_path()
		if(recipe.id != "")
			.[recipe.id] = recipe

/datum/gas_recipe
	var/id = ""
	var/machine_type = ""
	var/name = ""
	var/min_temp = TCMB
	var/max_temp = INFINITY
	var/energy_release = 0
	var/dangerous = FALSE
	/// Gas ID -> moles required (e.g. list(GAS_O2 = 1000, GAS_HYPERNOB = 85))
	var/list/requirements
	/// path -> count (e.g. list(/obj/item/hypernoblium_crystal = 1))
	var/list/products

/datum/gas_recipe/crystallizer
	machine_type = "Crystallizer"

/datum/gas_recipe/crystallizer/hypern_crystalium
	id = "hyper_crystalium"
	name = "Hypernoblium Crystal"
	min_temp = 3
	max_temp = 250
	energy_release = -250000
	requirements = list(GAS_O2 = 1000, GAS_HYPERNOB = 85)
	products = list(/obj/item/hypernoblium_crystal = 1)

/datum/gas_recipe/crystallizer/diamond
	id = "diamond"
	name = "Diamond"
	min_temp = 10000
	max_temp = 30000
	energy_release = 9500000
	requirements = list(GAS_CO2 = 1500)
	products = list(/obj/item/stack/sheet/mineral/diamond = 1)

/datum/gas_recipe/crystallizer/plasma_sheet
	id = "plasma_sheet"
	name = "Plasma sheet"
	min_temp = 10
	max_temp = 20
	energy_release = 3500000
	requirements = list(GAS_PLASMA = 450)
	products = list(/obj/item/stack/sheet/mineral/plasma = 1)

/datum/gas_recipe/crystallizer/crystallized_nitrium
	id = "crystallized_nitrium"
	name = "Nitrium crystal"
	min_temp = 10
	max_temp = 25
	energy_release = -45000
	requirements = list(GAS_NITRIUM = 150, GAS_O2 = 70, GAS_BZ = 50)
	products = list(/obj/item/nitrium_crystal = 1)
