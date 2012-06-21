module dex.emit;

import dex.state;
import dex.strutil;
import dex.minimizer;
import dex.input;

import hurt.algo.sorting;
import hurt.algo.binaryrangesearch;
import hurt.container.isr;
import hurt.container.iterator;
import hurt.container.map;
import hurt.container.set;
import hurt.container.crs;
import hurt.container.vector;
import hurt.container.multimap;
import hurt.conv.conv;
import hurt.io.stdio;
import hurt.io.stream;
import hurt.string.formatter;
import hurt.string.stringbuffer;
import hurt.string.utf;
import hurt.util.array;
import hurt.util.slog;

import std.process;

/** This function is used to write the created transition table to a given 
 *  file. If the file is allready exists it is overwritten.
 *
 *  The methode works by using the format function to lay out the state 
 *  transitions. 
 *
 * 	@param min The MinTable returned by the minizer.
 * 	@param states The Iterable container containing all states of the given
 * 		regular expressions.
 *  @param input All input character used.
 *  @param filename, The name of the output file.
 */
void writeTable(MinTable min, Iterable!(State) states, Set!(dchar) inputSet,
		string filename) {

	// Create the file
	hurt.io.stream.File file = new hurt.io.stream.File(filename ~ ".tab", 
		FileMode.OutNew);

	// Sort the output, so the states can be iterated in order by their
	// stateId.
	sortVector!(State)(cast(Vector!(State))states, 
		function(in State a, in State b) { 
			return a.getStateId() < b.getStateId(); 
		});

	// For every 10 states the length of the output per item must be
	// increased by one so no two string occupy the same space.
	int howManyBlanks = 0;
	size_t size = states.getSize();
	while(size > 0) {
		howManyBlanks++;
		size /= 10;
	}
	assert(howManyBlanks >= 1);

	StringBuffer!(dchar) sb = new StringBuffer!(dchar)();
	
	// Print the first row. The first row contains the input symbols
	ISRIterator!(dchar) it = inputSet.begin();
	for(int i = 0; i < howManyBlanks; i++)
		sb.pushBack(' ');

	for(; it.isValid(); it++) {
		for(int i = 0; i < howManyBlanks; i++)
			sb.pushBack(' ');

		sb.pushBack(*it);	
	}
	file.writeString(conv!(dstring,string)(sb.getString()));
	file.write('\n');
	sb.clear();

	for(int i = 0; i < howManyBlanks; i++)
		sb.pushBack(' ');
	for(int i = 0; i < inputSet.getSize(); i++) {
		sb.pushBack(format!(char,dchar)("%" ~ 
			conv!(int,string)(howManyBlanks+1) ~ "d", i));
	}
	file.writeString(conv!(dstring,string)(sb.getString()));
	file.write('\n');
	sb.clear();

	// Print the transitiones for every state on every input character.
	// If a state has no input character emit a -1 to mark a transistion
	// to an error state.
	foreach(it; states) {
		sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(howManyBlanks)
			~ "d", it.getStateId()));

		ISRIterator!(dchar) cit = inputSet.begin();
		for(; cit.isValid(); cit++) {
			sb.pushBack(' ');
			assert(it !is null);
			State next = it.getSingleTransition(*cit);
			int nextId = next is null ? -1 : next.getStateId();

			sb.pushBack(format!(char,dchar)("%" ~ 
				conv!(int,string)(howManyBlanks) ~ "d", nextId));
		}
		sb.pushBack('\n');
		file.writeString(conv!(dstring,string)(sb.getString()));
		sb.clear();
	}

	file.write('\n');
	file.write('\n');

	// The rest prints information about the minimazation ratio and
	// other information.
	sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(9)
		~ "s", "input"));

	ISRIterator!(MapItem!(dchar,Column)) rit = min.inputChar.begin();
	for(; rit.isValid(); rit++) {
		for(int i = 0; i < howManyBlanks; i++)
			sb.pushBack(' ');

		sb.pushBack((*rit).getKey());	
	}
	sb.pushBack('\n');
	file.writeString(conv!(dstring,string)(sb.getString()));
	sb.clear();

	rit = min.inputChar.begin();
	sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(9)
		~ "s", "column"));

	for(; rit.isValid(); rit++) {
		sb.pushBack(format!(char,dchar)("%" ~ 
			conv!(int,string)(howManyBlanks+1) ~ "d", (*rit).getData().idx));
	}
	sb.pushBack('\n');
	file.writeString(conv!(dstring,string)(sb.getString()));
	sb.clear();

	file.write('\n');
	sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(7)
		~ "s", "state"));

	foreach(idx, sit; min.state) {
		sb.pushBack(format!(char,dchar)("%3d", idx));
	}
	sb.pushBack('\n');
	file.writeString(conv!(dstring,string)(sb.getString()));
	sb.clear();

	sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(7)
		~ "s", "row"));

	foreach(idx, sit; min.state) {
		sb.pushBack(format!(char,dchar)("%3d", sit));
	}

	sb.pushBack('\n');
	sb.pushBack('\n');
	file.writeString(conv!(dstring,string)(sb.getString()));
	sb.clear();

	sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(4)
		~ "s", " "));
	for(int i = 0; i < min.table[0].getSize(); i++) {
		sb.pushBack(format!(char,dchar)("%3d", i));
	}
	sb.pushBack('\n');
	file.writeString(conv!(dstring,string)(sb.getString()));
	sb.clear();

	foreach(idx, rit; min.table) {
		sb.pushBack(format!(char,dchar)("%" ~ conv!(int,string)(4)
			~ "d", idx));
		foreach(s; rit) {
			sb.pushBack(format!(char,dchar)("%3d", s));
		}
		sb.pushBack('\n');
		file.writeString(conv!(dstring,string)(sb.getString()));
		sb.clear();
	}

	long oldTable = states.getSize() * inputSet.getSize();
	long newTable = min.table.getSize() * min.table[0].getSize();

	float oldTableDiv = 
		conv!(long,float)(oldTable) / conv!(long,float)(newTable);

	file.writeString("\n   table reduction ratio = ");
	file.writeString(format!(char,char)("%.3f", oldTableDiv));
	file.write(':');
	file.writeString("1\n\n");

	file.writeString("   old table has = ");
	file.writeString(conv!(long,string)(oldTable));
	file.writeString(" states\n");
	file.writeString("   new table has = ");
	file.writeString(conv!(long,string)(newTable));
	file.writeString(" states\n");
	file.close();
}
void writeNfa(Iterable!(State) states, Set!(dchar) inputSet,
		string fileName) {
	string[] strTable = ["digraph{\n"];
	StringBuffer!(char) strLine = new StringBuffer!(char)(16);
	foreach(it;states) {
		if(it.isAccepting()) {
			strLine.pushBack('\t').pushBack(it.toString());
			strLine.pushBack("\t[shape=doublecircle];\n");
			append(strTable, strLine.getString());
			strLine.clear();
		}
	}
	append(strTable, "\n");
	strLine.clear();

	// Record transitions
	foreach(pState;states) {
		State[] state;	

		state = pState.getTransition(0);
		foreach(jt;state) {
			string stateId1 = (pState.toString());
			string stateId2 = (jt.toString());
			strLine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
			strLine.pushBack("\t[label=\"epsilon\"];\n");
			append(strTable, strLine.getString());
			strLine.clear();
		}

		foreach(jt; inputSet) {
			dchar[1] inChar;
			inChar[0] = jt;
			string inputDChar = toUTF8(inChar);
			state = pState.getTransition(jt);
			foreach(kt;state) {
				string stateId1 = (pState.toString());
				string stateId2 = (kt.toString());
				strLine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
				//strLine.pushBack("\t[label=\"" ~ jt ~ "\"];\n");
				strLine.pushBack("\t[label=\"" ~ inputDChar ~ "\"];\n");
				append(strTable, strLine.getString());
				strLine.clear();
			}
		}	
	}

	append(strTable, "}");
	hurt.io.stream.File file = new hurt.io.stream.File(fileName ~ ".dot", 
		FileMode.OutNew);
	foreach(it;strTable) {
		file.writeString(it);
	}
	file.close();
	system("dot -T jpg " ~ fileName ~ ".dot > " ~ fileName ~ ".jpg");
}

