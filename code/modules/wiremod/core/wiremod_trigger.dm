/// Invoked by TRIGGER_CIRCUIT_COMPONENT macro (port may be null).
/proc/trigger_wiremod_circuit_component(obj/item/circuit_component/comp, datum/port/input/port)
	if(!QDELETED(comp))
		comp.input_received(port)
