// Reaction runner: parse mixture string, run all reactions in order, serialize back.

#include "reaction_runner.hpp"
#include "reactions.hpp"
#include "gas_mixture.hpp"
#include "gas_ids.hpp"
#include "reaction_constants.hpp"
#include <unordered_map>
#include <vector>
#include <algorithm>
#include <cmath>
#include <cstring>
#include <cstdlib>

namespace atmos {

// Single-pass parse without istringstream/getline.
static void parse_mixture(const std::string& s, GasMixtureView::MolesMap& moles, double& temp, double& vol) {
	moles.clear();
	temp = TCMB;
	vol = CELL_VOLUME;
	const char* p = s.data();
	const char* const end = p + s.size();
	while (p < end) {
		const char* semi = static_cast<const char*>(std::memchr(p, ';', static_cast<size_t>(end - p)));
		if (!semi) semi = end;
		const char* eq = static_cast<const char*>(std::memchr(p, '=', static_cast<size_t>(semi - p)));
		if (eq && eq > p && eq < semi - 1) {
			std::string key(p, static_cast<size_t>(eq - p));
			char* val_end = nullptr;
			double v = std::strtod(eq + 1, &val_end);
			if (val_end > eq + 1) {
				if (key == "TEMP") temp = v;
				else if (key == "VOLUME") vol = v;
				else if (key != "FIRE" && key != "FUSION") moles[key] = quantize(v);
			}
		}
		p = semi + (semi < end ? 1 : 0);
	}
}

static double total_moles(const GasMixtureView::MolesMap& moles) {
	double t = 0;
	for (const auto& p : moles) t += p.second;
	return t;
}

static std::string serialize_mixture(const GasMixtureView::MolesMap& moles, double temp, double vol,
	double fire_result, double fusion_result) {
	std::string out;
	out.reserve(512);
	for (const auto& p : moles)
		if (p.second > 0) {
			out += p.first;
			out += "=";
			out += std::to_string(p.second);
			out += ";";
		}
	out += "TEMP=";
	out += std::to_string(temp);
	out += ";VOLUME=";
	out += std::to_string(vol);
	if (fire_result != 0) {
		out += ";FIRE=";
		out += std::to_string(fire_result);
	}
	if (fusion_result != 0) {
		out += ";FUSION=";
		out += std::to_string(fusion_result);
	}
	return out;
}

// Reaction entry: priority (higher = first), and a function that returns STOP_REACTIONS to break.
using ReactFunc = ReactionResult(*)(GasMixtureView&, ReactionCallbacks*);
struct ReactionEntry { double priority; ReactFunc func; };

static ReactionResult run_one(GasMixtureView& air, ReactionCallbacks* cb, ReactFunc f) {
	return f(air, cb);
}

std::string run_reactions(const std::string& mixture_string) {
	GasMixtureView::MolesMap moles;
	double temp, vol;
	parse_mixture(mixture_string, moles, temp, vol);
	if (total_moles(moles) <= 0)
		return mixture_string;

	std::unordered_map<std::string, double> reaction_results;
	std::unordered_map<std::string, double> analyzer_results;
	GasMixtureView air;
	air.moles = &moles;
	air.temperature = &temp;
	air.volume = &vol;
	air.reaction_results = &reaction_results;
	air.analyzer_results = &analyzer_results;
	ReactionCallbacks cb = {}; // no side effects in DLL

	// Run in priority order (high first). Order from reactions.dm; exclude condensation (dynamic).
	// Check min_requirements in C++ (simplified: just run, each reaction no-ops if reqs not met).
	ReactionResult result = ReactionResult::NO_REACTION;

	// Noblium suppression first (priority INF)
	if (air.get_moles(GAS_HYPERNOB) >= REACTION_OPPRESSION_THRESHOLD && temp > REACTION_OPPRESSION_MIN_TEMP) {
		ReactionResult r = react_nobliumsupression(air);
		if (r == ReactionResult::STOP_REACTIONS) return serialize_mixture(moles, temp, vol, 0, 0);
	}

	// Water vapor (1) - gas part only
	if (air.get_moles(GAS_H2O) >= MOLES_GAS_VISIBLE && temp <= T0C + 40)
		result = (ReactionResult)((int)result | (int)react_water_vapor(air));

	// Fusion (2) - no fusion_powers, skip or run with empty map
	if (temp >= FUSION_TEMPERATURE_THRESHOLD && air.get_moles(GAS_TRITIUM) >= FUSION_TRITIUM_MOLES_USED
		&& air.get_moles(GAS_PLASMA) >= FUSION_MOLE_THRESHOLD && air.get_moles(GAS_CO2) >= FUSION_MOLE_THRESHOLD) {
		static std::unordered_map<std::string, double> empty_fusion;
		result = (ReactionResult)((int)result | (int)react_fusion(air, &cb, &empty_fusion));
	}

	// Nitryl (3), BZ (4), Stim (5), Noblium (6)
	if (temp >= FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 25 && air.get_moles(GAS_O2) >= 20 && air.get_moles(GAS_N2) >= 20 && air.get_moles(GAS_NITROUS) >= 5)
		result = (ReactionResult)((int)result | (int)react_nitrylformation(air));
	if (air.get_moles(GAS_NITROUS) >= 10 && air.get_moles(GAS_PLASMA) >= 10)
		result = (ReactionResult)((int)result | (int)react_bzformation(air, &cb));
	if (air.get_moles(GAS_TRITIUM) >= 30 && air.get_moles(GAS_PLASMA) >= 10 && air.get_moles(GAS_BZ) >= 20 && air.get_moles(GAS_NITRYL) >= 30 && temp >= STIMULUM_HEAT_SCALE/2)
		result = (ReactionResult)((int)result | (int)react_stimformation(air, &cb));
	if (air.get_moles(GAS_N2) >= 10 && air.get_moles(GAS_TRITIUM) >= 5 && temp <= NOBLIUM_FORMATION_MAX_TEMP)
		result = (ReactionResult)((int)result | (int)react_nobliumformation(air, &cb));

	// Dehagedorn (50)
	if (temp <= 1.99e12 && air.get_moles(GAS_QCD) >= MINIMUM_MOLE_COUNT) {
		static std::unordered_map<std::string, double> default_heats;
		if (default_heats.empty()) { default_heats["o2"]=20; default_heats["n2"]=20; default_heats["plasma"]=200; default_heats["co2"]=30; }
		result = (ReactionResult)((int)result | (int)react_dehagedorn(air, &default_heats));
	}

	// Halon (22), Zauker decomp (23), Nitrium decomp (24), PN hydrogen (25), PN tritium (26), PN BZ (27)
	if (air.get_moles(GAS_HALON) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_O2) >= MINIMUM_MOLE_COUNT && temp >= HALON_COMBUSTION_MIN_TEMPERATURE)
		result = (ReactionResult)((int)result | (int)react_halon_o2removal(air));
	if (air.get_moles(GAS_ZAUKER) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_N2) >= MINIMUM_MOLE_COUNT)
		result = (ReactionResult)((int)result | (int)react_zauker_decomp(air));
	if (air.get_moles(GAS_NITRIUM) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_O2) >= MINIMUM_MOLE_COUNT && temp <= NITRIUM_DECOMPOSITION_MAX_TEMP)
		result = (ReactionResult)((int)result | (int)react_nitrium_decomposition(air));
	if (air.get_moles(GAS_PROTO_NITRATE) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_HYDROGEN) >= PN_HYDROGEN_CONVERSION_THRESHOLD)
		result = (ReactionResult)((int)result | (int)react_proto_nitrate_hydrogen_response(air));
	if (air.get_moles(GAS_PROTO_NITRATE) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_TRITIUM) >= MINIMUM_MOLE_COUNT && temp >= PN_TRITIUM_CONVERSION_MIN_TEMP && temp <= PN_TRITIUM_CONVERSION_MAX_TEMP)
		result = (ReactionResult)((int)result | (int)react_proto_nitrate_tritium_response(air));
	if (air.get_moles(GAS_PROTO_NITRATE) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_BZ) >= MINIMUM_MOLE_COUNT && temp >= PN_BZASE_MIN_TEMP && temp <= PN_BZASE_MAX_TEMP)
		result = (ReactionResult)((int)result | (int)react_proto_nitrate_bz_response(air));

	// Freon formation (33), Healium (34), Zauker form (35), Nitrium form (36), Pluox (37), PN form (38), Antinoblium (40)
	if (air.get_moles(GAS_PLASMA) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_CO2) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_BZ) >= MINIMUM_MOLE_COUNT && temp >= FREON_FORMATION_MIN_TEMPERATURE)
		result = (ReactionResult)((int)result | (int)react_freonformation(air));
	if (air.get_moles(GAS_BZ) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_FREON) >= MINIMUM_MOLE_COUNT && temp >= HEALIUM_FORMATION_MIN_TEMP && temp <= HEALIUM_FORMATION_MAX_TEMP)
		result = (ReactionResult)((int)result | (int)react_healium_formation(air));
	if (air.get_moles(GAS_HYPERNOB) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_NITRIUM) >= MINIMUM_MOLE_COUNT && temp >= ZAUKER_FORMATION_MIN_TEMPERATURE && temp <= ZAUKER_FORMATION_MAX_TEMPERATURE)
		result = (ReactionResult)((int)result | (int)react_zauker_formation(air));
	if (air.get_moles(GAS_TRITIUM) >= 20 && air.get_moles(GAS_N2) >= 10 && air.get_moles(GAS_BZ) >= 5 && temp >= NITRIUM_FORMATION_MIN_TEMP)
		result = (ReactionResult)((int)result | (int)react_nitrium_formation(air));
	if (air.get_moles(GAS_CO2) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_O2) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_TRITIUM) >= MINIMUM_MOLE_COUNT && temp >= PLUOXIUM_FORMATION_MIN_TEMP && temp <= PLUOXIUM_FORMATION_MAX_TEMP)
		result = (ReactionResult)((int)result | (int)react_pluox_formation(air));
	if (air.get_moles(GAS_PLUOXIUM) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_HYDROGEN) >= MINIMUM_MOLE_COUNT && temp >= PN_FORMATION_MIN_TEMPERATURE && temp <= PN_FORMATION_MAX_TEMPERATURE)
		result = (ReactionResult)((int)result | (int)react_proto_nitrate_formation(air));
	if (air.get_moles(GAS_ANTINOBLIUM) >= MOLES_GAS_VISIBLE && temp >= REACTION_OPPRESSION_MIN_TEMP)
		result = (ReactionResult)((int)result | (int)react_antinoblium_replication(air));

	// Miasma sterilization (-999)
	if (temp >= T0C + 170 && air.get_moles(GAS_MIASMA) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_H2O) <= 0.1)
		result = (ReactionResult)((int)result | (int)react_miaster(air, &cb));

	// Nitric oxide (-5) - no enthalpies
	if (temp <= FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 100 && air.get_moles(GAS_NITRIC) >= MINIMUM_MOLE_COUNT)
		result = (ReactionResult)((int)result | (int)react_nitric_oxide(air, nullptr));

	// Freon fire (-12)
	if (air.get_moles(GAS_O2) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_FREON) >= MINIMUM_MOLE_COUNT && temp >= FREON_TERMINAL_TEMPERATURE)
		result = (ReactionResult)((int)result | (int)react_freonfire(air, &cb));

	// Tritfire (-1), Plasmafire (-2), Genericfire (-3) - need gas_data / callbacks; skip genericfire
	if (temp >= FIRE_MINIMUM_TEMPERATURE_TO_EXIST && air.get_moles(GAS_TRITIUM) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_O2) >= MINIMUM_MOLE_COUNT)
		result = (ReactionResult)((int)result | (int)react_tritfire(air, &cb));
	if (temp >= FIRE_MINIMUM_TEMPERATURE_TO_EXIST && air.get_moles(GAS_PLASMA) >= MINIMUM_MOLE_COUNT && air.get_moles(GAS_O2) >= MINIMUM_MOLE_COUNT)
		result = (ReactionResult)((int)result | (int)react_plasmafire(air, &cb));

	// Hagedorn (-inf)
	if (temp >= 2e12 && air.get_moles(GAS_QCD) < MINIMUM_MOLE_COUNT) {
		static std::unordered_map<std::string, double> qcd_heats;
		if (qcd_heats.empty()) { qcd_heats[GAS_QCD] = 20; }
		result = (ReactionResult)((int)result | (int)react_hagedorn(air, &cb, &qcd_heats));
	}

	double fire_val = 0, fusion_val = 0;
	if (reaction_results.count("fire")) fire_val = reaction_results["fire"];
	if (analyzer_results.count("fusion")) fusion_val = analyzer_results["fusion"];
	return serialize_mixture(moles, temp, vol, fire_val, fusion_val);
}

} // namespace atmos