/** A function that writes a given graph to a file of name fileName.
 *  Iterable is a container that implements opApply. The transitions of
 *  the states inside the container should correspond to the character inside
 *  the inputSet. Otherwise the transistion will not be displayed.
 *
 *  @param states The States of the graph.
 *  @param inputSet The transition character.
 *  @param fileName The filename of the resulting graph. Note that, if the file
 *  	exists, it will be overwritten.
 */
void writeGraph(Iterable!(State) states, Set!(dchar) inputSet,
		string fileName) {
	string[] strTable = ["digraph{\n"];
	StringBuffer!(char) strLine = new StringBuffer!(char)(16);

	// Write which endstates exist.
	foreach(it;states) {
		if(it.isAccepting()) {
			strLine.pushBack('\t').pushBack(it.toString());
			strLine.pushBack("\t[shape=doublecircle];\n");
			append(strTable, strLine.getString());
			strLine.clear();
		}
	}
	append(strTable, "\n");
	strLine.clear();

	// Record transitions
	StringBuffer!(dchar) tranSb = new StringBuffer!(dchar)(32);
	foreach(pState;states) {
		State[] state;	

		// write epsilon transition, this is one interesting for the nfa
		state = pState.getTransition(0);
		foreach(jt;state) {
			string stateId1 = (pState.toString());
			string stateId2 = (jt.toString());
			strLine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
			strLine.pushBack("\t[label=\"epsilon\"];\n");
			append(strTable, strLine.getString());
			strLine.clear();
		}

		MultiMap!(State,dchar) mm = new MultiMap!(State,dchar)();
		hurt.container.multimap.Iterator!(dchar,State) it;
		MultiMap!(dchar,State) pSmm = pState.getTransitions();
		if(pSmm is null || pSmm.getSize() == 0)
			continue;

		it = pSmm.begin();

		for(; it.isValid(); it++) {
			mm.insert(*it, it.getKey());
		}

		// write the transitions
		foreach(jt; mm.keys()) {
			hurt.container.multimap.Iterator!(State,dchar) kt = mm.range(jt);
			tranSb.clear();
			tranSb.pushBack("[");
			int count = 0;
			Vector!(dex.strutil.Range) r = makeRanges(kt);
			assert(r.getSize() > 0);
			foreach(kt; r) {
				dstring tmp = kt.toDString();
				assert(tmp.length > 0);
				tranSb.pushBack(tmp);
				tranSb.pushBack(",");
			}
			if(tranSb.peekBack() == ',')
				tranSb.popBack();
			tranSb.pushBack("]");

			string stateId1 = (pState.toString());
			string stateId2 = (jt.toString());
			strLine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
			//strLine.pushBack("\t[label=\"epsilon\"];\n");
			strLine.pushBack("\t[label=\"");
			strLine.pushBack(replaceNewline(toUTF8(tranSb.getString())));
			strLine.pushBack("\"];\n");
			append(strTable, strLine.getString());
			strLine.clear();

		}

	}

	append(strTable, "}");
	hurt.io.stream.File file = new hurt.io.stream.File(fileName ~ ".dot", 
		FileMode.OutNew);
	foreach(it;strTable) {
		file.writeString(it);
	}
	file.close();
	system("dot -Ln1 -T jpg " ~ fileName ~ ".dot > " ~ fileName ~ ".jpg");
}

/** The dot language doesn't display whitespace as wanted so it needs
 *  to be replaced.
 *
 *  @param str The string that needs to be processed.
 *  @returned The string where every \n is replaced by a newline, every \t by a 
 *		tabular and every " by a \\".
 */
