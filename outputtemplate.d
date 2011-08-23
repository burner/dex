abstract class Lexer {
	public void run();
	public dchar eolChar() const;
	public dchar eofChar() const;
}

private import hurt.io.stream;
private import hurt.io.file;
private import hurt.conv.conv;
private import hurt.string.utf;

class DexLexer : Lexer {
	import hurt.io.stdio;
	import std.stdio;
	private string filename;
	private hurt.io.stream.BufferedFile file;

	private size_t lineNumber;
	private size_t charIdx;
	private dchar[] currentLine;

	this(string filename) {
		this.filename = filename;
		this.lineNumber = 0;

		if(!exists(this.filename))
			throw new Exception(__FILE__ ~ ":" ~ conv!(int,string)(__LINE__) ~
				this.filename ~ " does not exists");

		this.file = new hurt.io.stream.BufferedFile(this.filename);
		this.getNextLine();
	}

	public void printFile() {
		foreach(char[] it; this.file) {
			foreach(char jt; it)
				print(jt);
			println();
		}
	}

	public size_t getCurrentLineCount() const {
		return this.lineNumber;
	}

	public size_t getCurrentIndexInLine() const {
		return this.charIdx;
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

	public void run() { // a stupid run methode could look like this »«¢¢ſð@
		println(__LINE__, this.isEOF(), this.isEmpty());
		/*dchar next = ' ';
		while(dchar.init != (next = getNextChar()))
			print(next);
		*/
		while(!isEmpty()) {
			if(this.getCurrentIndexInLine() == 0) {
				print(this.getCurrentLineCount());
			}
			print(getNextChar());
		}
	}

	public dchar eolChar() const {
		return '\n';
	}

	public dchar eofChar() const {
		return dchar.init;
	}
}

// some nice utf8 cömments ¼³²³½ŧłđſðđłđ]ðđĸłæa
void main() {
	DexLexer dl = new DexLexer("outputtemplate.d");
	dl.run();
}
