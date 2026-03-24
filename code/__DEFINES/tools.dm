// Tool types
#define TOOL_CROWBAR 		"crowbar"
#define TOOL_MULTITOOL 		"multitool"
#define TOOL_SCREWDRIVER 	"screwdriver"
#define TOOL_WIRECUTTER 	"wirecutter"
#define TOOL_WRENCH 		"wrench"
#define TOOL_WELDER 		"welder"
#define TOOL_ANALYZER		"analyzer"
#define TOOL_MINING			"mining"
#define TOOL_SHOVEL			"shovel"
#define TOOL_RETRACTOR	 	"retractor"
#define TOOL_HEMOSTAT 		"hemostat"
#define TOOL_CAUTERY 		"cautery"
#define TOOL_DRILL			"drill"
#define TOOL_SCALPEL		"scalpel"
#define TOOL_SAW			"saw"
#define TOOL_KNIFE 			"knife"
#define TOOL_BLOODFILTER 	"bloodfilter"
#define TOOL_ROLLINGPIN 	"rollingpin"
#define TOOL_UNROLLINGPIN 	"unrollingpin"
//Glasswork Tools
#define TOOL_BLOW			"blowing_rod"
#define TOOL_GLASS_CUT		"glasskit"
#define TOOL_BONESET		"bonesetter"

// If delay between the start and the end of tool operation is less than MIN_TOOL_SOUND_DELAY,
// tool sound is only played when op is started. If not, it's played twice.
#define MIN_TOOL_SOUND_DELAY 20

// tool_act chain flags

/// When a tooltype_act proc is successful
#define TOOL_ACT_TOOLTYPE_SUCCESS (1<<0)
/// When [COMSIG_ATOM_TOOL_ACT] blocks the act
#define TOOL_ACT_SIGNAL_BLOCKING (1<<1)

/// When [TOOL_ACT_TOOLTYPE_SUCCESS] or [TOOL_ACT_SIGNAL_BLOCKING] are set
#define TOOL_ACT_MELEE_CHAIN_BLOCKING (TOOL_ACT_TOOLTYPE_SUCCESS | TOOL_ACT_SIGNAL_BLOCKING)

// atom/base_item_interaction + COMSIG_ATOM_ITEM_INTERACTION (shells, etc.)
/// Interaction succeeded; stop the attack chain (see return_values.dm)
#define ITEM_INTERACT_SUCCESS (STOP_ATTACK_PROC_CHAIN)
/// Block further handling the same way as success (used by shells to consume tool clicks)
#define ITEM_INTERACT_BLOCKING (STOP_ATTACK_PROC_CHAIN)
