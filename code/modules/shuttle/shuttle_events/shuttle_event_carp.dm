/// Carp pass by or through the shuttle during hyperspace (tg-style CARPTIDE)
/datum/shuttle_event/simple_spawner/carp
	name = "Косяк карпов (опасно!)"
	event_probability = 4
	activation_fraction = 0.2
	spawning_list = list(/mob/living/simple_animal/hostile/carp = 12, /mob/living/simple_animal/hostile/carp/megacarp = 3)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE | SHUTTLE_EVENT_MISS_SHUTTLE
	spawn_probability_per_process = 20
	remove_from_list_when_spawned = TRUE
	self_destruct_when_empty = TRUE

/datum/shuttle_event/simple_spawner/carp/friendly
	name = "Косяк карпов (безобидно)"
	event_probability = 3
	activation_fraction = 0.1
	spawning_list = list(/mob/living/simple_animal/hostile/carp = 1)
	spawning_flags = SHUTTLE_EVENT_HIT_SHUTTLE | SHUTTLE_EVENT_MISS_SHUTTLE
	spawns_per_spawn = 2
	spawn_probability_per_process = 100
	remove_from_list_when_spawned = FALSE
	var/hit_the_shuttle_chance = 40

/datum/shuttle_event/simple_spawner/carp/friendly/get_spawn_turf()
	return prob(hit_the_shuttle_chance) ? pick(spawning_turfs_hit) : pick(spawning_turfs_miss)
