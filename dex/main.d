module dex.main;

import dex.input;

import hurt.io.stdio;

void main(string[] args) {
	Input input;
	if(args.length == 1) {
		println("no input file passed");
	} else if(args.length == 2) {
		try {
			input = new Input(args[1]);	
		} catch(Exception e) {
			println(e.msg);
			return;
		}
	}
	delete input;
}