string replaceNewline(string str) {
	StringBuffer!(char) ret = new StringBuffer!(char)(str.length+2);
	foreach(it; str) {
		if(it == '\n') {
			ret.pushBack("newline");
		} else if(it == '"') {
			ret.pushBack("\\");
			ret.pushBack('"');
		} else if(it == '\\') {
			ret.pushBack("\\");
		} else if(it == '\t') {
			ret.pushBack("tabular");
		} else {
			ret.pushBack(it);
		}
	}
	return ret.getString();
}

/** This functions returns a string which is a D function which tells you for a
 *  given input parameter if the state behind it is a accepting state or not. 
 *
 *  Of form:
 *
 *  private int isAccepetingState(stateType state) {
 *		switch(state) {
 *			case 0:
 *				return 34; // any positiv integer or -1
 *			case 1:
 *				return -1; // If it has no accepting state.
 *			default:
 *  			assert(false, "invalid state passed " ~ 
 *			 		conv!(stateType,string)(state));
 *		}
 *  }
 *
 *  @param min, The minimized Table comming from the minizer.
 *  @param stateType If the number of states is below ubyte.max the stateType
 *  	will be ubyte. You should see the pattern.
 *
 *  @return The created isAccepetingState function.
 */
string createIsAcceptingStateFunction(MinTable min) {
	StringBuffer!(char) ret = new StringBuffer!(char)(1024);
	
	// function header
	ret.pushBack("public static stateType " ~
		"isAcceptingState(stateType state) {\n");

	// function body which switch case
	ret.pushBack("\tswitch(state) {\n");
	foreach(it; min.states) {
		ret.pushBack("\t\tcase ");	
		ret.pushBack(conv!(int,string)(it.getStateId()));
		ret.pushBack(":\n");
		if(it.isAccepting()) {
			ret.pushBack("\t\t\treturn ");
			//ret.pushBack(conv!(int,string)(it.getFirstAcceptingState()));
			ret.pushBack(conv!(int,string)(it.getHighestAcceptingState()));
		} else {
			ret.pushBack("\t\t\treturn -1");
		}
		ret.pushBack(";\n");
	}

	// default case
	ret.pushBack("\t\tdefault:\n");
	ret.pushBack("\t\t\tassert(false,"),
	ret.pushBack(" format(\"an invalid state with id %d was passed\",\n");
	ret.pushBack("\t\t\t\tstate));\n");
	ret.pushBack("\t}\n");
	ret.pushBack("}\n");

	return ret.getString();
}

/** This functions returns a string which is a D function which defines the
 *  default run function.
 *
 *  Of form:
 *
 *	public void run() {
 *		dchar currentInputChar;
 *		byte currentState = 0;
 *
 *		byte nextState = -1;
 *		bool needToGetNextState = true;
 *		bool needToGetNextChar = true;
 *
 *		while(!this.isEmpty()) {
 *			if(needToGetNextChar) {
 *				currentInputChar = this.getNextChar();
 *			} else {
 *				needToGetNextChar = true;
 *			}
 *
 *			if(needToGetNextState) {
 *				nextState = this.getNextState(currentInputChar, currentState);
 *			} else {
 *				needToGetNextState = true;
 *			}
 *
 *			if(nextState != -1) {
 *				this.lexText.pushBack(currentInputChar);
 *			}
 *			if(nextState != -1) {
 *				currentState = nextState;
 *				continue;
 *			} else {
 *				needToGetNextChar = false;
 *				int isAccepting = this.isAcceptingState(currentState);
 *				if(isAccepting == -1) {
 *					USER DEFINED INPUT ERROR CODE
 *				} else {
 *					switch(isAccepting) {
 *						case 27: {
 *							USER DEFINED ACTION ON ACCEPTING STATE 27
 *						}
 *					}
 *				}
 *			}
 *			...
 *
 *
 *  @param min, The minimized Table comming from the minizer.
 *  @param stateType If the number of states is below ubyte.max the stateType
 *  	will be ubyte. You should see the pattern.
 *  @param input This Input type class is used to get information about the
 *  	end of line/file character as well as the regex production.
 *
 *  @return The created run function.
 */
