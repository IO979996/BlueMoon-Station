// Minimal gas mixture for C++ reaction engine.
// Moles and heat capacity interface; can be backed by auxmos or a simple map.

#ifndef BLUEMOON_ATMOS_REACTIONS_GAS_MIXTURE_HPP
#define BLUEMOON_ATMOS_REACTIONS_GAS_MIXTURE_HPP

#include <string>
#include <unordered_map>
#include "reaction_constants.hpp"

namespace atmos {

enum class ReactionResult : int {
	NO_REACTION = 0,
	REACTING = 1,
	STOP_REACTIONS = 2
};

// Gas mixture state for use in C++ reactions.
// Caller (BYOND/auxmos bridge) can wrap the real mixture and forward get/set to this.
struct GasMixtureView {
	using MolesMap = std::unordered_map<std::string, double>;

	MolesMap* moles = nullptr;
	double* temperature = nullptr;
	double* volume = nullptr;
	// Optional: if null, heat capacity is computed from default specific heats
	std::unordered_map<std::string, double>* specific_heats = nullptr;
	// Optional: reaction_results["fire"], analyzer_results["fusion"]
	std::unordered_map<std::string, double>* reaction_results = nullptr;
	std::unordered_map<std::string, double>* analyzer_results = nullptr;

	double get_moles(const std::string& id) const {
		if (!moles) return 0.0;
		auto it = moles->find(id);
		return it == moles->end() ? 0.0 : it->second;
	}
	void set_moles(const std::string& id, double amt) {
		if (!moles) return;
		if (amt <= 0.0) moles->erase(id);
		else (*moles)[id] = quantize(amt);
	}
	void adjust_moles(const std::string& id, double delta) {
		double cur = get_moles(id);
		set_moles(id, cur + delta);
	}
	double return_temperature() const { return temperature ? *temperature : TCMB; }
	void set_temperature(double t) { if (temperature) *temperature = t; }
	double return_volume() const { return volume ? *volume : CELL_VOLUME; }
	double return_pressure() const {
		double t = return_temperature();
		double n = total_moles();
		if (n <= 0 || t <= 0) return 0.0;
		return n * R_IDEAL_GAS_EQUATION * t / return_volume();
	}
	double total_moles() const {
		if (!moles) return 0.0;
		double sum = 0.0;
		for (const auto& p : *moles) sum += p.second;
		return sum;
	}
	double thermal_energy() const {
		return heat_capacity() * return_temperature();
	}
	double heat_capacity() const {
		if (!moles || !temperature) return 0.0;
		double cap = 0.0;
		if (specific_heats) {
			for (const auto& p : *moles)
				if (p.second > 0) {
					auto it = specific_heats->find(p.first);
					if (it != specific_heats->end())
						cap += p.second * it->second;
					else
						cap += p.second * 20.0; // default J/(K*mol)
				}
		} else {
			for (const auto& p : *moles)
				if (p.second > 0) cap += p.second * 20.0;
		}
		return cap;
	}
	void set_fire_result(double v) {
		if (reaction_results) (*reaction_results)["fire"] = v;
	}
	void add_fire_result(double v) {
		if (reaction_results) (*reaction_results)["fire"] += v;
	}
	void set_fusion_instability(double v) {
		if (analyzer_results) (*analyzer_results)["fusion"] = v;
	}
};

} // namespace atmos

#endif
