/datum/round_event_control/space_ninja
	name = "Spawn Space Ninja"
	typepath = /datum/round_event/ghost_role/space_ninja
	max_occurrences = 1
	weight = 10
	earliest_start = 45 MINUTES
	min_players = 0
	dynamic_should_hijack = TRUE
	category = EVENT_CATEGORY_INVASION
	description = "A space ninja infiltrates the station."

/datum/round_event/ghost_role/space_ninja
	minimum_required = 1
	role_name = "Space Ninja"

/datum/round_event/ghost_role/space_ninja/spawn_role()
	// Додзё на уровне ЦК (CentCom.dmm), точки в GLOB.ninjastart заполняются при загрузке карты.
	if(!length(GLOB.ninjastart))
		message_admins("Ninja Dojo has no spawn points (CentCom may not have loaded).")
		return MAP_ERROR

	var/list/candidates = get_candidates(ROLE_NINJA, null, ROLE_NINJA)
	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	var/mob/dead/selected_candidate = pick(candidates)
	var/key = selected_candidate.key

	var/mob/living/carbon/human/ninja = create_space_ninja(pick(GLOB.ninjastart))
	ninja.key = key
	ninja.mind.add_antag_datum(/datum/antagonist/ninja)
	spawned_mobs += ninja
	message_admins("[ADMIN_LOOKUPFLW(ninja)] has been made into a space ninja by an event.")
	log_game("[key_name(ninja)] was spawned as a ninja by an event.")

	return SUCCESSFUL_SPAWN


//=======//NINJA CREATION PROCS//=======//

/proc/create_space_ninja(spawn_loc)
	var/mob/living/carbon/human/new_ninja = new(spawn_loc)
	var/datum/preferences/random_human_options = new()//Randomize appearance for the ninja.
	random_human_options.real_name = "[pick(GLOB.ninja_titles)] [pick(GLOB.ninja_names)]"
	random_human_options.copy_to(new_ninja)
	new_ninja.dna.update_dna_identity()
	return new_ninja
