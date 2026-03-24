// Remote-control toggle for receivers (IC jammer/speaker UI removed with Integrated Electronics).

/obj/machinery/telecomms/receiver/Options_Menu()
	var/dat = ..()
	dat += "<br>Remote control: <a href='?src=[REF(src)];toggle_remote_control=1'>[GLOB.remote_control ? "<font color='green'><b>ENABLED</b></font>" : "<font color='red'><b>DISABLED</b></font>"]</a>"
	return dat

/obj/machinery/telecomms/receiver/Options_Topic(href, href_list)
	if(href_list["toggle_remote_control"])
		GLOB.remote_control = !GLOB.remote_control
