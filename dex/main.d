module dex.main;

import dex.input;
import dex.regex;

import hurt.io.stdio;
import hurt.conv.conv;

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
		RegEx re = new RegEx();
		foreach(it; input.getRegExCode()) {
			re.createNFA(it.getRegEx(), conv!(size_t,int)(it.getPriority()));
		}
		re.convertNfaToDfa();
		re.findErrorState();
		re.minimize();
		re.writeMinDFAGraph();
	}
	delete input;
}
