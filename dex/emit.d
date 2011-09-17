module dex.emit;

import dex.state;
import dex.strutil;
import dex.minimizer;
import dex.input;

import hurt.algo.sorting;
import hurt.container.isr;
import hurt.container.iterator;
import hurt.container.map;
import hurt.container.set;
import hurt.container.vector;
import hurt.container.multimap;
import hurt.conv.conv;
import hurt.io.stdio;
import hurt.io.stream;
import hurt.string.formatter;
import hurt.string.stringbuffer;
import hurt.string.utf;
import hurt.util.array;
import std.process;

void writeTable(MinTable min, Iterable!(State) states, Set!(dchar) inputSet,
		string filename) {

	hurt.io.stream.File file = new hurt.io.stream.File(filename ~ ".tab", 
		FileMode.OutNew);

	sortVector!(State)(cast(Vector!(State))states, 
		function(in State a, in State b) { 
		return a.getStateId() < b.getStateId(); });

	int howManyBlanks = 0;
	size_t size = states.getSize();
	while(size > 0) {
		howManyBlanks++;
		size /= 10;
	}
	assert(howManyBlanks >= 1);

	StringBuffer!(dchar) sb = new StringBuffer!(dchar)();
	
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

/* A function that writes a given graph to a file of name fileName.
 * Iterable is a container that implements opApply. The transitions of
 * the states inside the container should correspond to the character inside
 * the inputSet. Otherwise the transistion will not be displayed.
 */
void writeGraph(Iterable!(State) states, Set!(dchar) inputSet,
		string fileName) {
	string[] strTable = ["digraph{\n"];
	StringBuffer!(char) strLine = new StringBuffer!(char)(16);
	foreach(it;states) {
		if(it.acceptingState) {
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

		state = pState.getTransition(0);
		foreach(jt;state) {
			string stateId1 = (pState.toString());
			string stateId2 = (jt.toString());
			strLine.pushBack("\t" ~ stateId1 ~ " -> " ~ stateId2);
			strLine.pushBack("\t[label=\"epsilon\"];\n");
			append(strTable, strLine.getString());
			strLine.clear();
		}

		version(none) {
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

		MultiMap!(State,dchar) mm = new MultiMap!(State,dchar)();
		hurt.container.multimap.Iterator!(dchar,State) it;
		MultiMap!(dchar,State) pSmm = pState.getTransitions();
		if(pSmm is null || pSmm.getSize() == 0)
			continue;

		it = pSmm.begin();

		for(; it.isValid(); it++) {
			mm.insert(*it, it.getKey());
		}
		foreach(jt; mm.keys()) {
			hurt.container.multimap.Iterator!(State,dchar) kt = mm.range(jt);
			tranSb.clear();
			tranSb.pushBack("[");
			int count = 0;
			/*for(; kt.isValid(); kt++) {
				tranSb.pushBack(kt.getData());
				tranSb.pushBack(",");
				if(count != 0 && count % 20 == 0)
					tranSb.pushBack("\r");
				count++;
			}*/
			Vector!(Range) r = makeRanges(kt);
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
			strLine.pushBack(toUTF8(tranSb.getString()));
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

string createIsAcceptingStateFunction(MinTable min, string stateType) {
	StringBuffer!(char) ret = new StringBuffer!(char)(256*4);
	ret.pushBack("\tprivate int");
	ret.pushBack(" isAcceptingState(");
	ret.pushBack(stateType);
	ret.pushBack(" state) {\n");
	ret.pushBack("\t\tswitch(state) {\n");
	foreach(it; min.states) {
		ret.pushBack("\t\t\tcase ");	
		ret.pushBack(conv!(int,string)(it.getStateId()));
		ret.pushBack(":\n");
		if(it.isAccepting()) {
			ret.pushBack("\t\t\t\treturn ");
			ret.pushBack(conv!(int,string)(it.getFirstAcceptingState()));
		} else {
			ret.pushBack("\t\t\t\treturn -1");
		}
		ret.pushBack(";\n");
	}
	ret.pushBack("\t\t\tdefault:\n");
	ret.pushBack("\t\t\t\tassert(false, \"an invalid state was passed \" ~\n");
	ret.pushBack("\t\t\t\t\tconv!(int,string)(state));\n");
	ret.pushBack("\t\t}\n");
	ret.pushBack("\t}\n");

	return ret.getString();
}

string createDefaultRunFunction(MinTable min, string stateType, 
		Input input) {
	StringBuffer!(char) ret = new StringBuffer!(char)(256*4);
	ret.pushBack("\tpublic void run() {\n");
	ret.pushBack("\t\tdchar currentInputChar;\n");
	ret.pushBack("\t\t");
	ret.pushBack(stateType);
	ret.pushBack(" currentState = 0;\n\n");
	ret.pushBack("\t\t");
	ret.pushBack(stateType);
	ret.pushBack(" nextState = -1;\n");
	ret.pushBack("\t\tbool needToGetNextState = true;\n");
	ret.pushBack("\t\tbool needToGetNextChar = true;\n\n");
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
	ret.pushBack("\t\t\t\t\tswitch(isAccepting) {\n");

	sortVector!(RegexCode)(input.getRegExCode(),
		function(in RegexCode a, in RegexCode b) { 
		return a.getPriority() < b.getPriority(); });

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

string createGetNextState(string returnType) {
	StringBuffer!(char) ret = new StringBuffer!(char)(256);

	ret.pushBack("\tprivate ");
	ret.pushBack(returnType);
	ret.pushBack(" getNextState(dchar inputChar, ");
	ret.pushBack(returnType);
	ret.pushBack(" currentState) {\n");
	ret.pushBack("\t\tMapItem!(dchar,size_t) cm = ");
	ret.pushBack("this.charMapping.find(inputChar);\n");
	ret.pushBack("\t\tif(cm is null)\n");
	ret.pushBack("\t\t\treturn -1;\n\n");
	ret.pushBack("\t\tsize_t column = *cm;\n");
	ret.pushBack("\t\tsize_t row = this.stateMapping[currentState];\n");
	ret.pushBack("\t\treturn this.table[row][column];\n");
	//ret.pushBack("\t\t}\n\n");
	ret.pushBack("\t}\n\n");
	return ret.getString();
}

string createCharMapping(MinTable min) {
	StringBuffer!(char) ret = 
		new StringBuffer!(char)(min.inputChar.getSize() * 6);

	ret.pushBack("\tprivate void initCharMapping() {\n");
	ret.pushBack("\t\tthis.charMapping = new Map!(dchar,size_t)();\n\n");
	ret.pushBack("\t\tdchar inCh[");
	ret.pushBack(conv!(size_t,string)(min.inputChar.getSize()));
	ret.pushBack("] = [");
	ISRIterator!(MapItem!(dchar,Column)) it = min.inputChar.begin();
	int count = 0;
	for(; it.isValid(); it++) {
		ret.pushBack(format!(char,char)("'%c',", (*it).getKey()));
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

string createStateMapping(MinTable min) {
	StringBuffer!(char) ret = new StringBuffer!(char)(min.state.length * 6);
	int max = 0;
	foreach(it; min.state) {
		if(it > max) {
			max = it;
		}
	}
	if(max < 127) {
		ret.pushBack("\timmutable byte[] stateMapping = [\n\t");
	} else if(max < 32768) {
		ret.pushBack("\timmutable short[] stateMapping = [\n\t");
	} else {
		ret.pushBack("\timmutable int[] stateMapping = [\n\t");
	}

	int indent = 1;
	while(max > 0) {
		indent++;
		max /= 10;
	}
	string form = "%" ~ conv!(int,string)(indent) ~ "d,";
	
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
	/*if(max < 127) {
		ret.pushBack("\tprivate byte currentState;");
	} else if(max < 32768) {
		ret.pushBack("\tprivate short currentState;");
	} else {
		ret.pushBack("\tprivate int currentState;");
	}
	ret.pushBack("\n\n");*/
	
	return ret.getString();
}

string createTable(MinTable min, ref string stateType) {
	StringBuffer!(char) ret = new StringBuffer!(char)(min.table.getSize() * 
		min.table[0].getSize() * 4);

	ret.pushBack("\tprivate");

	int max = 0;
	foreach(it; min.table) {
		foreach(jt; it) {
			if(jt > max) {
				max = jt;
			}
		}
	}
	if(max < 127) {
		ret.pushBack(" immutable byte[][] table = [\n");
		stateType = "byte";
	} else if(max < 32768) {
		ret.pushBack(" immutable short[][] table = [\n");
		stateType = "short";
	} else {
		ret.pushBack(" immutable int[][] table = [\n");
		stateType = "int";
	}

	int indent = 1;
	while(max > 0) {
		indent++;
		max /= 10;
	}
	string form = "%" ~ conv!(int,string)(indent) ~ "d,";

	foreach(Vector!(int) it; min.table) {
		ret.pushBack("\t[");
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

void emitLexer(MinTable min, Input input, string classname, string filename) {
	hurt.io.stream.File file = new hurt.io.stream.File(filename, 
		FileMode.OutNew);

	file.writeString(base);
	string usercode = input.getUserCode();
	file.writeString("class " ~ classname ~ classHeader);
	string stateType;
	string table = createTable(min, stateType);
	string stateMapping = createStateMapping(min);
	string createInputCharMapping = createCharMapping(min);
	string getNextState = createGetNextState(stateType);
	string defaultRunFunction = createDefaultRunFunction(min, stateType, 
		input);
	string isAcceptinStateFunction = 
		createIsAcceptingStateFunction(min,stateType);
	string userCodeFormatted = formatUserCode(input.getUserCode());
	file.writeString(stateMapping);
	file.writeString(table);
	file.writeString(createInputCharMapping);
	file.writeString(getNextState);
	file.writeString(defaultRunFunction);
	file.writeString(isAcceptinStateFunction);
	file.writeString(classBody);
	file.writeString(userCodeFormatted);
	file.writeString("}");
	file.close();
}

private string base = `
import hurt.conv.conv;
import hurt.container.map;
import hurt.io.file;
import hurt.io.stdio;
import hurt.io.stream;
import hurt.string.utf;
import hurt.string.stringbuffer;

abstract class Lexer {
	public void run();
	public dchar eolChar() const;
	public dchar eofChar() const;
}

`;

private string classHeader = ` : Lexer {
	private string filename;
	private hurt.io.stream.BufferedFile file;

	private size_t lineNumber;
	private size_t charIdx;
	private dchar[] currentLine;
	private StringBuffer!(dchar) lexText;

	private Map!(dchar,size_t) charMapping;
`;

private string classBody = `
	this(string filename) {
		this.filename = filename;
		this.lineNumber = 0;

		if(!exists(this.filename)) {
			throw new Exception(__FILE__ ~ ":" ~ conv!(int,string)(__LINE__) ~
				this.filename ~ " does not exists");
		}

		this.charMapping = new Map!(dchar,size_t)();

		this.file = new hurt.io.stream.BufferedFile(this.filename);
		this.lexText = new StringBuffer!(dchar)(128);
		this.initCharMapping();
		this.getNextLine();
	}

	public void printFile() {
		foreach(char[] it; this.file) {
			foreach(char jt; it)
				print(jt);
			println();
		}
	}

	public dstring getCurrentLex() {
		return this.lexText.getString();
	}

	public size_t getCurrentLineCount() const {
		return this.lineNumber;
	}

	public size_t getCurrentIndexInLine() const {
		return this.charIdx;
	}

	public string getFilename() const {
		return this.filename;
	}

	public bool isEOF() {
		return this.file.eof();	
	}

	public bool isEmpty() {
		return this.isEOF() && (this.currentLine is null || 
			this.charIdx >= this.currentLine.length);
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

	public dchar getNextChar() {
		if(this.isEmpty()) {
			return eofChar();
		} else if(this.charIdx >= this.currentLine.length) {
			this.getNextLine();
			return eolChar();
		} else {
			assert(this.charIdx < this.currentLine.length, 
				conv!(size_t,string)(this.charIdx) ~ " " ~
				conv!(size_t,string)(this.currentLine.length));

			return this.currentLine[this.charIdx++];
		}
	}
`;

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
