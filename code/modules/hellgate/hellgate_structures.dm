// HellGate / PactDivest — OBJ-структуры (спрайты из sprites_HellGate)
// Иконки: icons/obj/hellgate/
// Имена состояний взяты из .dmi

/obj/structure/hellgate_vehicle
	name = "внедорожник 4x4"
	desc = "Колёсная техника. Пока просто декоративный объект."
	icon = 'icons/obj/hellgate/4x4.dmi'
	icon_state = "land_rover"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_dropship
	name = "дропшип"
	desc = "Транспортный летательный аппарат."
	icon = 'icons/obj/hellgate/dropship.dmi'
	icon_state = "ud"
	anchored = TRUE
	density = TRUE

// campaign_big.dmi: mlrs, mlrs_broken, tank, tank_broken
/obj/structure/hellgate_campaign
	name = "кампанийский объект"
	desc = "Крупный объект для кампании/миссии."
	icon = 'icons/obj/hellgate/campaign_big.dmi'
	icon_state = "mlrs"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_campaign/tank
	name = "танк"
	desc = "Боевая машина."
	icon_state = "tank"

/obj/structure/hellgate_campaign/tank_broken
	name = "подбитый танк"
	icon_state = "tank_broken"

/obj/structure/hellgate_campaign/mlrs_broken
	name = "подбитая РСЗО"
	icon_state = "mlrs_broken"

// npc_beacon.dmi: beacon_undeployed, beacon_deployed_off, beacon_deployed_on, beacon_activating, beacon_emissive, beacon_deploying, fc_beacon_*
/obj/structure/hellgate_beacon
	name = "маяк НПС"
	desc = "Маяк. Будет активироваться и спавнить мобов."
	icon = 'icons/obj/hellgate/npc_beacon.dmi'
	icon_state = "beacon_undeployed"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_beacon/deployed
	icon_state = "beacon_deployed_off"

/obj/structure/hellgate_beacon/deployed_on
	icon_state = "beacon_deployed_on"

// train.dmi: nt, sat, hyperdyne, construction, crates, weapons, mech, empty, maglev
/obj/structure/hellgate_train
	name = "поезд"
	desc = "Состав. Пока просто декоративный объект."
	icon = 'icons/obj/hellgate/train.dmi'
	icon_state = "nt"
	anchored = TRUE
	density = TRUE

/obj/structure/hellgate_train/sat
	icon_state = "sat"

/obj/structure/hellgate_train/hyperdyne
	icon_state = "hyperdyne"

/obj/structure/hellgate_train/construction
	icon_state = "construction"

/obj/structure/hellgate_train/crates
	icon_state = "crates"

/obj/structure/hellgate_train/weapons
	icon_state = "weapons"

/obj/structure/hellgate_train/mech
	icon_state = "mech"

/obj/structure/hellgate_train/empty
	icon_state = "empty"

/obj/structure/hellgate_train/maglev
	icon_state = "maglev"

// tram_rails.dmi: railend, rail_floor, anchor, anchor_bot, rail
/obj/structure/hellgate_tram_rails
	name = "трамвайные рельсы"
	desc = "Рельсы для трамвая."
	icon = 'icons/obj/hellgate/tram_rails.dmi'
	icon_state = "rail"
	anchored = TRUE
	density = FALSE

/obj/structure/hellgate_tram_rails/railend
	icon_state = "railend"

/obj/structure/hellgate_tram_rails/rail_floor
	icon_state = "rail_floor"

/obj/structure/hellgate_tram_rails/anchor
	icon_state = "anchor"

/obj/structure/hellgate_tram_rails/anchor_bot
	icon_state = "anchor_bot"
