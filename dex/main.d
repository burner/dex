module dex.main;

import dex.emit;
import dex.input;
import dex.minimizer;
import dex.regex;

import hurt.io.stdio;
import hurt.conv.conv;
import hurt.util.getopt;
import hurt.time.stopwatch;
import hurt.time.time;
import hurt.util.slog;
import hurt.util.stacktrace;

void main(string[] args) {
	scope Trace st = new Trace("main");

	// handle the args arguments
	Args ar = Args(args);
	ar.setHelpText("dex a lexer generator for the D Programming Langauge");
	string inputFilename = null;
	ar.setOption("-i", "--input", "set the input file", inputFilename);

	string outputFilename = null;
	ar.setOption("-o", "--output", "set the output file", outputFilename);

	string outputClassname = null;
	ar.setOption("-oc", "--outputclassname", "set the class name of output file"
		, outputClassname);

	string nfaFilename = null;
	ar.setOption("-ng", "--nfagraph", "set the output file for the nfa graph" ~
		". if this option is passed the nfa graph will be printed", 
		nfaFilename);

	string dfaFilename = null;
	ar.setOption("-dg", "--dfagraph", "set the output file for the dfa graph" ~ 
		". if this option is passed the dfa graph will be printed", 
		dfaFilename);

	string mdfaFilename = null;
	ar.setOption("-mdg", "--mdfagraph", "set the output file for the dfa graph" 
		~ ". if this option is passed the minimized dfa graph will be printed", 
		mdfaFilename);

	string nonStatic;
	ar.setOption("-n", "--nonstatic", "set the filename for the non static part"
		~ " of the lexer", nonStatic);

	string nonStaticModulename;
	ar.setOption("-nm", "--nonstaticname", "set the modulename for the non " ~
		"static part of the lexer only usefull is -n(onstatic) is set", 
		nonStaticModulename);

	if(args.length == 1 || inputFilename is null) {
		ar.printHelp();
		return;
	}

	// parse the input file
	Input input;
	try {
		input = new Input(inputFilename);	
	} catch(Exception e) {
		println(e.msg);
		return;
	}

	// create the minimized dfa
	println("please wait ... this can take some time");
	RegEx re = new RegEx();
	foreach(it; input.getRegExCode()) {
		re.createNFA(it.getRegEx(), conv!(size_t,int)(it.getPriority()));
	}

	re.convertNfaToDfa();
	re.findErrorState();
	re.minimize();
	
	// print graphs
	if(mdfaFilename !is null) {
		re.writeMinDFAGraph(mdfaFilename);
	}

	if(dfaFilename !is null) {
		re.writeDFAGraph(dfaFilename);
	}

	if(nfaFilename !is null) {
		re.writeNFAGraph(nfaFilename);
	}

	MinTable min = re.minTable();

	// emit lexer
	//re.writeTable("dfaTable",min);
	if(outputFilename !is null && outputFilename.length) {
		emitLexer(min,input,outputClassname,outputFilename);
	}
	if(nonStatic !is null && nonStatic.length) {
		emitNonStatic(min,input,nonStaticModulename, nonStatic);
	}

	// cleanup
	//re.minTable();
	delete input;
	delete st;
	//Trace.printStats();
}
