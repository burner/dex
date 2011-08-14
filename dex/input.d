module dex.input;

import hurt.container.vector;
import hurt.io.stream;
import hurt.io.file;
import hurt.io.stdio;
import hurt.util.array;
import hurt.string.stringbuffer;

import dex.strutil;

class RegexCode {
	private string regex;
	private string code;

	this(string regex) {
		this.regex = regex;
	}
}

enum ParseState {
	None,
	UserCode,
	RegexCode
}

class Input {
	private string filename;
	private string userCode;
	private File ins;
	private Vector!(RegexCode) regexCode;

	private static bool isWellFormedFilename(in string filename) {
		if(filename.length <= 4)
			return false;

		if(filename[$-4..$] != ".dex")
			return false;

		return true;
	}

	this(string filename) {
		this.filename = filename;
		this.regexCode = new Vector!(RegexCode)(16);
		if(!isWellFormedFilename(filename))
			throw new Exception("Filename not well formed");
	
		if(!exists(this.filename))
			throw new Exception("File does not Exist");

		this.ins = new File(filename);
		this.parseFile();
	}

	~this() {
		if(this.ins.isOpen())
			this.ins.close();
		else
			println("file should have been opened");

		assert(!this.ins.isOpen(), "file should not be open");
	}

	private void parseFile() {
		ParseState ps = ParseState.None;
		StringBuffer!(char) tmp = new StringBuffer!(char)(32);
		int braceStack = 0;
		foreach(size_t idx, char[] it; this.ins) {
			final switch(ps) {
			case ParseState.None: {
				// check if line contains the start of a user code segment
				int ucLow = userCodeParanthesis(it);
				if(ucLow != -1) {
					// the usercode is only one line long
					int ucUp = userCodeParanthesis(it, ucLow+2);
					//println(__FILE__,__LINE__,ucLow, ucUp, it.length);
					if(ucUp != -1) {
						char[] uc = it[ucLow+2..ucUp];
						assert(-1 == userCodeParanthesis(uc));
						this.userCode ~= "\n" ~ uc;
					} else {
						ps = ParseState.UserCode;
						tmp.pushBack(it[ucLow+2..$]);
						tmp.pushBack("\n");
					}
				}
				int rcLow = findTick(it);
				if(rcLow != -1) {
					int rcUp = findTick(it);
					if(rcUp == -1) {
						throw new Exception("line " ~ conv!(size_t,string)(idx)
							~ " missing tick after regex expression");
					} else {
						this.regexCode(new RegexCode(it[rcLow+1..rcUp]));
						int nxtLft = userCodeBrace('{')(it,rcUp+1);
						int frstLft = nxtLft;
						if(nxtLft == -1) {
							throw new Exception("line " ~ 
								conv!(size_t,string)(idx) ~ " missing tick 
								after regex expression");
						} else {
							braceStack++;
							while(-1 != (nxtLft = 
									userCodeBrace('{')(it,nxtLft+1)) ) {
								braceStack++;
							}
							int nxtRght = userCodeBrace('}')(it,rcUp+1);
							bool done = false;
							while(-1 != (nxtRght = 
									userCodeBrace('}')(it,nxtLft+1)) ) {
								braceStack--;
								if(braceStack == 0) {
									
								}
							}
						}
					}
				}
				break;
			}
			case ParseState.UserCode: {
				int ucLow = userCodeParanthesis(it);
				if(-1 == ucLow) {
					tmp.pushBack(it); 
					tmp.pushBack("\n");
				} else {
					tmp.pushBack(it[0..ucLow]);
					this.userCode ~= tmp.getString();
					tmp.clear();
					ps = ParseState.None;
				}
				break;
			}
			case ParseState.RegexCode: {
				break;
			}
			}
		}
		println(this.userCode);
	}
}
