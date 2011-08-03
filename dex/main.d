module dex.main;

import dex.regex;

import std.stdio;

void main() {
	writeln("all unittest passed");
	RegEx r1 = new RegEx();
	writeln("regex object created");
	assert(r1.createNFA("if", 1));
	assert(r1.createNFA("function", 2));
	assert(r1.createNFA("delegate", 3));
	assert(r1.createNFA("[:digit:][:digit:]*", 4));
	//assert(r1.createNFA("[:alpha:][:alpha:]*", 5));
	writeln("nfa's created");
	r1.writeNFAGraph();
	writeln("nfa's graph created");
	r1.convertNfaToDfa();
	r1.findErrorState();	
	writeln("nfa to dfa convertions done");
	r1.writeDFAGraph();
	writeln("dfa's graph created");
	r1.minimize();
	return;
}
