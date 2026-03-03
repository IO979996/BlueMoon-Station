// Атмосфера на DM (газ в gas_mixture.gases, реакции в react(), без Auxmos).

// Подсистема и глобальные заглушки
/datum/controller/subsystem/air/proc/get_max_gas_mixes()
	return 0

/datum/controller/subsystem/air/proc/get_amt_gas_mixes()
	return 0

/proc/equalize_all_gases_in_list(gas_list)
	if(!length(gas_list))
		return
	var/datum/gas_mixture/total = new
	for(var/datum/gas_mixture/G in gas_list)
		if(G)
			total.merge(G)
	var/n = length(gas_list)
	var/datum/gas_mixture/avg = total.copy()
	avg.multiply(1 / n)
	for(var/datum/gas_mixture/G in gas_list)
		if(G)
			G.copy_from(avg)

/datum/controller/subsystem/air/proc/process_turf_equalize_auxtools(remaining)
	return 0

/datum/controller/subsystem/air/proc/process_excited_groups_auxtools(remaining)
	return 0

/datum/controller/subsystem/air/proc/process_turfs_auxtools(remaining)
	return 0

/datum/controller/subsystem/air/proc/finish_turf_processing_auxtools(time_remaining)
	return 0

/datum/controller/subsystem/air/proc/thread_running()
	return FALSE

/proc/finalize_gas_refs()
	return

/datum/controller/subsystem/air/proc/auxtools_update_reactions()
	return

/proc/auxtools_atmos_init(gas_data)
	return TRUE

/proc/_auxtools_register_gas(gas)
	return

/proc/process_atmos_callbacks(remaining)
	return

/turf/proc/__update_auxtools_turf_adjacency_info()
	return

/turf/proc/update_air_ref(flag)
	return

/datum/gas_mixture/proc/__gasmixture_register()
	return

/datum/gas_mixture/proc/__gasmixture_unregister()
	return

/datum/gas_mixture/proc/__auxtools_parse_gas_string(string)
	return

// gas_mixture: хранение в gases[gas_id] = moles, temperature, volume
/datum/gas_mixture/proc/get_moles(gas_id)
	return gases[gas_id] || 0

/datum/gas_mixture/proc/set_moles(gas_id, amt_val)
	gases[gas_id] = max(0, amt_val)

/datum/gas_mixture/proc/adjust_moles(id_val, num_val)
	set_moles(id_val, get_moles(id_val) + num_val)

/datum/gas_mixture/proc/return_temperature()
	return temperature

/datum/gas_mixture/proc/set_temperature(arg_temp)
	temperature = max(arg_temp, TCMB)

/datum/gas_mixture/proc/return_volume()
	return max(0, volume)

/datum/gas_mixture/proc/set_volume(vol_arg)
	volume = max(0, vol_arg)

/datum/gas_mixture/proc/total_moles()
	. = 0
	for(var/id in gases)
		. += gases[id]

/datum/gas_mixture/proc/heat_capacity()
	. = 0
	var/list/cached_gasheats = GLOB.gas_data.specific_heats
	for(var/id in gases)
		. += (gases[id] || 0) * (cached_gasheats[id] || 0)

/datum/gas_mixture/proc/thermal_energy()
	return temperature * heat_capacity()

/datum/gas_mixture/proc/return_pressure()
	if(volume <= 0)
		return 0
	return total_moles() * R_IDEAL_GAS_EQUATION * temperature / volume

/datum/gas_mixture/proc/clear()
	gases.Cut()

/datum/gas_mixture/proc/archive()
	temperature_archived = temperature
	gas_archive = gases.Copy()
	return TRUE

/datum/gas_mixture/proc/get_gases()
	return gases

