module dex.input;

import hurt.container.vector;
import hurt.conv.conv;
import hurt.io.stream;
import hurt.io.file;
import hurt.io.stdio;
import hurt.util.array;
import hurt.string.stringbuffer;

import dex.strutil;

class RegexCode {
	private string regex;
	private string code;

	this(char[] regex) {
		this.regex ~= regex.idup;
	}

	public void setCode(char[] code) {
		this.code ~= code.idup;
	}

	public override string toString() {
		return regex ~ " : " ~ code;
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
		foreach(it;this.regexCode) {
			println(it.toString());
		}
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
					int rcUp = findTick(it, rcLow+1);
					if(rcUp == -1) {
						throw new Exception("line " ~ conv!(size_t,string)(idx)
							~ " missing tick after regex expression");
					} else {
						assert(rcLow+1 < rcUp, conv!(int,string)(rcLow+1) ~
							" " ~ conv!(int,string)(rcUp));
						this.regexCode.append(new RegexCode(it[rcLow+1..rcUp]));
						assert(this.regexCode.getSize() >= 1, 
							conv!(long,string)(this.regexCode.getSize()));
						int nxtLft = userCodeBrace!('{')(it,rcUp+1);
						int frstLft = nxtLft;
						if(nxtLft == -1) {
							throw new Exception("line " ~ 
								conv!(size_t,string)(idx) ~ " missing tick 
								after regex expression");
						} else {
							braceStack++;
							while(-1 != (nxtLft = 
									userCodeBrace!('{')(it,nxtLft+1)) ) {
								braceStack++;
							}
							int nxtRght = userCodeBrace!('}')(it,rcUp+1);
							int lstRght = -1;
							bool done = false;
							while(-1 != nxtRght) {
								braceStack--;
								//println(__FILE__,__LINE__, braceStack);
								if(braceStack <= 0 && !done) {
									lstRght = nxtRght;
									done = true;	
									//println(cast(string)it[frstLft+1..lstRght]);
									this.regexCode.peekBack().setCode(
										it[frstLft+1..lstRght]
										);
									ps = ParseState.None;
								} else if(braceStack <= 0 && done) {
									throw new Exception("line " ~ 
										conv!(size_t,string)(idx) ~ 
										" missing tick after regex expression");
								}
								nxtRght = userCodeBrace!('}')(it,nxtRght+1);
							}
							if(!done)
								tmp.pushBack(it[frstLft+1..lstRght]);
								tmp.pushBack('\n');
								ps = ParseState.RegexCode;
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
				int nxtLft = -1;
				while(-1 != (nxtLft = userCodeBrace!('{')(it,nxtLft+1)) ) {
					braceStack++;
				}
				int nxtRght = userCodeBrace!('}')(it,0);
				int lstRght = -1;
				bool done = false;
				while(-1 != nxtRght) {
					braceStack--;
					//println(__FILE__,__LINE__, braceStack);
					if(braceStack <= 0 && !done) {
						lstRght = nxtRght;
						done = true;	
						//println(cast(string)it[frstLft+1..lstRght]);
						this.regexCode.peekBack().setCode(
							it[frstLft+1..lstRght]
							);
						ps = ParseState.None;
					} else if(braceStack <= 0 && done) {
						throw new Exception("line " ~ 
							conv!(size_t,string)(idx) ~ 
							" missing tick after regex expression");
					}
					nxtRght = userCodeBrace!('}')(it,nxtRght+1);
				}
				break;
			}
			}
		}
		println(this.userCode);
	}
}
