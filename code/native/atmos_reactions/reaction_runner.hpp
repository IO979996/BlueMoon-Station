// Runs all reactions in priority order. Used by BYOND bridge.
#ifndef BLUEMOON_ATMOS_REACTIONS_RUNNER_HPP
#define BLUEMOON_ATMOS_REACTIONS_RUNNER_HPP

#include <string>

namespace atmos {

// Input: "o2=100;n2=800;TEMP=293.15;VOLUME=2500" (gas_id=moles separated by ;)
// Output: same format with updated values, optionally ";FIRE=0.5;FUSION=3.14"
// Returns empty string on parse error.
std::string run_reactions(const std::string& mixture_string);

} // namespace atmos

#endif
