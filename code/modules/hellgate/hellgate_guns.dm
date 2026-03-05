// HellGate / PactDivest — оружие на спрайтах sprites_HellGate
// Пистолет VP78 10mm, винтовка C77 7.62, пулемёт M41A 5.56
// Иконки: icons/obj/hellgate/, в руках: icons/mob/inhands/hellgate/
// Имена состояний взяты из .dmi (pistols: vp78/vp78_e, rifles64: c77/c77_e, machineguns64: m41a/m41a_e и др.)

// Магазин 7.62 для C77 (в билде нет отдельного m762)
/obj/item/ammo_box/magazine/m762
	name = "магазин (7.62мм)"
	desc = "Магазин под винтовочный патрон 7.62."
	icon = 'icons/obj/hellgate/rifle-ammo.dmi'
	icon_state = "c77"
	ammo_type = /obj/item/ammo_casing/a762
	caliber = "a762"
	max_ammo = 30
	multiple_sprites = 2

/obj/item/gun/ballistic/automatic/pistol/hellgate_vp78
	name = "VP78"
	desc = "Пистолет калибра 10мм. В билде."
	icon = 'icons/obj/hellgate/pistols.dmi'
	icon_state = "vp78"
	item_state = "vp78"
	lefthand_file = 'icons/mob/inhands/hellgate/pistols_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/pistols_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/m10mm
	fire_sound = 'sound/weapons/gun/pistol/shot.ogg'
	can_suppress = FALSE
	burst_size = 1
	fire_delay = 0
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC)
	automatic_burst_overlay = FALSE

/obj/item/gun/ballistic/automatic/pistol/hellgate_vp78/update_icon_state()
	icon_state = chambered ? "vp78" : "vp78_e"

/obj/item/gun/ballistic/automatic/hellgate_c77
	name = "C77"
	desc = "Винтовка калибра 7,62 (как калаш 12 в билде)."
	icon = 'icons/obj/hellgate/rifles64.dmi'
	icon_state = "c77"
	item_state = "c77"
	lefthand_file = 'icons/mob/inhands/hellgate/rifles_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/rifles_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/m762
	fire_sound = 'sound/weapons/rifleshot.ogg'
	can_suppress = FALSE
	burst_size = 1
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT)
	automatic_burst_overlay = FALSE
	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/ballistic/automatic/hellgate_c77/update_icon_state()
	icon_state = chambered ? "c77" : "c77_e"

/obj/item/gun/ballistic/automatic/hellgate_m41a
	name = "M41A"
	desc = "Автомат калибра 5,56."
	icon = 'icons/obj/hellgate/machineguns64.dmi'
	icon_state = "m41a"
	item_state = "m41a"
	lefthand_file = 'icons/mob/inhands/hellgate/machineguns_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/machineguns_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/m556
	fire_sound = 'sound/weapons/rifleshot.ogg'
	can_suppress = FALSE
	burst_size = 3
	burst_shot_delay = 2
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	automatic_burst_overlay = TRUE
	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/ballistic/automatic/hellgate_m41a/update_icon_state()
	icon_state = chambered ? "m41a" : "m41a_e"

// V41 — 7.62 (как и C74). В inhand .dmi нет состояния v41 — используем m41a для отображения в руках
/obj/item/gun/ballistic/automatic/hellgate_v41
	name = "V41"
	desc = "Пулемёт калибра 7,62."
	icon = 'icons/obj/hellgate/machineguns64.dmi'
	icon_state = "v41"
	item_state = "m41a"
	lefthand_file = 'icons/mob/inhands/hellgate/machineguns_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/machineguns_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/m762
	fire_sound = 'sound/weapons/rifleshot.ogg'
	can_suppress = FALSE
	burst_size = 3
	burst_shot_delay = 2
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	automatic_burst_overlay = TRUE
	weapon_weight = WEAPON_HEAVY

/obj/item/gun/ballistic/automatic/hellgate_v41/update_icon_state()
	icon_state = chambered ? "v41" : "v41_e"

// C74 — 7.62
/obj/item/gun/ballistic/automatic/hellgate_c74
	name = "C74"
	desc = "Автомат калибра 7,62."
	icon = 'icons/obj/hellgate/machineguns64.dmi'
	icon_state = "c74"
	item_state = "c74"
	lefthand_file = 'icons/mob/inhands/hellgate/machineguns_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/machineguns_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/m762
	fire_sound = 'sound/weapons/rifleshot.ogg'
	can_suppress = FALSE
	burst_size = 3
	burst_shot_delay = 2
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	automatic_burst_overlay = TRUE
	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/ballistic/automatic/hellgate_c74/update_icon_state()
	icon_state = chambered ? "c74" : "c74_e"

// SG60 — .45
/obj/item/gun/ballistic/automatic/hellgate_sg60
	name = "SG60"
	desc = "Пулемёт калибра .45."
	icon = 'icons/obj/hellgate/machineguns64.dmi'
	icon_state = "sg60"
	item_state = "sg60"
	lefthand_file = 'icons/mob/inhands/hellgate/machineguns_left_1.dmi'
	righthand_file = 'icons/mob/inhands/hellgate/machineguns_right_1.dmi'
	mag_type = /obj/item/ammo_box/magazine/smgm45
	fire_sound = 'sound/weapons/gunshot_smg.ogg'
	can_suppress = FALSE
	burst_size = 3
	burst_shot_delay = 2
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	automatic_burst_overlay = TRUE
	weapon_weight = WEAPON_MEDIUM

/obj/item/gun/ballistic/automatic/hellgate_sg60/update_icon_state()
	icon_state = chambered ? "sg60" : "sg60_e"
