/// Совпадение предмета с задачей /datum/objective/steal (как у пинпоинтера целей).
/proc/item_matches_steal_objective(obj/item/I, datum/objective/steal/S)
	if(!I || !S.steal_target)
		return FALSE
	if(istype(I, S.steal_target))
		if(S.targetinfo)
			return S.targetinfo.check_special_completion(I)
		return TRUE
	if(S.targetinfo && (I.type in S.targetinfo.altitems))
		return S.targetinfo.check_special_completion(I)
	return FALSE

/// Метка «цель кражи» при осмотре предмета предателем, если тип предмета — цель активной задачи на кражу.
/proc/append_traitor_steal_target_examine(obj/item/I, mob/user, list/examine_list)
	if(!istype(I) || !examine_list || !user?.mind?.has_antag_datum(/datum/antagonist/traitor))
		return
	for(var/datum/objective/steal/S in GLOB.objectives)
		if(!S.steal_target)
			continue
		if(!length(S.get_owners()))
			continue
		if(item_matches_steal_objective(I, S))
			examine_list += "<hr>"
			examine_list += span_notice("[ЦЕЛЬ ДЛЯ КРАЖИ]")
			return
	for(var/datum/objective/steal_five_of_type/F in GLOB.objectives)
		if(!length(F.get_owners()))
			continue
		if(is_type_in_typecache(I, F.wanted_items))
			examine_list += "<hr>"
			examine_list += span_notice("[ЦЕЛЬ ДЛЯ КРАЖИ]")
			return
	for(var/datum/objective/heist/H in GLOB.objectives)
		if(!H.target || !ispath(H.target, /obj/item))
			continue
		if(!length(H.get_owners()))
			continue
		if(istype(I, H.target))
			examine_list += "<hr>"
			examine_list += span_notice("[ЦЕЛЬ ДЛЯ КРАЖИ]")
			return
