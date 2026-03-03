// All gas reactions — declarations.
// Implementations in reactions.cpp. Side effects (radiation, research, spawn) 
// are reported via ReactionCallbacks so DM/auxmos can run them.

#ifndef BLUEMOON_ATMOS_REACTIONS_REACTIONS_HPP
#define BLUEMOON_ATMOS_REACTIONS_REACTIONS_HPP

#include "gas_mixture.hpp"

namespace atmos {

// Optional callbacks for reactions that need DM (radiation_pulse, SSresearch, spawn hot_ice, etc.)
struct ReactionCallbacks {
	void (*radiation_pulse)(void* holder, double rad_power) = nullptr;
	void (*add_research)(double amount) = nullptr;
	void (*spawn_hot_ice)(void* holder) = nullptr;
	void (*fire_expose)(void* holder, double temperature) = nullptr;
	void* holder = nullptr;
};

// Noblium suppression — stops further reactions
ReactionResult react_nobliumsupression(GasMixtureView& air);

// Water vapor — gas change; DM must run location.freon_gas_act / water_vapor_gas_act
ReactionResult react_water_vapor(GasMixtureView& air);

// Tritium combustion
ReactionResult react_tritfire(GasMixtureView& air, ReactionCallbacks* cb);

// Plasma combustion
ReactionResult react_plasmafire(GasMixtureView& air, ReactionCallbacks* cb);

// Generic fire (oxidation/fuel from gas_data)
ReactionResult react_genericfire(GasMixtureView& air, ReactionCallbacks* cb,
	const std::unordered_map<std::string, double>* oxidation_temps,
	const std::unordered_map<std::string, double>* oxidation_rates,
	const std::unordered_map<std::string, double>* fuel_temps,
	const std::unordered_map<std::string, double>* fuel_rates,
	const std::unordered_map<std::string, std::unordered_map<std::string, double>>* fire_products,
	const std::unordered_map<std::string, double>* enthalpies);

// Fusion
ReactionResult react_fusion(GasMixtureView& air, ReactionCallbacks* cb,
	const std::unordered_map<std::string, double>* fusion_powers);

// Nitryl formation
ReactionResult react_nitrylformation(GasMixtureView& air);

// BZ formation
ReactionResult react_bzformation(GasMixtureView& air, ReactionCallbacks* cb);

// Stimulum formation
ReactionResult react_stimformation(GasMixtureView& air, ReactionCallbacks* cb);

// Noblium formation
ReactionResult react_nobliumformation(GasMixtureView& air, ReactionCallbacks* cb);

// Miasma sterilization
ReactionResult react_miaster(GasMixtureView& air, ReactionCallbacks* cb);

// Nitric oxide decomposition
ReactionResult react_nitric_oxide(GasMixtureView& air,
	const std::unordered_map<std::string, double>* enthalpies);

// Hagedorn / Dehagedorn
ReactionResult react_hagedorn(GasMixtureView& air, ReactionCallbacks* cb,
	const std::unordered_map<std::string, double>* specific_heats);
ReactionResult react_dehagedorn(GasMixtureView& air,
	const std::unordered_map<std::string, double>* specific_heats);

// Freon fire & formation
ReactionResult react_freonfire(GasMixtureView& air, ReactionCallbacks* cb);
ReactionResult react_freonformation(GasMixtureView& air);

// Halon O2 removal
ReactionResult react_halon_o2removal(GasMixtureView& air);

// Healium, Zauker, Nitrium, Pluoxium, Proto-Nitrate, Antinoblium
ReactionResult react_healium_formation(GasMixtureView& air);
ReactionResult react_zauker_formation(GasMixtureView& air);
ReactionResult react_zauker_decomp(GasMixtureView& air);
ReactionResult react_nitrium_formation(GasMixtureView& air);
ReactionResult react_nitrium_decomposition(GasMixtureView& air);
ReactionResult react_pluox_formation(GasMixtureView& air);
ReactionResult react_proto_nitrate_formation(GasMixtureView& air);
ReactionResult react_proto_nitrate_hydrogen_response(GasMixtureView& air);
ReactionResult react_proto_nitrate_tritium_response(GasMixtureView& air);
ReactionResult react_proto_nitrate_bz_response(GasMixtureView& air);
ReactionResult react_antinoblium_replication(GasMixtureView& air);

} // namespace atmos

#endif
