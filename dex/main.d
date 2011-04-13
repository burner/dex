module dex.main;

import dex.regex;

import std.stdio;

void main() {
	writeln("all unittest passed");
	RegEx r1 = new RegEx();
	assert(r1.createNFA("ab\\[[ts]*\\]"));
	//r1.cleanUp();
	//assert(r1.createNFA("abtz*"));
	//r1.cleanUp();
	r1.writeNFAGraph();
	r1.convertNfaToDfa();
	r1.writeDFAGraph();
	return;
}
