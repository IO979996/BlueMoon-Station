// Circuit / wiremod signals

#define COMSIG_PORT_SET_VALUE "port_set_value"
#define COMSIG_PORT_SET_TYPE "port_set_type"
#define COMSIG_PORT_DISCONNECT "port_disconnect"

#define COMSIG_CIRCUIT_ADD_COMPONENT "circuit_add_component"
#define COMPONENT_CANCEL_ADD_COMPONENT (1<<0)

#define COMSIG_CIRCUIT_ADD_COMPONENT_MANUALLY "circuit_add_component_manually"

#define COMSIG_CIRCUIT_SHELL_REMOVED "circuit_shell_removed"

#define COMSIG_CIRCUIT_COMPONENT_ADDED "circuit_component_added"
#define COMSIG_CIRCUIT_COMPONENT_REMOVED "circuit_component_removed"

#define COMSIG_CIRCUIT_SET_CELL "circuit_set_cell"
#define COMSIG_CIRCUIT_SET_ON "circuit_set_on"
#define COMSIG_CIRCUIT_SET_SHELL "circuit_set_shell"
#define COMSIG_CIRCUIT_SET_LOCKED "circuit_set_locked"

#define COMSIG_CIRCUIT_PRE_POWER_USAGE "circuit_pre_power_usage"
#define COMPONENT_OVERRIDE_POWER_USAGE (1<<0)

#define COMSIG_CIRCUIT_PRE_SAVE_TO_JSON "circuit_pre_save_to_json"
#define COMSIG_CIRCUIT_POST_LOAD "circuit_post_load"

#define COMSIG_ATOM_USB_CABLE_TRY_ATTACH "usb_cable_try_attach"
#define COMSIG_USB_CABLE_ATTACHED (1<<0)
#define COMSIG_USB_CABLE_CONNECTED_TO_CIRCUIT (1<<1)
#define COMSIG_CANCEL_USB_CABLE_ATTACK (1<<2)

#define COMSIG_CIRCUIT_COMPONENT_SAVE "circuit_component_save"
#define COMSIG_CIRCUIT_COMPONENT_SAVE_DATA "circuit_component_save_data"
#define COMSIG_CIRCUIT_COMPONENT_LOAD_DATA "circuit_component_load_data"

#define COMSIG_MOVABLE_CIRCUIT_LOADED "movable_circuit_loaded"

#define COMSIG_CIRCUIT_COMPONENT_PERFORM_ACTION "circuit_component_perform_action"

#define COMSIG_GLOB_CIRCUIT_NTNET_DATA_SENT "!circuit_ntnet_data_sent"

#define COMSIG_CIRCUIT_ACTION_COMPONENT_REGISTERED "circuit_action_component_registered"
#define COMSIG_CIRCUIT_ACTION_COMPONENT_UNREGISTERED "circuit_action_component_unregistered"

#define COMSIG_CIRCUIT_NFC_DATA_SENT "circuit_nfc_data_receive"

#define COMSIG_SHELL_CIRCUIT_ATTACHED "shell_circuit_attached"
#define COMSIG_SHELL_CIRCUIT_REMOVED "shell_circuit_removed"

#define COMSIG_USB_PORT_REGISTER_PHYSICAL_OBJECT "usb_port_register_physical_object"
#define COMSIG_USB_PORT_UNREGISTER_PHYSICAL_OBJECT "usb_port_unregister_physical_object"

/// From /obj/structure/money_bot add_money(): (amount_added)
#define COMSIG_MONEYBOT_ADD_MONEY "moneybot_add_money"

/// Airlock shell / wiremod (sent from airlock when state changes, if implemented on base type)
#define COMSIG_AIRLOCK_SET_BOLT "airlock_set_bolt"
#define COMSIG_AIRLOCK_OPEN "airlock_open"
#define COMSIG_AIRLOCK_CLOSE "airlock_close"

/// TG name alias — BlueMoon uses COMSIG_PARENT_EXAMINE
#define COMSIG_ATOM_EXAMINE COMSIG_PARENT_EXAMINE

/// TG name alias — BlueMoon uses COMSIG_PARENT_QDELETING
#define COMSIG_QDELETING COMSIG_PARENT_QDELETING

/// TG name — BlueMoon sends COMSIG_OBJ_SETANCHORED from set_anchored()
#define COMSIG_MOVABLE_SET_ANCHORED COMSIG_OBJ_SETANCHORED

/// Circuit scanner gate shell
#define COMSIG_SCANGATE_SHELL_PASS "scangate_shell_pass"

/// BCI / surgery organ hooks (stubs for wiremod files if surgery doesn't send them)
#ifndef COMSIG_ORGAN_IMPLANTED
#define COMSIG_ORGAN_IMPLANTED "organ_implanted"
#endif
#ifndef COMSIG_ORGAN_REMOVED
#define COMSIG_ORGAN_REMOVED "organ_removed"
#endif

/// Right-click in hand (TG); not wired on all items — registered only where supported
#ifndef COMSIG_ITEM_ATTACK_SELF_SECONDARY
#define COMSIG_ITEM_ATTACK_SELF_SECONDARY "item_attack_self_secondary"
#endif

/// attack_hand secondary chain (TG)
#ifndef SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
#define SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN (1<<0)
#endif
