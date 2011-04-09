module dex.main;

import dex.regex;

import std.stdio;

void main() {
	writeln("all unittest passed");
	RegEx r1 = new RegEx();
	assert(r1.createNFA("ab(t|(if)s)*"));
	r1.cleanUp();
	assert(r1.createNFA("(t|(u)s)p"));
	r1.cleanUp();
	assert(r1.createNFA("tsp*"));
	r1.writeNFAGraph();
	return;
}