string createDefaultRunFunction(MinTable min, string stateType, 
		Input input) {
	StringBuffer!(char) ret = new StringBuffer!(char)(256*4);
	
	// header
	ret.pushBack("\tpublic void run() {\n");

	// local declartion
	ret.pushBack("\t\tdchar currentInputChar;\n");
	ret.pushBack("\t\t");
	ret.pushBack(stateType);
	ret.pushBack(" currentState = 0;\n\n");
	ret.pushBack("\t\t");
	ret.pushBack(stateType);
	ret.pushBack(" nextState = -1;\n");
	ret.pushBack("\t\tbool needToGetNextState = true;\n");
	ret.pushBack("\t\tbool needToGetNextChar = true;\n\n");

	// main loop
	ret.pushBack("\t\twhile(!this.isEmpty()) {\n");
	ret.pushBack("\t\t\tif(needToGetNextChar) {\n");
	ret.pushBack("\t\t\t\tcurrentInputChar = this.getNextChar();\n");
	ret.pushBack("\t\t\t} else {\n");
	ret.pushBack("\t\t\t\tneedToGetNextChar = true;\n");
	ret.pushBack("\t\t\t}\n\n");
	ret.pushBack("\t\t\tif(needToGetNextState) {\n");
	ret.pushBack("\t\t\t\tnextState = this.getNextState(currentInputChar, ");
	ret.pushBack("currentState);\n");
	ret.pushBack("\t\t\t} else {\n");
	ret.pushBack("\t\t\t\tneedToGetNextState = true;\n");
	ret.pushBack("\t\t\t}\n\n");
	ret.pushBack("\t\t\tif(nextState != -1) {\n");
	ret.pushBack("\t\t\t\tthis.lexText.pushBack(currentInputChar);\n");
	ret.pushBack("\t\t\t}\n");
	ret.pushBack("\t\t\tif(nextState != -1) {\n");
	ret.pushBack("\t\t\t\tcurrentState = nextState;\n");
	ret.pushBack("\t\t\t\tcontinue;\n");
	ret.pushBack("\t\t\t} else {\n");
	ret.pushBack("\t\t\t\tneedToGetNextChar = false;\n");
	ret.pushBack("\t\t\t\tint isAccepting = ");
	ret.pushBack("this.isAcceptingState(currentState);\n");
	ret.pushBack("\t\t\t\tif(isAccepting == -1) {\n");

	string inputErrorFunction = input.getInputErrorCode();
	if(inputErrorFunction !is null && inputErrorFunction.length > 0) {
		ret.pushBack(inputErrorFunction);
		ret.pushBack("\n");
	} else {
		ret.pushBack("\t\t\t\t\tprintfln(\"lex error at character %d of line");
		ret.pushBack(" %d in file %s\",\n \t\t\t\t\t\t");
		ret.pushBack("this.getCurrentIndexInLine(),\n\t\t\t\t\t\t");
		ret.pushBack("this.getCurrentLineCount(),\n\t\t\t\t\t\t");
		ret.pushBack("this.getFilename());\n");
		ret.pushBack("\t\t\t\t\tassert(false, \"Lex error\");\n");
	}

	ret.pushBack("\t\t\t\t} else {\n");

	// accepting switch case
	ret.pushBack("\t\t\t\t\tswitch(isAccepting) {\n");

	sortVector!(RegexCode)(input.getRegExCode(),
		function(in RegexCode a, in RegexCode b) { 
			return a.getPriority() < b.getPriority(); 
		});

	foreach(RegexCode it; input.getRegExCode()) {
		ret.pushBack("\t\t\t\t\t\tcase ");
		ret.pushBack(conv!(size_t,string)(it.getPriority()));
		ret.pushBack(": {\n");
		ret.pushBack(it.getCode());
		ret.pushBack("\n\t\t\t\t\t\t}\n\t\t\t\t\t\tbreak;\n");
	}

	ret.pushBack("\t\t\t\t\t}\n");
	ret.pushBack("\t\t\t\t\tthis.lexText.clear();\n");
	ret.pushBack("\t\t\t\t\tcurrentState = 0;\n");
	ret.pushBack("\t\t\t\t}\n");
	ret.pushBack("\t\t\t}\n");

	ret.pushBack("\t\t}\n");

	// processing the the rest of the input
	ret.pushBack("\t\tint isAccepting = ");
	ret.pushBack("this.isAcceptingState(currentState);\n");
	ret.pushBack("\t\tif(isAccepting == -1) {\n");

	if(inputErrorFunction !is null && inputErrorFunction.length > 0) {
		ret.pushBack(inputErrorFunction);
		ret.pushBack("\n");
	} else {
		ret.pushBack("\t\t\tprintfln(\"lex error at character %d of line");
		ret.pushBack(" %d in file %s\",\n \t\t\t\t");
		ret.pushBack("this.getCurrentIndexInLine(),\n\t\t\t\t");
		ret.pushBack("this.getCurrentLineCount(),\n\t\t\t\t");
		ret.pushBack("this.getFilename());\n");
		ret.pushBack("\t\t\tassert(false, \"Lex error\");\n");
	}

	ret.pushBack("\t\t} else {\n");
	ret.pushBack("\t\t\tswitch(isAccepting) {\n");

	foreach(RegexCode it; input.getRegExCode()) {
		ret.pushBack("\t\t\t\tcase ");
		ret.pushBack(conv!(size_t,string)(it.getPriority()));
		ret.pushBack(": {\n");
		ret.pushBack(it.getCode());
		ret.pushBack("\n\t\t\t\t}\n\t\t\t\tbreak;\n");
	}
	ret.pushBack("\t\t\t}\n");

	ret.pushBack("\t\t}\n");
	ret.pushBack("\t}\n\n");

	return ret.getString();
}

/** This functions returns a string which is a D function which defines the
 *  getNextState function. This function returns the next state depending on
 *  the current state the input character as well as the state transition 
 *  table.
 *
 *  Of form:
 *
 *	private returnTable getNextState(dchar inputChar, 
 *			returnType currentState) {
 *		MapItem!(dchar,size_t) cm = this.charMapping.find(inputChar);
 *		assert(cm !is null);
 *		size_t column = *cm;
 *		size_t row = this.stateMapping[currentState];
 *		return this.table[row][column];
 *	}
 *
 *
 *  @param returnType If the number of states is below ubyte.max the returnType
 *  	will be ubyte. You should see the pattern.
 *
 *  @return The created getNextState function.
 */
string createGetNextState() {
	StringBuffer!(char) ret = new StringBuffer!(char)(256);

	ret.pushBack("\tprivate stateType");
	ret.pushBack(" getNextState(dchar inputChar, ");
	ret.pushBack(" currentState) {\n");
	ret.pushBack("\t\tMapItem!(dchar,size_t) cm = ");
	ret.pushBack("this.charMapping.find(inputChar);\n");
	ret.pushBack("\t\tassert(cm !is null);\n");
	ret.pushBack("\t\tsize_t column = *cm;\n");
	ret.pushBack("\t\tsize_t row = this.stateMapping[currentState];\n");
	ret.pushBack("\t\treturn this.table[row][column];\n");
	ret.pushBack("\t}\n\n");
	return ret.getString();
}

/** Deprecated, succeded by inputrange
 */
