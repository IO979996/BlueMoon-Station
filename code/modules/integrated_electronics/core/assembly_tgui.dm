/// TGUI "IntegratedCircuit" backend for legacy Integrated Electronics (assemblies + loose chips).

GLOBAL_LIST_INIT(ie_integrated_circuit_ui_types, list("string", "number", "entity", "signal", "any", "option"))

/proc/ie_ic_is_output_side_pin(datum/integrated_io/io)
	if(!io)
		return FALSE
	if(io.pin_type == IC_OUTPUT)
		return TRUE
	if(istype(io, /datum/integrated_io/activate/out))
		return TRUE
	return FALSE

/proc/ie_ic_fundamental_type(datum/integrated_io/io)
	if(!io)
		return "any"
	if(io.io_type == PULSE_CHANNEL)
		return "signal"
	if(istype(io, /datum/integrated_io/number) || istype(io, /datum/integrated_io/boolean))
		return "number"
	if(istype(io, /datum/integrated_io/string) || istype(io, /datum/integrated_io/char) || istype(io, /datum/integrated_io/color) || istype(io, /datum/integrated_io/dir))
		return "string"
	if(istype(io, /datum/integrated_io/ref) || istype(io, /datum/integrated_io/selfref))
		return "entity"
	if(istype(io, /datum/integrated_io/lists) || istype(io, /datum/integrated_io/index))
		return "any"
	return "any"

/proc/ie_ic_serialize_data(datum/integrated_io/io)
	var/data = io.data
	if(isnull(data))
		return null
	if(isweakref(data))
		var/datum/weakref/wr = data
		var/atom/A = wr.resolve()
		return A ? A.name : null
	if(islist(data))
		return "list([length(data)])"
	if(isnum(data) || istext(data))
		return data
	return "[data]"

/proc/ie_ic_collect_input_ios(obj/item/integrated_circuit/chip)
	var/list/L = list()
	for(var/datum/integrated_io/io as anything in chip.inputs)
		L += io
	for(var/datum/integrated_io/io as anything in chip.activators)
		if(!istype(io, /datum/integrated_io/activate/out))
			L += io
	return L

/proc/ie_ic_collect_output_ios(obj/item/integrated_circuit/chip)
	var/list/L = list()
	for(var/datum/integrated_io/io as anything in chip.outputs)
		L += io
	for(var/datum/integrated_io/io as anything in chip.activators)
		if(istype(io, /datum/integrated_io/activate/out))
			L += io
	return L

/proc/ie_ic_input_connected_refs(datum/integrated_io/io)
	var/list/out = list()
	for(var/datum/integrated_io/other as anything in io.linked)
		if(ie_ic_is_output_side_pin(other))
			out += REF(other)
	return out

/proc/ie_ic_build_port_entry(datum/integrated_io/io)
	return list(
		"name" = io.name,
		"type" = ie_ic_fundamental_type(io),
		"ref" = REF(io),
		"color" = "blue",
		"current_data" = ie_ic_serialize_data(io),
		"datatype_data" = null,
		"connected_to" = ie_ic_input_connected_refs(io),
	)

/proc/ie_ic_component_payload(obj/item/integrated_circuit/chip)
	var/list/component_data = list()
	/// Use numeric indices so json_encode produces JSON arrays; `L += list(assoc)` merges keys into L.
	var/list/input_ports = list()
	var/port_i = 0
	for(var/datum/integrated_io/io as anything in ie_ic_collect_input_ios(chip))
		port_i++
		input_ports[port_i] = ie_ic_build_port_entry(io)
	component_data["input_ports"] = input_ports
	var/list/output_ports = list()
	port_i = 0
	for(var/datum/integrated_io/io as anything in ie_ic_collect_output_ios(chip))
		port_i++
		var/list/out_entry = ie_ic_build_port_entry(io)
		out_entry["connected_to"] = list()
		output_ports[port_i] = out_entry
	component_data["output_ports"] = output_ports
	component_data["name"] = chip.displayed_name || chip.name
	component_data["x"] = chip.ie_ui_rel_x
	component_data["y"] = chip.ie_ui_rel_y
	component_data["removable"] = chip.removable
	return component_data

/proc/ie_ic_get_input_io(obj/item/integrated_circuit/chip, port_id)
	var/list/L = ie_ic_collect_input_ios(chip)
	if(port_id < 1 || port_id > length(L))
		return null
	return L[port_id]

