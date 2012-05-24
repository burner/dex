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

	bool verbose = false;
	ar.setOption("-v", "--verbose", 
		"if set you get more information about the process"
		, verbose);

	string nonStaticModulename;
	ar.setOption("-nm", "--nonstaticname", "set the modulename for the non " ~
		"static part of the lexer only usefull is -n(onstatic) is set", 
		nonStaticModulename, true);

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
		log(verbose, "%s", it.getRegEx());
		re.createNFA(it.getRegEx(), conv!(size_t,int)(it.getPriority()));
	}

	
	log(verbose, "convertNfaToDfa");
	re.convertNfaToDfa();
	log(verbose, "findErrorState");
	re.findErrorState();
	log(verbose, "minimize");
	re.minimize();
	
	// print graphs
	if(mdfaFilename !is null) {
		log(verbose, "writing min dfa");
		re.writeMinDFAGraph(mdfaFilename);
	}

	if(dfaFilename !is null) {
		log(verbose, "writing dfa");
		re.writeDFAGraph(dfaFilename);
	}

	if(nfaFilename !is null) {
		log(verbose, "writing nfa");
		re.writeNFAGraph(nfaFilename);
	}

	MinTable min = re.minTable();

	// emit lexer
	//re.writeTable("dfaTable",min);
	if(outputFilename !is null && outputFilename.length) {
		log(verbose, "emit lexer");
		emitLexer(min,input,outputClassname,outputFilename);
	}
	if(nonStatic !is null && nonStatic.length) {
		log(verbose, "emit non-static aka lextable");
		emitNonStatic(min,input,nonStaticModulename, nonStatic);
	}

	// cleanup
	//re.minTable();
	delete input;
	delete st;
	if(verbose) Trace.printStats();
}
