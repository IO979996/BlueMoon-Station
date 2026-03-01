// Консоль в додзё: телепорт на станцию в случайную точку из списка (как scroll of teleportation) и кнопка «Убраться прочь» после выполнения остальных целей.

/proc/ninja_other_objectives_complete(mob/living/carbon/human/ninja)
	if(!ninja?.mind)
		return FALSE
	var/list/objectives = ninja.mind.get_all_objectives()
	if(!length(objectives))
		return FALSE
	for(var/datum/objective/O in objectives)
		if(istype(O, /datum/objective/ninja_leave))
			continue
		if(!O.completed && !O.check_completion())
			return FALSE
	return TRUE

/// TRUE, если выполнено не менее min_count целей (цель «Убраться прочь» не учитывается).
/proc/ninja_completed_objectives_count(mob/living/carbon/human/ninja, min_count = 3)
	if(!ninja?.mind || min_count <= 0)
		return FALSE
	var/completed = 0
	for(var/datum/objective/O in ninja.mind.get_all_objectives())
		if(istype(O, /datum/objective/ninja_leave))
			continue
		if(O.completed || O.check_completion())
			completed++
			if(completed >= min_count)
				return TRUE
	return FALSE

/obj/structure/ninjatele
	name = "Терминал внедрения"
	desc = "Консоль для телепортации на станцию в случайное место из сетки сканов (как свиток телепортации)."
	icon = 'icons/obj/ninjaobjects.dmi'
	icon_state = "teleconsole"
	anchored = TRUE

/obj/structure/ninjatele/attack_hand(mob/user, list/params)
	if(!is_ninja(user))
		return
	var/mob/living/carbon/human/ninja = user
	var/choice = tgui_alert(ninja, "Телепортироваться на станцию в случайную точку?", "Терминал внедрения", list("Телепорт на станцию", "Отмена"))
	if(choice != "Телепорт на станцию" || !ninja.can_interact_with(src))
		return
	add_fingerprint(ninja)
	ninja_teleport_to_station(ninja)

/obj/structure/ninjatele/proc/ninja_teleport_to_station(mob/living/carbon/human/ninja)
	if(!length(GLOB.teleportlocs))
		to_chat(ninja, span_warning("Сетка сканов станции недоступна."))
		return
	var/area_name = pick(GLOB.teleportlocs)
	var/area/thearea = GLOB.teleportlocs[area_name]
	var/list/L = list()
	for(var/turf/T in get_area_turfs(thearea.type))
		if(!is_blocked_turf(T))
			L += T
	if(!length(L))
		to_chat(ninja, span_warning("Не удалось найти подходящую точку в выбранной зоне."))
		return
	var/turf/dest = pick(L)
	var/turf/T = get_turf(ninja)
	if(do_teleport(ninja, dest, forceMove = TRUE, channel = TELEPORT_CHANNEL_MAGIC, forced = TRUE))
		ninja.log_message("Ninja VOID-shifted from [COORD(T)] to [COORD(ninja)].", LOG_GAME)
		playsound(ninja.loc, 'sound/effects/phasein.ogg', 25, TRUE)
		playsound(ninja.loc, 'sound/effects/sparks2.ogg', 50, TRUE)
		new /obj/effect/temp_visual/dir_setting/ninja/phase(get_turf(ninja), ninja.dir)
		to_chat(ninja, span_boldnotice("Телепортация на станцию успешна."))

/// Вызывается из способности костюма «Убраться прочь» или при необходимости из консоли. Завершает раунд для ниндзя.
/proc/ninja_leave_round(mob/living/carbon/human/ninja)
	if(!ninja?.mind)
		return
	var/datum/objective/ninja_leave/leave_obj = locate(/datum/objective/ninja_leave) in ninja.mind.get_all_objectives()
	if(leave_obj)
		leave_obj.completed = TRUE
	ninja.visible_message(span_boldnotice("[ninja] растворяется в дыму и исчезает в никуда!"))
	playsound(ninja, 'sound/effects/smoke.ogg', 30, TRUE)
	var/turf/T = get_turf(ninja)
	new /obj/effect/particle_effect/smoke(T)
	ninja.log_message("Ninja left the round (all objectives complete).", LOG_GAME)
	ninja.ghostize(FALSE, penalize = FALSE, voluntary = TRUE)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(qdel), ninja), 1)
