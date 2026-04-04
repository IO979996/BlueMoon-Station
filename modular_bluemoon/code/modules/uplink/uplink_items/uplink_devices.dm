/datum/uplink_item/inteq/shieldbelt
	name = "Shieldbelt"
	desc = "Лучшие умы ЧВК додумались использовать портативные генераторы щита не только в скафандрах."
	item = /obj/item/shieldbelt
	cost = 12
	purchasable_from = (UPLINK_TRAITORS)

/datum/uplink_item/device_tools/traitor_objective_pinpointer
	name = "Пинпоинтер целей"
	desc = "Синхронизируется с вашими задачами и указывает на выбранную цель (украсть, убить, защитить и т.д.). Alt+клик — переключить задание."
	item = /obj/item/pinpointer/traitor_objective
	cost = 1
	purchasable_from = (UPLINK_TRAITORS)

/datum/uplink_item/device_tools/traitor_objective_pinpointer/purchase(mob/user, datum/component/uplink/U, atom/source)
	var/atom/A = spawn_item(item, user, U)
	var/turf/T = get_turf(user)
	var/atom/uplink = U.parent
	var/vr_text = is_vr_level(T.z) ? " in VR" : ""
	log_uplink("[key_name(user)] purchased [A.name] for [cost] telecrystals from [uplink?.name][vr_text]")
	if(!vr_text && !is_centcom_level(T.z) && GLOB.master_mode == ROUNDTYPE_EXTENDED)
		message_antigrif("[ADMIN_LOOKUPFLW(user)] purchased [A.name] at [ADMIN_VERBOSEJMP(T)].")
	if(purchase_log_vis && U.purchase_log)
		U.purchase_log.LogPurchase(A, src, cost)
	if(istype(A, /obj/item/pinpointer/traitor_objective))
		var/obj/item/pinpointer/traitor_objective/P = A
		if(user?.mind)
			P.linked_mind = user.mind
			P.init_default_objective()
