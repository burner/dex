module dex.main;

import dex.input;
import dex.regex;

import hurt.io.stdio;
import hurt.conv.conv;
import hurt.util.getopt;

void main(string[] args) {
	Args ar = Args(args);
	ar.setHelpText("dex a lexer generator for the D Programming Langauge");
	string inputFilename = null;
	string outputFilename = "out.d";
	string nfaFilename = null;
	string dfaFilename = null;
	string mdfaFilename = null;
	ar.setOption("-i", "--input", "set the input file", inputFilename);
	ar.setOption("-o", "--output", "set the output file", outputFilename);
	ar.setOption("-ng", "--nfagraph", "set the output file for the nfa graph" ~
		". if this option is passed the nfa graph will be printed", 
		nfaFilename);
	ar.setOption("-dg", "--dfagraph", "set the output file for the dfa graph" ~ 
		". if this option is passed the dfa graph will be printed", 
		dfaFilename);
	ar.setOption("-mdg", "--mdfagraph", "set the output file for the dfa graph" 
		~ ". if this option is passed the minimized dfa graph will be printed", 
		mdfaFilename);

	if(args.length == 1 || inputFilename is null) {
		ar.printHelp();
		return;
	}

	Input input;
	try {
		input = new Input(inputFilename);	
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
	
	if(mdfaFilename !is null) {
		re.writeMinDFAGraph(mdfaFilename);
	}

	if(dfaFilename !is null) {
		re.writeDFAGraph(dfaFilename);
	}

	if(nfaFilename !is null) {
		re.writeNFAGraph(nfaFilename);
	}

	delete input;
}
