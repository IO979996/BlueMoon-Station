//All defines used in reactions are located in ..\__DEFINES\reactions.dm
// Остальные реакции перенесены в Rust (auxmos-bluemoon, bluemoon_reactions). В DM остаются:
// — condensation (создаётся динамически под реагенты, exclude = TRUE по умолчанию),
// — вызовы fire_expose, radiation_burn, fusion_ball (из Rust).

/proc/init_gas_reactions()
	. = list()

	for(var/r in subtypesof(/datum/gas_reaction))
		var/datum/gas_reaction/reaction = r
		reaction = new r
		if(!reaction.exclude)
			. += reaction
	sortTim(., GLOBAL_PROC_REF(cmp_gas_reaction))

/proc/cmp_gas_reaction(datum/gas_reaction/a, datum/gas_reaction/b) // compares lists of reactions by the maximum priority contained within the list
	return b.priority - a.priority

/datum/gas_reaction
	//regarding the requirements lists: the minimum or maximum requirements must be non-zero.
	//when in doubt, use MINIMUM_MOLE_COUNT.
	var/list/min_requirements
	var/exclude = FALSE //do it this way to allow for addition/removal of reactions midmatch in the future
	var/priority = 100 //lower numbers are checked/react later than higher numbers. if two reactions have the same priority they may happen in either order
	var/name = "reaction"
	var/id = "r"

/datum/gas_reaction/New()
	init_reqs()

/datum/gas_reaction/proc/init_reqs()

/datum/gas_reaction/proc/react(datum/gas_mixture/air, atom/location)
	return NO_REACTION

/datum/gas_reaction/proc/test()
	return list("success" = TRUE)

/datum/gas_reaction/condensation
	priority = 0
	name = "Condensation"
	id = "condense"
	exclude = TRUE
	var/datum/reagent/condensing_reagent

/datum/gas_reaction/condensation/New(datum/reagent/R)
	. = ..()
	if(!istype(R))
		return
	min_requirements = list(
		"MAX_TEMP" = initial(R.boiling_point)
	)
	min_requirements[R.get_gas()] = MOLES_GAS_VISIBLE
	name = "[R.name] condensation"
	id = "[R.type] condensation"
	condensing_reagent = GLOB.chemical_reagents_list[R.type]
	exclude = FALSE

/datum/gas_reaction/condensation/react(datum/gas_mixture/air, datum/holder)
	. = NO_REACTION
	var/turf/open/location = holder
	if(!istype(location))
		return
	var/temperature = air.return_temperature()
	var/static/datum/reagents/reagents_holder = new
	reagents_holder.clear_reagents()
	reagents_holder.chem_temp = temperature
	var/G = condensing_reagent.get_gas()
	var/amt = air.get_moles(G)
	air.adjust_moles(G, -min(initial(condensing_reagent.condensation_amount), amt))
	if(air.get_moles(G) < MOLES_GAS_VISIBLE)
		amt += air.get_moles(G)
		air.set_moles(G, 0.0)
	reagents_holder.add_reagent(condensing_reagent.type, amt)
	. = REACTING
	for(var/atom/movable/AM in location)
		if(location.intact && AM.level == 1)
			continue
		reagents_holder.reaction(AM, TOUCH)
	reagents_holder.reaction(location, TOUCH)

/proc/fire_expose(turf/open/location, datum/gas_mixture/air, temperature)
	if(istype(location) && temperature > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
		location.hotspot_expose(temperature, CELL_VOLUME)
		for(var/I in location)
			var/atom/movable/item = I
			item.temperature_expose(air, temperature, CELL_VOLUME)
		location.temperature_expose(air, temperature, CELL_VOLUME)

/proc/radiation_burn(turf/open/location, rad_power)
	if(istype(location) && prob(10))
		radiation_pulse(location, rad_power)

/proc/fusion_ball(datum/holder, reaction_energy, instability)
	var/turf/open/location
	if (istype(holder,/datum/pipeline)) //Find the tile the reaction is occuring on, or a random part of the network if it's a pipenet.
		var/datum/pipeline/fusion_pipenet = holder
		location = get_turf(pick(fusion_pipenet.members))
	else
		location = get_turf(holder)
	if(location)
		var/particle_chance = ((PARTICLE_CHANCE_CONSTANT)/(reaction_energy-PARTICLE_CHANCE_CONSTANT)) + 1//Asymptopically approaches 100% as the energy of the reaction goes up.
		if(prob(PERCENT(particle_chance)))
			location.fire_nuclear_particle()
		var/rad_power = max((FUSION_RAD_COEFFICIENT/instability) + FUSION_RAD_MAX,0)
		radiation_pulse(location,rad_power)
