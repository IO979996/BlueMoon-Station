/// Deferred callbacks from wiremod ports (matches TG SScircuit_component behaviour)
SUBSYSTEM_DEF(circuit_component)
	name = "Circuit Components"
	flags = SS_BACKGROUND|SS_NO_INIT
	priority = FIRE_PRIORITY_DEFAULT
	wait = 1
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/queued_callbacks = list()

/datum/controller/subsystem/circuit_component/proc/add_callback(datum/callback/CL)
	if(!CL)
		return
	queued_callbacks += CL

/datum/controller/subsystem/circuit_component/fire(resumed = FALSE)
	if(!length(queued_callbacks))
		return
	var/list/run = queued_callbacks
	queued_callbacks = list()
	for(var/datum/callback/CB in run)
		if(!QDELETED(CB))
			CB.Invoke()
		if(MC_TICK_CHECK)
			return
