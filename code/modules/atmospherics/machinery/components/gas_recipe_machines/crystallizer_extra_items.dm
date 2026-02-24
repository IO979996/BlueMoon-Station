/// Crystallizer recipes: gas crystal grenades, fuel pellets, stacks (from WhiteMoon)
/// Sprites: copy from WhiteMoon icons/obj/weapons/grenade.dmi, exploration.dmi, stack_objects.dmi, mineral sheets

// === Gas crystal grenades (base + types) ===
/obj/item/grenade/gas_crystal
	desc = "A crystal from the crystallizer."
	name = "Gas Crystal"
	icon = 'icons/obj/weapons/grenade.dmi'
	icon_state = "bluefrag"
	item_state = "flashbang"
	resistance_flags = FIRE_PROOF

/obj/item/grenade/gas_crystal/prime(mob/living/lanced_by)
	..()
	update_mob()

/obj/item/grenade/gas_crystal/healium_crystal
	name = "Healium crystal"
	desc = "A crystal made from Healium gas, cold to the touch."
	icon_state = "healium_crystal"
	var/fix_range = 7

/obj/item/grenade/gas_crystal/healium_crystal/prime(mob/living/lanced_by)
	..()
	playsound(src, 'sound/effects/spray2.ogg', 100, TRUE)
	for(var/turf/open/T in range(fix_range, src))
		var/datum/gas_mixture/new_air = new
		new_air.set_moles(GAS_O2, MOLES_O2STANDARD)
		new_air.set_moles(GAS_N2, MOLES_N2STANDARD)
		new_air.set_temperature(T20C)
		T.air.merge(new_air)
	qdel(src)

/obj/item/grenade/gas_crystal/proto_nitrate_crystal
	name = "Proto Nitrate crystal"
	desc = "A crystal made from Proto Nitrate gas."
	icon_state = "proto_nitrate_crystal"
	var/refill_range = 5
	var/n2_gas_amount = 80
	var/o2_gas_amount = 30

/obj/item/grenade/gas_crystal/proto_nitrate_crystal/prime(mob/living/lanced_by)
	..()
	playsound(src, 'sound/effects/spray2.ogg', 100, TRUE)
	for(var/turf/open/T in view(refill_range, src))
		var/dist = max(get_dist(T, src), 1)
		T.air.adjust_moles(GAS_N2, n2_gas_amount / dist)
		T.air.adjust_moles(GAS_O2, o2_gas_amount / dist)
	qdel(src)

/obj/item/grenade/gas_crystal/nitrous_oxide_crystal
	name = "N2O crystal"
	desc = "A crystal made from N2O gas."
	icon_state = "n2o_crystal"
	var/fill_range = 1
	var/n2o_gas_amount = 10

/obj/item/grenade/gas_crystal/nitrous_oxide_crystal/prime(mob/living/lanced_by)
	..()
	playsound(src, 'sound/effects/spray2.ogg', 100, TRUE)
	for(var/turf/open/T in view(fill_range, src))
		var/dist = max(get_dist(T, src), 1)
		T.air.adjust_moles(GAS_NITROUS, n2o_gas_amount / dist)
	qdel(src)

/obj/item/grenade/gas_crystal/crystal_foam
	name = "crystal foam"
	desc = "A crystal with a foggy inside."
	icon_state = "crystal_foam"
	var/breach_range = 7

/obj/item/grenade/gas_crystal/crystal_foam/prime(mob/living/lanced_by)
	..()
	var/datum/reagents/first_batch = new(75)
	var/datum/reagents/second_batch = new(50)
	first_batch.add_reagent(/datum/reagent/aluminium, 75)
	second_batch.add_reagent(/datum/reagent/smart_foaming_agent, 25)
	second_batch.add_reagent(/datum/reagent/toxin/acid/fluacid, 25)
	chem_splash(get_turf(src), breach_range, list(first_batch, second_batch))
	playsound(src, 'sound/effects/spray2.ogg', 100, TRUE)
	update_mob()
	qdel(src)

// === Fuel pellets ===
/obj/item/fuel_pellet
	name = "standard fuel pellet"
	desc = "A compressed fuel pellet."
	icon = 'icons/obj/exploration.dmi'
	icon_state = "fuel_basic"
	w_class = WEIGHT_CLASS_SMALL
	var/uses = 5

/obj/item/fuel_pellet/advanced
	name = "advanced fuel pellet"
	icon_state = "fuel_advanced"

/obj/item/fuel_pellet/exotic
	name = "exotic fuel pellet"
	icon_state = "fuel_exotic"

// === Stacks (crystallizer products) ===
/obj/item/stack/ammonia_crystals
	name = "ammonia crystals"
	singular_name = "ammonia crystal"
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "ammonia_crystal"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	max_amount = 50
	grind_results = list(/datum/reagent/ammonia = 10)
	merge_type = /obj/item/stack/ammonia_crystals

/obj/item/stack/sheet/mineral/metal_hydrogen
	name = "metallic hydrogen"
	singular_name = "metallic hydrogen sheet"
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-metal_hydrogen"
	merge_type = /obj/item/stack/sheet/mineral/metal_hydrogen

/obj/item/stack/sheet/mineral/zaukerite
	name = "zaukerite"
	singular_name = "zaukerite crystal"
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-zaukerite"
	merge_type = /obj/item/stack/sheet/mineral/zaukerite

/obj/item/stack/sheet/hot_ice
	name = "hot ice"
	singular_name = "hot ice sheet"
	icon = 'icons/obj/stack_objects.dmi'
	icon_state = "sheet-hot_ice"
	merge_type = /obj/item/stack/sheet/hot_ice