/datum/gas_mixture/proc/merge(datum/gas_mixture/giver)
	if(!giver)
		return FALSE
	if(abs(temperature - giver.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		var/self_heat_capacity = heat_capacity()
		var/giver_heat_capacity = giver.heat_capacity()
		var/combined_heat_capacity = giver_heat_capacity + self_heat_capacity
		if(combined_heat_capacity > 0)
			temperature = (giver.temperature * giver_heat_capacity + temperature * self_heat_capacity) / combined_heat_capacity
	for(var/giver_id in giver.gases)
		gases[giver_id] = (gases[giver_id] || 0) + (giver.gases[giver_id] || 0)
	return TRUE

/datum/gas_mixture/proc/copy_from(datum/gas_mixture/giver)
	if(!giver)
		return FALSE
	gases = giver.gases.Copy()
	temperature = giver.temperature
	volume = giver.volume
	return TRUE

/datum/gas_mixture/proc/__remove(datum/gas_mixture/into, amount_arg)
	var/sum = total_moles()
	amount_arg = min(amount_arg, sum)
	if(amount_arg <= 0)
		return
	var/ratio = sum > 0 ? amount_arg / sum : 0
	into.temperature = temperature
	if(!into.gases)
		into.gases = list()
	for(var/id in gases)
		var/amt = (gases[id] || 0) * ratio
		if(amt > 0)
			into.gases[id] = (into.gases[id] || 0) + amt
			gases[id] = (gases[id] || 0) - amt
	GAS_GARBAGE_COLLECT(gases)

/datum/gas_mixture/proc/__remove_ratio(into, ratio_arg)
	ratio_arg = clamp(ratio_arg, 0, 1)
	__remove(into, total_moles() * ratio_arg)

/datum/gas_mixture/proc/transfer_to(datum/gas_mixture/other, moles)
	var/datum/gas_mixture/removed = new type(volume)
	__remove(removed, moles)
	other.merge(removed)
	return TRUE

/datum/gas_mixture/proc/get_oxidation_power(temp)
	. = 0
	var/list/oxidation_temps = GLOB.gas_data.oxidation_temperatures
	var/list/oxidation_rates = GLOB.gas_data.oxidation_rates
	for(var/id in gases)
		var/t_ox = oxidation_temps[id]
		if(t_ox && t_ox > temp)
			. += (gases[id] || 0) * (oxidation_rates[id] || 0)
	return .

/datum/gas_mixture/proc/get_fuel_amount(temp)
	. = 0
	var/list/fuel_temps = GLOB.gas_data.fire_temperatures
	var/list/fuel_rates = GLOB.gas_data.fire_burn_rates
	for(var/id in gases)
		var/t_f = fuel_temps[id]
		if(t_f && t_f > temp)
			. += (gases[id] || 0) / max(fuel_rates[id], 0.01)
	return .

/datum/gas_mixture/proc/equalize_with(datum/gas_mixture/total)
	if(!total)
		return
	var/total_vol = volume + total.volume
	if(total_vol <= 0)
		return
	var/self_heat = heat_capacity()
	var/other_heat = total.heat_capacity()
	if(self_heat + other_heat > 0)
		temperature = (temperature * self_heat + total.temperature * other_heat) / (self_heat + other_heat)
		total.temperature = temperature
	for(var/id in gases | total.gases)
		var/our_m = gases[id] || 0
		var/their_m = total.gases[id] || 0
		var/combined = our_m + their_m
		gases[id] = combined * volume / total_vol
		total.gases[id] = combined * total.volume / total_vol

/datum/gas_mixture/proc/transfer_ratio_to(datum/gas_mixture/other, ratio)
	var/datum/gas_mixture/removed = new type(volume)
	__remove_ratio(removed, ratio)
	other.merge(removed)
	return TRUE

/datum/gas_mixture/proc/adjust_heat(heat)
	var/cap = heat_capacity()
	if(cap > MINIMUM_HEAT_CAPACITY)
		set_temperature(temperature + heat / cap)

/datum/gas_mixture/proc/compare(datum/gas_mixture/other)
	for(var/id in gases | other.gases)
		var/delta = abs((gases[id] || 0) - (other.gases[id] || 0))
		if(delta > MINIMUM_MOLES_DELTA_TO_MOVE)
			return id
	if(abs(temperature - other.temperature) > MINIMUM_TEMPERATURE_DELTA_TO_SUSPEND)
		return "temp"
	return ""

/datum/gas_mixture/proc/mark_immutable()
	return

/datum/gas_mixture/proc/scrub_into(datum/gas_mixture/into, ratio_v, list/gas_list)
	if(!into)
		return FALSE
	var/datum/gas_mixture/removed = new type(volume)
	for(var/gid in gas_list & gases)
		var/m = (gases[gid] || 0) * ratio_v
		if(m > 0)
			removed.gases[gid] = (removed.gases[gid] || 0) + m
			gases[gid] = (gases[gid] || 0) - m
	GAS_GARBAGE_COLLECT(gases)
	into.merge(removed)
	return TRUE

/datum/gas_mixture/proc/get_by_flag(flag_val)
	. = list()
	var/list/flags = GLOB.gas_data.flags
	for(var/id in gases)
		if(flags[id] & flag_val)
			.[id] = gases[id]

/datum/gas_mixture/proc/__remove_by_flag(datum/gas_mixture/into, flag_val, amount_val)
	var/list/with_flag = get_by_flag(flag_val)
	var/sum = 0
	for(var/id in with_flag)
		sum += with_flag[id]
	if(sum <= 0)
		return
	var/ratio = min(1, amount_val / sum)
	for(var/id in with_flag)
		var/amt = with_flag[id] * ratio
		if(amt > 0)
			into.gases[id] = (into.gases[id] || 0) + amt
			gases[id] = (gases[id] || 0) - amt
	GAS_GARBAGE_COLLECT(gases)

/datum/gas_mixture/proc/divide(num_val)
	if(num_val <= 0)
		return
	for(var/id in gases)
		gases[id] /= num_val

/datum/gas_mixture/proc/multiply(num_val)
	for(var/id in gases)
		gases[id] *= num_val

/datum/gas_mixture/proc/subtract(num_val)
	for(var/id in gases)
		gases[id] = max(0, (gases[id] || 0) - num_val)

/datum/gas_mixture/proc/add(num_val)
	for(var/id in gases)
		gases[id] = (gases[id] || 0) + num_val

/datum/gas_mixture/proc/adjust_multi(...)
	var/list/arglist = args
	for(var/i in 2 to length(arglist))
		var/list/elem = arglist[i]
		if(length(elem) >= 2)
			adjust_moles(elem[1], elem[2])

/datum/gas_mixture/proc/adjust_moles_temp(id_val, num_val, temp_val)
	adjust_moles(id_val, num_val)
	if(num_val != 0 && total_moles() > 0)
		var/cap = heat_capacity()
		if(cap > MINIMUM_HEAT_CAPACITY)
			var/list/cached_gasheats = GLOB.gas_data.specific_heats
			var/delta_heat = num_val * (cached_gasheats[id_val] || 0) * temp_val
			temperature = (temperature * cap + delta_heat) / heat_capacity()

/datum/gas_mixture/proc/partial_heat_capacity(gas_id)
	var/list/cached_gasheats = GLOB.gas_data.specific_heats
	return (gases[gas_id] || 0) * (cached_gasheats[gas_id] || 0)

/datum/gas_mixture/proc/set_min_heat_capacity(arg_min)
	return

/datum/gas_mixture/proc/temperature_share(datum/gas_mixture/sharer, conduction_coefficient, sharer_temperature, sharer_heat_capacity)
	if(sharer)
		sharer_temperature = sharer.temperature
	var/temperature_delta = temperature - sharer_temperature
	if(abs(temperature_delta) <= MINIMUM_TEMPERATURE_DELTA_TO_CONSIDER)
		return sharer_temperature
	var/self_heat_capacity = heat_capacity()
	if(!sharer_heat_capacity && sharer)
		sharer_heat_capacity = sharer.heat_capacity()
	if(self_heat_capacity > MINIMUM_HEAT_CAPACITY && sharer_heat_capacity > MINIMUM_HEAT_CAPACITY)
		var/heat = conduction_coefficient * temperature_delta * (self_heat_capacity * sharer_heat_capacity / (self_heat_capacity + sharer_heat_capacity))
		temperature = max(temperature - heat / self_heat_capacity, TCMB)
		sharer_temperature = max(sharer_temperature + heat / sharer_heat_capacity, TCMB)
		if(sharer)
			sharer.temperature = sharer_temperature
	return sharer_temperature

/datum/gas_mixture/proc/react(datum/holder)
	. = NO_REACTION
	if(!total_moles())
		return
	var/list/reactions = list()
	for(var/datum/gas_reaction/G in SSair.gas_reactions)
		reactions += G
	if(!length(reactions))
		return
	reaction_results = new
	var/temp = return_temperature()
	var/ener = thermal_energy()
	reaction_loop:
		for(var/r in reactions)
			var/datum/gas_reaction/reaction = r
			var/list/min_reqs = reaction.min_requirements
			if((min_reqs["TEMP"] && temp < min_reqs["TEMP"]) \
			|| (min_reqs["ENER"] && ener < min_reqs["ENER"]))
				continue
			if(min_reqs["MAX_TEMP"] && temp > min_reqs["MAX_TEMP"])
				continue
			for(var/id in min_reqs)
				if(id == "TEMP" || id == "ENER" || id == "MAX_TEMP")
					continue
				if(get_moles(id) < min_reqs[id])
					continue reaction_loop
			. |= reaction.react(src, holder)
			if(. & STOP_REACTIONS)
				break
