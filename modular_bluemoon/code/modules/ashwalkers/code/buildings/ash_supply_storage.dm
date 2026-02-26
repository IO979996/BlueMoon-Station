// Сундук/хранилище эшволкеров — куча эшовских вещей для некрополиса (порт из Whitemoon)
/obj/structure/closet/crate/ash_walker_supply
	name = "хранилище эшволкеров"
	desc = "Большой сундук, набитый одеждой, оружием и утварью пеплоходцев. Слава Некрополису."

/obj/structure/closet/crate/ash_walker_supply/PopulateContents()
	// Одежда — несколько вариантов и запас
	for(var/i in 1 to 12)
		new /obj/item/clothing/under/costume/gladiator/ash_walker(src)
	// Оружие и инструменты
	new /obj/item/melee/macahuitl(src)
	new /obj/item/melee/macahuitl(src)
	new /obj/item/reagent_containers/glass/beaker/primitive_centrifuge(src)
	new /obj/item/reagent_containers/glass/beaker/primitive_centrifuge(src)
	// Хирургические инструменты эшволкеров
	new /obj/item/scalpel/ashwalker(src)
	new /obj/item/retractor/ashwalker(src)
	new /obj/item/circular_saw/ashwalker(src)
	new /obj/item/hemostat/ashwalker(src)
	new /obj/item/cautery/ashwalker(src)
	// Крафт — кости, сухожилия, шкуры
	new /obj/item/stack/sheet/bone(src, 10)
	new /obj/item/stack/sheet/sinew(src, 10)
	new /obj/item/stack/sheet/animalhide/goliath_hide(src, 5)
	// Примитивные инструменты
	new /obj/item/wrench/ashwalker(src)
	new /obj/item/crowbar/ashwalker(src)
	new /obj/item/screwdriver/ashwalker(src)
	new /obj/item/wirecutters/ashwalker(src)
