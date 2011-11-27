module dex.input;

import hurt.container.vector;
import hurt.conv.conv;
import hurt.io.stream;
import hurt.io.file;
import hurt.io.stdio;
import hurt.util.array;
import hurt.util.stacktrace;
import hurt.string.stringbuffer;

import dex.strutil;

/** The input parser creates objects of regex, useraction for every given regex
 *  code. An example could look like:
 *  "[:digit:][:digit:_]*" {: printfln("int %s", this.getCurrentLex()); :}
 *  
 *  The RegexCode object member regex will contain the string between the
 *  ticks. The RegexCode member code will contain everything between {: and :}
 *  
 *  The propority member is simple the line the regex code was found in. This is
 *  importent because the resulting state machine can have multiple accepting
 *  states for a given input. To resolve this conflict the user code of the
 *  RegexCode with the lowest priority is run.
 */
class RegexCode {
	private string regex;
	private string code;
	private size_t priority;

	this(char[] regex, size_t priority) {
		this.regex ~= regex.idup;
		this.priority = priority;
	}

	public void setCode(string code) {
		this.code ~= code;
	}

	public void setCode(char[] code) {
		this.code ~= code.idup;
	}

	public override string toString() {
		return regex ~ " " ~ conv!(size_t,string)(this.priority) 
			~ " : " ~ code;
	}

	public string getRegEx() {
		return this.regex;
	}

	public string getCode() {
		return this.code;
	}

	public size_t getPriority() const {
		return this.priority;
	}
}

/** The Input Parser can be in any of the four states. This is used to keep
 *  track of the parsing of the input file.
 */
enum ParseState {
	None,
	UserCode,
	InputErrorCode,
	RegexCode
}

/** The Input parser class. A given .dex file this class find all defined
 *  userCode as well as all RegexCode,action pairs.
 */
class Input {
	private string filename;
	private string userCode;
	private string inputErrorCode;
	private File ins;
	private Vector!(RegexCode) regexCode;

	/** This function is called to make sure that the given filename
	 *  if of form *.dex
	 *
	 *  @param filename The filename to check
	 *
	 *  @return true if ends on .dex false otherwise
	 */
	private static bool isWellFormedFilename(in string filename) {
		scope Trace st = new Trace("isWellFormedFilename");
		if(filename.length <= 4)
			return false;

		if(filename[$-4..$] != ".dex")
			return false;

		return true;
	}

	/** The constructor of the Input Parser. If this returns the file is parsed.
	 *
	 *  @param filename The filename of the file to parse.
	 */
	this(string filename) {
		// init member
		scope Trace st = new Trace("input this");
		this.filename = filename;
		this.regexCode = new Vector!(RegexCode)(16);

		// test if file has formated name, very bad test if the file is valid
		if(!isWellFormedFilename(filename))
			throw new Exception("Filename not well formed");
	
		// test if the file exists
		if(!exists(this.filename))
			throw new Exception("File does not Exist");

		// open the file
		this.ins = new File(filename);

		//parse the file
		this.parseFile();

		// check that at least one file exists
		if(this.regexCode.getSize() == 0) {
			throw new Exception(filename ~ " doesn't contain any regex code");
		}
	}

	~this() {
		if(this.ins.isOpen())
			this.ins.close();
		else
			println("file should have been opened");

		assert(!this.ins.isOpen(), "file should not be open");
	}

	/** File is parse expression by expression so to speak. The parser starts in
	 *  state None if its encounter a %% it enters the usercode mode. This
	 *  mode is only left if another %% is found. If in Mode None a " is
	 *  encountered the mode RegexCode is entered. To leave this mode a ", {:
	 *  and a :} must be found. If a {% is found the inputError Mode is entered.
	 *  That means everything till the next %} is placed wherever an error in
	 *  the lexer must be handled. All these modes are not entered if the end
	 *  of scope for the mode is on the same line as the start.
	 */
	private void parseFile() {
		scope Trace st = new Trace("parseFile");
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
						this.userCode ~= "\n\n" ~ uc;
					} else {
						ps = ParseState.UserCode;
						tmp.pushBack(it[ucLow+2..$]);
						tmp.pushBack("\n");
					}
					break;
				}
				int ieLow = userCodeBrace!(false,'%')(it, 0);
				if(ieLow != -1) {
					int ieUp = userCodeBrace!(true,'%')(it, ieLow+2);
					if(ieUp != -1) {
						char[] uc = it[ieLow+2..ieUp];
						this.inputErrorCode ~= "\n" ~ uc;
					} else {
						ps = ParseState.InputErrorCode;
						tmp.pushBack(it[ieLow+2..$]);
						tmp.pushBack("\n");
					}
					break;
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
						this.regexCode.append(
							// the line number stored in the idx variable
							// defines the priority of the regex expression
							new RegexCode(it[rcLow+1..rcUp], idx));
						assert(this.regexCode.getSize() >= 1, 
							conv!(long,string)(this.regexCode.getSize()));

						int rucLow = userCodeBrace!(false,':')(it,rcUp+1);
						if(rucLow == -1)
							throw new Exception("line " ~ 
								conv!(size_t,string)(idx) ~ 
								" should contain {: " ~
								"aka regex code start symbol");

						int rucUp = userCodeBrace!(true,':')(it,rucLow+2);
						if(rucUp == -1) {
							tmp.pushBack(it[rucLow+2..$]);
							tmp.pushBack('\n');
							ps = ParseState.RegexCode;
						} else {
							this.regexCode.peekBack().setCode(
								it[rucLow+2..rucUp]);
						}
					}
					break;
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
					this.userCode ~= '\n';
					tmp.clear();
					ps = ParseState.None;
				}
				break;
			}
			case ParseState.InputErrorCode: {
				int ieLow = userCodeBrace!(true,'%')(it);
				if(ieLow == -1) {
					tmp.pushBack(it);
					tmp.pushBack("\n");
				} else {
					tmp.pushBack(it[0..ieLow]);
					this.inputErrorCode ~= tmp.getString();
					tmp.clear();
					ps = ParseState.None;
				}
				break;
			}
			case ParseState.RegexCode: {
				int rucUp = userCodeBrace!(true,'}')(it);
				if(rucUp == -1) {
					tmp.pushBack(it);
					tmp.pushBack('\n');
				} else {
					tmp.pushBack(it[0..rucUp]);
					tmp.pushBack('\n');
					this.regexCode.peekBack().setCode(tmp.getString());
					tmp.clear();
					ps = ParseState.None;
				}
				break;
			}
			}
		}
	}

	public Vector!(RegexCode) getRegExCode() {
		return this.regexCode;
	}

	public string getUserCode() {
		return this.userCode;
	}

	public string getInputErrorCode() {
		return this.inputErrorCode;
	}
}
