/// Пинпоинтер из аплинка предателя: отслеживает выбранную цель из списка задач.
/obj/item/pinpointer/traitor_objective
	name = "синдикатовский пинпоинтер целей"
	desc = "Ручной трекер, синхронизируемый с вашими заданиями. Alt+клик — выбрать другое задание."
	icon_state = "pinpointer_syndicate"
	item_state = "pinpointer_black"
	resets_target = FALSE
	var/datum/mind/linked_mind
	var/datum/objective/selected_objective
	var/obj_index = 0
	var/next_global_search = 0

/obj/item/pinpointer/traitor_objective/equipped(mob/user, slot, initial)
	. = ..()
	try_link_mind(user)

/obj/item/pinpointer/traitor_objective/pickup(mob/user)
	. = ..()
	try_link_mind(user)

/obj/item/pinpointer/traitor_objective/proc/try_link_mind(mob/user)
	if(!user?.mind || linked_mind)
		return
	linked_mind = user.mind
	if(!selected_objective)
		init_default_objective()

/obj/item/pinpointer/traitor_objective/proc/init_default_objective()
	if(!linked_mind)
		return
	var/list/objs = linked_mind.get_all_objectives()
	if(!length(objs))
		return
	obj_index = 1
	selected_objective = objs[obj_index]

/obj/item/pinpointer/traitor_objective/attack_self(mob/living/user)
	try_link_mind(user)
	..()

/obj/item/pinpointer/traitor_objective/AltClick(mob/user)
	. = ..()
	if(!user.canUseTopic(src, BE_CLOSE))
		return
	try_link_mind(user)
	if(!linked_mind)
		to_chat(user, span_warning("Не удалось связать пинпоинтер с вашим разумом."))
		return
	var/list/objs = linked_mind.get_all_objectives()
	if(!length(objs))
		to_chat(user, span_warning("Нет задач для отслеживания."))
		return
	obj_index = (obj_index % length(objs)) + 1
	selected_objective = objs[obj_index]
	to_chat(user, span_notice("Отслеживание: [selected_objective.explanation_text]"))
	if(active)
		scan_for_target()
	update_icon()

/obj/item/pinpointer/traitor_objective/scan_for_target()
	if(!linked_mind || QDELETED(linked_mind))
		if(target)
			unset_target()
		return
	var/list/objs = linked_mind.get_all_objectives()
	if(selected_objective && !(selected_objective in objs))
		selected_objective = null
		init_default_objective()
	if(!selected_objective)
		if(target)
			unset_target()
		return
	var/atom/movable/new_target = resolve_trackable_atom(selected_objective)
	if(new_target != target)
		set_target(new_target)

/obj/item/pinpointer/traitor_objective/proc/resolve_trackable_atom(datum/objective/O)
	if(!O)
		return null
	if(istype(O, /datum/objective/steal/exchange/backstab))
		var/datum/objective/steal/S = O
		return pick_closest_atom(find_steal_candidates(S))
	if(istype(O, /datum/objective/steal/exchange))
		var/datum/objective/steal/exchange/E = O
		if(E.target?.current)
			return E.target.current
		return null
	if(istype(O, /datum/objective/nuclear/revert))
		for(var/obj/item/disk/nuclear/D in GLOB.poi_list)
			return D
		return null
	if(istype(O, /datum/objective/nuclear))
		return null
	if(istype(O, /datum/objective/protect_object))
		var/datum/objective/protect_object/PO = O
		if(PO.protect_target && !QDELETED(PO.protect_target))
			return PO.protect_target
		return null
	if(istype(O, /datum/objective/steal))
		var/datum/objective/steal/S = O
		return pick_closest_atom(find_steal_candidates(S))
	if(istype(O, /datum/objective/heist))
		var/datum/objective/heist/H = O
		if(!H.target)
			return null
		return pick_closest_atom(find_typepath_candidates(H.target))
	if(istype(O, /datum/objective/steal_five_of_type))
		var/datum/objective/steal_five_of_type/F = O
		return pick_closest_atom(find_typecache_candidates(F.wanted_items))
	if(istype(O, /datum/objective/download))
		return null
	if(istype(O, /datum/objective/sabotage))
		return null
	if(istype(O, /datum/objective/destroy))
		if(O.target?.current)
			return O.target.current
		return null
	if(O.target?.current)
		var/mob/living/M = O.target.current
		if(istype(M))
			return M
		return O.target.current
	return null

/obj/item/pinpointer/traitor_objective/proc/find_steal_candidates(datum/objective/steal/S)
	. = list()
	if(!S.steal_target)
		return
	for(var/obj/item/I in GLOB.poi_list)
		if(item_matches_steal_objective(I, S))
			. += I
	for(var/mob/living/M in GLOB.mob_living_list)
		for(var/obj/item/I in M.GetAllContents())
			if(item_matches_steal_objective(I, S))
				. += I
	if(length(.) || world.time < next_global_search)
		return
	next_global_search = world.time + 30
	for(var/obj/item/I in world)
		if(item_matches_steal_objective(I, S))
			. += I
			return

/obj/item/pinpointer/traitor_objective/proc/find_typepath_candidates(obj/path)
	. = list()
	if(!ispath(path, /obj))
		return
	for(var/obj/O in GLOB.poi_list)
		if(istype(O, path))
			. += O
	for(var/mob/living/M in GLOB.mob_living_list)
		for(var/obj/O in M.GetAllContents())
			if(istype(O, path))
				. += O
	if(length(.) || world.time < next_global_search)
		return
	next_global_search = world.time + 30
	for(var/obj/O in world)
		if(istype(O, path))
			. += O
			return

/obj/item/pinpointer/traitor_objective/proc/find_typecache_candidates(list/typecache)
	. = list()
	if(!length(typecache))
		return
	for(var/obj/item/I in GLOB.poi_list)
		if(is_type_in_typecache(I, typecache))
			. += I
	for(var/mob/living/M in GLOB.mob_living_list)
		for(var/obj/item/I in M.GetAllContents())
			if(is_type_in_typecache(I, typecache))
				. += I
	if(length(.) || world.time < next_global_search)
		return
	next_global_search = world.time + 30
	for(var/obj/item/I in world)
		if(is_type_in_typecache(I, typecache))
			. += I
			return

/obj/item/pinpointer/traitor_objective/proc/pick_closest_atom(list/atom/movable/cands)
	var/turf/here = get_turf(src)
	if(!here || !length(cands))
		return null
	var/atom/movable/best = null
	var/bestd = 1e9
	for(var/atom/movable/A in cands)
		if(QDELETED(A))
			continue
		var/turf/there = get_turf(A)
		if(!there || there.z != here.z)
			continue
		var/d = get_dist_euclidian(here, there)
		if(d < bestd)
			bestd = d
			best = A
	return best
