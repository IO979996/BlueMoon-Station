/**
 * Flying blood splatter (tgstation-style): moves across turfs, leaves a trail, and can stain mobs/objects along the path.
 */
/obj/effect/decal/cleanable/blood/hitsplatter
	name = "blood splatter"
	desc = "A spray of blood."
	pass_flags = PASSTABLE | PASSGRILLE
	icon_state = "splatter1"
	random_icon_states = list("splatter1", "splatter2", "splatter3", "splatter4", "splatter5")
	plane = GAME_PLANE
	layer = ABOVE_WINDOW_LAYER
	mergeable_decal = FALSE
	turf_loc_check = FALSE
	var/turf/prev_loc
	/// Skip the end-of-flight floor DNA when we already placed a wall splatter etc.
	var/skip = FALSE
	/// How many dense things we can paint before expiring; also scales moveloop range.
	var/splatter_strength = 3
	var/hit_endpoint = FALSE
	/// Delay between steps (deciseconds), same scale as [/datum/controller/subsystem/move_manager/proc/move_towards].
	var/splatter_speed = 1
	var/flight_dir = NONE
	var/leave_blood = TRUE
	var/datum/move_loop/blood_move_loop

/obj/effect/decal/cleanable/blood/hitsplatter/Initialize(mapload, list/datum/disease/diseases)
	. = ..()
	prev_loc = get_turf(src)
	leave_blood = TRUE

/obj/effect/decal/cleanable/blood/hitsplatter/Destroy()
	detach_blood_move_loop()
	return ..()

/obj/effect/decal/cleanable/blood/hitsplatter/proc/detach_blood_move_loop()
	if(!blood_move_loop)
		return
	UnregisterSignal(blood_move_loop, list(COMSIG_MOVELOOP_PREPROCESS_CHECK, COMSIG_MOVELOOP_POSTPROCESS, COMSIG_PARENT_QDELETING))
	blood_move_loop = null

/obj/effect/decal/cleanable/blood/hitsplatter/proc/finish_flight_splat()
	if(QDELETED(src))
		return
	if(isturf(loc) && !skip && length(blood_DNA))
		playsound(src, 'sound/weapons/slice.ogg', 35, TRUE, -1)
		loc.add_blood_DNA(blood_DNA.Copy(), null)

/obj/effect/decal/cleanable/blood/hitsplatter/proc/expire()
	if(QDELETED(src))
		return
	SSmove_manager.stop_looping(src)
	detach_blood_move_loop()
	finish_flight_splat()
	qdel(src)

/obj/effect/decal/cleanable/blood/hitsplatter/proc/fly_towards(turf/target_turf, range)
	if(!target_turf || QDELETED(src))
		qdel(src)
		return
	flight_dir = get_dir(src, target_turf)
	blood_move_loop = SSmove_manager.move_towards(
		src,
		target_turf,
		splatter_speed,
		FALSE,
		splatter_speed * range,
		SSmovement,
		MOVEMENT_ABOVE_SPACE_PRIORITY,
		MOVEMENT_LOOP_START_FAST,
	)
	if(!blood_move_loop)
		qdel(src)
		return
	RegisterSignal(blood_move_loop, COMSIG_MOVELOOP_PREPROCESS_CHECK, PROC_REF(pre_move))
	RegisterSignal(blood_move_loop, COMSIG_MOVELOOP_POSTPROCESS, PROC_REF(post_move))
	RegisterSignal(blood_move_loop, COMSIG_PARENT_QDELETING, PROC_REF(loop_done))

/obj/effect/decal/cleanable/blood/hitsplatter/proc/pre_move(datum/move_loop/source)
	SIGNAL_HANDLER
	prev_loc = get_turf(src)

/obj/effect/decal/cleanable/blood/hitsplatter/proc/post_move(datum/move_loop/source, succeed, visual_delay)
	SIGNAL_HANDLER
	if(loc == prev_loc || !isturf(loc))
		return
	for(var/atom/movable/iter_atom in loc)
		if(hit_endpoint)
			return
		if(iter_atom == src || iter_atom.invisibility || iter_atom.alpha <= 0 || (isobj(iter_atom) && !iter_atom.density))
			continue
		if(splatter_strength <= 0)
			break
		if(!length(blood_DNA))
			continue
		iter_atom.add_blood_DNA(blood_DNA.Copy(), null)
		splatter_strength--
		if(splatter_strength <= 0)
			expire()
			return
	if(!leave_blood)
		if(length(blood_DNA))
			loc.add_blood_DNA(blood_DNA.Copy(), null)
		return
	var/obj/effect/decal/cleanable/blood/splats/trail = new(loc, null)
	trail.transfer_blood_dna(blood_DNA, null)
	trail.bloodiness = max(round(trail.bloodiness * 0.34), 1)
	trail.update_icon()

/obj/effect/decal/cleanable/blood/hitsplatter/proc/loop_done(datum/source)
	SIGNAL_HANDLER
	blood_move_loop = null
	if(QDELETED(src))
		return
	finish_flight_splat()
	qdel(src)

/obj/effect/decal/cleanable/blood/hitsplatter/Bump(atom/bumped_atom)
	if(!iswallturf(bumped_atom) && !istype(bumped_atom, /obj/structure/window))
		expire()
		return
	if(istype(bumped_atom, /obj/structure/window))
		var/obj/structure/window/bumped_window = bumped_atom
		if(!bumped_window.fulltile)
			hit_endpoint = TRUE
			expire()
			return
	hit_endpoint = TRUE
	var/turf/wall_turf = get_turf(prev_loc)
	if(!leave_blood)
		if(wall_turf && length(blood_DNA))
			wall_turf.add_blood_DNA(blood_DNA.Copy(), null)
		skip = TRUE
		SSmove_manager.stop_looping(src)
		detach_blood_move_loop()
		qdel(src)
		return
	if(wall_turf && length(blood_DNA))
		var/obj/effect/decal/cleanable/blood/splatter/final_splatter = new(wall_turf, null)
		final_splatter.transfer_blood_dna(blood_DNA, null)
		final_splatter.pixel_x = (dir == EAST ? 32 : (dir == WEST ? -32 : 0))
		final_splatter.pixel_y = (dir == NORTH ? 32 : (dir == SOUTH ? -32 : 0))
	skip = TRUE
	SSmove_manager.stop_looping(src)
	detach_blood_move_loop()
	qdel(src)
