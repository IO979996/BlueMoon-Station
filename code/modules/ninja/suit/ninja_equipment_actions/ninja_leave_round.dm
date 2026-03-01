// Способность «Убраться прочь» выдаётся костюмом после выполнения всех целей (кроме одноимённой). Появляется в панели способностей с оповещением в чат.

/datum/action/item_action/ninja_leave_round
	name = "Убраться прочь"
	desc = "Покинуть станцию и завершить миссию. Доступно после выполнения всех 6 целей."
	button_icon_state = "ninja_exit"
	icon_icon = 'icons/mob/actions/actions_ninja.dmi'
	background_icon_state = "background_green"

/datum/action/item_action/ninja_leave_round/Trigger(trigger_flags)
	. = ..()
	if(!. || !iscarbon(owner))
		return
	var/mob/living/carbon/human/ninja = owner
	if(!ninja?.mind)
		return
	ninja_leave_round(ninja)
