// Armory redcode safe

#define SPARE_ID_SAFE_CODE_1 47
#define SPARE_ID_SAFE_CODE_2 23

/// Золотой сейф для запасной карты капитана. Фиксированный код выдается главам на бумажке.
/// Спрайт из tgstation: icons/obj/storage/storage.dmi
/obj/structure/safe/spare_id
	name = "golden safe"
	desc = "A prestigious safe with a golden sheen, designated for storing the Captain's spare ID. The combination is known to station heads."
	icon = 'modular_bluemoon/icons/obj/storage/storage.dmi'
	icon_state = "spare_safe"
	density = FALSE

/obj/structure/safe/spare_id/Initialize(mapload)
	. = ..()
	tumblers = list(SPARE_ID_SAFE_CODE_1, SPARE_ID_SAFE_CODE_2)
	if(mapload && !locate(/obj/item/card/id/captains_spare) in src)
		var/obj/item/card/id/captains_spare/card = new(src)
		space += card.w_class
	SSticker.OnRoundstart(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(setup_spare_id_safe_and_bridge_airlocks)))

/obj/structure/safe/spare_id/update_icon_state()
	// tgstation storage.dmi: spare_safe (open), spare_safe_locked (closed)
	if(open)
		icon_state = "spare_safe"
	else
		icon_state = "spare_safe_locked"

#undef SPARE_ID_SAFE_CODE_1
#undef SPARE_ID_SAFE_CODE_2

/obj/structure/safe
	/// Список кодов, при которых открывается сейф
	var/list/open_security_levels = list()
	/// Переменная кастомизации интерфейса TGUI
	var/tgui_theme = "ntos"

/obj/structure/safe/ui_static_data(mob/user)
	var/list/data = list()
	data["theme"] = tgui_theme

	return data

/// Proc for opening safe via certain condition, using station code in our case.
/obj/structure/safe/proc/code_opening()
	SIGNAL_HANDLER
	return

//////////////////////////////////////////////////

/obj/structure/safe/floor/syndi
	name = "plastitanium safe"
	desc = "This looks like a hell of plastitanium chunk of armored safe, built into a wall or floor, with a dial and syndicate insignia on it."
	icon = 'modular_bluemoon/icons/obj/structures.dmi'
	icon_state = "floorsafe_syndi"
	number_of_tumblers = 4

/// Сейф оружейной СБ и только оружейной
/obj/structure/safe/floor/syndi/armory
	name = "armory safe"
	number_of_tumblers = 8
	maxspace = 48
	open_security_levels = list(SEC_LEVEL_RED, SEC_LEVEL_LAMBDA, SEC_LEVEL_GAMMA)
	tgui_theme = "syndicate"

/obj/structure/safe/floor/syndi/armory/Initialize(mapload)
	. = ..()
	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(code_opening)) // Ловим сигнал смены кода на станции

/obj/structure/safe/floor/syndi/armory/code_opening()
	if(GLOB.security_level in open_security_levels) // Если кодов нет в списке - не откроет
		playsound(src, 'modular_bluemoon/sound/effects/opening-gears.ogg', 200, ignore_walls = TRUE)
		visible_message("<span class='warning'>You hear a loud sound of something heavy opening.</span>")
		locked = 0
		open = 1
		current_tumbler_index = 7
		update_icon()

/obj/structure/safe/floor/syndi/armory/Destroy()
	. = ..()
	UnregisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED)

GLOBAL_VAR_INIT(spare_id_safe_setup_done, FALSE)

/// Роли глав, которым может выдаваться код от золотого сейфа
#define SPARE_ID_SAFE_HEAD_ROLES list("Captain", "Head of Personnel", "Head of Security", "Chief Engineer", "Research Director", "Chief Medical Officer")

/// Выдача бумажки с кодом всем главам и аварийный режим шлюзов мостика при отсутствии командования
/proc/setup_spare_id_safe_and_bridge_airlocks()
	if(GLOB.spare_id_safe_setup_done)
		return
	GLOB.spare_id_safe_setup_done = TRUE

	var/list/mob/living/carbon/human/heads = list()
	for(var/mob/living/carbon/human/H in GLOB.human_list)
		if(H.stat == DEAD || !H.mind || !(H.mind.assigned_role in SPARE_ID_SAFE_HEAD_ROLES))
			continue
		heads += H

	if(length(heads))
		for(var/mob/living/carbon/human/head in heads)
			var/obj/item/paper/fluff/spare_id_safe_code/paper = new()
			if(head.equip_to_slot_if_possible(paper, ITEM_SLOT_BACKPACK, disable_warning = TRUE, bypass_equip_delay_self = TRUE))
				// Успешно положено в рюкзак
			else
				paper.forceMove(get_turf(head))
	else
		// Нет глав — шлюзы в области мостика переводим в аварийный режим
		for(var/obj/machinery/door/airlock/A in GLOB.airlocks)
			var/area/airlock_area = get_area(A)
			if(!istype(airlock_area, /area/command/bridge))
				continue
			A.set_emergency_exit(TRUE)

#undef SPARE_ID_SAFE_HEAD_ROLES

