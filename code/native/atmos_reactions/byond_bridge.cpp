// BYOND extension bridge: exports run_reactions and version for call_ext("atmos_cpp", ...).

#include "reaction_runner.hpp"
#include <string>
#include <cstring>

#ifdef _WIN32
#define EXPORT __declspec(dllexport)
#else
#define EXPORT __attribute__((visibility("default")))
#endif

static char return_buffer[65536];

extern "C" {
	EXPORT const char* run_reactions(const char* input) {
		if (!input) return "";
		std::string out = atmos::run_reactions(input);
		size_t n = out.size();
		if (n >= sizeof(return_buffer)) n = sizeof(return_buffer) - 1;
		std::memcpy(return_buffer, out.c_str(), n);
		return_buffer[n] = '\0';
		return return_buffer;
	}

	EXPORT const char* version() {
		return "atmos_cpp 1.0";
	}
}
