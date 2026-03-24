/// NTNet / legacy cipher material (was also used by removed Integrated Electronics).
PROCESSING_SUBSYSTEM_DEF(circuit)
	name = "Circuit"
	stat_tag = "CIR"
	init_order = INIT_ORDER_CIRCUIT
	flags = NONE

	var/cipherkey

/datum/controller/subsystem/processing/circuit/Initialize(start_timeofday)
	cipherkey = uppertext(random_string(2000 + rand(0, 10), GLOB.alphabet))
	return ..()