string createCharMapping(MinTable min) {
	StringBuffer!(char) ret = 
		new StringBuffer!(char)(min.inputChar.getSize() * 6);

	ret.pushBack("\tprivate void initCharMapping() {\n");
	ret.pushBack("\t\tthis.charMapping = new Map!(dchar,size_t)();\n\n");
	ret.pushBack("\t\tchar inCh[");
	ret.pushBack(conv!(size_t,string)(min.inputChar.getSize()));
	ret.pushBack("] = [");
	ISRIterator!(MapItem!(dchar,Column)) it = min.inputChar.begin();
	int count = 0;
	for(; it.isValid(); it++) {
		//ret.pushBack(format!(char,char)("'%c',", (*it).getKey()));
		ret.pushBack("'");
		if((*it).getKey() == '\n') {
			ret.pushBack("\\n");
		} else if((*it).getKey() == '\t') {
			ret.pushBack("\\t");
		} else if((*it).getKey() == '\\') {
			ret.pushBack("\\\\");
		} else {
			ret.pushBack(conv!(dchar,string)((*it).getKey()));
		}
		ret.pushBack("',");
		if(count != 0 && count % 10 == 0) {
			ret.pushBack("\n");
			ret.pushBack("\t\t");
		}
		count++;
	}
	ret.popBack();
	ret.pushBack("];\n\n");
	ret.pushBack("\t\tint inInt[");
	ret.pushBack(conv!(size_t,string)(min.inputChar.getSize()));
	ret.pushBack("] = [");
	it = min.inputChar.begin();
	count = 0;
	for(; it.isValid(); it++) {
		ret.pushBack(format!(char,char)("%3d,", (*it).getData().idx));
		if(count != 0 && count % 10 == 0) {
			ret.pushBack("\n");
			ret.pushBack("\t\t");
		}
		count++;
	}
	ret.popBack();
	ret.pushBack("];\n\n");
	ret.pushBack("\t\tfor(int i = 0; i < inCh.length; i++) {\n");
	ret.pushBack("\t\t\tthis.charMapping.insert(inCh[i],");
	ret.pushBack("conv!(int,size_t)(inInt[i]));\n");
	ret.pushBack("\t\t}\n");
	ret.pushBack("\t}\n\n");

	return ret.getString();
}

/** This funciton created the state mapping table. 
 *  The type of the array depends on how many states there are.
 *
 *  @param min The minimized state table mapping comming from the minimizer.
 *
 *  @return A string containing the array of state mappings.
 */
string createStateMapping(MinTable min) {
	StringBuffer!(char) ret = new StringBuffer!(char)(1024);

	// get the highest state id
	int max = 0;
	foreach(it; min.state) {
		if(it > max) {
			max = it;
		}
	}

	// define the array
	if(max < 127) {
		ret.pushBack("immutable byte[] stateMapping = [\n");
	} else if(max < 32768) {
		ret.pushBack("immutable short[] stateMapping = [\n");
	} else {
		ret.pushBack("immutable int[] stateMapping = [\n");
	}

	// find out how many spaces are need to pretty print
	int indent = 1;
	while(max > 0) {
		indent++;
		max /= 10;
	}
	string form = "%" ~ conv!(int,string)(indent) ~ "d,";
	
	// print the table
	int count = 0;
	foreach(int it; min.state) {
		ret.pushBack(format!(char,char)(form,it));
		if(count != 0 && count % 20 == 0) {
			ret.pushBack("\n");
			ret.pushBack("\t");
		}
		count++;
	}
	ret.popBack();
	ret.pushBack("];\n\n");
	
	return ret.getString();
}

/** This funciton creates the state transition table. 
 *  The type of the array depends on how many states there are.
 *
 *  @param min The minimized state table transition comming from the minimizer.
 *
 *  @return A string containing the array of state transitions.
 */
string createTable(MinTable min, ref string stateType) {
	StringBuffer!(char) ret = new StringBuffer!(char)(min.table.getSize() * 
		min.table[0].getSize() * 4);

	ret.pushBack("public static");

	int max = 0;
	foreach(it; min.table) {
		foreach(jt; it) {
			if(jt > max) {
				max = jt;
			}
		}
	}
	if(max < 127) {
		ret.pushBack(" immutable(byte[][]) table = [\n");
		stateType = "byte";
	} else if(max < 16384) {
		ret.pushBack(" immutable(short[][]) table = [\n");
		stateType = "short";
	} else {
		ret.pushBack(" immutable(int[][]) table = [\n");
		stateType = "int";
	}

	int indent = 1;
	while(max > 0) {
		indent++;
		max /= 10;
	}
	string form = "%" ~ conv!(int,string)(indent) ~ "d,";

	foreach(Vector!(int) it; min.table) {
		ret.pushBack("[");
		foreach(int jt; it) {
			ret.pushBack(format!(char,char)(form, jt));
		}
		ret.popBack();
		ret.pushBack("],\n");
	}
	ret.popBack();
	ret.popBack();
	ret.pushBack("];\n\n");

	return ret.getString();
}

/** Pretty print the user code.
 *
 * @param userCode The userCode
 *
 * @return The pretty printed userCode
 */
string formatUserCode(string userCode) {
	StringBuffer!(dchar) ret = new StringBuffer!(dchar)(userCode.length*2);
	foreach(dchar c; conv!(string,dstring)(userCode)) {
		if(c == '\n') {
			ret.pushBack('\n');
			ret.pushBack('\t');
		} else {
			ret.pushBack(c);
		}
	}
	ret.pushBack("\n\n");
	return conv!(dstring,string)(ret.getString());
}

/** As written in the function createCharRange, we have created the Map 
 *  int,Set!(dchar). To be sure the mapping is correct, this functions
 *  compares the originating map with the created mapping.
 *
 *  @param nm The newly created map.
 *  @param om The old allready created map.
 *
 *  @return true if the test was passed false otherwise.
 */