/proc/ie_ic_get_output_io(obj/item/integrated_circuit/chip, port_id)
	var/list/L = ie_ic_collect_output_ios(chip)
	if(port_id < 1 || port_id > length(L))
		return null
	return L[port_id]

/proc/ie_ic_chip_from_index(atom/movable/host, component_id)
	if(istype(host, /obj/item/electronic_assembly))
		var/obj/item/electronic_assembly/ea = host
		if(component_id < 1 || component_id > length(ea.assembly_components))
			return null
		return ea.assembly_components[component_id]
	if(istype(host, /obj/item/integrated_circuit))
		if(component_id != 1)
			return null
		return host
	return null

/proc/ie_ic_shared_host(atom/movable/A, atom/movable/B)
	var/obj/item/electronic_assembly/ea = A?.loc
	if(istype(ea, /obj/item/electronic_assembly) && (B?.loc == ea))
		return ea
	return null

/obj/item/electronic_assembly/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/circuit_assets)
	)

/obj/item/electronic_assembly/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/electronic_assembly/ui_interact(mob/user, obj/item/integrated_circuit/circuit_pins)
	. = ..()
	if(!check_interactivity(user))
		return
	var/datum/tgui/ui = SStgui.try_update_ui(user, src, null)
	if(!ui)
		ui = new(user, src, "IntegratedCircuit", name)
		ui.open()
	ui.set_autoupdate(TRUE)

/obj/item/electronic_assembly/ui_static_data(mob/user)
	. = list()
	.["global_basic_types"] = GLOB.ie_integrated_circuit_ui_types
	.["screen_x"] = ie_tgui_screen_x
	.["screen_y"] = ie_tgui_screen_y

/obj/item/electronic_assembly/ui_data(mob/user)
	. = list()
	.["ie_circuit"] = TRUE
	.["circuit_on"] = TRUE
	.["is_admin"] = FALSE
	.["variables"] = list()
	.["display_name"] = name
	.["components"] = list()
	var/comp_i = 0
	for(var/obj/item/integrated_circuit/part as anything in assembly_components)
		comp_i++
		.["components"][comp_i] = ie_ic_component_payload(part)
	.["screen_x"] = ie_tgui_screen_x
	.["screen_y"] = ie_tgui_screen_y
	var/obj/item/integrated_circuit/examined = ie_gui_examined_circuit?.resolve()
	.["examined_name"] = examined?.displayed_name
	.["examined_desc"] = examined ? "[examined.desc]\n[examined.extended_desc || ""]" : null
	.["examined_notices"] = list()
	if(examined)
		.["examined_notices"] += list(list(
			"content" = "Сложность: [examined.complexity] | КД: [examined.cooldown_per_use / 10] с",
			"color" = "transparent",
			"icon" = "info",
		))
	.["examined_rel_x"] = ie_gui_examined_x
	.["examined_rel_y"] = ie_gui_examined_y

