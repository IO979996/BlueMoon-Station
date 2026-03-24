/// Helper define that can only be used in /obj/item/circuit_component/input_received()
#define COMPONENT_TRIGGERED_BY(trigger, port) (trigger.value && trigger == port)

/// Define to be placed at any proc that is triggered by a port.
#define CIRCUIT_TRIGGER SHOULD_NOT_SLEEP(TRUE)

// Port defines
#define PORT_MAX_NAME_LENGTH 50

#define PORT_TYPE_ANY "any"
#define PORT_TYPE_STRING "string"
#define PORT_MAX_STRING_LENGTH 5000
#define PORT_MAX_STRING_DISPLAY 100
#define PORT_TYPE_NUMBER "number"
#define PORT_TYPE_SIGNAL "signal"
#define PORT_TYPE_INSTANT_SIGNAL "instant signal"
#define PORT_TYPE_RESPONSE_SIGNAL "response signal"
#define PORT_TYPE_TABLE "table"
#define PORT_TYPE_OPTION "option"
#define PORT_TYPE_BOOLEAN "boolean"

/// Simple list type (BlueMoon wiremod uses a flat string key, not TG composites)
#define PORT_TYPE_LIST "list"

#define PORT_TYPE_ATOM "entity"
#define PORT_TYPE_DATUM "datum"
#define PORT_TYPE_USER "user"

#define PORT_ATOM_MAX_RANGE 7

#define COMPONENT_DEFAULT_NAME "component"
#define COMPONENT_DEFAULT_CATEGORY "Unassigned"

#define COMPONENT_MIN_RANDOM_POS 200
#define COMPONENT_MAX_RANDOM_POS 400
#define COMPONENT_MAX_POS 10000

#define COMPONENT_SIGNAL (world.time / (1 SECONDS))

#define COMP_COMPARISON_EQUAL "="
#define COMP_COMPARISON_NOT_EQUAL "!="
#define COMP_COMPARISON_GREATER_THAN ">"
#define COMP_COMPARISON_LESS_THAN "<"
#define COMP_COMPARISON_GREATER_THAN_OR_EQUAL ">="
#define COMP_COMPARISON_LESS_THAN_OR_EQUAL "<="

#define COMP_CLOCK_DELAY (0.9 SECONDS)

#define SHELL_FLAG_CIRCUIT_UNREMOVABLE (1<<0)
#define SHELL_FLAG_REQUIRE_ANCHOR (1<<1)
#define SHELL_FLAG_USB_PORT (1<<2)
#define SHELL_FLAG_ALLOW_FAILURE_ACTION (1<<3)
#define SHELL_FLAG_CIRCUIT_UNMODIFIABLE (1<<5)

#define SHELL_CAPACITY_TINY 12
#define SHELL_CAPACITY_SMALL 25
#define SHELL_CAPACITY_MEDIUM 50
#define SHELL_CAPACITY_LARGE 100
#define SHELL_CAPACITY_VERY_LARGE 500

#define USB_CABLE_MAX_RANGE 2

/// True if atom A is within range tiles of atom B (TG helper; used by usb cable).
#define IN_GIVEN_RANGE(atom_a, atom_b, range) (get_dist(atom_a, atom_b) <= (range))

#define CIRCUIT_FLAG_INPUT_SIGNAL (1<<0)
#define CIRCUIT_FLAG_OUTPUT_SIGNAL (1<<1)
#define CIRCUIT_FLAG_ADMIN (1<<2)
#define CIRCUIT_FLAG_HIDDEN (1<<3)
#define CIRCUIT_FLAG_INSTANT (1<<4)
#define CIRCUIT_FLAG_REFUSE_MODULE (1<<5)
#define CIRCUIT_NO_DUPLICATES (1<<6)
#define CIRCUIT_FLAG_DISABLED (1<<7)
#define CIRCUIT_FLAG_UNDUPEABLE (1<<8)

#define DATATYPE_FLAG_ALLOW_MANUAL_INPUT (1<<0)
#define DATATYPE_FLAG_AVOID_VALUE_UPDATE (1<<1)
#define DATATYPE_FLAG_ALLOW_ATOM_INPUT (1<<2)
#define DATATYPE_FLAG_COMPOSITE (1<<3)

/// Deferred component triggers (see wiremod_trigger.dm)
#define TRIGGER_CIRCUIT_COMPONENT(COMP, PORT) trigger_wiremod_circuit_component(COMP, PORT)

/// TIMER_COOLDOWN_* indices for wiremod components
#define COOLDOWN_CIRCUIT_PATHFIND_SAME "wiremod_cd_pathfind_same"
#define COOLDOWN_CIRCUIT_PATHFIND_DIF "wiremod_cd_pathfind_dif"
#define COOLDOWN_CIRCUIT_SOUNDEMITTER "wiremod_cd_soundemitter"
#define COOLDOWN_CIRCUIT_SPEECH "wiremod_cd_speech"
#define COOLDOWN_CIRCUIT_TARGET_INTERCEPT "wiremod_cd_target_intercept"
