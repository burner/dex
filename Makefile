all: crude

crude:
	#dmd dex/*.d -offsm -unittest libphobos2.a libhurt.a -I../libhurt/ -gc
	dmd dex/main.d dex/bitmap.d dex/fsm.d dex/list.d -offsm -unittest libphobos2.a libhurt.a -I../libhurt/ -gc
