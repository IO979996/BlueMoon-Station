// Личный додзё космического ниндзя: консоль телепорта на станцию (в случайную точку из списка как scroll) и кнопка «Убраться прочь» после выполнения всех целей.

// Область додзё (основная комната со спавном).
/area/ninja/outpost
	name = "SpiderClan Dojo"
	icon_state = "ninja_dojo"
	ambientsounds = list('sound/ambience/ambifailure.ogg', 'sound/ambience/ambigen4.ogg', 'sound/ambience/ambimaint2.ogg', 'sound/ambience/ambimystery.ogg', 'sound/ambience/ambitech2.ogg')
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	sound_environment = SOUND_AREA_MEDIUM_SOFTFLOOR

// Область «холдинга» / пещеры (криопод для модуля «второй шанс», оборудование под цели).
/area/ninja/holding
	name = "SpiderClan Holding Facility"
	icon_state = "ninja_holding"
	ambientsounds = list('sound/ambience/ambifailure.ogg', 'sound/ambience/ambigen4.ogg', 'sound/ambience/ambimaint2.ogg', 'sound/ambience/ambimystery.ogg', 'sound/ambience/ambitech2.ogg')
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	sound_environment = SOUND_AREA_MEDIUM_SOFTFLOOR

// Внешняя территория клана (космос/астероиды вокруг аутпоста).
/area/ninja/outside
	name = "SpiderClan Territory"
	icon_state = "ninja_outside"
	sound_environment = SOUND_AREA_ASTEROID

// Совместимость: телепорт призрака ищет и эту область.
/area/ruin/space/ninja_zen
	name = "Ninja Dojo"
	icon_state = "ninja_dojo"
	requires_power = FALSE
	has_gravity = STANDARD_GRAVITY
	sound_environment = SOUND_AREA_MEDIUM_SOFTFLOOR

// Криопод для выхода ниндзя из раунда и капсула «второй шанс» (вики SS220).
/obj/machinery/cryopod/ninja
	name = "крио-стазис Клана Паука"
	desc = "Капсула долговременной заморозки. Позволяет покинуть раунд и вернуться к Клану после выполнения целей. Только для космических ниндзя."
	icon_state = "cryopod-open"
	tele = TRUE
	time_till_despawn = 15 SECONDS
	on_store_message = "отбыл к Клану Паука."
	on_store_name = "Клан Паука"

/obj/machinery/cryopod/ninja/close_machine(atom/movable/target)
	if(isliving(target) && !is_ninja(target))
		to_chat(target, span_warning("Только космический ниндзя может использовать эту капсулу."))
		return
	return ..()

/obj/machinery/cryopod/ninja/MouseDrop_T(mob/living/target, mob/user)
	if(isliving(target))
		if(target == user && !is_ninja(user))
			to_chat(user, span_warning("Только космический ниндзя может использовать эту капсулу."))
			return
		if(target != user && !is_ninja(target))
			to_chat(user, span_warning("В капсулу Клана можно поместить только ниндзя."))
			return
	return ..()

// Ландмарк точки спавна ниндзя в додзё (по аналогии с wizardstart).
/obj/effect/landmark/ninja_spawn
	name = "ninja spawn"
	icon_state = "snukeop_spawn"

/obj/effect/landmark/ninja_spawn/Initialize(mapload)
	. = ..()
	GLOB.ninjastart += get_turf(src)
	return INITIALIZE_HINT_QDEL

// Додзё на карте ЦК (CentCom.dmm): область area/ninja/outpost, спавны, криопод, терминал внедрения (телепорт как у scroll + «Убраться прочь» после выполнения целей).