bool testIfMappingIsComplete(Map!(int,Set!(dchar)) nm, Map!(dchar,Column) om) {
	ISRIterator!(MapItem!(int,Set!(dchar))) nmIt = nm.begin();
	for(; nmIt.isValid(); nmIt++) {
		ISRIterator!(dchar) jt = (*nmIt).getData().begin();
		for(; jt.isValid(); jt++) {
			if(om.find(*jt).getData().idx != (*nmIt).getKey()) {
				printfln("%d != %d, %c == %c", om.find(*jt).getData().idx,
					(*nmIt).getKey(), *jt, om.find(*jt).getKey());
				return false;
			}
		}
	}

	ISRIterator!(MapItem!(dchar,Column)) omIt = om.begin();
	outer: for(; omIt.isValid(); omIt++) {
		MapItem!(int,Set!(dchar)) m = nm.find((*omIt).getData().idx);	
		if(m is null) {
			printfln("no entry for idx %d", (*omIt).getData().idx);
			return false;
		}

		ISRIterator!(dchar) msIt = m.getData().begin();
		for(; msIt.isValid(); msIt++) {
			if(*msIt == (*omIt).getKey())
				continue outer;
		}
		printfln("char %c not mapped to idx %d", (*omIt).getKey(), 
			(*omIt).getData().idx);
		return false;
	}
	
	return true;
}

/** This function returns a string containing the sorted Range array for the
 *  character mapping. This function procedded createCharMapping.
 *
 *  Of form:
 *
 *	static immutable Range!(dchar,size_t)[59] inputRange = [
 *		Range!(dchar,size_t)('\t',0),Range!(dchar,size_t)('\n',1),
 *		Range!(dchar,size_t)(' ',2), ... ];
 *
 *  @param min The minimized table.
 *
 *  @return The array of sorted Range structs.
 */
string createCharRange(MinTable min) {
	// first you got to bring Map!(dchar,Column) to Map!(int,Set!(dchar)) 
	// where the key is the idx variable of the column. I'm not using
	// a multimap because this way the Set of dchars is in order which makes
	// it's easier to create the ranges afterwards
	Map!(int,Set!(dchar)) sameIdx = new Map!(int,Set!(dchar))();
	ISRIterator!(MapItem!(dchar,Column)) it = min.inputChar.begin();
	MapItem!(int,Set!(dchar)) tmp;
	for(; it.isValid(); it++) {
		tmp = sameIdx.find((*it).getData().idx);
		if(tmp !is null) {
			assert((*it).getKey() != dchar.init);
			tmp.getData().insert((*it).getKey());
			tmp = null;
		} else {
			Set!(dchar) tS = new Set!(dchar)();
			assert((*it).getKey() != dchar.init);
			tS.insert((*it).getKey());
			sameIdx.insert((*it).getData().idx, tS);
		}
	}

	assert(testIfMappingIsComplete(sameIdx, min.inputChar));

	// fill the range array
	Vector!(hurt.algo.binaryrangesearch.Range!(dchar,int)) vec = 
		new Vector!(hurt.algo.binaryrangesearch.Range!(dchar,int))(32);
	ISRIterator!(MapItem!(int,Set!(dchar))) jt = sameIdx.begin();
	size_t sameIdxCnt = 0;
	for(; jt.isValid(); jt++) {
		Set!(dchar) sTmp = (*jt).getData();
		sameIdxCnt += sTmp.getSize();
		hurt.algo.binaryrangesearch.Range!(dchar,int) rTmp = 
			hurt.algo.binaryrangesearch.Range!(dchar,int)((*jt).getKey());
		assert(rTmp.value == (*jt).getKey());
		assert(!rTmp.isFirstSet());
		assert(!rTmp.isLastSet());
		
		ISRIterator!(dchar) mt = sTmp.begin();	
		for(; mt.isValid(); mt++) {
			if(rTmp.canExpend(*mt)) {
				rTmp.expend(*mt);
				assert(rTmp.first == *mt || rTmp.last == *mt);
			} else {
				assert(rTmp.first != dchar.init);
				//printfln("%c %c %d", rTmp.first, rTmp.last, rTmp.value);
				vec.pushBack(rTmp);
				rTmp = hurt.algo.binaryrangesearch.
					Range!(dchar,int)(*mt, (*jt).getKey());
				assert(rTmp.first == *mt);
			}
		}
		if(rTmp.isFirstSet()) {
			assert(rTmp.isFirstSet());
			//printfln("%c %c %d", rTmp.first, rTmp.last, rTmp.value);
			vec.pushBack(rTmp);
		}
	}
	assert(sameIdxCnt == min.inputChar.getSize(), 
		conv!(size_t,string)(sameIdxCnt) ~ " " ~ 
		conv!(size_t,string)(min.inputChar.getSize()));

	hurt.algo.binaryrangesearch.Range!(dchar,int)[] tmpArray1 = vec.elements();

	it = min.inputChar.begin();
	for(; it.isValid(); it++) {
		try {
			assert( (*it).getData().idx == 
				linearSearch!(dchar,int)(tmpArray1, (*it).getKey()));
		} catch(Exception e) {
			printfln("couldn't find %c", (*it).getKey());
			assert(false);
		}
	}
	
	sortVector!(hurt.algo.binaryrangesearch.Range!(dchar,int))(vec, 
		function(in hurt.algo.binaryrangesearch.Range!(dchar,int) a, 
				in hurt.algo.binaryrangesearch.Range!(dchar,int) b) {
			return a.first < b.first; 
		});

	// check to see if the mapping has no error
	hurt.algo.binaryrangesearch.Range!(dchar,int)[] tmpArray = vec.elements();

	it = min.inputChar.begin();
	for(; it.isValid(); it++) {
		try {
			assert( (*it).getData().idx == 
				linearSearch!(dchar,int)(tmpArray, (*it).getKey()));
		} catch(Exception e) {
			printfln("couldn't find %c", (*it).getKey());
			assert(false);
		}
	}

	it = min.inputChar.begin();
	for(; it.isValid(); it++) {
		try {
			assert( (*it).getData().idx == 
				binarySearchRange!(dchar,int)(tmpArray, (*it).getKey(), 
					dchar.init));
		} catch(Exception e) {
			printfln("couldn't find %c", (*it).getKey());
			assert(false);
		}
	}

	StringBuffer!(dchar) ret = 
		new StringBuffer!(dchar)(min.inputChar.getSize()*8);

	ret.pushBack("public static immutable(Range!(dchar,size_t)[");
	ret.pushBack(conv!(size_t,dstring)(vec.getSize()));
	ret.pushBack("]) inputRange = [");
	int cnt = 0;
	foreach(kt; vec) {
		if(cnt % 2 == 0) {
			ret.pushBack("\n\t");
		}
		if(!kt.isLastSet()) {
			ret.pushBack("Range!(dchar,size_t)('");
			ret.pushBack(replaceWhiteSpace(kt.first));
			ret.pushBack("',");
			ret.pushBack(conv!(int,dstring)(kt.value));
			ret.pushBack("),");
		} else {
			ret.pushBack("Range!(dchar,size_t)('");
			ret.pushBack(replaceWhiteSpace(kt.first));
			ret.pushBack("','");
			ret.pushBack(replaceWhiteSpace(kt.last));
			ret.pushBack("',");
			ret.pushBack(conv!(int,dstring)(kt.value));
			ret.pushBack("),");
		}
		cnt++;
	}
	ret.popBack();
	ret.pushBack("];\n\n");

	return conv!(dstring,string)(ret.getString());
}

