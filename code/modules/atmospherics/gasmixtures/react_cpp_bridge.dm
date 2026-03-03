// Мост для расчёта реакций через C++ модуль (atmos_cpp.dll).
// Если расширение atmos_cpp загружено, react() использует его вместо auxmos для реакций.

var/atmos_cpp_available = null

/proc/__detect_atmos_cpp()
	if (atmos_cpp_available != null)
		return atmos_cpp_available
	atmos_cpp_available = FALSE
	try
		call_ext("atmos_cpp", "version")()
		atmos_cpp_available = TRUE
	catch (var/exception/e)
		// расширение не загружено
		if(e)
			atmos_cpp_available = FALSE
	return atmos_cpp_available

/proc/__serialize_mixture_for_cpp(datum/gas_mixture/air)
	var/list/parts = list()
	for (var/g in air.get_gases())
		var/m = air.get_moles(g)
		if (m > 0)
			parts += "[g]=[m]"
	parts += "TEMP=[air.return_temperature()]"
	parts += "VOLUME=[air.return_volume()]"
	return parts.Join(";")

/proc/__apply_cpp_mixture_result(datum/gas_mixture/air, result_string)
	if (!result_string)
		return
	var/list/gases_before = air.get_gases()
	var/list/parts = splittext(result_string, ";")
	var/list/parsed = list()
	for (var/part in parts)
		var/eq = findtext(part, "=")
		if (!eq)
			continue
		var/key = copytext(part, 1, eq)
		var/val = text2num(copytext(part, eq + 1))
		if (val == null)
			continue
		parsed[key] = val
	for (var/g in gases_before)
		var/new_val = parsed[g] || 0
		if (air.get_moles(g) != new_val)
			air.set_moles(g, new_val)
	for (var/key in parsed)
		if (key != "TEMP" && key != "VOLUME" && key != "FIRE" && key != "FUSION")
			if (!(key in gases_before))
				air.set_moles(key, parsed[key])
	var/new_temp = parsed["TEMP"]
	if (new_temp != null && air.return_temperature() != new_temp)
		air.set_temperature(new_temp)
	var/new_vol = parsed["VOLUME"]
	if (new_vol != null && air.return_volume() != new_vol)
		air.set_volume(new_vol)
	if ("FIRE" in parsed)
		if (!air.reaction_results)
			air.reaction_results = new
		air.reaction_results["fire"] = parsed["FIRE"]
	if ("FUSION" in parsed)
		if (!air.analyzer_results)
			air.analyzer_results = new
		air.analyzer_results["fusion"] = parsed["FUSION"]

/proc/__react_via_cpp(datum/gas_mixture/air, datum/holder)
	var/input = __serialize_mixture_for_cpp(air)
	var/result = call_ext("atmos_cpp", "run_reactions")(input)
	__apply_cpp_mixture_result(air, result)
	return REACTING
