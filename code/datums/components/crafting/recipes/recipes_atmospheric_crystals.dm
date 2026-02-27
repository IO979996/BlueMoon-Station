// Крафты из продуктов кристаллайзера (вкладка Atmospheric -> Crystals)
// + рецепты атмос-оборудования из WhiteMoon-station (Atmospheric -> Atmos equipment)

/datum/crafting_recipe/zaukerite_bolt
	name = "Zaukerite bolt"
	result = /obj/item/zaukerite_bolt
	reqs = list(
		/obj/item/stack/sheet/mineral/zaukerite = 1,
		/obj/item/stack/rods = 1,
	)
	time = 25
	category = CAT_ATMOSPHERIC
	subcategory = CAT_CRYSTALS

/datum/crafting_recipe/hot_ice_pack
	name = "Hot ice cooling pack"
	result = /obj/item/hot_ice_pack
	reqs = list(
		/obj/item/stack/sheet/hot_ice = 3,
		/obj/item/stack/sheet/cloth = 2,
	)
	time = 30
	category = CAT_ATMOSPHERIC
	subcategory = CAT_CRYSTALS

// --- Atmos equipment (из WhiteMoon atmospheric.dm) ---
/datum/crafting_recipe/igniter
	name = "Igniter"
	result = /obj/machinery/igniter
	reqs = list(
		/obj/item/stack/sheet/metal = 5,
		/obj/item/assembly/igniter = 1,
	)
	time = 20
	category = CAT_ATMOSPHERIC
	subcategory = CAT_ATMOSPHERIC_EQUIPMENT

/datum/crafting_recipe/ammonia_pack
	name = "Ammonia pack"
	result = /obj/item/ammonia_pack
	reqs = list(
		/obj/item/stack/ammonia_crystals = 3,
		/obj/item/stack/sheet/cloth = 2,
	)
	time = 25
	category = CAT_ATMOSPHERIC
	subcategory = CAT_CRYSTALS

/datum/crafting_recipe/crystal_cell_assembly
	name = "Crystal cell assembly"
	result = /obj/item/stock_parts/cell/crystal_cell
	reqs = list(
		/obj/item/stack/sheet/mineral/plasma = 2,
		/obj/item/stack/sheet/mineral/diamond = 1,
		/obj/item/stack/cable_coil = 5,
		/obj/item/stack/sheet/glass = 1,
	)
	tools = list(TOOL_WELDER, TOOL_SCREWDRIVER)
	time = 40
	category = CAT_ATMOSPHERIC
	subcategory = CAT_CRYSTALS
