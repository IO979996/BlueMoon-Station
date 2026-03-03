// All gas reactions — C++ implementation.
// Mirrors code/modules/atmospherics/gasmixtures/reactions.dm

#include "reactions.hpp"
#include "gas_ids.hpp"
#include <algorithm>
#include <cmath>
#include <random>
#include <vector>

namespace atmos {

static ReactionResult apply_temperature_change(GasMixtureView& air, double old_heat_cap, double energy_delta) {
	double new_heat_cap = air.heat_capacity();
	if (new_heat_cap <= MINIMUM_HEAT_CAPACITY) return ReactionResult::REACTING;
	double t = (air.return_temperature() * old_heat_cap + energy_delta) / new_heat_cap;
	air.set_temperature(std::max(t, TCMB));
	return ReactionResult::REACTING;
}

// ---- Noblium suppression ----
ReactionResult react_nobliumsupression(GasMixtureView& air) {
	(void)air;
	return ReactionResult::STOP_REACTIONS;
}

// ---- Water vapor: gas part only; DM runs location.freon_gas_act / water_vapor_gas_act ----
ReactionResult react_water_vapor(GasMixtureView& air) {
	double temp = air.return_temperature();
	if (temp <= WATER_VAPOR_FREEZE) return ReactionResult::NO_REACTION; // DM handles freon_gas_act
	if (temp > T0C + 40) return ReactionResult::NO_REACTION;
	double h2o = air.get_moles(GAS_H2O);
	if (h2o < MOLES_GAS_VISIBLE) return ReactionResult::NO_REACTION;
	air.adjust_moles(GAS_H2O, -MOLES_GAS_VISIBLE);
	return ReactionResult::REACTING;
}

// ---- Tritium combustion ----
ReactionResult react_tritfire(GasMixtureView& air, ReactionCallbacks* cb) {
	double energy_released = 0;
	double old_heat_cap = air.heat_capacity();
	double temp = air.return_temperature();
	air.set_fire_result(0);

	double o2 = air.get_moles(GAS_O2);
	double trit = air.get_moles(GAS_TRITIUM);
	double burned_fuel = 0;
	if (o2 < trit) {
		burned_fuel = o2 / TRITIUM_BURN_OXY_FACTOR;
		air.adjust_moles(GAS_TRITIUM, -burned_fuel);
	} else {
		burned_fuel = trit * TRITIUM_BURN_TRIT_FACTOR;
		air.adjust_moles(GAS_TRITIUM, -trit / TRITIUM_BURN_TRIT_FACTOR);
		air.adjust_moles(GAS_O2, -air.get_moles(GAS_TRITIUM));
	}
	if (burned_fuel > 0) {
		energy_released += FIRE_HYDROGEN_ENERGY_RELEASED * burned_fuel;
		air.adjust_moles(GAS_H2O, burned_fuel / TRITIUM_BURN_OXY_FACTOR);
		air.add_fire_result(burned_fuel);
		if (cb && cb->radiation_pulse && cb->holder && burned_fuel > TRITIUM_MINIMUM_RADIATION_ENERGY)
			cb->radiation_pulse(cb->holder, energy_released / TRITIUM_BURN_RADIOACTIVITY_FACTOR);
	}
	if (energy_released > 0) {
		double new_heat_cap = air.heat_capacity();
		if (new_heat_cap > MINIMUM_HEAT_CAPACITY)
			air.set_temperature((temp * old_heat_cap + energy_released) / new_heat_cap);
	}
	if (cb && cb->fire_expose && cb->holder && air.return_temperature() > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
		cb->fire_expose(cb->holder, air.return_temperature());
	return burned_fuel > 0 ? ReactionResult::REACTING : ReactionResult::NO_REACTION;
}

// ---- Plasma combustion ----
ReactionResult react_plasmafire(GasMixtureView& air, ReactionCallbacks* cb) {
	double energy_released = 0;
	double old_heat_cap = air.heat_capacity();
	double temp = air.return_temperature();
	air.set_fire_result(0);

	double o2 = air.get_moles(GAS_O2);
	double plasma = air.get_moles(GAS_PLASMA);
	double temperature_scale = 0;
	if (temp > PLASMA_UPPER_TEMPERATURE)
		temperature_scale = 1.0;
	else if (temp > PLASMA_MINIMUM_BURN_TEMPERATURE)
		temperature_scale = (temp - PLASMA_MINIMUM_BURN_TEMPERATURE) / (PLASMA_UPPER_TEMPERATURE - PLASMA_MINIMUM_BURN_TEMPERATURE);

	double plasma_burn_rate = 0;
	double oxygen_burn_rate = 0;
	if (temperature_scale > 0) {
		oxygen_burn_rate = OXYGEN_BURN_RATE_BASE - temperature_scale;
		bool super_sat = (o2 / plasma) > SUPER_SATURATION_THRESHOLD;
		if (o2 > plasma * PLASMA_OXYGEN_FULLBURN)
			plasma_burn_rate = (plasma * temperature_scale) / PLASMA_BURN_RATE_DELTA;
		else
			plasma_burn_rate = (temperature_scale * (o2 / PLASMA_OXYGEN_FULLBURN)) / PLASMA_BURN_RATE_DELTA;
		if (plasma_burn_rate > MINIMUM_HEAT_CAPACITY) {
			plasma_burn_rate = std::min({ plasma_burn_rate, plasma, o2 / oxygen_burn_rate });
			air.adjust_moles(GAS_PLASMA, -plasma_burn_rate);
			air.adjust_moles(GAS_O2, -(plasma_burn_rate * oxygen_burn_rate));
			if (super_sat)
				air.adjust_moles(GAS_TRITIUM, plasma_burn_rate);
			else
				air.adjust_moles(GAS_CO2, plasma_burn_rate);
			energy_released += FIRE_PLASMA_ENERGY_RELEASED * plasma_burn_rate;
			air.add_fire_result(plasma_burn_rate * (1 + oxygen_burn_rate));
		}
	}
	if (energy_released > 0) {
		double new_heat_cap = air.heat_capacity();
		if (new_heat_cap > MINIMUM_HEAT_CAPACITY)
			air.set_temperature((temp * old_heat_cap + energy_released) / new_heat_cap);
	}
	if (cb && cb->fire_expose && cb->holder && air.return_temperature() > FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
		cb->fire_expose(cb->holder, air.return_temperature());
	return energy_released > 0 ? ReactionResult::REACTING : ReactionResult::NO_REACTION;
}

// ---- Generic fire: requires gas_data tables from DM ----
ReactionResult react_genericfire(GasMixtureView& air, ReactionCallbacks* cb,
	const std::unordered_map<std::string, double>* oxidation_temps,
	const std::unordered_map<std::string, double>* oxidation_rates,
	const std::unordered_map<std::string, double>* fuel_temps,
	const std::unordered_map<std::string, double>* fuel_rates,
	const std::unordered_map<std::string, std::unordered_map<std::string, double>>* fire_products,
	const std::unordered_map<std::string, double>* enthalpies) {
	if (!air.moles || !oxidation_temps || !oxidation_rates || !fuel_temps || !fuel_rates || !fire_products || !enthalpies)
		return ReactionResult::NO_REACTION;
	double temp = air.return_temperature();
	double oxidation_power = 0;
	double total_fuel = 0;
	std::unordered_map<std::string, double> oxidizers, fuels;
	for (const auto& p : *air.moles) {
		const std::string& g = p.first;
		double m = p.second;
		if (m <= 0) continue;
		auto ot = oxidation_temps->find(g);
		if (ot != oxidation_temps->end() && ot->second > temp) {
			double scale = std::max(0.0, 1.0 - temp / ot->second);
			double amt = m * scale;
			oxidizers[g] = amt;
			auto or_ = oxidation_rates->find(g);
			if (or_ != oxidation_rates->end()) oxidation_power += amt * or_->second;
		} else {
			auto ft = fuel_temps->find(g);
			if (ft != fuel_temps->end() && ft->second > temp) {
				auto fr = fuel_rates->find(g);
				double rate = (fr != fuel_rates->end()) ? fr->second : 1.0;
				double amt = (m / rate) * std::max(0.0, 1.0 - temp / ft->second);
				fuels[g] = amt;
				total_fuel += amt;
			}
		}
	}
	if (oxidation_power <= 0 || total_fuel <= 0) return ReactionResult::NO_REACTION;
	double ratio = oxidation_power / total_fuel;
	if (ratio > 1) for (auto& o : oxidizers) o.second /= ratio;
	else if (ratio < 1) for (auto& f : fuels) f.second *= ratio;
	double energy_released = 0;
	std::unordered_map<std::string, double> burn_results;
	for (const auto& kv : fuels) {
		const std::string& fuel = kv.first;
		double amt = kv.second;
		burn_results[fuel] = (burn_results.count(fuel) ? burn_results[fuel] : 0) - amt;
		auto eh = enthalpies->find(fuel);
		if (eh != enthalpies->end()) energy_released += amt * eh->second;
		auto prod = fire_products->find(fuel);
		if (prod != fire_products->end())
			for (const auto& pr : prod->second)
				burn_results[pr.first] = (burn_results.count(pr.first) ? burn_results[pr.first] : 0) + amt;
	}
	for (const auto& kv : burn_results)
		air.adjust_moles(kv.first, kv.second);
	double final_energy = air.thermal_energy() + energy_released;
	double hc = air.heat_capacity();
	if (hc > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(final_energy / hc);
	air.set_fire_result(std::min(total_fuel, oxidation_power) * 2.0);
	if (cb && cb->fire_expose && cb->holder)
		cb->fire_expose(cb->holder, air.return_temperature());
	return ReactionResult::REACTING;
}

// ---- Fusion ----
ReactionResult react_fusion(GasMixtureView& air, ReactionCallbacks* cb,
	const std::unordered_map<std::string, double>* fusion_powers) {
	double old_heat_cap = air.heat_capacity();
	double initial_plasma = air.get_moles(GAS_PLASMA);
	double initial_carbon = air.get_moles(GAS_CO2);
	double vol = air.return_volume();
	double scale_factor = vol / PI_DM;
	double toroidal_size = (2.0 * PI_DM) + std::atan((vol - TOROID_VOLUME_BREAKEVEN) / TOROID_VOLUME_BREAKEVEN);
	double gas_power = 0;
	if (fusion_powers && air.moles)
		for (const auto& p : *air.moles) {
			auto it = fusion_powers->find(p.first);
			if (it != fusion_powers->end()) gas_power += it->second * p.second;
		}
	double instability = fmod_positive(std::pow(gas_power * INSTABILITY_GAS_POWER_FACTOR, 2), toroidal_size);
	air.set_fusion_instability(instability);

	double plasma = (initial_plasma - FUSION_MOLE_THRESHOLD) / scale_factor;
	double carbon = (initial_carbon - FUSION_MOLE_THRESHOLD) / scale_factor;
	plasma = fmod_positive(plasma - instability * std::sin(carbon * (PI_DM / 180.0)), toroidal_size);
	carbon = fmod_positive(carbon - plasma, toroidal_size);
	air.set_moles(GAS_PLASMA, plasma * scale_factor + FUSION_MOLE_THRESHOLD);
	air.set_moles(GAS_CO2, carbon * scale_factor + FUSION_MOLE_THRESHOLD);
	double delta_plasma = initial_plasma - air.get_moles(GAS_PLASMA);
	double reaction_energy = delta_plasma * PLASMA_BINDING_ENERGY;
	if (instability < FUSION_INSTABILITY_ENDOTHERMALITY)
		reaction_energy = std::max(reaction_energy, 0.0);
	else if (reaction_energy < 0)
		reaction_energy *= std::sqrt(instability - FUSION_INSTABILITY_ENDOTHERMALITY);

	if (air.thermal_energy() + reaction_energy < 0) {
		air.set_moles(GAS_PLASMA, initial_plasma);
		air.set_moles(GAS_CO2, initial_carbon);
		return ReactionResult::NO_REACTION;
	}
	air.adjust_moles(GAS_TRITIUM, -FUSION_TRITIUM_MOLES_USED);
	if (reaction_energy > 0) {
		double conv = FUSION_TRITIUM_MOLES_USED * (reaction_energy * FUSION_TRITIUM_CONVERSION_COEFFICIENT);
		air.adjust_moles(GAS_O2, conv);
		air.adjust_moles(GAS_NITROUS, conv);
	} else {
		double conv = FUSION_TRITIUM_MOLES_USED * (-reaction_energy * FUSION_TRITIUM_CONVERSION_COEFFICIENT);
		air.adjust_moles(GAS_BZ, conv);
		air.adjust_moles(GAS_NITRYL, conv);
	}
	if (reaction_energy != 0) {
		if (cb && cb->radiation_pulse && cb->holder) {
			double rad = std::max((-1000.0 / instability) + 2000.0, 0.0);
			cb->radiation_pulse(cb->holder, rad);
		}
		double new_heat_cap = air.heat_capacity();
		if (new_heat_cap > MINIMUM_HEAT_CAPACITY)
			air.set_temperature(clamp((air.return_temperature() * old_heat_cap + reaction_energy) / new_heat_cap, TCMB, 1e30));
		return ReactionResult::REACTING;
	}
	return ReactionResult::NO_REACTION;
}

// ---- Nitryl formation ----
ReactionResult react_nitrylformation(GasMixtureView& air) {
	double temp = air.return_temperature();
	double old_heat_cap = air.heat_capacity();
	double o2 = air.get_moles(GAS_O2);
	double n2 = air.get_moles(GAS_N2);
	double heat_eff = std::min({ temp / (FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 100.0), o2, n2 });
	double energy_used = heat_eff * NITRYL_FORMATION_ENERGY;
	if (o2 - heat_eff < 0 || n2 - heat_eff < 0) return ReactionResult::NO_REACTION;
	air.adjust_moles(GAS_O2, -heat_eff);
	air.adjust_moles(GAS_N2, -heat_eff);
	air.adjust_moles(GAS_NITRYL, heat_eff * 2.0);
	return apply_temperature_change(air, old_heat_cap, -energy_used);
}

// ---- BZ formation ----
ReactionResult react_bzformation(GasMixtureView& air, ReactionCallbacks* cb) {
	double temp = air.return_temperature();
	double pressure = air.return_pressure();
	double old_heat_cap = air.heat_capacity();
	double n2o = air.get_moles(GAS_NITROUS);
	double plasma = air.get_moles(GAS_PLASMA);
	double ratio = std::max(plasma / n2o, 1.0);
	double eff = std::min({ 1.0 / ((pressure / (0.1 * ONE_ATMOSPHERE)) * ratio), n2o, plasma / 2.0 });
	double energy_released = 2.0 * eff * FIRE_CARBON_ENERGY_RELEASED;
	if (n2o - eff < 0 || plasma - 2.0 * eff < 0 || energy_released <= 0) return ReactionResult::NO_REACTION;
	air.adjust_moles(GAS_BZ, eff);
	if (eff >= n2o - 1e-9) {
		air.adjust_moles(GAS_BZ, -std::min(pressure, 1.0));
		air.adjust_moles(GAS_O2, std::min(pressure, 1.0));
	}
	air.adjust_moles(GAS_NITROUS, -eff);
	air.adjust_moles(GAS_PLASMA, -2.0 * eff);
	if (cb && cb->add_research)
		cb->add_research(std::min(eff * eff * BZ_RESEARCH_SCALE, BZ_RESEARCH_MAX_AMOUNT));
	return apply_temperature_change(air, old_heat_cap, energy_released);
}

// ---- Stimulum formation ----
ReactionResult react_stimformation(GasMixtureView& air, ReactionCallbacks* cb) {
	double old_heat_cap = air.heat_capacity();
	double temp = air.return_temperature();
	double trit = air.get_moles(GAS_TRITIUM);
	double plasma = air.get_moles(GAS_PLASMA);
	double nitryl = air.get_moles(GAS_NITRYL);
	double heat_scale = std::min({ temp / STIMULUM_HEAT_SCALE, trit, plasma, nitryl });
	double stim_energy = heat_scale + STIMULUM_FIRST_RISE*heat_scale*heat_scale - STIMULUM_FIRST_DROP*heat_scale*heat_scale*heat_scale
		+ STIMULUM_SECOND_RISE*heat_scale*heat_scale*heat_scale*heat_scale - STIMULUM_ABSOLUTE_DROP*heat_scale*heat_scale*heat_scale*heat_scale*heat_scale;
	if (trit - heat_scale < 0 || plasma - heat_scale < 0 || nitryl - heat_scale < 0) return ReactionResult::NO_REACTION;
	air.adjust_moles(GAS_STIMULUM, heat_scale / 10.0);
	air.adjust_moles(GAS_TRITIUM, -heat_scale);
	air.adjust_moles(GAS_PLASMA, -heat_scale);
	air.adjust_moles(GAS_NITRYL, -heat_scale);
	if (cb && cb->add_research && stim_energy > 0)
		cb->add_research(STIMULUM_RESEARCH_AMOUNT * stim_energy);
	if (stim_energy != 0)
		return apply_temperature_change(air, old_heat_cap, stim_energy);
	return ReactionResult::REACTING;
}

// ---- Noblium formation ----
ReactionResult react_nobliumformation(GasMixtureView& air, ReactionCallbacks* cb) {
	double temp = air.return_temperature();
	if (temp > NOBLIUM_FORMATION_MAX_TEMP) return ReactionResult::NO_REACTION;
	double n2 = air.get_moles(GAS_N2);
	double trit = air.get_moles(GAS_TRITIUM);
	double bz = air.get_moles(GAS_BZ);
	double trit_per_nob = 5.0 * trit / std::max(trit + 1000.0 * bz, 0.001);
	double nob_formed = std::min(n2 / 10.0, trit / std::max(trit_per_nob, 0.005));
	if (nob_formed <= 0) return ReactionResult::NO_REACTION;
	double trit_consumed = nob_formed * trit_per_nob;
	if (trit_consumed > trit || nob_formed * 10.0 > n2) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	air.adjust_moles(GAS_N2, -nob_formed * 10.0);
	air.adjust_moles(GAS_TRITIUM, -trit_consumed);
	air.adjust_moles(GAS_HYPERNOB, nob_formed);
	double energy_released = nob_formed * NOBLIUM_FORMATION_ENERGY / std::max(1.0, bz * 10.0);
	if (cb && cb->add_research) cb->add_research(nob_formed * NOBLIUM_RESEARCH_AMOUNT);
	return apply_temperature_change(air, old_heat_cap, energy_released);
}

// ---- Miasma sterilization ----
ReactionResult react_miaster(GasMixtureView& air, ReactionCallbacks* cb) {
	if (air.get_moles(GAS_H2O) > 0.1) return ReactionResult::NO_REACTION;
	double miasma = air.get_moles(GAS_MIASMA);
	double cleaned = std::min(miasma, 20.0 + (air.return_temperature() - (T0C + 170.0)) / 20.0);
	if (cleaned <= 0) return ReactionResult::NO_REACTION;
	air.adjust_moles(GAS_MIASMA, -cleaned);
	air.adjust_moles(GAS_O2, cleaned);
	air.set_temperature(air.return_temperature() + cleaned * 0.002);
	if (cb && cb->add_research) cb->add_research(cleaned * MIASMA_RESEARCH_AMOUNT);
	return ReactionResult::REACTING;
}

// ---- Nitric oxide ----
ReactionResult react_nitric_oxide(GasMixtureView& air,
	const std::unordered_map<std::string, double>* enthalpies) {
	double nitric = air.get_moles(GAS_NITRIC);
	double oxygen = air.get_moles(GAS_O2);
	double max_amount = std::max(nitric / 8.0, MINIMUM_MOLE_COUNT);
	double h_cap = air.heat_capacity();
	double total_moles = air.total_moles();
	double enthalpy = air.return_temperature() * (h_cap + R_IDEAL_GAS_EQUATION * total_moles);
	if (enthalpies) {
		auto en_no = enthalpies->find(GAS_NITRIC);
		auto en_no2 = enthalpies->find(GAS_NITRYL);
		double h_no = (en_no != enthalpies->end()) ? en_no->second : 0;
		double h_no2 = (en_no2 != enthalpies->end()) ? en_no2->second : 0;
		if (oxygen > MINIMUM_MOLE_COUNT) {
			double reaction_amount = std::min(max_amount, oxygen) / 4.0;
			air.adjust_moles(GAS_NITRIC, -reaction_amount * 2.0);
			air.adjust_moles(GAS_O2, -reaction_amount);
			air.adjust_moles(GAS_NITRYL, reaction_amount * 2.0);
			enthalpy += reaction_amount * -(h_no - h_no2);
		}
		air.adjust_moles(GAS_NITRIC, -max_amount);
		air.adjust_moles(GAS_O2, max_amount * 0.5);
		air.adjust_moles(GAS_N2, max_amount * 0.5);
		enthalpy += max_amount * -h_no;
	} else {
		if (oxygen > MINIMUM_MOLE_COUNT) {
			double reaction_amount = std::min(max_amount, oxygen) / 4.0;
			air.adjust_moles(GAS_NITRIC, -reaction_amount * 2.0);
			air.adjust_moles(GAS_O2, -reaction_amount);
			air.adjust_moles(GAS_NITRYL, reaction_amount * 2.0);
		}
		air.adjust_moles(GAS_NITRIC, -max_amount);
		air.adjust_moles(GAS_O2, max_amount * 0.5);
		air.adjust_moles(GAS_N2, max_amount * 0.5);
	}
	if (enthalpies)
		air.set_temperature(enthalpy / (air.heat_capacity() + R_IDEAL_GAS_EQUATION * air.total_moles()));
	return ReactionResult::REACTING;
}

// ---- Hagedorn ----
ReactionResult react_hagedorn(GasMixtureView& air, ReactionCallbacks* cb,
	const std::unordered_map<std::string, double>* specific_heats) {
	if (air.get_moles(GAS_QCD) > 0) return ReactionResult::NO_REACTION;
	double initial_energy = air.thermal_energy();
	if (!air.moles) return ReactionResult::NO_REACTION;
	for (auto it = air.moles->begin(); it != air.moles->end(); )
		it = air.moles->erase(it);
	double qcd_sh = 20.0;
	if (specific_heats) { auto it = specific_heats->find(GAS_QCD); if (it != specific_heats->end()) qcd_sh = it->second; }
	double amount = initial_energy / (air.return_temperature() * qcd_sh);
	air.set_moles(GAS_QCD, amount);
	if (cb && cb->add_research)
		cb->add_research(std::min(amount * QCD_RESEARCH_AMOUNT, 100000.0));
	return ReactionResult::REACTING;
}

// ---- Dehagedorn ----
ReactionResult react_dehagedorn(GasMixtureView& air,
	const std::unordered_map<std::string, double>* specific_heats) {
	double initial_energy = air.thermal_energy();
	air.set_moles(GAS_QCD, 0);
	air.set_temperature(std::min(air.return_temperature(), 1.8e12));
	double new_temp = air.return_temperature();
	if (!specific_heats || !air.moles) return ReactionResult::REACTING;
	std::vector<std::string> gases;
	for (const auto& p : *specific_heats) {
		if (p.first == GAS_QCD || p.first == GAS_TRITIUM || p.first == GAS_HYPERNOB) continue;
		gases.push_back(p.first);
	}
	static std::mt19937 rng(std::random_device{}());
	double energy_remaining = initial_energy;
	while (energy_remaining > 0 && !gases.empty()) {
		std::string g = gases[rng() % gases.size()];
		double sh = specific_heats->at(g);
		double add = std::max(0.1, energy_remaining / (sh * new_temp * 20.0));
		air.adjust_moles(g, add);
		energy_remaining = initial_energy - air.thermal_energy();
	}
	if (air.heat_capacity() > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(initial_energy / air.heat_capacity());
	return ReactionResult::REACTING;
}

// ---- Freon fire ----
ReactionResult react_freonfire(GasMixtureView& air, ReactionCallbacks* cb) {
	double temp = air.return_temperature();
	double max_burn_temp = FREON_MAXIMUM_BURN_TEMPERATURE;
	if (air.get_moles(GAS_PROTO_NITRATE) > MINIMUM_MOLE_COUNT)
		max_burn_temp = FREON_CATALYST_MAX_TEMPERATURE;
	if (temp > max_burn_temp) return ReactionResult::NO_REACTION;
	double temperature_scale = 0;
	if (temp < FREON_TERMINAL_TEMPERATURE) temperature_scale = 0;
	else if (temp < FREON_LOWER_TEMPERATURE) temperature_scale = 0.5;
	else temperature_scale = (max_burn_temp - temp) / (max_burn_temp - FREON_TERMINAL_TEMPERATURE);
	if (temperature_scale <= 0) return ReactionResult::NO_REACTION;
	double oxygen_burn_ratio = OXYGEN_BURN_RATIO_BASE - temperature_scale;
	double freon_moles = air.get_moles(GAS_FREON);
	double oxygen_moles = air.get_moles(GAS_O2);
	double freon_burn_rate;
	if (oxygen_moles < freon_moles * FREON_OXYGEN_FULLBURN)
		freon_burn_rate = ((oxygen_moles / FREON_OXYGEN_FULLBURN) / FREON_BURN_RATE_DELTA) * temperature_scale;
	else
		freon_burn_rate = (freon_moles / FREON_BURN_RATE_DELTA) * temperature_scale;
	if (freon_burn_rate < MINIMUM_HEAT_CAPACITY) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	freon_burn_rate = std::min({ freon_burn_rate, freon_moles, oxygen_moles / oxygen_burn_ratio });
	air.adjust_moles(GAS_FREON, -freon_burn_rate);
	air.adjust_moles(GAS_O2, -(freon_burn_rate * oxygen_burn_ratio));
	air.adjust_moles(GAS_CO2, freon_burn_rate);
	double energy_consumed = FIRE_FREON_ENERGY_CONSUMED * freon_burn_rate;
	double new_heat_cap = air.heat_capacity();
	if (new_heat_cap > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(std::max((temp * old_heat_cap - energy_consumed) / new_heat_cap, TCMB));
	if (cb && cb->spawn_hot_ice && cb->holder && temp >= FREON_HOT_ICE_MIN_TEMP && temp <= FREON_HOT_ICE_MAX_TEMP)
		cb->spawn_hot_ice(cb->holder);
	return ReactionResult::REACTING;
}

// ---- Freon formation ----
ReactionResult react_freonformation(GasMixtureView& air) {
	double temp = air.return_temperature();
	double plasma = air.get_moles(GAS_PLASMA);
	double co2 = air.get_moles(GAS_CO2);
	double bz = air.get_moles(GAS_BZ);
	double heat_factor = (temp - FREON_FORMATION_MIN_TEMPERATURE) / 100.0;
	double minimal = std::min({ plasma / 0.6, co2 / 0.3, bz / 0.1 });
	double reaction_units = std::min({ heat_factor * minimal * 0.05, plasma / 0.6, co2 / 0.3, bz / 0.1 });
	if (reaction_units <= 0) return ReactionResult::NO_REACTION;
	air.adjust_moles(GAS_PLASMA, -reaction_units * 0.6);
	air.adjust_moles(GAS_CO2, -reaction_units * 0.3);
	air.adjust_moles(GAS_BZ, -reaction_units * 0.1);
	air.adjust_moles(GAS_FREON, reaction_units * 10.0);
	double old_heat_cap = air.heat_capacity();
	double energy_consumed = FREON_FORMATION_ENERGY_CONSUMED * reaction_units;
	if (old_heat_cap > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(std::max((air.return_temperature() * old_heat_cap - energy_consumed) / air.heat_capacity(), TCMB));
	return ReactionResult::REACTING;
}

// ---- Halon O2 removal ----
ReactionResult react_halon_o2removal(GasMixtureView& air) {
	double temp = air.return_temperature();
	double halon = air.get_moles(GAS_HALON);
	double oxygen = air.get_moles(GAS_O2);
	double heat_eff = std::min({ temp / HALON_COMBUSTION_TEMPERATURE_SCALE, halon, oxygen / 20.0 });
	if (heat_eff <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	air.adjust_moles(GAS_HALON, -heat_eff);
	air.adjust_moles(GAS_O2, -(heat_eff * 20.0));
	air.adjust_moles(GAS_PLUOXIUM, heat_eff * 2.5);
	double energy_used = heat_eff * HALON_COMBUSTION_ENERGY;
	double new_heat_cap = air.heat_capacity();
	if (new_heat_cap > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(std::max((temp * old_heat_cap - energy_used) / new_heat_cap, TCMB));
	return ReactionResult::REACTING;
}

// ---- Healium formation ----
ReactionResult react_healium_formation(GasMixtureView& air) {
	double temp = air.return_temperature();
	if (temp > HEALIUM_FORMATION_MAX_TEMP) return ReactionResult::NO_REACTION;
	double freon = air.get_moles(GAS_FREON);
	double bz = air.get_moles(GAS_BZ);
	double heat_eff = std::min({ temp * 0.3, freon / 2.75, bz / 0.25 });
	if (heat_eff <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	air.adjust_moles(GAS_FREON, -heat_eff * 2.75);
	air.adjust_moles(GAS_BZ, -heat_eff * 0.25);
	air.adjust_moles(GAS_HEALIUM, heat_eff * 3.0);
	double energy_released = heat_eff * HEALIUM_FORMATION_ENERGY;
	return apply_temperature_change(air, old_heat_cap, energy_released);
}

// ---- Zauker formation ----
ReactionResult react_zauker_formation(GasMixtureView& air) {
	double temp = air.return_temperature();
	if (temp > ZAUKER_FORMATION_MAX_TEMPERATURE) return ReactionResult::NO_REACTION;
	double hypernob = air.get_moles(GAS_HYPERNOB);
	double nitrium = air.get_moles(GAS_NITRIUM);
	double heat_eff = std::min({ temp * ZAUKER_FORMATION_TEMPERATURE_SCALE, hypernob / 0.01, nitrium / 0.5 });
	if (heat_eff <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	air.adjust_moles(GAS_HYPERNOB, -heat_eff * 0.01);
	air.adjust_moles(GAS_NITRIUM, -heat_eff * 0.5);
	air.adjust_moles(GAS_ZAUKER, heat_eff * 0.5);
	double energy_used = heat_eff * ZAUKER_FORMATION_ENERGY;
	double new_heat_cap = air.heat_capacity();
	if (new_heat_cap > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(std::max((temp * old_heat_cap - energy_used) / new_heat_cap, TCMB));
	return ReactionResult::REACTING;
}

// ---- Zauker decomp ----
ReactionResult react_zauker_decomp(GasMixtureView& air) {
	double n2 = air.get_moles(GAS_N2);
	double zauker = air.get_moles(GAS_ZAUKER);
	double burned = std::min({ ZAUKER_DECOMPOSITION_MAX_RATE, n2, zauker });
	if (burned <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	double temp = air.return_temperature();
	air.adjust_moles(GAS_ZAUKER, -burned);
	air.adjust_moles(GAS_O2, burned * 0.3);
	air.adjust_moles(GAS_N2, burned * 0.7);
	double energy_released = ZAUKER_DECOMPOSITION_ENERGY * burned;
	return apply_temperature_change(air, old_heat_cap, energy_released);
}

// ---- Nitrium formation ----
ReactionResult react_nitrium_formation(GasMixtureView& air) {
	double temp = air.return_temperature();
	double trit = air.get_moles(GAS_TRITIUM);
	double n2 = air.get_moles(GAS_N2);
	double bz = air.get_moles(GAS_BZ);
	double heat_eff = std::min({ temp / NITRIUM_FORMATION_TEMP_DIVISOR, trit, n2, bz / 0.05 });
	if (heat_eff <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	air.adjust_moles(GAS_TRITIUM, -heat_eff);
	air.adjust_moles(GAS_N2, -heat_eff);
	air.adjust_moles(GAS_BZ, -heat_eff * 0.05);
	air.adjust_moles(GAS_NITRIUM, heat_eff);
	double energy_used = heat_eff * NITRIUM_FORMATION_ENERGY;
	double new_heat_cap = air.heat_capacity();
	if (new_heat_cap > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(std::max((temp * old_heat_cap - energy_used) / new_heat_cap, TCMB));
	return ReactionResult::REACTING;
}

// ---- Nitrium decomposition ----
ReactionResult react_nitrium_decomposition(GasMixtureView& air) {
	double temp = air.return_temperature();
	if (temp > NITRIUM_DECOMPOSITION_MAX_TEMP) return ReactionResult::NO_REACTION;
	double nitrium = air.get_moles(GAS_NITRIUM);
	double heat_eff = std::min(temp / NITRIUM_DECOMPOSITION_TEMP_DIVISOR, nitrium);
	if (heat_eff <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	air.adjust_moles(GAS_NITRIUM, -heat_eff);
	air.adjust_moles(GAS_N2, heat_eff);
	air.adjust_moles(GAS_HYDROGEN, heat_eff);
	double energy_released = heat_eff * NITRIUM_DECOMPOSITION_ENERGY;
	return apply_temperature_change(air, old_heat_cap, energy_released);
}

// ---- Pluoxium formation ----
ReactionResult react_pluox_formation(GasMixtureView& air) {
	double temp = air.return_temperature();
	if (temp > PLUOXIUM_FORMATION_MAX_TEMP) return ReactionResult::NO_REACTION;
	double co2 = air.get_moles(GAS_CO2);
	double o2 = air.get_moles(GAS_O2);
	double trit = air.get_moles(GAS_TRITIUM);
	double produced = std::min({ PLUOXIUM_FORMATION_MAX_RATE, o2 * 0.5, co2, trit / 0.01 });
	if (produced <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	air.adjust_moles(GAS_CO2, -produced);
	air.adjust_moles(GAS_O2, -produced * 2.0);
	air.adjust_moles(GAS_TRITIUM, -produced * 0.01);
	air.adjust_moles(GAS_PLUOXIUM, produced);
	air.adjust_moles(GAS_HYDROGEN, produced * 0.01);
	double energy_released = produced * PLUOXIUM_FORMATION_ENERGY;
	return apply_temperature_change(air, old_heat_cap, energy_released);
}

// ---- Proto nitrate formation ----
ReactionResult react_proto_nitrate_formation(GasMixtureView& air) {
	double temp = air.return_temperature();
	if (temp > PN_FORMATION_MAX_TEMPERATURE) return ReactionResult::NO_REACTION;
	double pluox = air.get_moles(GAS_PLUOXIUM);
	double h2 = air.get_moles(GAS_HYDROGEN);
	double heat_eff = std::min({ temp * 0.005, pluox / 0.2, h2 / 2.0 });
	if (heat_eff <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	air.adjust_moles(GAS_HYDROGEN, -heat_eff * 2.0);
	air.adjust_moles(GAS_PLUOXIUM, -heat_eff * 0.2);
	air.adjust_moles(GAS_PROTO_NITRATE, heat_eff * 2.2);
	double energy_released = heat_eff * PN_FORMATION_ENERGY;
	return apply_temperature_change(air, old_heat_cap, energy_released);
}

// ---- Proto nitrate hydrogen response ----
ReactionResult react_proto_nitrate_hydrogen_response(GasMixtureView& air) {
	double proto = air.get_moles(GAS_PROTO_NITRATE);
	double h2 = air.get_moles(GAS_HYDROGEN);
	double produced = std::min({ PN_HYDROGEN_CONVERSION_MAX_RATE, h2, proto });
	if (produced <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	double temp = air.return_temperature();
	air.adjust_moles(GAS_HYDROGEN, -produced);
	air.adjust_moles(GAS_PROTO_NITRATE, produced * 0.5);
	double energy_used = produced * PN_HYDROGEN_CONVERSION_ENERGY;
	double new_heat_cap = air.heat_capacity();
	if (new_heat_cap > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(std::max((temp * old_heat_cap - energy_used) / new_heat_cap, TCMB));
	return ReactionResult::REACTING;
}

// ---- Proto nitrate tritium response ----
ReactionResult react_proto_nitrate_tritium_response(GasMixtureView& air) {
	double temp = air.return_temperature();
	if (temp > PN_TRITIUM_CONVERSION_MAX_TEMP) return ReactionResult::NO_REACTION;
	double proto = air.get_moles(GAS_PROTO_NITRATE);
	double trit = air.get_moles(GAS_TRITIUM);
	double produced = std::min({ temp / 34.0 * (trit * proto) / (trit + 10.0 * proto), trit, proto / 0.01 });
	if (produced <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	air.adjust_moles(GAS_PROTO_NITRATE, -produced * 0.01);
	air.adjust_moles(GAS_TRITIUM, -produced);
	air.adjust_moles(GAS_HYDROGEN, produced);
	double energy_released = produced * PN_TRITIUM_CONVERSION_ENERGY;
	return apply_temperature_change(air, old_heat_cap, energy_released);
}

// ---- Proto nitrate BZ response ----
ReactionResult react_proto_nitrate_bz_response(GasMixtureView& air) {
	double temp = air.return_temperature();
	if (temp > PN_BZASE_MAX_TEMP) return ReactionResult::NO_REACTION;
	double proto = air.get_moles(GAS_PROTO_NITRATE);
	double bz = air.get_moles(GAS_BZ);
	double consumed = std::min({ temp / 2240.0 * bz * proto / (bz + proto), bz, proto });
	if (consumed <= 0) return ReactionResult::NO_REACTION;
	double old_heat_cap = air.heat_capacity();
	air.adjust_moles(GAS_BZ, -consumed);
	air.adjust_moles(GAS_PROTO_NITRATE, -consumed);
	air.adjust_moles(GAS_N2, consumed * 0.4);
	air.adjust_moles(GAS_HELIUM, consumed * 1.6);
	air.adjust_moles(GAS_PLASMA, consumed * 0.8);
	double energy_released = consumed * PN_BZASE_ENERGY;
	return apply_temperature_change(air, old_heat_cap, energy_released);
}

// ---- Antinoblium replication ----
ReactionResult react_antinoblium_replication(GasMixtureView& air) {
	double total = air.total_moles();
	double antinob = air.get_moles(GAS_ANTINOBLIUM);
	double total_not = total - antinob;
	if (total_not < MINIMUM_MOLE_COUNT) return ReactionResult::NO_REACTION;
	double rate = std::min(antinob / ANTINOBLIUM_CONVERSION_DIVISOR, total_not);
	if (!air.moles) return ReactionResult::NO_REACTION;
	for (auto& p : *air.moles) {
		if (p.first == GAS_ANTINOBLIUM) continue;
		if (p.second > 0)
			air.adjust_moles(p.first, -rate * (p.second / total_not));
	}
	air.adjust_moles(GAS_ANTINOBLIUM, rate);
	double old_heat_cap = air.heat_capacity();
	double new_heat_cap = air.heat_capacity();
	if (new_heat_cap > MINIMUM_HEAT_CAPACITY)
		air.set_temperature(std::max(air.return_temperature() * old_heat_cap / new_heat_cap, TCMB));
	return ReactionResult::REACTING;
}

} // namespace atmos