/** Process whitespaces to make graphviz not to fuck up.
 */
pure dstring replaceWhiteSpace(in dchar c) {
	if(c == '\n')
		return "\\n";
	else if(c == '\t')
		return "\\t";
	else if(c == '\\')
		return "\\\\";
	else if(c == '\'')
		return "\\'";
	else 
		return conv!(dchar,dstring)(c);
}

private string escapeTick(string str) {
	StringBuffer!(char) ret = new StringBuffer!(char)();
	foreach(char it; str) {
		if(it == '"') {
			ret.pushBack("\\\"");
		} else {
			ret.pushBack(it);
		}
	}
	return ret.getString();
}

private string getTokenAcceptFunction(Input input) {
	StringBuffer!(char) ret = new StringBuffer!(char)(1024);
	ret.pushBack("public static immutable(string) acceptAction = \n`");

	foreach(RegexCode it; input.getRegExCode()) {
		ret.pushBack("\tcase ");
		ret.pushBack(conv!(size_t,string)(it.getPriority()));
		ret.pushBack(": {\n");
		ret.pushBack(it.getCode());
		ret.pushBack("\n\t\t}\n\t\tbreak;\n");
	}
	ret.pushBack("`;");

	return ret.getString();
}

private string csrToString(MinTable min, string stateType) {
	auto ret = new StringBuffer!(char)(2048);
	auto csr = CRS!(int)(min.table, -1);
	log("csr reduction ratio %f", csr.getRatio());

	ret.pushBack("auto csr = new CSR!(%s)(\n", stateType);
	ret.pushBack("[");
	foreach(it; csr.getColumn()) {
		ret.pushBack("%d, ", it);
	}
	ret.popBack();
	ret.popBack();
	ret.pushBack("],\n[");
	foreach(it; csr.getRows()) {
		ret.pushBack("%d, ", it);
	}
	ret.popBack();
	ret.popBack();
	ret.pushBack("],\n[");
	foreach(it; csr.getValues()) {
		ret.pushBack("%d, ", it);
	}
	ret.popBack();
	ret.popBack();
	ret.pushBack("],\n");
	ret.popBack();
	ret.popBack();
	ret.pushBack(");\n");

	return ret.getString();
}

/** Calling this function will write a lexer to the given filename.
 *
 *  @param min The minimized Table, this table comes from the minizer.
 *  @param input The user created Input.
 *  @param classname The name of the resulting class containing the lexer
 *  @param filename The filename of the file the lexer will be written to.
 *  	If the file exists it will be overwritten.
 */
void emitLexer(MinTable min, Input input, string classname, string filename) {
	hurt.io.stream.File file = new hurt.io.stream.File(filename, 
		FileMode.OutNew);

	file.writeString(base);
	file.writeString("class " ~ classname ~ classHeader);
	file.writeString(classBody);
	file.writeString("}");
	file.close();
}

void emitNonStatic(MinTable min, Input input, string modulename, 
		string filename, bool locationStruct) {
	string stateType;
	string table = createTable(min, stateType);
	string isAcceptinStateFunction = 
		createIsAcceptingStateFunction(min);
	string charRange = createCharRange(min);
	string tokenAccept = getTokenAcceptFunction(input);
	string stateMapping = createStateMapping(min);
	//string csrTable = csrToString(min, stateType);
	//log("csrTable %s", csrTable);

	hurt.io.stream.File file = new hurt.io.stream.File(filename, 
		FileMode.OutNew);

	string[] imports = ["hurt.string.formatter","hurt.algo.binaryrangesearch"];

	sort!(string)(imports, function(in string a, in string b) {
		return a < b;});

	file.writeString(format("module %s;\n\n", modulename));
	foreach(string it; imports) {
		file.writeString(format("import %s;\n", it));
	}

	file.write('\n');
	if(locationStruct) {
		file.writeString(locStruct);
	} else {
		file.writeString("import location;");
	}
	file.write('\n');
	file.write('\n');
	file.writeString("alias ");
	file.writeString(stateType);
	file.writeString(" stateType;\n\n");
	file.writeString(stateMapping);
	file.writeString(table);
	file.writeString(isAcceptinStateFunction);
	file.write('\n');
	file.writeString(charRange);
	file.writeString(tokenAccept);
	file.close();	
}

// Static parts of the lexer
private string base = `
import hurt.algo.binaryrangesearch;
import hurt.container.map;
import hurt.container.stack;
import hurt.conv.conv;
import hurt.io.file;
import hurt.io.stdio;
import hurt.io.stream;
import hurt.string.formatter;
import hurt.string.stringbuffer;
import hurt.string.utf;
import hurt.util.slog;
import hurt.util.pair;

`;

