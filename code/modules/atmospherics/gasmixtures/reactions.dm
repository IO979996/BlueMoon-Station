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

// Реакции в Rust "auxmos-bluemoon": только id и min_requirements для регистрации в auxmos, логика в bluemoon.rs
/datum/gas_reaction/nobstop
	priority = 400
	name = "Noblium suppression"
	id = "nobstop"
/datum/gas_reaction/nobstop/init_reqs()
	min_requirements = list(GAS_HYPERNOB = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/vapor
	priority = 390
	name = "Water vapor"
	id = "vapor"
/datum/gas_reaction/vapor/init_reqs()
	min_requirements = list(GAS_H2O = MOLES_GAS_VISIBLE)

/datum/gas_reaction/plasmafire
	priority = 380
	name = "Plasma fire"
	id = "plasmafire"
/datum/gas_reaction/plasmafire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		GAS_PLASMA = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/tritfire
	priority = 375
	name = "Tritium fire"
	id = "tritfire"
/datum/gas_reaction/tritfire/init_reqs()
	min_requirements = list(
		"TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST,
		GAS_TRITIUM = MINIMUM_MOLE_COUNT,
		GAS_O2 = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/fusion
	priority = 370
	name = "Fusion"
	id = "fusion"
/datum/gas_reaction/fusion/init_reqs()
	min_requirements = list(
		"ENER" = FUSION_ENERGY_THRESHOLD,
		GAS_PLASMA = FUSION_MOLE_THRESHOLD,
		GAS_TRITIUM = MINIMUM_MOLE_COUNT
	)

/datum/gas_reaction/genericfire
	priority = 365
	name = "Generic fire"
	id = "genericfire"
/datum/gas_reaction/genericfire/init_reqs()
	min_requirements = list("TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST, "FIRE_REAGENTS" = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/nitrylformation
	priority = 360
	name = "Nitryl formation"
	id = "nitrylformation"
/datum/gas_reaction/nitrylformation/init_reqs()
	min_requirements = list("TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST, GAS_O2 = MINIMUM_MOLE_COUNT, GAS_PLASMA = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/bzformation
	priority = 355
	name = "BZ formation"
	id = "bzformation"
/datum/gas_reaction/bzformation/init_reqs()
	min_requirements = list(GAS_NITROUS = MINIMUM_MOLE_COUNT, GAS_PLASMA = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/stimformation
	priority = 350
	name = "Stimulum formation"
	id = "stimformation"
/datum/gas_reaction/stimformation/init_reqs()
	min_requirements = list(GAS_TRITIUM = MINIMUM_MOLE_COUNT, GAS_PLASMA = MINIMUM_MOLE_COUNT, GAS_NITROUS = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/nobformation
	priority = 345
	name = "Noblium formation"
	id = "nobformation"
/datum/gas_reaction/nobformation/init_reqs()
	min_requirements = list("MAX_TEMP" = NOBLIUM_FORMATION_MAX_TEMP, GAS_TRITIUM = MINIMUM_MOLE_COUNT, GAS_PLASMA = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/sterilization
	priority = 340
	name = "Miasma sterilization"
	id = "sterilization"
/datum/gas_reaction/sterilization/init_reqs()
	min_requirements = list("TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST, GAS_MIASMA = MINIMUM_MOLE_COUNT, GAS_O2 = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/nitric_oxide
	priority = 335
	name = "Nitric oxide decomposition"
	id = "nitric_oxide"
/datum/gas_reaction/nitric_oxide/init_reqs()
	min_requirements = list("TEMP" = FIRE_MINIMUM_TEMPERATURE_TO_EXIST, GAS_NITRIC = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/hagedorn
	priority = 330
	name = "Hagedorn"
	id = "hagedorn"
/datum/gas_reaction/hagedorn/init_reqs()
	min_requirements = list(GAS_PLASMA = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/dehagedorn
	priority = 325
	name = "De-Hagedorn"
	id = "dehagedorn"
/datum/gas_reaction/dehagedorn/init_reqs()
	min_requirements = list(GAS_PLASMA = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/freonfire
	priority = 320
	name = "Freon fire"
	id = "freonfire"
/datum/gas_reaction/freonfire/init_reqs()
	min_requirements = list(GAS_FREON = MINIMUM_MOLE_COUNT, GAS_O2 = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/freonformation
	priority = 315
	name = "Freon formation"
	id = "freonformation"
/datum/gas_reaction/freonformation/init_reqs()
	min_requirements = list("TEMP" = FREON_FORMATION_MIN_TEMPERATURE, GAS_PLASMA = MINIMUM_MOLE_COUNT, GAS_BZ = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/halon_o2removal
	priority = 310
	name = "Halon O2 removal"
	id = "halon_o2removal"
/datum/gas_reaction/halon_o2removal/init_reqs()
	min_requirements = list("TEMP" = HALON_COMBUSTION_MIN_TEMPERATURE, GAS_HALON = MINIMUM_MOLE_COUNT, GAS_O2 = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/healium_formation
	priority = 305
	name = "Healium formation"
	id = "healium_formation"
/datum/gas_reaction/healium_formation/init_reqs()
	min_requirements = list("TEMP" = HEALIUM_FORMATION_MIN_TEMP, GAS_PLASMA = MINIMUM_MOLE_COUNT, GAS_BZ = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/zauker_formation
	priority = 300
	name = "Zauker formation"
	id = "zauker_formation"
/datum/gas_reaction/zauker_formation/init_reqs()
	min_requirements = list("TEMP" = ZAUKER_FORMATION_MIN_TEMPERATURE, GAS_PLASMA = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/zauker_decomp
	priority = 295
	name = "Zauker decomposition"
	id = "zauker_decomp"
/datum/gas_reaction/zauker_decomp/init_reqs()
	min_requirements = list(GAS_ZAUKER = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/nitrium_formation
	priority = 290
	name = "Nitrium formation"
	id = "nitrium_formation"
/datum/gas_reaction/nitrium_formation/init_reqs()
	min_requirements = list("TEMP" = NITRIUM_FORMATION_MIN_TEMP, GAS_PLASMA = MINIMUM_MOLE_COUNT, GAS_HYDROGEN = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/nitrium_decomp
	priority = 285
	name = "Nitrium decomposition"
	id = "nitrium_decomp"
/datum/gas_reaction/nitrium_decomp/init_reqs()
	min_requirements = list("MAX_TEMP" = NITRIUM_DECOMPOSITION_MAX_TEMP, GAS_NITRIUM = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/pluox_formation
	priority = 280
	name = "Pluoxium formation"
	id = "pluox_formation"
/datum/gas_reaction/pluox_formation/init_reqs()
	min_requirements = list("TEMP" = PLUOXIUM_FORMATION_MIN_TEMP, "MAX_TEMP" = PLUOXIUM_FORMATION_MAX_TEMP, GAS_CO2 = MINIMUM_MOLE_COUNT, GAS_O2 = MINIMUM_MOLE_COUNT, GAS_TRITIUM = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/proto_nitrate_formation
	priority = 275
	name = "Proto-Nitrate formation"
	id = "proto_nitrate_formation"
/datum/gas_reaction/proto_nitrate_formation/init_reqs()
	min_requirements = list("TEMP" = PN_FORMATION_MIN_TEMPERATURE, "MAX_TEMP" = PN_FORMATION_MAX_TEMPERATURE, GAS_PLASMA = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/proto_nitrate_hydrogen_response
	priority = 270
	name = "Proto-Nitrate hydrogen response"
	id = "proto_nitrate_hydrogen_response"
/datum/gas_reaction/proto_nitrate_hydrogen_response/init_reqs()
	min_requirements = list(GAS_PROTO_NITRATE = MINIMUM_MOLE_COUNT, GAS_HYDROGEN = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/proto_nitrate_tritium_response
	priority = 265
	name = "Proto-Nitrate tritium response"
	id = "proto_nitrate_tritium_response"
/datum/gas_reaction/proto_nitrate_tritium_response/init_reqs()
	min_requirements = list("TEMP" = PN_TRITIUM_CONVERSION_MIN_TEMP, GAS_PROTO_NITRATE = MINIMUM_MOLE_COUNT, GAS_TRITIUM = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/proto_nitrate_bz_response
	priority = 260
	name = "Proto-Nitrate BZ response"
	id = "proto_nitrate_bz_response"
/datum/gas_reaction/proto_nitrate_bz_response/init_reqs()
	min_requirements = list("TEMP" = PN_BZASE_MIN_TEMP, "MAX_TEMP" = PN_BZASE_MAX_TEMP, GAS_PROTO_NITRATE = MINIMUM_MOLE_COUNT, GAS_PLASMA = MINIMUM_MOLE_COUNT)

/datum/gas_reaction/antinoblium_replication
	priority = 255
	name = "Antinoblium replication"
	id = "antinoblium_replication"
/datum/gas_reaction/antinoblium_replication/init_reqs()
	min_requirements = list("TEMP" = REACTION_OPPRESSION_MIN_TEMP, GAS_ANTINOBLIUM = MINIMUM_MOLE_COUNT, GAS_PLASMA = MINIMUM_MOLE_COUNT)

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
