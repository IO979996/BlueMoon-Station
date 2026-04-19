/// True when changeling Cellular Emporium should list ANTAG_EXTENDED-only powers (ERP stings, arm tentacle, etc.).
/proc/changeling_lewd_shop_round()
	if(GLOB.round_type == ROUNDTYPE_DYNAMIC_LIGHT || GLOB.master_mode == ROUNDTYPE_DYNAMIC_LIGHT)
		return TRUE
	if(GLOB.master_mode == ROUNDTYPE_EXTENDED)
		return TRUE
	if(SSticker?.mode && (SSticker.mode.config_tag in list("Extended", "secret_extended")))
		return TRUE
	if(istype(SSticker?.mode, /datum/game_mode/dynamic) && GLOB.dynamic_type_threat_max <= 70)
		return TRUE
	return FALSE