private string classHeader = ` {
	private string filename;
	private hurt.io.stream.BufferedFile file;

	private size_t lineNumber;
	private size_t charIdx;
	private dchar[] currentLine;
	private StringBuffer!(dchar) lexText;
	private Stack!(dchar) inputChar;
	private immutable dchar eol = '\n';
	private immutable dchar eof = '\0';

	private Location loc;

	// false means single run, true means step be step
	private bool kind;
`;

private string classBody = `
	this(string filename, bool kind = false) {
		this.filename = filename;
		this.lineNumber = 0;
		this.inputChar = new Stack!(dchar)();

		if(!exists(this.filename)) {
			throw new Exception(__FILE__ ~ ":" ~ conv!(int,string)(__LINE__) ~
				this.filename ~ " does not exists");
		}

		this.file = null;
		this.file = new hurt.io.stream.BufferedFile(this.filename);
		this.lexText = new StringBuffer!(dchar)(128);
		this.getNextLine();

		this.kind = false;
	}

	~this() {
	}

	public void printFile() {
		foreach(char[] it; this.file) {
			foreach(char jt; it)
				print(jt);
			println();
		}
	}

	private dstring getCurrentLex() const {
		return this.lexText.getString();
	}

	private size_t getCurrentLineCount() const {
		return this.lineNumber;
	}

	private size_t getCurrentIndexInLine() const {
		return this.charIdx;
	}

	public string getFilename() const {
		return this.filename;
	}

	private bool isEOF() {
		return this.file.eof();	
	}

	private stateType getNextState(dchar inputChar, stateType currentState) 
			const {
		size_t column = binarySearchRange!(dchar,size_t)(inputRange, inputChar,
			-2);
		size_t row = stateMapping[conv!(stateType,size_t)(currentState)];
		if(column == -2) {
			return -1;
		}
		return table[row][column];
	}

	public bool isEmpty() {
		return this.isEOF() && (this.currentLine is null || 
			this.charIdx > this.currentLine.length);
	}

	private void getNextLine() {
		char[] tmp = this.file.readLine();
		if(tmp !is null) {
			this.currentLine = toUTF32Array(tmp);
			this.charIdx = 0;
		} else {
			this.currentLine = null;
		}
		this.lineNumber++;
	}

	private dchar getCurrentChar() {
		if(this.isEmpty()) {
			return eof;
		} else if(this.charIdx >= this.currentLine.length) {
			this.getNextLine();
			return eol;
		} else {
			return this.currentLine[this.charIdx];
		}
	}

	private dchar getNextChar() {
		if(!this.inputChar.isEmpty()) {
			return this.inputChar.pop();
		} else if(this.isEmpty()) {
			return eof;
		} else if(this.charIdx >= this.currentLine.length) {
			this.getNextLine();
			return eol;
		} else {
			assert(this.charIdx < this.currentLine.length, 
				conv!(size_t,string)(this.charIdx) ~ " " ~
				conv!(size_t,string)(this.currentLine.length));

			return this.currentLine[this.charIdx++];
		}
	}

	public void acceptingAction(stateType acceptingState) {
		switch(acceptingState) {
				mixin(acceptAction);
			default:
				assert(false, format("no action for %d defined",
					acceptingState));
		}
	}

	public Location getLoc() {
		return this.loc;
	}

	public void saveLocation() {
		this.loc = Location(this.filename, this.getCurrentLineCount(),
			this.getCurrentIndexInLine());
	}

	private bool errorFunction(stateType currentState, stateType nextState, 
			dchar input) {
		return false;
	}

	public void run() {
		stateType currentState = 0;
		stateType nextState = -1;
		this.saveLocation();
		while(!this.isEmpty()) {
			dchar nextChar = this.getNextChar();
			nextState = this.getNextState(nextChar, currentState);
			if(nextState != -1) { // simplie a next state
				currentState = nextState;
				lexText.pushBack(nextChar);
			// accepting state
			} else if(nextState == -1) { 
				stateType accept = isAcceptingState(currentState);
				if(accept != -1) {
					//log("%2d accept number %d", currentState, accept);
					inputChar.push(nextChar);
					this.acceptingAction(accept);
					this.lexText.clear();
					currentState = 0;
					this.saveLocation();
				} else {
					if(this.errorFunction(currentState, nextState, nextChar)) {
						currentState = 0;
						this.saveLocation();
						this.lexText.clear();
					} else {
						assert(false, 
							format("we failed with state %d and nextstate %d, 
							" ~ "inputchar was %c", currentState, 
							nextState, nextChar));
					}
				}
				if(this.kind) { // single step
					return;
				}
			}
		}

		// we are done but there their might be a state left
		if(currentState == 0) {
			//ok I guess
			return;
		} else if(isAcceptingState(currentState)) {
			this.acceptingAction(isAcceptingState(currentState));
			this.lexText.clear();
			return;
		} else {
			//hm not so cool
			assert(false, format("no more input when in state %d", 
				currentState));
		}
		this.file.close();
	}
`;

immutable(string) locStruct = 
`public struct Location {
	private string file;
	private size_t row;
	private size_t column;

	public this(string file, size_t row, size_t column) {
		this.file = file;
		this.row = row;
		this.column = column;
	}
	
	public string getFile() const {
		return this.file;
	}

	public size_t getRow() const {
		return this.row;
	}

	public size_t getColumn() const {
		return this.column;
	}

	public bool isDummyLoc() const {
		return (this.file is null || this.file == "") &&
			this.row == 0 || this.column == 0;
	}

	public string toString() const {
		return format("%s:%u:%u", this.file, this.row, this.column);
	}
}`;

string runFunction = `
	/*public void run() { // a stupid run methode could look like this »«¢¢ſð@
		println(__LINE__, this.isEOF(), this.isEmpty());
		while(!isEmpty()) {
			if(this.getCurrentIndexInLine() == 0) {
				print(this.getCurrentLineCount());
			}
			print(getNextChar());
		}
	}*/

`;
