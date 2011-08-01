module dex.main;

import dex.regex;

import std.stdio;

void main() {
	writeln("all unittest passed");
	RegEx r1 = new RegEx();
	writeln("regex object created");
	//assert(r1.createNFA("[a-z][a-z]*", 1));
	//r1.cleanUp();
	//assert(r1.createNFA("[012]*", 2));
	assert(r1.createNFA("[:digit:]*", 1));
	assert(r1.createNFA("[:alpha:]*", 2));
	writeln("nfa's created");
	//r1.writeNFAGraph();
	writeln("nfa's graph created");
	r1.convertNfaToDfa();
	r1.findErrorState();	
	writeln("nfa to dfa convertions done");
	//r1.writeDFAGraph();
	writeln("dfa's graph created");
	r1.minimize();
	return;
}
