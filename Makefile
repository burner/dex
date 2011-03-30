all: crude

crude:
	dmd dex/*.d -offsm -unittest libphobos2.a libhurt.a -I../libhurt/ -gc