/obj/item/electronic_assembly/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("add_connection")
			var/ocid = text2num(params["output_component_id"])
			var/icid = text2num(params["input_component_id"])
			var/opid = text2num(params["output_port_id"])
			var/ipid = text2num(params["input_port_id"])
			var/obj/item/integrated_circuit/out_chip = ie_ic_chip_from_index(src, ocid)
			var/obj/item/integrated_circuit/in_chip = ie_ic_chip_from_index(src, icid)
			if(!out_chip || !in_chip)
				return
			var/datum/integrated_io/out_io = ie_ic_get_output_io(out_chip, opid)
			var/datum/integrated_io/in_io = ie_ic_get_input_io(in_chip, ipid)
			if(!out_io || !in_io)
				return
			if(out_io.io_type != in_io.io_type)
				return
			if(ie_ic_shared_host(out_chip, in_chip) != src)
				return
			out_io.connect_pin(in_io)
			. = TRUE
		if("remove_connection")
			var/cid = text2num(params["component_id"])
			var/port_id = text2num(params["port_id"])
			var/is_input = params["is_input"]
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip)
				return
			var/datum/integrated_io/io = is_input ? ie_ic_get_input_io(chip, port_id) : ie_ic_get_output_io(chip, port_id)
			if(!io)
				return
			io.disconnect_all()
			. = TRUE
		if("detach_component")
			var/cid = text2num(params["component_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !usr)
				return
			if(try_remove_component(chip, usr))
				. = TRUE
		if("set_component_coordinates")
			var/cid = text2num(params["component_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip)
				return
			chip.ie_ui_rel_x = clamp(text2num(params["rel_x"]), -500, 500)
			chip.ie_ui_rel_y = clamp(text2num(params["rel_y"]), -500, 500)
			. = TRUE
		if("set_component_input")
			var/cid = text2num(params["component_id"])
			var/pid = text2num(params["port_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !usr)
				return
			var/datum/integrated_io/io = ie_ic_get_input_io(chip, pid)
			if(!io)
				return
			if(io.io_type == PULSE_CHANNEL)
				if(istype(io, /datum/integrated_io/activate/out))
					return TRUE
				chip.check_then_do_work(io.ord, ignore_power = TRUE)
				return TRUE
			if(params["set_null"])
				io.write_data_to_pin(null)
				return TRUE
			if(params["marked_atom"])
				if(ie_ic_fundamental_type(io) != "entity")
					return TRUE
				var/atom/movable/M = usr.get_active_held_item()
				if(istype(M))
					io.write_data_to_pin(WEAKREF(M))
				else
					var/client/C = usr.client
					if(C?.holder?.marked_datum)
						io.write_data_to_pin(WEAKREF(C.holder.marked_datum))
				return TRUE
			var/ftype = ie_ic_fundamental_type(io)
			var/new_val = params["input"]
			if(ftype == "number")
				io.write_data_to_pin(text2num(new_val))
			else if(ftype == "string" || ftype == "any")
				io.write_data_to_pin(new_val)
			else
				io.write_data_to_pin(new_val)
			return TRUE
		if("get_component_value")
			var/cid = text2num(params["component_id"])
			var/pid = text2num(params["port_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip || !usr)
				return
			var/datum/integrated_io/io = ie_ic_get_output_io(chip, pid)
			if(!io)
				return
			var/msg = copytext("[ie_ic_serialize_data(io)]", 1, 80)
			usr.balloon_alert(usr, "[io.name]: [msg]")
			. = TRUE
		if("set_display_name")
			var/nn = params["display_name"]
			if(isnull(nn))
				return TRUE
			name = reject_bad_name(strip_html(nn), TRUE) || initial(name)
			. = TRUE
		if("set_examined_component")
			var/cid = text2num(params["component_id"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip)
				return
			ie_gui_examined_circuit = WEAKREF(chip)
			ie_gui_examined_x = text2num(params["x"])
			ie_gui_examined_y = text2num(params["y"])
			. = TRUE
		if("remove_examined_component")
			ie_gui_examined_circuit = null
			. = TRUE
		if("move_screen")
			ie_tgui_screen_x = text2num(params["screen_x"])
			ie_tgui_screen_y = text2num(params["screen_y"])
			. = TRUE
		if("swap_input_connection_order")
			var/cid = text2num(params["component_id"])
			var/pid = text2num(params["port_id"])
			var/lower = text2num(params["lower_index"])
			var/obj/item/integrated_circuit/chip = ie_ic_chip_from_index(src, cid)
			if(!chip)
				return
			var/datum/integrated_io/io = ie_ic_get_input_io(chip, pid)
			if(!io || length(io.linked) < lower + 1 || lower < 1)
				return
			io.linked.Swap(lower, lower + 1)
			. = TRUE
	if(action in list("add_variable", "remove_variable", "add_setter_or_getter", "save_circuit"))
		return TRUE

/obj/item/integrated_circuit/ui_assets(mob/user)
	if(assembly)
		return assembly.ui_assets(user)
	return list(
		get_asset_datum(/datum/asset/simple/circuit_assets)
	)

/obj/item/integrated_circuit/ui_state(mob/user)
	if(assembly)
		return assembly.ui_state(user)
	return GLOB.hands_state

/obj/item/integrated_circuit/ui_static_data(mob/user)
	if(assembly)
		return assembly.ui_static_data(user)
	. = list()
	.["global_basic_types"] = GLOB.ie_integrated_circuit_ui_types
	.["screen_x"] = ie_tgui_screen_x
	.["screen_y"] = ie_tgui_screen_y

/obj/item/integrated_circuit/ui_data(mob/user)
	if(assembly)
		return assembly.ui_data(user)
	. = list()
	.["ie_circuit"] = TRUE
	.["circuit_on"] = TRUE
	.["is_admin"] = FALSE
	.["variables"] = list()
	.["display_name"] = displayed_name || name
	.["components"] = list()
	.["components"][1] = ie_ic_component_payload(src)
	.["screen_x"] = ie_tgui_screen_x
	.["screen_y"] = ie_tgui_screen_y
	var/obj/item/integrated_circuit/examined = ie_gui_examined_circuit?.resolve()
	if(examined != src)
		examined = null
	.["examined_name"] = examined?.displayed_name
	.["examined_desc"] = examined ? "[examined.desc]\n[examined.extended_desc || ""]" : null
	.["examined_notices"] = list()
	if(examined)
		.["examined_notices"][1] = list(
			"content" = "Сложность: [examined.complexity] | КД: [examined.cooldown_per_use / 10] с",
			"color" = "transparent",
			"icon" = "info",
		)
	.["examined_rel_x"] = ie_gui_examined_x
	.["examined_rel_y"] = ie_gui_examined_y

/obj/item/integrated_circuit/ui_act(action, list/params)
	if(assembly)
		return assembly.ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("add_connection")
			return
		if("remove_connection")
			var/port_id = text2num(params["port_id"])
			var/is_input = params["is_input"]
			var/datum/integrated_io/io = is_input ? ie_ic_get_input_io(src, port_id) : ie_ic_get_output_io(src, port_id)
			if(io)
				io.disconnect_all()
				. = TRUE
		if("detach_component")
			. = TRUE
		if("set_component_coordinates")
			ie_ui_rel_x = clamp(text2num(params["rel_x"]), -500, 500)
			ie_ui_rel_y = clamp(text2num(params["rel_y"]), -500, 500)
			. = TRUE
		if("set_component_input")
			var/pid = text2num(params["port_id"])
			var/datum/integrated_io/io = ie_ic_get_input_io(src, pid)
			if(!io || !usr)
				return
			if(io.io_type == PULSE_CHANNEL)
				if(istype(io, /datum/integrated_io/activate/out))
					return TRUE
				check_then_do_work(io.ord, ignore_power = TRUE)
				return TRUE
			if(params["set_null"])
				io.write_data_to_pin(null)
				return TRUE
			if(params["marked_atom"])
				if(ie_ic_fundamental_type(io) != "entity")
					return TRUE
				var/atom/movable/M = usr.get_active_held_item()
				if(istype(M))
					io.write_data_to_pin(WEAKREF(M))
				else
					var/client/C = usr.client
					if(C?.holder?.marked_datum)
						io.write_data_to_pin(WEAKREF(C.holder.marked_datum))
				return TRUE
			var/ftype = ie_ic_fundamental_type(io)
			var/new_val = params["input"]
			if(ftype == "number")
				io.write_data_to_pin(text2num(new_val))
			else
				io.write_data_to_pin(new_val)
			return TRUE
		if("get_component_value")
			var/pid = text2num(params["port_id"])
			var/datum/integrated_io/io = ie_ic_get_output_io(src, pid)
			if(!io || !usr)
				return
			usr.balloon_alert(usr, "[io.name]: [copytext("[ie_ic_serialize_data(io)]", 1, 80)]")
			. = TRUE
		if("set_display_name")
			var/nn = params["display_name"]
			if(!isnull(nn))
				displayed_name = reject_bad_name(strip_html(nn), TRUE) || displayed_name
			. = TRUE
		if("set_examined_component")
			ie_gui_examined_circuit = WEAKREF(src)
			ie_gui_examined_x = text2num(params["x"])
			ie_gui_examined_y = text2num(params["y"])
			. = TRUE
		if("remove_examined_component")
			ie_gui_examined_circuit = null
			. = TRUE
		if("move_screen")
			ie_tgui_screen_x = text2num(params["screen_x"])
			ie_tgui_screen_y = text2num(params["screen_y"])
			. = TRUE
		if("swap_input_connection_order")
			var/pid = text2num(params["port_id"])
			var/lower = text2num(params["lower_index"])
			var/datum/integrated_io/io = ie_ic_get_input_io(src, pid)
			if(!io || length(io.linked) < lower + 1 || lower < 1)
				return
			io.linked.Swap(lower, lower + 1)
			. = TRUE
	if(action in list("add_variable", "remove_variable", "add_setter_or_getter", "save_circuit"))
		return TRUE
