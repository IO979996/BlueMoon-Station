// Reaction constants — mirror of code/__DEFINES/reactions.dm and atmospherics.dm
// Used by C++ reaction engine. Keep in sync with DM defines.

#ifndef BLUEMOON_ATMOS_REACTIONS_CONSTANTS_HPP
#define BLUEMOON_ATMOS_REACTIONS_CONSTANTS_HPP

#include <cmath>

namespace atmos {

// From atmospherics.dm
constexpr double R_IDEAL_GAS_EQUATION = 8.31;
constexpr double ONE_ATMOSPHERE = 101.325;
constexpr double TCMB = 2.7;
constexpr double T0C = 273.15;
constexpr double T20C = 293.15;
constexpr double CELL_VOLUME = 2500.0;
constexpr double FIRE_MINIMUM_TEMPERATURE_TO_EXIST = 100.0 + T0C;
constexpr double PLASMA_MINIMUM_BURN_TEMPERATURE = 100.0 + T0C;
constexpr double PLASMA_UPPER_TEMPERATURE = 1370.0 + T0C;
constexpr double PLASMA_OXYGEN_FULLBURN = 10.0;
constexpr double MOLES_GAS_VISIBLE = 0.25;

// From gas_mixture.dm
constexpr double MINIMUM_HEAT_CAPACITY = 0.0003;
constexpr double MINIMUM_MOLE_COUNT = 0.01;

// From reactions.dm — plasma fire
constexpr double OXYGEN_BURN_RATE_BASE = 1.4;
constexpr double PLASMA_BURN_RATE_DELTA = 9.0;
constexpr double FIRE_CARBON_ENERGY_RELEASED = 100000.0;
constexpr double FIRE_HYDROGEN_ENERGY_RELEASED = 280000.0;
constexpr double FIRE_PLASMA_ENERGY_RELEASED = 3000000.0;
constexpr double WATER_VAPOR_FREEZE = 200.0;
constexpr double NITRYL_FORMATION_ENERGY = 100000.0;
constexpr double TRITIUM_BURN_OXY_FACTOR = 100.0;
constexpr double TRITIUM_BURN_TRIT_FACTOR = 10.0;
constexpr double TRITIUM_BURN_RADIOACTIVITY_FACTOR = 5000.0;
constexpr double TRITIUM_MINIMUM_RADIATION_ENERGY = 0.1;
constexpr double SUPER_SATURATION_THRESHOLD = 96.0;
constexpr double STIMULUM_HEAT_SCALE = 100000.0;
constexpr double STIMULUM_FIRST_RISE = 0.65;
constexpr double STIMULUM_FIRST_DROP = 0.065;
constexpr double STIMULUM_SECOND_RISE = 0.0009;
constexpr double STIMULUM_ABSOLUTE_DROP = 0.00000335;
constexpr double REACTION_OPPRESSION_THRESHOLD = 5.0;
constexpr double NOBLIUM_FORMATION_ENERGY = 2e9;
constexpr double NOBLIUM_FORMATION_MAX_TEMP = 15.0;
constexpr double NOBLIUM_RESEARCH_AMOUNT = 25.0;
constexpr double BZ_RESEARCH_SCALE = 4.0;
constexpr double BZ_RESEARCH_MAX_AMOUNT = 400.0;
constexpr double MIASMA_RESEARCH_AMOUNT = 6.0;
constexpr double STIMULUM_RESEARCH_AMOUNT = 50.0;
constexpr double FUSION_MOLE_THRESHOLD = 250.0;
constexpr double FUSION_TRITIUM_MOLES_USED = 1.0;
constexpr double FUSION_TRITIUM_CONVERSION_COEFFICIENT = 1e-10;
constexpr double INSTABILITY_GAS_POWER_FACTOR = 0.003;
constexpr double PLASMA_BINDING_ENERGY = 20000000.0;
constexpr double TOROID_VOLUME_BREAKEVEN = 1000.0;
constexpr double FUSION_TEMPERATURE_THRESHOLD = 10000.0;
constexpr double FUSION_INSTABILITY_ENDOTHERMALITY = 2.0;
constexpr double QCD_RESEARCH_AMOUNT = 0.2;
constexpr double REACTION_OPPRESSION_MIN_TEMP = 20.0;

// Freon
constexpr double FREON_MAXIMUM_BURN_TEMPERATURE = T0C;
constexpr double FREON_CATALYST_MAX_TEMPERATURE = 310.0;
constexpr double FREON_LOWER_TEMPERATURE = 60.0;
constexpr double FREON_TERMINAL_TEMPERATURE = 50.0;
constexpr double FREON_HOT_ICE_MIN_TEMP = 120.0;
constexpr double FREON_HOT_ICE_MAX_TEMP = 160.0;
constexpr double FREON_OXYGEN_FULLBURN = 10.0;
constexpr double FREON_BURN_RATE_DELTA = 4.0;
constexpr double FIRE_FREON_ENERGY_CONSUMED = 3e5;
constexpr double FREON_FORMATION_MIN_TEMPERATURE = FIRE_MINIMUM_TEMPERATURE_TO_EXIST + 100.0;
constexpr double FREON_FORMATION_ENERGY_CONSUMED = 2e5;
constexpr double OXYGEN_BURN_RATIO_BASE = 2.0;

// Halon
constexpr double HALON_COMBUSTION_ENERGY = 2500.0;
constexpr double HALON_COMBUSTION_MIN_TEMPERATURE = T0C + 70.0;
constexpr double HALON_COMBUSTION_TEMPERATURE_SCALE = FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 10.0;

// Healium, Zauker, Nitrium, Pluoxium, Proto-Nitrate, Antinoblium
constexpr double HEALIUM_FORMATION_MIN_TEMP = 25.0;
constexpr double HEALIUM_FORMATION_MAX_TEMP = 300.0;
constexpr double HEALIUM_FORMATION_ENERGY = 9000.0;
constexpr double ZAUKER_FORMATION_MIN_TEMPERATURE = 50000.0;
constexpr double ZAUKER_FORMATION_MAX_TEMPERATURE = 75000.0;
constexpr double ZAUKER_FORMATION_TEMPERATURE_SCALE = 5e-6;
constexpr double ZAUKER_FORMATION_ENERGY = 5000.0;
constexpr double ZAUKER_DECOMPOSITION_MAX_RATE = 20.0;
constexpr double ZAUKER_DECOMPOSITION_ENERGY = 460.0;
constexpr double NITRIUM_FORMATION_MIN_TEMP = 1500.0;
constexpr double NITRIUM_FORMATION_TEMP_DIVISOR = FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 8.0;
constexpr double NITRIUM_FORMATION_ENERGY = 100000.0;
constexpr double NITRIUM_DECOMPOSITION_MAX_TEMP = T0C + 70.0;
constexpr double NITRIUM_DECOMPOSITION_TEMP_DIVISOR = FIRE_MINIMUM_TEMPERATURE_TO_EXIST * 8.0;
constexpr double NITRIUM_DECOMPOSITION_ENERGY = 30000.0;
constexpr double PLUOXIUM_FORMATION_MIN_TEMP = 50.0;
constexpr double PLUOXIUM_FORMATION_MAX_TEMP = T0C;
constexpr double PLUOXIUM_FORMATION_MAX_RATE = 5.0;
constexpr double PLUOXIUM_FORMATION_ENERGY = 250.0;
constexpr double PN_FORMATION_MIN_TEMPERATURE = 5000.0;
constexpr double PN_FORMATION_MAX_TEMPERATURE = 10000.0;
constexpr double PN_FORMATION_ENERGY = 650.0;
constexpr double PN_HYDROGEN_CONVERSION_THRESHOLD = 150.0;
constexpr double PN_HYDROGEN_CONVERSION_MAX_RATE = 5.0;
constexpr double PN_HYDROGEN_CONVERSION_ENERGY = 2500.0;
constexpr double PN_TRITIUM_CONVERSION_MIN_TEMP = 150.0;
constexpr double PN_TRITIUM_CONVERSION_MAX_TEMP = 340.0;
constexpr double PN_TRITIUM_CONVERSION_ENERGY = 10000.0;
constexpr double PN_BZASE_MIN_TEMP = 260.0;
constexpr double PN_BZASE_MAX_TEMP = 280.0;
constexpr double PN_BZASE_ENERGY = 60000.0;
constexpr double ANTINOBLIUM_CONVERSION_DIVISOR = 90.0;

constexpr double PI_DM = 3.1416;

inline double quantize(double v) {
	return std::round(v * 1e7) / 1e7;
}
inline double inverse(double x) { return 1.0 / x; }
inline double clamp(double v, double lo, double hi) {
	if (v < lo) return lo;
	if (v > hi) return hi;
	return v;
}
inline double fmod_positive(double a, double b) {
	double r = std::fmod(a, b);
	return r < 0 ? r + b : r;
}

} // namespace atmos

#endif
