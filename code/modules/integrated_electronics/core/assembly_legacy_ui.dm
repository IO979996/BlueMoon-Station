/// Классический браузерный UI для интегральной электроники (альтернатива TGUI).

/obj/item/electronic_assembly/proc/ie_legacy_ui_interact(mob/user, obj/item/integrated_circuit/focus_chip)
	if(!user)
		return
	var/window_id = "ie_asm_legacy_[REF(src)]"
	var/title = "[name] (классика)"
	var/body
	if(focus_chip && (focus_chip in assembly_components))
		body = focus_chip.ie_legacy_chip_page_html(src)
	else
		body = ie_legacy_assembly_overview_html()
	var/datum/browser/popup = new(user, window_id, title, 760, 680)
	popup.set_content(body)
	popup.open()

/obj/item/electronic_assembly/proc/ie_legacy_assembly_overview_html()
	. = "<div style='font-size:12px;font-family:sans-serif'>"
	. += "<p><a href='?src=[REF(src)];ie_ui_mode=tgui'><b>Новый интерфейс (TGUI)</b></a></p>"
	. += "<h3>[html_encode(name)]</h3>"
	. += "<p>"
	. += "<a href='?src=[REF(src)];rename=1'>Переименовать корпус</a> · "
	if(battery)
		. += "<a href='?src=[REF(src)];remove_cell=1'>Достать батарею</a> ([round(100 * battery.charge / max(battery.maxcharge, 1), 0.1)]%)"
	else
		. += "Батарея не установлена"
	. += "</p>"
	if(!length(assembly_components))
		. += "<p><i>В корпусе нет микросхем.</i></p></div>"
		return
	. += "<table border='1' cellspacing='0' cellpadding='4' style='border-collapse:collapse;width:100%'>"
	. += "<tr><th>Компонент</th><th>Место/сложн.</th><th>Действия</th></tr>"
	for(var/obj/item/integrated_circuit/C as anything in assembly_components)
		var/actions = "<a href='?src=[REF(src)];ie_legacy_chip=[REF(C)]'>Открыть (классика)</a>"
		if(C.removable)
			actions += " · <a href='?src=[REF(src)];component=[REF(C)];remove=1'>Извлечь</a>"
			actions += " · <a href='?src=[REF(src)];component=[REF(C)];rename_component=1'>Переименовать</a>"
			actions += " · <a href='?src=[REF(src)];component=[REF(C)];interact=1'>В руку / использовать</a>"
			actions += " · <a href='?src=[REF(src)];component=[REF(C)];change_pos=1'>Позиция</a>"
		actions += " · <a href='?src=[REF(src)];component=[REF(C)];scan=1'>Скан ref</a>"
		. += "<tr><td>[html_encode(C.displayed_name || C.name)]</td><td>[C.size] / [C.complexity]</td><td>[actions]</td></tr>"
	. += "</table>"
	. += "<p class='notice'><small>Провода: мультитул или намотка; данные на пин: мультитул «данные» или отладчик. Скан ref — режим ref на отладчике.</small></p>"
	. += "</div>"

/obj/item/integrated_circuit/proc/ie_legacy_chip_page_html(obj/item/electronic_assembly/asm)
	. = "<div style='font-size:12px;font-family:sans-serif'>"
	if(asm)
		. += "<p><a href='?src=[REF(asm)];ie_ui_mode=tgui'><b>Новый интерфейс (TGUI)</b></a> · "
		. += "<a href='?src=[REF(asm)];ie_legacy_overview=1'>К списку компонентов</a></p>"
	else
		. += "<p><a href='?src=[REF(src)];ie_ui_mode=tgui'><b>Новый интерфейс (TGUI)</b></a></p>"
	. += "<h3>[html_encode(displayed_name || name)]</h3>"
	if(extended_desc)
		. += "<p class='notice'>[html_encode(extended_desc)]</p>"
	. += "<p>"
	. += "<a href='?src=[REF(src)];rename=1'>Переименовать чип</a>"
	if(asm)
		. += " · <a href='?src=[REF(asm)];component=[REF(src)];scan=1'>Скан ref (через корпус)</a>"
	else
		. += " · <a href='?src=[REF(src)];scan=1'>Скан ref</a>"
	. += "</p>"
	if(length(inputs))
		. += "<h4>Входы</h4><table border='1' cellspacing='0' cellpadding='3' style='border-collapse:collapse;width:100%'>"
		. += "<tr><th>Пин</th><th>Тип</th><th>Значение</th><th>Связи / действия</th></tr>"
		for(var/datum/integrated_io/I in inputs)
			. += ie_legacy_pin_row_html(I)
		. += "</table>"
	if(length(outputs))
		. += "<h4>Выходы</h4><table border='1' cellspacing='0' cellpadding='3' style='border-collapse:collapse;width:100%'>"
		. += "<tr><th>Пин</th><th>Тип</th><th>Значение</th><th>Связи / действия</th></tr>"
		for(var/datum/integrated_io/O in outputs)
			. += ie_legacy_pin_row_html(O)
		. += "</table>"
	if(length(activators))
		. += "<h4>Активация</h4><table border='1' cellspacing='0' cellpadding='3' style='border-collapse:collapse;width:100%'>"
		. += "<tr><th>Пин</th><th>Тип</th><th>Значение</th><th>Связи / действия</th></tr>"
		for(var/datum/integrated_io/A in activators)
			. += ie_legacy_pin_row_html(A)
		. += "</table>"
	. += "<p class='notice'><small>Провод / снять провод / данные — держите мультитул, намотку или отладчик в активной руке.</small></p>"
	. += "</div>"

/obj/item/integrated_circuit/proc/ie_legacy_pin_row_html(datum/integrated_io/pin)
	if(!pin)
		return ""
	var/is_pulse_out = istype(pin, /datum/integrated_io/activate/out)
	var/links = ""
	if(istype(pin, /datum/integrated_io/lists))
		links += "<a href='?src=[REF(src)];ie_legacy_list=1;list_pin=[REF(pin)]'>Редактор списка</a> "
	if(pin.io_type == PULSE_CHANNEL && !is_pulse_out)
		links += "<a href='?src=[REF(src)];manual_pulse=1;pin=[REF(pin)]'>Импульс</a> "
	if(pin.io_type == PULSE_CHANNEL || pin.io_type == DATA_CHANNEL)
		links += "<a href='?src=[REF(src)];pin=[REF(pin)];act=wire'>Провод</a> "
	if(pin.io_type == DATA_CHANNEL || (pin.io_type == PULSE_CHANNEL && !is_pulse_out))
		links += "<a href='?src=[REF(src)];pin=[REF(pin)];act=data'>Данные</a> "
	for(var/datum/integrated_io/L in pin.linked)
		links += "<a href='?src=[REF(src)];pin=[REF(pin)];link=[REF(L)];act=unwire'>✖ [html_encode(L.name)]</a> "
	return "<tr><td>[html_encode(pin.name)]</td><td>[pin.display_pin_type()]</td><td>[pin.display_data(pin.data)]</td><td>[links]</td></tr>"

/obj/item/integrated_circuit/proc/ie_legacy_ui_interact_chip(mob/user)
	if(!user)
		return
	var/datum/browser/popup = new(user, "ie_chip_legacy_[REF(src)]", "[displayed_name || name] (классика)", 720, 640)
	popup.set_content(ie_legacy_chip_page_html(null))
	popup.open()
